class FiberUtilsTestCase extends ClassyTestCase
  @testName: "fiber-utils"

  testServerSynchronize: ->
    Fiber = Npm.require 'fibers'
    Future = Npm.require 'fibers/future'

    state = []
    fiberBody = (number) =>
      state.push number
      # Compute a sum of all items in the state array so far.
      sum = _.reduce state, ((memo, item) -> memo + item), 0
      # Force a fiber yield so other fibers will run and will corrupt state.
      Fiber.yield()
      # Append the sum to the end of the array.
      state.push sum

    # Spawn a bunch of fibers and have them run the fiberBody.
    fibers = []
    numFibers = 10
    doneFibers = 0
    context = {}
    for index in [1..numFibers]
      do (index) ->
        fibers.push Fiber ->
          # Synchronize execution of the fiber body.
          _.synchronize context, 'fiberBody', ->
            fiberBody index
          doneFibers++

    # Run the fibers until they all finish.
    while doneFibers isnt numFibers
      fiber.run() for fiber in fibers

    # Check the state.
    @assertEqual state, [1,1,2,4,3,11,4,26,5,57,6,120,7,247,8,502,9,1013,10,2036]

  testClientSynchronizeStub: ->
    # Test that the synchronize stub is defined on the client and that it works.
    bodyCalled = false
    _.synchronize @, 'test', =>
      bodyCalled = true

    @assertTrue bodyCalled, "Synchronize stub does not work on the client."

# Register test cases.
ClassyTestCase.addTest new FiberUtilsTestCase()
