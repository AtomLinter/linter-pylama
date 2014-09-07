module.exports =
  configDefaults:
    'Executable path': null
    'Ignore errors and warnings (comma-separated)': null
    'Select linters (comma-separated)': 'mccabe,pep8,pyflakes,pep257'

  activate: ->
    console.log 'Linter-Pylama: package loaded,
                 ready to get initialized by AtomLinter.'
