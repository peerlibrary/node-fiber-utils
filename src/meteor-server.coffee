{FiberUtils} = require './server'

import Fiber from 'fibers'
import Future from 'fibers/future'

fiberUtils = new FiberUtils Fiber, Future

export {fiberUtils as FiberUtils}
