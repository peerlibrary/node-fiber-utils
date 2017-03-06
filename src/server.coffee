{FiberUtils} = require './base'
{OrderedFence} = require './fence'

FiberUtils::sleep = (ms) ->
  future = new @Future()
  setTimeout ->
    future.return()
  ,
    ms
  future.wait()
  return

FiberUtils::wrap = (f, scope=null) ->
  (args...) =>
    @Future.wrap(f).apply(scope, args).wait()

FiberUtils::in = (f, scope=null, handleErrors=null) ->
  (args...) =>
    try
      if @Fiber.current
        f.apply(scope, args)
      else
        new @Fiber(->
          f.apply(scope, args)
        ).run()
    catch error
      if handleErrors
        handleErrors.call scope, error
      else
        throw error

    # Function cannot return a value when not already running
    # inside a Fiber, so let us not return a value at all.
    return

FiberUtils::ensure = (f, scope=null, handleErrors=null) ->
  @in(f, scope, handleErrors)()

  # Function cannot return a value when not already running
  # inside a Fiber, so let us not return a value at all.
  return

FiberUtils::synchronize = (guardObject, uniqueId, f, options={}) ->
  # Use the guard object to determine whether we have reentered.
  guards = guardObject._guards ?= {}
  guards[uniqueId] ?= new OrderedFence @Fiber, @Future, options
  topLevel = guards[uniqueId].enter()

  try
    return f()
  finally
    guards[uniqueId].exit topLevel
    delete guards[uniqueId] if uniqueId of guards and not guards[uniqueId].isInUse()

module.exports = {
  FiberUtils
}