class FiberUtilsTestCase extends ClassyTestCase
  @testName: "fiber-utils"

  testServerSynchronize: ->
    Fiber = Npm.require 'fibers'

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

  testServerDeadlock: ->
    Fiber = Npm.require 'fibers'

    # Create two fibers which will grab the guard in reverse order. This would cause
    # a deadlock unless we properly detect it.
    context = {}
    firstSectionReached = false
    secondSectionReached = false
    fiberA = Fiber ->
      FiberUtils.synchronize context, 'guardA', ->
        # Now we yield so that the other fiber may grab this guard.
        Fiber.yield()
        # Then try to grab the other guard.
        FiberUtils.synchronize context, 'guardB', ->
          # If everything works correctly, this should throw an exception. If not, this
          # will cause a deadlock.
          firstSectionReached = true

    fiberB = Fiber ->
      FiberUtils.synchronize context, 'guardB', ->
        # Now also grab the first guard. This will cause a future to be waited upon and
        # therefore this fiber will yield.
        FiberUtils.synchronize context, 'guardA', ->
          # This code will be reached when the first fiber is aborted due to a deadlock.
          secondSectionReached = true

    # Run the first fiber so it acquires guardA and yields.
    fiberA.run()
    # Run the second fiber so it acquires guardB and waits on guardA, yielding.
    fiberB.run()
    # Run the first fiber so it tries to acquire guardB. This should throw and cause the
    # second fiber to be unblocked and let it successfully acquire guardA and finish.
    @assertThrows ->
      fiberA.run()

    @assertFalse firstSectionReached
    @assertTrue secondSectionReached

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
        FiberUtils.synchronize context, 'guard2', (->
          # Entering this section should throw.
        ),
          allowNested: false

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
