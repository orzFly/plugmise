describe 'plugin', ->
  Promise = require 'bluebird'
  Plugmise = require '../lib/plugmise'
  Defer = ->
    defer = {}
    defer.promise = new Promise (resolve, reject) ->
      defer.resolve = resolve
      defer.reject = reject
    defer


  describe 'finish', ->
    it 'should work', (done) ->
      p = new Plugmise()
      p.finish().then done

  describe 'plug', ->
    it 'should work', ->
      p = new Plugmise()
      called = false

      p.plug (a, b) ->
        called = true
        a.should.equal 1
        b.should.equal 3
        Promise.resolve()

      p.call(1, 3).then ->
        called.should.be.true

    it 'should work with non-Promise generator', ->
      p = new Plugmise()
      called = false

      p.plug (a, b) ->
        called = true
        a.should.equal 1
        b.should.equal 3

      p.call(1, 3).then ->
        called.should.be.true

    it 'should work with 4 plugs', ->
      p = new Plugmise()
      defer1 = Defer()
      defer2 = Defer()
      events = []

      p.plug (a, b) ->
        a.should.equal 1
        b.should.equal 3
        events.push "1 called"
        defer1.promise.then ->
          events.push "1.promise finished"
          defer2.resolve()

      p.plug (a, b) ->
        a.should.equal 1
        b.should.equal 3
        events.push "2 called"
        defer2.promise.then ->
          events.push "2.promise finished"

      p.plug (a, b) ->
        a.should.equal 1
        b.should.equal 3
        events.push "3 called"
        defer1.resolve()

      p.plug (a, b) ->
        a.should.equal 1
        b.should.equal 3
        events.push "4 called"
        
      p.call(1, 3).then ->
        events.should.be.eql [
          '1 called'
          '2 called'
          '3 called'
          '4 called'
          '1.promise finished'
          '2.promise finished'
        ]

  describe 'plugAsync', ->
    it 'should work', ->
      p = new Plugmise()
      deferSync = Defer()
      deferAsync = Defer()
      events = []

      p.plug (a, b) ->
        a.should.equal 1
        b.should.equal 3
        events.push "sync plug called"
        deferSync.promise.then ->
          events.push "sync plug finished"

      p.plug (a, b) ->
        a.should.equal 1
        b.should.equal 3
        events.push "sync plug resolver called"
        deferSync.resolve()

      p.plugAsync (a, b) ->
        p.refCount.should.equal 1
        a.should.equal 1
        b.should.equal 3
        events.push "async plug called"
        deferAsync.promise.then ->
          events.push "async plug finished"

      p.call(1, 3).then ->
        events.push "call finished"
        deferAsync.resolve()

        p.refCount.should.equal 1
        p.finish().then ->
          p.refCount.should.equal 0
          events.push "plugmise finished"

          events.should.be.eql [
            'sync plug called'
            'sync plug resolver called'
            'sync plug finished'
            'async plug called'
            'call finished'
            'async plug finished'
            'plugmise finished'
          ]