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
      description: 'Excutable path for external Pylama.
      Example: /usr/local/bin/pylama'
    ignoreErrorsAndWarnings:
      type: 'string'
      default: ''
      description: 'Comma-separated list of errors and warnings.
      Example: E111,E114,D101,D102,DW0311'
    selectLinters:
      type: 'string'
      default: 'mccabe,pep8,pyflakes,pep257'
      description: 'Comma-separated list of the linters.'
    skipFiles:
      type: 'string'
      default: ''
      description: 'Skip files by masks.
      Comma-separated list of a file names.
      Example: */messages.py,*/__init__.py'
    useInternalPylama:
      type: 'boolean'
      default: false
      description: 'Use internal Pylama with Virtualenv detection
      and other cool thing. This is an experimental stuff and may be unstable.'

  activate: ->
    console.log 'Linter-Pylama: package loaded,
                 ready to get initialized by AtomLinter.'
