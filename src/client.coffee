{FiberUtils} = require './base'

# On the client side, there are no fibers so no need to do anything.
FiberUtils::synchronize = (guardObject, uniqueId, body) ->
  body()

module.exports = {
  FiberUtils
}
