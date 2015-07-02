# On the client side, there are no fibers so no need to do anything.
_.synchronize = (guardObject, uniqueId, body) ->
  body()
