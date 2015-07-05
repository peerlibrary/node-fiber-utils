Fiber = Npm.require 'fibers'
Future = Npm.require 'fibers/future'

class FiberUtils.OrderedFence
  constructor: ({@allowRecursive}) ->
    @allowRecursive ?= false

    # A chain of futures to enforce order.
    @_futures = []
    # Fiber that is currently executing the guarded section.
    @_currentFiber = null

  enter: ->
    if Fiber.current is @_currentFiber
      # We allow to reenter the guarded section from the current fiber. We must not establish
      # a dependency in this case as this would cause a deadlock.
      throw new Error "Recursive reentry of guarded section within the same fiber not allowed." unless @allowRecursive

      return false

    future = null
    future = @_futures[@_futures.length - 1] unless _.isEmpty @_futures
    # Establish a new future so others may depend on us.
    ownFuture = new Future()
    @_futures.push ownFuture
    # Depend on any futures before us.
    future?.wait()
    # When we start executing, there can only be one outstanding future.
    assert @_futures[0] is ownFuture
    assert not @_currentFiber
    # Store current fiber.
    @_currentFiber = Fiber.current

    true

  exit: (topLevel) ->
    return unless topLevel

    # Reset current fiber.
    @_currentFiber = null
    # The first future is resolved.
    @_futures.shift()?.return()
