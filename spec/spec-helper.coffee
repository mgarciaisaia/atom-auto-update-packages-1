originalPackageConfig = atom.config.get('auto-update-packages')

window.prepareCleanEnvironment = ->
  waitsForPromise ->
    atom.packages.activatePackage('auto-update-packages')
  runs ->
    atom.config.unset('auto-update-packages')

window.restoreEnvironment = ->
  atom.config.set('auto-update-packages', originalPackageConfig)
