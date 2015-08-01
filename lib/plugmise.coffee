Promise = require 'bluebird'

module.exports = class Plugmise
  constructor: ->
    @refCount = 0
    @syncGenerators = []
    @asyncGenerators = []
    @finishPromise = null
    @finishResolve = null

  _increase: ->
    @refCount += 1

  _decrease: ->
    @refCount -= 1

    if @refCount == 0 and @finishResolve
      @finishResolve(null)
      @finishResolve = null

  _createDisponser: ->
    Promise.resolve(@_increase()).disposer => @_decrease()

  call: (args...) ->
    syncPromise = Promise.settle(@syncGenerators.map (fn) -> fn(args...)).return(null)

    if @asyncGenerators.length > 0
      asyncPromise = Promise.using @_createDisponser(), =>
        Promise.settle(@asyncGenerators.map (fn) -> fn(args...)).return(null)

    syncPromise

  plug: (fn) ->
    @syncGenerators.push fn

  plugAsync: (fn) ->
    @asyncGenerators.push fn

  finish: (fn) ->
    return @finishPromise if @finishPromise

    if @refCount == 0
      @finishPromise = Promise.resolve(null)
    else
      @finishPromise = new Promise (resolve) =>
        @finishResolve = resolve