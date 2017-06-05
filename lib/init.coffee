module.exports = {
  config: {
    pylamaVersion: {
      type: 'string'
      default: 'internal'
      enum: ['external', 'internal']
      description: 'Switch between internal Pylama (with Virtualenv detection
      and other cool things) or external stable Pylama (do not forget to
      specify executable path)'
      order: 0
    }
    interpreter: {
      type: 'string'
      default: 'python, python.exe'
      description: '''Python interpreter for `internal` Pylama.
      Comma-separated list of path to Python executables. The first path has a
      higher priority over the last one. By default linter-pylama will
      automatically try to find virtual environments or global Python executable.
      If you use this config, automatic lookup will have lowest priority.
      You can use `$PROJECT` or `$PROJECT_NAME` substitution for project-specific
      paths.\n
      For example:
      `~/.venv/$PROJECT_NAME/bin/python, $PROJECT/venv/bin/python, /usr/bin/pytho3, python`
      '''
      order: 1
    }
    executablePath: {
      type: 'string'
      default: 'pylama, pylama.exe'
      description: """Excutable path for `external` Pylama.
      Comma-separated list of path to Pylama executables. The first path has a
      higher priority over the last one.
      You can use `$PROJECT` or `$PROJECT_NAME` substitution for project-specific
      paths.\n
      For example:
      `~/.venv/$PROJECT_NAME/bin/pylama, $PROJECT/venv/bin/pylama, /usr/local/bin/pylama, pylama`
      """
      order: 2
    }
    configFileLoad: {
      type: 'string'
      default: 'Don\'t use pylama config'
      enum: [
        'Don\'t use pylama config',
        'Use pylama config']
      title: 'Use Pylama configuration file'
      order: 3
    }
    configFileName: {
      type: 'string'
      default: 'pylama.ini'
      title: 'Configuration file name'
      order: 4
    }
    ignoreErrorsAndWarnings: {
      type: 'string'
      default: 'D203,D212,D213,D404'
      description: """Comma-separated list of errors and warnings.
      For example: `ED203,D212,D213,D404,E111,E114,D101,D102,DW0311`
      See more: https://goo.gl/jeYN96, https://goo.gl/O8xhLM
      """
      order: 5
    }
    skipFiles: {
      type: 'string'
      default: ''
      description: """Skip files by masks.
      Comma-separated list of a file names.
      For example: `*/messages.py,*/__init__.py`
      """
      order: 6
    }
    lintOnFly: {
      type: 'boolean'
      default: true
      description: "Enable linting on the fly. Need to restart Atom"
      order: 7
    }
    usePep8: {
      type: 'boolean'
      default: true
      title: 'Use pycodestyle/pep8'
      description: 'Use pycodestyle/pep8 style guide checker'
      order: 8
    }
    usePep257: {
      type: 'boolean'
      default: true
      title: 'Use pydocstyle/pep257'
      description: 'Use pydocstyle/pep257 docstring conventions checker'
      order: 9
    }
    usePyflakes: {
      type: 'boolean'
      default: true
      title: 'Use Pyflakes'
      description: 'Use Pyflakes checker'
      order: 10
    }
    usePylint: {
      type: 'boolean'
      default: false
      title: 'Use PyLint'
      description: 'Use PyLint linter. May be unstable for internal Pylama.
      For use with external Pylama you should install pylama_pylint module
      ("pip install pylama-pylint")'
      order: 11
    }
    useMcCabe: {
      type: 'boolean'
      default: true
      title: 'Use McCabe'
      description: 'Use McCabe complexity checker'
      order: 12
    }
    useRadon: {
      type: 'boolean'
      default: false
      title: 'Use Radon'
      description: 'Use Radon complexity and code metrics checker'
      order: 13
    }
    useIsort: {
      type: 'boolean'
      default: false
      title: 'Use isort'
      description: 'Use isort imports checker'
      order: 14
    }
    isortOnSave: {
      type: 'boolean'
      default: false
      title: 'isort imports on save (experimental)'
      order: 15
    }
  }


  activate: ->
    require('atom-package-deps').install 'linter-pylama'


  provideLinter: ->
    LinterPylama = require './linter-pylama.coffee'
    provider = new LinterPylama()
    {
      grammarScopes: [
        'source.python'
        'source.python.django'
      ]
      name: 'Pylama'
      scope: 'file'
      lint: provider.lint
      lintsOnChange: do provider.isLintOnFly
    }
}
