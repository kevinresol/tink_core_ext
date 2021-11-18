package tink.core.ext;

import tink.core.Callback;
import tink.core.Signal;
import tink.core.Error;

using Lambda;

interface SubscriptionObject extends LinkObject {
	final error:Signal<Error>;
}

@:forward
abstract Subscription(SubscriptionObject) from SubscriptionObject to SubscriptionObject {
	@:to public inline function asLink():CallbackLink return this;
	
	@:from public static inline function ofMany(subscriptions:Array<Subscription>):Subscription {
		return new Subscriptions(subscriptions);
	}
}

class SimpleSubscription extends SimpleLink implements SubscriptionObject {
	public final error:Signal<Error>;
	
	public function new(f:CallbackLink, error) {
		super(f);
		this.error = error;
	}
}

class Subscriptions implements SubscriptionObject {
	public final error:Signal<Error>;
	
	final callbacks:CallbackLink;
	
	public function new(list:Array<Subscription>) {
		callbacks = [for(sub in list) sub.asLink()];
		error = new Signal(cb -> [for(sub in list) sub.error.handle(cb)]);
	}
	
	public function cancel() {
		callbacks.cancel();
	}
}