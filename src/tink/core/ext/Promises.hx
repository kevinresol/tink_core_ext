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
					
					obj.push({
						name: name,
						kind: FVar(promiseType(field.type.toComplex())),
						pos: field.pos,
						meta: [{name: ':optional', pos: field.pos}],
					});
					
					exprs.push(
						macro tink.core.Promise.lift(__obj.$name)
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