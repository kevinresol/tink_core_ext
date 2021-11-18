package tink.core.ext;

import haxe.macro.Expr;
import haxe.macro.Context;

using tink.CoreApi;
#if macro
using tink.MacroApi;
#end

class Outcomes {
	public static macro function multi(e:Expr, ?combined:Expr):Expr {
		return switch e.expr {
			case EObjectDecl(fields):
				final values = [
					for (field in fields) {
						final name = field.field;
						switch Context.typeof(field.expr).getID() {
							case 'tink.core.Outcome': // ok;
							case v:
								field.expr.pos.error('$v should be tink.core.Outcome');
						}
						macro @:pos(field.expr.pos) o.$name;
					}
				];
				final sucesses = [for (field in fields) macro tink.core.Outcome.Success($i{field.field})];
				final failures = {
					final base = [for (_ in fields) macro _];
					[
						for (i in 0...fields.length) {
							final copy = base.copy();
							copy[i] = macro @:pos(fields[i].expr.pos) tink.core.Outcome.Failure(e);
							macro $a{copy};
						}
					];
				}
				final result = switch combined {
					case macro null:
						EObjectDecl([for (field in fields) {field: field.field, expr: macro $i{field.field}}]).at(e.pos);
					case v:
						combined;
				}

				return macro @:pos(e.pos) {
					final o = $e;
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
