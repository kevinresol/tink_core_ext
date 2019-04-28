package tink.core.ext;

import haxe.macro.Expr;
import haxe.macro.Context;

using tink.CoreApi;
#if macro
using tink.MacroApi;
#end

class Promises {
	
	public static macro function multi(e:Expr, ?lazy:Expr):Expr {
		return switch Context.typeof(e) {
			case TAnonymous(_.get() => {fields: fields}):
				
				var obj:Array<Field> = [];
				var exprs:Array<Expr> = [];
				
				for(field in fields) {
					var name = field.name;
					
					var ct = promiseType(field.type.toComplex());
					switch ct {
						case TPath({name: 'DirectType', pack: ['tink', 'macro']}): field.pos.error('Cannot determine the type of ${field.name}, please hint its type explicitly');
						case _: // ok
					}
					obj.push({
						name: name,
						kind: FVar(ct),
						pos: field.pos,
						meta: [{name: ':optional', pos: field.pos}],
					});
					
					exprs.push(
						macro (__obj.$name:Promise<$ct>)
							.handle(@:privateAccess tink.core.ext.Promises.handle(cb, function(v) __ctx.ret.$name = v, __ctx))
					);
				}
				
				switch lazy {
					case macro null: lazy = macro false;
					case _: //
				}
				
				var ct = TAnonymous(obj);
				return macro @:pos(e.pos) {
					var __obj = $e;
					var __ctx:{ret:$ct, count:Int} = {ret: {}, count: $v{fields.length}};
					Promise.lift(Future.async(function(cb) $b{exprs}, $lazy));
				}
				
			default:
				e.pos.error('Expected inline object declaration');
		}
	}
	
	static function handle<T, R>(cb:Outcome<R, Error>->Void, assign:T->Void, ctx:{ret:R, count:Int}) {
		return function(o) switch o {
			case Success(v):
				assign(v);
				if(--ctx.count == 0) cb(Success(ctx.ret));
			case Failure(e):
				cb(Failure(e));
		}
	}
	
	#if macro
	static function promiseType(ct:ComplexType) {
		return Context.typeof(macro {
			function f<A>(p:tink.core.Promise<A>):A return null;
			f((null:$ct));
		}).toComplex();
	}
	#end
}