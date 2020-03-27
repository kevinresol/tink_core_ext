package;

import tink.core.ext.*;

using tink.CoreApi;

@:asserts
class OutcomesTest {
	
	public function new() {}
	
	public function multi() {
		var outcome = Outcomes.multi({
			foo: foo(),
			bar: bar(),
		});
		
		outcome.next(function(o) {
			asserts.assert(o.foo == 1);
			asserts.assert(o.bar == 'b');
			return Noise;
		})
		.handle(asserts.handle);
		return asserts;
	}
	
	public function multiWithError() {
		var outcome = Outcomes.multi({
			foo: foo(),
			bar: bar(),
			baz: baz(),
		});
		
		switch outcome {
			case Success(_): asserts.fail(new Error('Should fail'));
			case Failure(e): asserts.assert(e.message == 'f');
		}
		return asserts.done();
	}
	
	function foo():Outcome<Int, Error> return Success(1);
	function bar():Outcome<String, Error> return Success('b');
	function baz():Outcome<String, Error> return Failure(new Error('f'));
}