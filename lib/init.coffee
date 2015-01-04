module.exports =
  config:
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
    skipFiles:
      type: 'string'
      default: ''
      description: 'Skip files by masks.
      Comma-separated list of a file names.
      Example: */messages.py,*/__init__.py'
    useMccabe:
      type: 'boolean'
      default: true
      description: 'Use McCabe checker.'
    usePep8:
      type: 'boolean'
      default: true
      description: 'Use PEP8 style guide checker.'
    usePyflakes:
      type: 'boolean'
      default: true
      description: 'Use PyFlakes checker.'
    usePep257:
      type: 'boolean'
      default: true
      description: 'Use PEP257 docstring conventions checker.'
    usePylint:
      type: 'boolean'
      default: false
      description: 'Use PyLint linter. May be unstable for internal Pylama.
      For use with external Pylama you should install pylama_pylint module
      ("pip install pylama-pylint").'
    pylamaVersion:
      type: 'string'
      default: 'external'
      enum: ['external', 'internal']
      description: 'Select between internal Pylama (with Virtualenv detection
      and other cool things or external stable Pylama (do not forget to
      specify executable path).'

  activate: ->
    console.log 'Linter-Pylama: package loaded,
                 ready to get initialized by AtomLinter.'
