FiberUtils.synchronize = (guardObject, uniqueId, body, options={}) ->
  # Use the guard object to determine whether we have reentered.
  guards = guardObject._guards ?= {}
  guards[uniqueId] ?= new FiberUtils.OrderedFence options
  topLevel = guards[uniqueId].enter()

  try
    return body()
  finally
    guards[uniqueId].exit topLevel
    delete guards[uniqueId] if uniqueId of guards and not guards[uniqueId].isInUse()
