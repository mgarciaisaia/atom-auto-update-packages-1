fs = null
path = null
PackageUpdater = null

getFs = ->
  fs ?= require 'fs-plus'

NAMESPACE = 'auto-update-packages'
CONFIG_KEY_INTERVAL_MINUTES = 'intervalMinutes'

MINIMUM_AUTO_UPDATE_BLOCK_DURATION_MINUTES = 15

CONFIG_DEFAULTS = { }
CONFIG_DEFAULTS[CONFIG_KEY_INTERVAL_MINUTES] = {
  type: 'integer',
  default: 6 * 60,
  minimum: MINIMUM_AUTO_UPDATE_BLOCK_DURATION_MINUTES
}

WARMUP_WAIT = 10 * 1000

module.exports =
  config: CONFIG_DEFAULTS

  activate: (state) ->
    @updateNowCommand = atom.commands.add 'atom-workspace', "#{NAMESPACE}:update-now", =>
      @updatePackages(false)

    setTimeout =>
      @enableAutoUpdate()
    , WARMUP_WAIT

  deactivate: ->
    @disableAutoUpdate()
    @updateNowCommand.dispose()

  enableAutoUpdate: ->
    @updatePackagesIfAutoUpdateBlockIsExpired()

    @autoUpdateCheck = setInterval =>
      @updatePackagesIfAutoUpdateBlockIsExpired()
    , @getAutoUpdateCheckInterval()

    @configSubscription = atom.config.onDidChange =>
      @disableAutoUpdate()
      @enableAutoUpdate()

  disableAutoUpdate: ->
    @configSubscription?.dispose()
    @configSubscription = null

    clearInterval(@autoUpdateCheck) if @autoUpdateCheck
    @autoUpdateCheck = null

  updatePackagesIfAutoUpdateBlockIsExpired: ->
    lastUpdateTime = @loadLastUpdateTime() || 0
    if Date.now() > lastUpdateTime + @getAutoUpdateBlockDuration()
      @updatePackages()

  updatePackages: (isAutoUpdate = true) ->
    PackageUpdater ?= require './package-updater'
    PackageUpdater.updatePackages(isAutoUpdate)
    @saveLastUpdateTime()

  getAutoUpdateBlockDuration: ->
    minutes = atom.config.get([NAMESPACE, CONFIG_KEY_INTERVAL_MINUTES].join('.'))

    if minutes < MINIMUM_AUTO_UPDATE_BLOCK_DURATION_MINUTES
      minutes = MINIMUM_AUTO_UPDATE_BLOCK_DURATION_MINUTES

    minutes * 60 * 1000

  getAutoUpdateCheckInterval: ->
    @getAutoUpdateBlockDuration() / 15

  # auto-upgrade-packages runs on each Atom instance,
  # so we need to share the last updated time via a file between the instances.
  loadLastUpdateTime: ->
    try
      string = getFs().readFileSync(@getLastUpdateTimeFilePath())
      parseInt(string)
    catch
      null

  saveLastUpdateTime: ->
    getFs().writeFileSync(@getLastUpdateTimeFilePath(), Date.now().toString())

  getLastUpdateTimeFilePath: ->
    path ?= require 'path'
    dotAtomPath = getFs().absolute('~/.atom')
    path.join(dotAtomPath, 'storage', "#{NAMESPACE}-last-update-time")
