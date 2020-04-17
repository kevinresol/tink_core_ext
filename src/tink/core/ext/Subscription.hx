package tink.core.ext;

import tink.core.Callback;
import tink.core.Signal;
import tink.core.Error;

using Lambda;

interface SubscriptionObject extends LinkObject {
	var error(default, null):Signal<Error>;
}

@:forward
abstract Subscription(SubscriptionObject) from SubscriptionObject to SubscriptionObject {
	@:to public inline function asLink():CallbackLink return this;
	
	@:from public static inline function ofMany(subscriptions:Array<Subscription>):Subscription {
		return new Subscriptions(subscriptions);
	}
}

class SimpleSubscription extends SimpleLink implements SubscriptionObject {
	public var error(default, null):Signal<Error>;
	
	public function new(f:CallbackLink, error) {
		super(f);
		this.error = error;
	}
}

class Subscriptions implements SubscriptionObject {
	public var error(default, null):Signal<Error>;
	
	var callbacks:CallbackLink;
	
	public function new(list:Array<Subscription>) {
		callbacks = [for(sub in list) sub.asLink()];
		error = new Signal(function(cb) return [for(sub in list) sub.error.handle(cb)]);
	}
	
	public function cancel() {
		callbacks.cancel();
	}
}