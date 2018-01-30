package tink.core.ext;

import haxe.macro.Expr;
import haxe.macro.Context;

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
					
					exprs.push(macro tink.core.Promise.lift(__obj.$name).handle(function(o) switch o {
						case Success(v):
							__ret.$name = v;
							if(--__count == 0) cb(Success(__ret));
						case Failure(e):
							cb(Failure(e));
					}));
				}
				
				switch lazy {
					case macro null: lazy = macro false;
					case _: //
				}
				
				var ct = TAnonymous(obj);
				return macro @:pos(e.pos) {
					var __obj = $e;
					var __ret:$ct = {};
					var __count = $v{fields.length};
					Promise.lift(Future.async(function(cb) $b{exprs}, $lazy));
				}
				
			default:
				e.pos.error('Expected inline object declaration');
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