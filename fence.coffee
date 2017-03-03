Fiber = Npm.require 'fibers'
Future = Npm.require 'fibers/future'

class FiberUtils.OrderedFence
  constructor: ({@allowRecursive, @allowNested, @breakDeadlocks}) ->
    @allowRecursive ?= true
    @allowNested ?= true
    @breakDeadlocks ?= true

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

    if Fiber.current._guardsActive > 0 and not @allowNested
      # By default we disallow nested guards in order to prevent the possibility of deadlock from occuring.
      throw new Error "Nesting of guarded sections is not allowed."

    # Track dependencies.
    dependedFiber = null
    if @_currentFiber
      Fiber.current._dependencies ?= []
      Fiber.current._dependencies.push @_currentFiber
      dependedFiber = @_currentFiber

      # Search for cycles.
      visited = []
      queue = [Fiber.current]
      loop
        node = queue.shift()
        break unless node

        if node in visited
          if @breakDeadlocks
            # Remove our dependency.
            Fiber.current._dependencies = _.without Fiber.current._dependencies, @_currentFiber
            # Prevent deadlock.
            throw new Error "Dependency cycle detected between guarded sections."

          console.warn "Dependency cycle detected between guarded sections. Deadlock not broken."
          break

        visited.push node
        queue = queue.concat node._dependencies
      # Free references to fibers.
      queue = null
      visited = null

    future = null
    future = @_futures[@_futures.length - 1] unless _.isEmpty @_futures
    # Establish a new future so others may depend on us.
    ownFuture = new Future()
    @_futures.push ownFuture
    # Depend on any futures before us.
    future?.wait()
    # Remove dependency.
    Fiber.current._dependencies = _.without Fiber.current._dependencies, dependedFiber if dependedFiber
    # When we start executing, there can only be one outstanding future.
    assert @_futures[0] is ownFuture
    assert not @_currentFiber
    # Store current fiber.
    @_currentFiber = Fiber.current
    @_currentFiber._guardsActive ?= 0
    @_currentFiber._guardsActive++

    true

  exit: (topLevel) ->
    return unless topLevel

    # Reset current fiber.
    assert @_currentFiber._guardsActive > 0
    @_currentFiber._guardsActive--
    @_currentFiber = null
    # The first future is resolved.
    @_futures.shift()?.return()
