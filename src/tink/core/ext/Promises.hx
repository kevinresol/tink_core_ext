package tink.core.ext;

import haxe.macro.Expr;
import haxe.macro.Context;

#if macro
using tink.MacroApi;
#end

class Promises {
	public static macro function multi(e:Expr):Expr {
		return switch Context.typeof(e) {
			case TAnonymous(_.get() => {fields: fields}):
				var vars = [];
				var results = [];
				var promises = [];
				
				for(field in fields) {
					var name = field.name;
					var varname = '__promises_$name';
					var type = field.type;
					var ct = type.toComplex();
					
					
					vars.push({
						expr: null,
						name: varname,
						type: promiseType(ct),
					});
					
					promises.push(macro tink.core.Promise.lift(__obj.$name).next(function(v) {
						$i{varname} = v;
						return tink.core.Noise.Noise.Noise;
					}));
					
					results.push({
						field: name,
						expr: macro $i{varname},
					});
				}
				
				return macro {
					var __obj = $e;
					${EVars(vars).at()}
					var __promises = $a{promises};
					tink.core.Promise.inParallel(__promises)
						.next(function(_) return ${EObjectDecl(results).at()});
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