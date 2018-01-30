package ;

import tink.unit.*;
import tink.testrunner.*;
import tink.core.ext.*;

using tink.CoreApi;

@:asserts
class RunTests {

  static function main() {
    Runner.run(TestBatch.make([
      new RunTests(),
    ])).handle(Runner.exit);
  }
  
  function new() {}
  
  public function test() {
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
  
  public function lazy() {
    Promises.multi({
      d: dummy(),
    }, true);
    haxe.Timer.delay(function() {
      asserts.assert(!run);
      asserts.done();
    }, 100);
    return asserts;
  }
  
  var run = false;
  function foo() return delay('foo', 100);
  function bar() return delay('bar', 200);
  function dummy() return Future.async(function(cb) cb(run = true), true);
  function delay(v, i) return Future.async(function(cb) haxe.Timer.delay(cb.bind(v), i));
}