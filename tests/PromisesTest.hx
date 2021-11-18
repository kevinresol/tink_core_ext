package;

import tink.core.ext.*;

using tink.CoreApi;

@:asserts
class PromisesTest {
	
	public function new() {}
	
	public function multi() {
		Promises.multi({
			f: foo(),
			b: bar(),
		})
			.next(o -> {
				asserts.assert(o.f == 'foo');
				asserts.assert(o.b == 'bar');
			})
			.handle(asserts.handle);
		return asserts;
	}
	
	public function privateType() {
		var p = Promise.resolve(({foo:1}:Private));
		Promises.multi({f: p})
			.next(o -> asserts.assert(o.f.foo == 1))
			.handle(asserts.handle);
		return asserts;
	}
	
	
	// public function lazy() {
	//   Promises.multi({
	//     d: dummy(),
	//   });
	//   haxe.Timer.delay(function() {
	//     asserts.assert(!run);
	//     asserts.done();
	//   }, 100);
	//   return asserts;
	// }
	
	public function queue() {
		var counter = 0;
		var queue = Promises.queue();
		var promises = [for(i in 1...4) Promise.lazy(() -> Promise.irreversible((resolve, reject) -> {
			haxe.Timer.delay(() -> {
				counter += i;
				resolve(Noise);
			}, (5-i)*20);
		}))];
		
		asserts.assert(counter == 0);
		queue.queue(() -> promises[0]).handle(o -> asserts.assert(counter == 1));
		queue.queue(() -> promises[1]).handle(o -> asserts.assert(counter == 3));
		asserts.assert(counter == 0);
		queue.queue(() -> promises[2]).handle(o -> {
			asserts.assert(counter == 6);
			asserts.done();
		});
		
		return asserts;
	}
	
	var run = false;
	function foo() return Future.delay(100, 'foo');
	function bar() return Future.delay(200, 'bar');
	function dummy() return Future.irreversible(cb -> cb(run = true));
}

private typedef Private = {foo:Int}