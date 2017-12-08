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