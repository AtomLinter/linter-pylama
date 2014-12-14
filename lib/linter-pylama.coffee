linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"


{exec} = require 'child_process'
{log, warn} = require "#{linterPath}/lib/utils"
path = require 'path'


class LinterPylama extends Linter
  @enable: false
  @pylamaVersion: ''
  @syntax: 'source.python'
  @cmd: ''
  @cfg: null
  linterName: 'pylama'
  regex: ':(?<line>\\d+):(?<col>\\d+):\\s+((((?<error>E)|(?<warning>[CDFNW]))(?<code>\\d+)(:\\s+|\\s+))|(.*?))(?<message>.+)\n'

  constructor: (@editor) ->
    super @editor
    @cfg = atom.config.get('linter-pylama')
    pylamaVersion = @cfg['pylamaVersion']
    if pylamaVersion is 'internal'
      @cmd = path.join(path.dirname(__dirname), 'bin', 'pylama.py')
      @enabled = true
      do @initPythonPath
      do @initCmd
    else
      @cmd = @cfg['executablePath']
      exec "#{@cmd} --version", @executionCheckHandler

  executionCheckHandler: (error, stdout, stderr) =>
    if not @enabled
      versionRegEx = /pylama ([\d\.]+)/
      if versionRegEx.test(stderr)
        @pylamaVersion = versionRegEx.exec(stderr)[1]
      else
        if versionRegEx.test(stdout)
          @pylamaVersion = versionRegEx.exec(stdout)[1]
      if not @pylamaVersion
        result = if error? then '#' + error.code + ': ' else ''
        result += 'stdout: ' + stdout if stdout.length > 0
        result += 'stderr: ' + stderr if stderr.length > 0
        result = result.replace(/\r\n|\n|\r/, '')
        console.error "Linter-Pylama: \"#{@cmd}\" \
        was not executable: \"#{result}\". \
        Please, check executable path in the linter settings."
        return
    @enabled = true
    log "Linter-Pylama: found pylama " + @pylamaVersion
    do @initPythonPath
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
        ignoreErrors = @cfg['ignoreErrorsAndWarnings']
        if ignoreErrors and ignoreErrors.length > 0
          @cmd = "#{@cmd} -i #{ignoreErrors}"
        useMcCabe = if @cfg['useMccabe'] then 'mccabe' else ''
        usePEP8 = if @cfg['usePep8'] then 'pep8' else ''
        usePyFlakes = if @cfg['usePyflakes'] then 'pyflakes' else ''
        usePEP257 = if @cfg['usePep257'] then 'pep257' else ''
        if @cfg['pythonVersion'] is 'python2'
          usePylint = if @cfg['usePylint'] then 'pylint' else ''
        else
          usePylint = if @cfg['usePylint'] then 'pylint3' else ''
        linters = [useMcCabe, usePEP8, usePEP257, usePyFlakes, usePylint].join()
        linters = linters.replace /(,,+)|(,$)/, ''
        if not linters
          linters = 'none'
        @cmd = "#{@cmd} -l #{linters}"
        skipFiles = @cfg['skipFiles']
        if skipFiles
          @cmd = "#{@cmd} --skip #{skipFiles}"
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
