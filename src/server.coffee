{FiberUtils} = require './base'
{OrderedFence} = require './fence'

FiberUtils::ensureFiber = (func) ->
  if @Fiber.current
    func()
  else
    new @Fiber(func).run()

  # Function cannot return a value when not already running
  # inside a Fiber, so let us not return a value at all.
  return

FiberUtils::synchronize = (guardObject, uniqueId, body, options={}) ->
  # Use the guard object to determine whether we have reentered.
  guards = guardObject._guards ?= {}
  guards[uniqueId] ?= new OrderedFence @Fiber, @Future, options
  topLevel = guards[uniqueId].enter()

  try
    return body()
  finally
    guards[uniqueId].exit topLevel
    delete guards[uniqueId] if uniqueId of guards and not guards[uniqueId].isInUse()

module.exports = {
  FiberUtils
}