{FiberUtils} = require './server'

Fiber = Npm.require 'fibers'
Future = Npm.require 'fibers/future'

module.exports = {
  FiberUtils: new FiberUtils Fiber, Future
}