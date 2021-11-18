package tink.core.ext;

import haxe.macro.Expr;
import haxe.macro.Context;

using tink.CoreApi;
#if macro
using tink.MacroApi;
#end

class Promises {
	
	public static macro function multi(e:Expr):Expr {
		return switch haxe.macro.Context.typeof(e) {
			case TAnonymous(_.get() => {fields: fields}):
				
				final obj:Array<Field> = [];
				final exprs:Array<Expr> = [];
				
				for(field in fields) {
					final name = field.name;
					
					final ct = switch field.type.reduce().toComplex() {
						case TPath({name: 'DirectType', pack: ['tink', 'macro']}) | (macro:Dynamic) | (macro:Any):
							field.pos.error('Cannot determine the type of ${field.name}, please hint its type explicitly');
						case ct:
							promiseType(ct);
					}
					
					obj.push({
						name: name,
						kind: FVar(ct),
						pos: field.pos,
					});
					
					exprs.push(macro (__obj.$name:Promise<$ct>).handle(__ctx.handle((r, v) -> r.$name = v)));
				}
				
				final ct = TAnonymous(obj);
				return macro @:pos(e.pos) {
					final __obj = $e;
					Future.irreversible(cb -> {
						final __ctx = new tink.core.ext.Promises.PromisesContainer<$ct>(cb, $v{fields.length});
						$b{exprs}
					}).asPromise();
				}
				
			default:
				e.pos.error('Expected inline object declaration');
		}
	}
	
	public static inline function queue<T>():PromiseQueue<T> {
		return new PromiseQueue();
	}
	
	#if macro
	static function promiseType(ct:ComplexType) {
		return Context.typeof(macro {
			function f<A>(p:tink.core.Promise<A>):A return null;
			f((null:$ct));
		}).toComplex();
	}
	#end
}

class PromisesContainer<T:{}> {
	final result:T = cast {};
	final cb:Outcome<T, Error>->Void;
	var count:Int;
	
	public function new(cb, count) {
		this.cb = cb;
		this.count = count;
	}
	
	public function handle<R>(assign:T->R->Void) {
		return function(o) switch o {
			case Success(v):
				assign(result, v);
				if(--count == 0) cb(Success(result));
			case Failure(e):
				cb(Failure(e));
		}
	}
}

class PromiseQueue<T> {
	final pending:Array<Pair<PromiseTrigger<T>, ()->Promise<T>>>;
	
	var busy:Bool;
	
	public function new() {
		pending = [];
		busy = false;
	}
	
	public inline function asap(f:()->Promise<T>, ?delayNext:()->Future<Noise>):Promise<T> {
		return add(f, pending.unshift, delayNext);
	}
	
	public inline function queue(f:()->Promise<T>, ?delayNext:()->Future<Noise>):Promise<T> {
		return add(f, pending.push, delayNext);
	}
	
	public function add(f:()->Promise<T>, adder:Pair<PromiseTrigger<T>, ()->Promise<T>>->Void, ?delayNext:()->Future<Noise>):Promise<T> {
		if(delayNext == null) delayNext = Future.delay.bind(0, Noise);
		
		function run() {
			busy = true;
			return f();
		}
		
		final ret:Promise<T> =
			if(busy) {
				final trigger = Promise.trigger();
				adder(new Pair(trigger, run));
				trigger;
			} else {
				run();
			}
			
		ret.handle(o -> delayNext().handle(proceed));
		
		return ret;
	}
	
	function proceed() {
		switch pending.shift() {
			case null: busy = false;
			case pair: pair.b().handle(pair.a.trigger);
		}
	}
	
	function terminate() {
		for(pair in pending) pair.a.reject(new Error('Previous operation failed'));
	}
}