# Tink Core Extensions

By design some features are not included in tink_core. Mainly those involve macros, because tink_core it self is supposed to be usable in macro. So here are some extensions to it.

## Promise Extensions

While `Promise.inParallel / inSequence` only supports array of promises of the same type, `Promises.multi` allows mixing different types of promises in the syntax of an anonymous object.

```haxe
var promise1:Promise<Int>;
var promise2:Promise<String>;

Promises.multi({
	int: promise1,
	str: promise2,
}).handle(function(o) switch o {
	case Success(result):
		$type(result.int); // Int
		$type(result.str); // String
	case _:
});
```

## Outcome Extensions

`Outcome.multi` produces a single `Success` if all the provided outcomes are success. The second parameter is an optional expression to produce the combined result from the indivdual results. When not provided, it will by default produce an object with the same field names as the input object.

```haxe
var outcome1:Outcome<Int>;
var outcome2:Outcome<String>;

switch Outcomes.multi({int: outcome1, str: outcome2}) {
	case Success(result):
		$type(result.int); // Int
		$type(result.str); // String
	case Failure(e):
}

switch Outcomes.multi({int: outcome1, str: outcome2}, {foo: int, bar: str}) {
	case Success(result):
		$type(result.foo); // Int
		$type(result.bar); // String
	case Failure(e):
}
```