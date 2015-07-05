module.exports =
  config:
    executablePath:
      type: 'string'
      default: 'pylama'
      description: 'Excutable path for external Pylama.
      Example: /usr/local/bin/pylama'
    lintOnFly:
      type: 'boolean'
      default: true
      descrition: "Enable linting on the fly. Need to restart Atom."
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
      title: 'Use McCabe'
      description: 'Use McCabe complexity checker.'
    usePep8:
      type: 'boolean'
      default: true
      title: 'Use PEP8'
      description: 'Use PEP8 style guide checker.'
    usePyflakes:
      type: 'boolean'
      default: true
      title: 'Use PyFlakes'
      description: 'Use PyFlakes checker.'
    usePep257:
      type: 'boolean'
      default: true
      title: 'Use PEP257'
      description: 'Use PEP257 docstring conventions checker.'
    usePylint:
      type: 'boolean'
      default: false
      title: 'Use PyLint'
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
    if not atom.packages.getLoadedPackage 'linter'
      atom.notifications.addError 'Linter package not found',
      detail: '[linter-pylama] `linter` package not found. \
      Please install https://github.com/AtomLinter/Linter'
      return
    console.log 'Linter-Pylama: package loaded,
                 ready to get initialized by AtomLinter.'

  provideLinter: ->
    LinterPylama = require './linter-pylama.coffee'
    @provider = new LinterPylama()
    return {
      grammarScopes: ['source.python']
      scope: 'file'
      lint: @provider.lint
      lintOnFly: do @provider.isLintOnFly
    }
