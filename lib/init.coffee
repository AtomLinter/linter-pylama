module.exports =
  config:
    enableAsyncMode:
      type: 'boolean'
      default: false
      description: 'Enable async mode. Usefull for checking a lot of
      files. Dont supported with PyLint.'
    executablePath:
      type: 'string'
      default: 'pylama'
      description: 'Pylama excutable path. Example: /usr/local/bin/pylama'
    ignoreErrorsAndWarnings:
      type: 'string'
      default: ''
      description: 'Comma-separated list of errors and warnings.
      Example: E111,E114,D101,D102,DW0311'
    selectLinters:
      type: 'string'
      default: 'mccabe,pep8,pyflakes,pep257'
      description: 'Comma-separated list of the linters.'

  activate: ->
    console.log 'Linter-Pylama: package loaded,
                 ready to get initialized by AtomLinter.'
