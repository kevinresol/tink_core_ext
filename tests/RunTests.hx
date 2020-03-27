package ;

import tink.unit.*;
import tink.testrunner.*;

@:asserts
class RunTests {

  static function main() {
    Runner.run(TestBatch.make([
      new PromisesTest(),
      new OutcomesTest(),
    ])).handle(Runner.exit);
  }
}