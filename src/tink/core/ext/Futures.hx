package tink.core.ext;

import haxe.macro.Expr;
import haxe.macro.Context;

using tink.CoreApi;
#if macro
using tink.MacroApi;
#end

class Futures {
	
	public static macro function multi(e:Expr):Expr {
		return switch haxe.macro.Context.typeof(e) {
			case TAnonymous(_.get() => {fields: fields}):
				
				final obj:Array<Field> = [];
				final exprs:Array<Expr> = [];
				
				for(field in fields) {
					final name = field.name;
					final ct = futureType(field.type.toComplex());
					
					obj.push({
						name: name,
						kind: FVar(ct),
						pos: field.pos,
					});
					
					exprs.push(macro (__obj.$name:Future<$ct>).handle(__ctx.handle(function(r, v) r.$name = v)));
				}
				
				final ct = TAnonymous(obj);
				return macro @:pos(e.pos) {
					final __obj = $e;
					Future.async(function(cb) {
						final __ctx = new tink.core.ext.Futures.FuturesContainer<$ct>(cb, $v{fields.length});
						$b{exprs}
					});
				}
				
			default:
				e.pos.error('Expected inline object declaration');
		}
	}
	
	#if macro
	static function futureType(ct:ComplexType) {
		return Context.typeof(macro {
			function f<A>(p:tink.core.Future<A>):A return null;
			f((null:$ct));
		}).toComplex();
	}
	#end
}

class FuturesContainer<T:{}> {
	final result:T = cast {};
	final cb:T->Void;
	var count:Int;
	
	public function new(cb, count) {
		this.cb = cb;
		this.count = count;
	}
	
	public function handle<R>(assign:T->R->Void) {
		return function(v) {
			assign(result, v);
			if(--count == 0) cb(result);
		}
	}
}