module.exports =
  config:
    pylamaVersion:
      type: 'string'
      default: 'internal'
      enum: ['external', 'internal']
      description: 'Switch between internal Pylama (with Virtualenv detection
      and other cool things) or external stable Pylama (do not forget to
      specify executable path)'
      order: 0
    interpreter:
      type: 'string'
      default: 'python'
      description: 'Python interpreter for internal Pylama
      (python, python3, /usr/bin/python, /usr/local/bin/python3, etc.)'
      order: 1
    executablePath:
      type: 'string'
      default: 'pylama'
      description: 'Excutable path for external Pylama.
      Example: /usr/local/bin/pylama'
      order: 2
    configFileLoad:
      type: 'string'
      default: 'Don\'t use pylama config'
      enum: [
        'Don\'t use pylama config',
        'Use pylama config']
      title: 'Use Pylama configuration file'
      order: 3
    configFileName:
      type: 'string'
      default: 'pylama.ini'
      title: 'Configuration file name'
      order: 4
    ignoreErrorsAndWarnings:
      type: 'string'
      default: 'D203,D212,D213,D404'
      description: 'Comma-separated list of errors and warnings.
      Example: ED203,D212,D213,D404,111,E114,D101,D102,DW0311.
      See more: https://goo.gl/jeYN96, https://goo.gl/O8xhLM'
      order: 5
    skipFiles:
      type: 'string'
      default: ''
      description: 'Skip files by masks.
      Comma-separated list of a file names.
      Example: */messages.py,*/__init__.py'
      order: 6
    lintOnFly:
      type: 'boolean'
      default: true
      description: "Enable linting on the fly. Need to restart Atom"
      order: 7
    usePep8:
      type: 'boolean'
      default: true
      title: 'Use pycodestyle/pep8'
      description: 'Use pycodestyle/pep8 style guide checker'
      order: 8
    usePep257:
      type: 'boolean'
      default: true
      title: 'Use pydocstyle/pep257'
      description: 'Use pydocstyle/pep257 docstring conventions checker'
      order: 9
    usePyflakes:
      type: 'boolean'
      default: true
      title: 'Use Pyflakes'
      description: 'Use Pyflakes checker'
      order: 10
    usePylint:
      type: 'boolean'
      default: false
      title: 'Use PyLint'
      description: 'Use PyLint linter. May be unstable for internal Pylama.
      For use with external Pylama you should install pylama_pylint module
      ("pip install pylama-pylint")'
      order: 11
    useMcCabe:
      type: 'boolean'
      default: true
      title: 'Use McCabe'
      description: 'Use McCabe complexity checker'
      order: 12
    useRadon:
      type: 'boolean'
      default: false
      title: 'Use Radon'
      description: 'Use Radon complexity and code metrics checker'
      order: 13
    useIsort:
      type: 'boolean'
      default: false
      title: 'Use isort'
      description: 'Use isort imports checker'
      order: 14
    isortOnSave:
      type: 'boolean'
      default: false
      title: 'isort imports on save (experimental)'
      order: 15


  activate: ->
    require('atom-package-deps').install 'linter-pylama'
    console.log 'Linter-Pylama: package loaded,
                 ready to get initialized by AtomLinter.'


  provideLinter: ->
    LinterPylama = require './linter-pylama.coffee'
    @provider = new LinterPylama()
    {
      grammarScopes: [
        'source.python'
        'source.python.django'
      ]
      scope: 'file'
      lint: @provider.lint
      lintOnFly: do @provider.isLintOnFly
    }
