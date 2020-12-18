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
				var values = [
					for (field in fields) {
						var name = field.field;
						switch Context.typeof(field.expr).getID() {
							case 'tink.core.Outcome': // ok;
							case v:
								field.expr.pos.error('$v should be tink.core.Outcome');
						}
						macro @:pos(field.expr.pos) o.$name;
					}
				];
				var sucesses = [for (field in fields) macro tink.core.Outcome.Success($i{field.field})];
				var failures = {
					var base = [for (_ in fields) macro _];
					[
						for (i in 0...fields.length) {
							var copy = base.copy();
							copy[i] = macro @:pos(fields[i].expr.pos) tink.core.Outcome.Failure(e);
							macro $a{copy};
						}
					];
				}
				var result = EObjectDecl([for (field in fields) {field: field.field, expr: macro $i{field.field}}]).at(e.pos);

				return macro @:pos(e.pos) {
					var o = $e;
					switch $a{values} {
						case [$a{sucesses}]: tink.core.Outcome.Success($result);
						case $a{failures} : tink.core.Outcome.Failure(e);
					}
				}

			case _:
				e.pos.error('Expected object declaration');
		}
	}
}
