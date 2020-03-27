package tink.core.ext;

import haxe.macro.Expr;
import haxe.macro.Context;

using tink.CoreApi;
#if macro
using tink.MacroApi;
#end

class Outcomes {
	
	public static macro function multi(e:Expr):Expr {
		return switch e.expr {
			case EObjectDecl(fields):
				var values = [for(field in fields) {
					var name = field.field;
					macro o.$name;
				}];
				var sucesses = [for(field in fields) macro Success($i{field.field})];
				var failures = {
					var base = [for(_ in fields) macro _];
					[for(i in 0...fields.length) {
						var copy = base.copy();
						copy[i] = macro Failure(e);
						macro $a{copy};
					}];
				}
				var result = EObjectDecl([for(field in fields) {field: field.field, expr: macro $i{field.field}}]).at(e.pos);
			
				return (macro {
					var o = $e;
					switch $a{values} {
						case [$a{sucesses}]: tink.core.Outcome.Success($result);
						case $a{failures}: tink.core.Outcome.Failure(e);
					}
				}).log();
				
			case _:
				e.pos.error('Expected object declaration');
		}
	}
}