module.exports =
  configDefaults:
    'Executable path': ''
    'Ignore errors and warnings (comma-separated)': ''
    'Select linters (comma-separated)': 'mccabe,pep8,pyflakes,pep257'
    'Enable async mode (dont supported with pylint)': false

  activate: ->
    console.log 'Linter-Pylama: package loaded,
                 ready to get initialized by AtomLinter.'
