module.exports =
  configDefaults:
    'Executable path': null
    'Ignore errors and warnings (comma-separated)': null

  activate: ->
    console.log 'Linter-Pylama: package loaded,
                 ready to get initialized by AtomLinter.'
