package tink.core.ext;

import tink.core.Callback;
import tink.core.Future;
import tink.core.Error;

using Lambda;

interface SubscriptionObject extends LinkObject {
	var error(default, null):Future<Error>;
}

@:forward
abstract Subscription(SubscriptionObject) from SubscriptionObject to SubscriptionObject {
	@:to public inline function asLink():CallbackLink return this;
	
	@:from public static inline function ofMany(subscriptions:Array<Subscription>):Subscription {
		return new Subscriptions(subscriptions);
	}
}

class SimpleSubscription extends SimpleLink implements SubscriptionObject {
	public var error(default, null):Future<Error>;
	
	public function new(f:CallbackLink, error) {
		super(f);
		this.error = error;
	}
}

class Subscriptions implements SubscriptionObject {
	public var error(default, null):Future<Error>;
	
	var callbacks:CallbackLink;
	
	public function new(list:Array<Subscription>) {
		callbacks = [for(sub in list) sub.asLink()];
		error = list.fold(function(sub, combined:Future<Error>) return combined.first(sub.error), cast Future.NEVER);
	}
	
	public function cancel() {
		callbacks.cancel();
	}
}