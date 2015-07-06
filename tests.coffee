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
          FiberUtils.synchronize context, 'fiberBody', ->
            fiberBody index
          doneFibers++

    # Run the fibers until they all finish.
    while doneFibers isnt numFibers
      fiber.run() for fiber in fibers

    # Check the state.
    @assertEqual state, [1, 1, 2, 4, 3, 11, 4, 26, 5, 57, 6, 120, 7, 247, 8, 502, 9, 1013, 10, 2036]

  testServerRecursiveGuards: ->
    context = {}
    section1 = (levels) ->
      return if levels <= 0

      # Recursive guards are allowed by default.
      FiberUtils.synchronize context, 'section1', ->
        section1 levels - 1

    section1 10

    section2 = (levels) ->
      return if levels <= 0

      FiberUtils.synchronize context, 'section2', ->
        section2 levels - 1
      ,
        allowRecursive: false

    @assertThrows ->
      section2 10

  testServerNestedGuards: ->
    context = {}
    @assertThrows ->
      FiberUtils.synchronize context, 'guard1', ->
        FiberUtils.synchronize context, 'guard2', ->
          # Entering this section should throw.

    FiberUtils.synchronize context, 'guard3', ->
      FiberUtils.synchronize context, 'guard4', (->
        # Entering this section should NOT throw.
      ),
        allowNested: true

  testClientSynchronizeStub: ->
    # Test that the synchronize stub is defined on the client and that it works.
    bodyCalled = false
    FiberUtils.synchronize @, 'test', =>
      bodyCalled = true

    @assertTrue bodyCalled, "Synchronize stub does not work on the client."

# Register test cases.
ClassyTestCase.addTest new FiberUtilsTestCase()
