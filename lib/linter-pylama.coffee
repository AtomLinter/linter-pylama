linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"


{exec} = require 'child_process'
{log, warn} = require "#{linterPath}/lib/utils"
path = require 'path'


class LinterPylama extends Linter
  @enabled: false
  @syntax: 'source.python'
  @cmd: ''
  @ignoreErrors: ''
  @pylamaPath: ''
  @skipFiles: ''
  @useMcCabe: false
  @usePEP8: false
  @usePyFlakes: false
  @usePyLint: false
  @usePEP257: false
  linterName: 'pylama'
  regex: ':(?<line>\\d+):(?<col>\\d+):\\s+((((?<error>E)|(?<warning>[CDFNW]))(?<code>\\d+)(:\\s+|\\s+))|(.*?))(?<message>.+)(\r)?\n'

  constructor: (@editor) ->
    super @editor
    do @initPythonPath
    atom.config.observe 'linter-pylama.ignoreErrorsAndWarnings', =>
      ignoreErrors = atom.config.get('linter-pylama.ignoreErrorsAndWarnings')
      if ignoreErrors and ignoreErrors.length > 0
        @ignoreErrors = "-i #{ignoreErrors}"
      else
        @ignoreErrors = ''
      do @initCmd
    atom.config.observe 'linter-pylama.usePylint', =>
      usePyLint = atom.config.get 'linter-pylama.usePylint'
      @usePyLint = if usePyLint then 'pylint' else ''
      do @initCmd
    atom.config.observe 'linter-pylama.useMccabe', =>
      useMcCabe = atom.config.get 'linter-pylama.useMccabe'
      @useMcCabe = if useMcCabe then 'mccabe' else ''
      do @initCmd
    atom.config.observe 'linter-pylama.usePep8', =>
      usePEP8 = atom.config.get 'linter-pylama.usePep8'
      @usePEP8 = if usePEP8 then 'pep8' else ''
      do @initCmd
    atom.config.observe 'linter-pylama.usePep257', =>
      usePEP257 = atom.config.get 'linter-pylama.usePep257'
      @usePEP257 = if usePEP257 then 'pep257' else ''
      do @initCmd
    atom.config.observe 'linter-pylama.usePyflakes', =>
      usePyFlakes = atom.config.get 'linter-pylama.usePyflakes'
      @usePyFlakes = if usePyFlakes then 'pyflakes' else ''
      do @initCmd
    atom.config.observe 'linter-pylama.skipFiles', =>
      skipFiles = atom.config.get 'linter-pylama.skipFiles'
      if skipFiles
        @skipFiles = "--skip #{skipFiles}"
      else
        @skipFiles = ''
      do @initCmd

    atom.config.observe 'linter-pylama.executablePath', =>
      pylamaVersion = atom.config.get 'linter-pylama.pylamaVersion'
      if pylamaVersion is 'external'
        @enabled = false
        @pylamaPath = atom.config.get 'linter-pylama.executablePath'
        exec "#{@pylamaPath} --version", @executionCheckHandler

    atom.config.observe 'linter-pylama.pylamaVersion', =>
      pylamaVersion = atom.config.get 'linter-pylama.pylamaVersion'
      if pylamaVersion is 'internal'
        @pylamaPath = path.join path.dirname(__dirname), 'bin', 'pylama.py'
        @enabled = true
        @pylamaVersion = pylamaVersion
        do @initCmd
      else
        pylamaPath = atom.config.get 'linter-pylama.executablePath'
        if @pylamaPath != pylamaPath
          @enabled = false
          @pylamaPath = pylamaPath
          exec "#{@pylamaPath} --version", @executionCheckHandler

  executionCheckHandler: (error, stdout, stderr) =>
    pylamaVersion = ''
    if not @enabled
      versionRegEx = /pylama(.exe)? ([\d\.]+)/
      if versionRegEx.test(stderr)
        pylamaVersion = versionRegEx.exec(stderr)[0]
      else if versionRegEx.test(stdout)
        pylamaVersion = versionRegEx.exec(stdout)[0]
      if not pylamaVersion
        result = if error? then '#' + error.code + ': ' else ''
        result += 'stdout: ' + stdout if stdout.length > 0
        result += 'stderr: ' + stderr if stderr.length > 0
        result = result.replace(/\r\n|\n|\r/, '')
        console.error "Linter-Pylama: \"#{@pylamaPath}\" \
        was not executable: \"#{result}\". \
        Please, check executable path in the linter settings."
        return
      @enabled = true
    log "Linter-Pylama: found " + pylamaVersion
    do @initCmd

  initPythonPath: =>
    pythonPath = if process.env['PYTHONPATH'] then process.env.PYTHONPATH else ''
    sep = path.delimiter
    process.env.PYTHONPATH =
      "#{path.dirname(@editor.getPath())}#{sep}#{process.env.PWD}"
    if pythonPath
      process.env.PYTHONPATH = "#{process.env.PYTHONPATH}#{sep}#{pythonPath}"

  initCmd: =>
      if @enabled
        @cmd = "#{@pylamaPath}"
        if @ignoreErrors
          @cmd = "#{@cmd} #{@ignoreErrors}"
        if @skipFiles
          @cmd = "#{@cmd} #{@skipFiles}"
        linters = [
          @usePyFlakes
          @useMcCabe
          @usePEP8
          @usePyLint
          @usePEP257
        ].join()
        linters = linters.replace /(,+)/g, ','
        linters = linters.replace /(^,+)|(,+$)/g, ''
        if not linters
          linters = 'none'
        @cmd = "#{@cmd} -l #{linters}"
        log 'Linter-Pylama: initialization completed'


  lintFile: (filePath, callback) =>
    if @enabled
      super filePath, callback

  formatMessage: (match) ->
    type = if match.error then match.error else match.warning
    type = if type then type else ''
    code = if match.code then match.code else ''
    "#{type}#{code} #{match.message}"

module.exports = LinterPylama
