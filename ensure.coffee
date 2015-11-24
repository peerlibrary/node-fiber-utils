Fiber = Npm.require 'fibers'

FiberUtils.ensureFiber = (func) ->
  if Fiber.current
    func()
  else
    new Fiber(func).run()

  # Function cannot return a value when not already running
  # inside a Fiber, so let us not return a value at all.
  return
