Fiber utilities
===============

A package which provides utilities for [node fibers](https://github.com/laverdet/node-fibers).

Installation
------------

NPM:

```
npm install fiber-utils
```

Meteor:

```
meteor add peerlibrary:fiber-utils
```

Initialization (NPM)
--------------------

NPM package does not depend directly on fibers package because you have to make sure you
have loaded fibers package only once. This is why you should install fibers package yourself,
and then initialize this package using symbols imported from the fibers package:

```js
var Fiber = require('fibers');
var Future = require('fibers/future')
var FiberUtils = new require('fiber-utils').FiberUtils(Fiber, Future);
```

Initialization (Meteor)
-----------------------

Meteor package exports initialized `FiberUtils` symbol automatically.
It is initialized with fibers package provided by Meteor and shared through all
its code and packages.

Usage
-----

### `FiberUtils.sleep(ms)` ###

Sleep for `ms` milliseconds inside a current fiber.

### `FiberUtils.wrap(f, scope)` ###

Returns a fiber-enabled synchronous function, which when called will pass any arguments to the
original function `f`, and then wait for the function to finish inside a current fiber.
You can optionally bind `this` to `scope` during execution of `f`.

### `FiberUtils.in(f, scope)` ###

Wrap function `f` in a way to assure that it is run inside a fiber. If the wrapped function is
called already inside a fiber, it is simply normally executed. But if it is outside of any fiber,
then a new fiber is constructed and function `f` is executed inside it.
You can optionally bind `this` to `scope` during execution of `f`.

### `FiberUtils.ensure(f, scope)` ###

Similar to `FiberUtils.in(f, scope)`, but it also calls wrapped function immediately.

### `FiberUtils.synchronize(guardObject, uniqueId, f, options)` ###

Calls function `f` in a way that only one fiber can call it at a time, and all other calls are queued.
After one execution of `f` finished, the next queued call of `f` starts.
This allows one to implement critical sections of your code in which you want to ensure only
one fiber is running it, even if the fiber yields during the execution of the critical section.

`guardObject` serves as an object to synchronize on. You could use one object for everything,
or you might want a fine-grained synchronization and for example use a current object in a method to
limit synchronization to each instance of a class.

`uniqueId` is an ID of this critical section. Again, allows you to decide how granular you want
your synchronization to be. It is namespaced to `guardObject`.

There are the following `options` available:
* `allowRecursive` (default `true`): do you want to allow recursive reentry of a critical section within the same fiber
* `allowNested` (default `true`): do you want to allow nested critical sections, which can lead to deadlocks
* `breakDeadlocks` (default `true`): if we detect a deadlock, we can break the deadlock by making one critical section throw an exception

Examples
--------

```js
class Bank {
  transfer(from, to, amount) {
    FiberUtils.ensure(() => {
      FiberUtils.synchronize(this, 'transfer', () => {
        from.decrease(amount)
        to.increase(amount)
      })
    })
  }  
}
```