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
			.next(function(o) {
				asserts.assert(o.f == 'foo');
				asserts.assert(o.b == 'bar');
				return Noise;
			})
			.handle(asserts.handle);
		return asserts;
	}
	
	public function privateType() {
		var p = Promise.resolve(({foo:1}:Private));
		Promises.multi({f: p})
			.next(function(o) {
				asserts.assert(o.f.foo == 1);
				return Noise;
			})
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
		var promises = [for(i in 1...4) Promise.lazy(() -> new Promise(function(resolve, reject) {
			haxe.Timer.delay(function() {
				counter += i;
				resolve(Noise);
			}, (5-i)*20);
		}))];
		
		asserts.assert(counter == 0);
		queue.queue(() -> promises[0]).handle(o -> {
			asserts.assert(counter == 1);
		});
		queue.queue(() -> promises[1]).handle(o -> {
			asserts.assert(counter == 3);
		});
		asserts.assert(counter == 0);
		queue.queue(() -> promises[2]).handle(o -> {
			asserts.assert(counter == 6);
			asserts.done();
		});
		
		return asserts;
	}
	
	var run = false;
	function foo() return delay('foo', 100);
	function bar() return delay('bar', 200);
	function dummy() return Future.async(function(cb) cb(run = true), true);
	function delay(v, i) return Future.async(function(cb) haxe.Timer.delay(cb.bind(v), i));
}

private typedef Private = {foo:Int}