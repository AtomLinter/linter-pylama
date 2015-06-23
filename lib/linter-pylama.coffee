linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"

fs = require "fs"
{exec} = require 'child_process'
{log, warn} = require "#{linterPath}/lib/utils"
path = require 'path'


class LinterPylama extends Linter
  regex: '(?<file>.+):(?<line>\\d+):(?<col>\\d+):\\s+((((?<error>E)|(?<warning>[CDFNW]))(?<code>\\d+)(:\\s+|\\s+))|(.*?))(?<message>.+)(\r)?\n'

  linterName: 'pylama'
  @syntax: 'source.python'
  @cmd: ''
  @pylamaPath: ''

  constructor: (@editor) ->
    super @editor
    @pylamaVersion_ = atom.config.observe 'linter-pylama.pylamaVersion', =>
      do @initPylama
    @executablePath_ = atom.config.observe 'linter-pylama.executablePath', =>
      do @initPylama
    @ignoreErrorsAndWarnings_ = atom.config.observe 'linter-pylama.ignoreErrorsAndWarnings', =>
      do @initCmd
    @skipFiles_ = atom.config.observe 'linter-pylama.skipFiles', =>
      do @initCmd
    @useMcCabe_ = atom.config.observe 'linter-pylama.useMccabe', =>
      do @initCmd
    @usePEP8_ = atom.config.observe 'linter-pylama.usePep8', =>
      do @initCmd
    @usePEP257_ = atom.config.observe 'linter-pylama.usePep257', =>
      do @initCmd
    @usePyFlakes_ = atom.config.observe 'linter-pylama.usePyflakes', =>
      do @initCmd
    @usePyLint_ = atom.config.observe 'linter-pylama.usePylint', =>
      do @initCmd
    do @initPythonPath
    do @initPylama


  destroy: ->
    super
    do @pylamaVersion_.dispose
    do @executablePath_.dispose
    do @ignoreErrorsAndWarnings_.dispose
    do @skipFiles_.dispose
    do @useMcCabe_.dispose
    do @usePEP8_.dispose
    do @usePEP257_.dispose
    do @usePyFlakes_.dispose
    do @usePyLint_.dispose


  executionCheckHandler: (error, stdout, stderr) =>
    pylamaVersion = ''
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
      @pylamaPath = ''
      return
    log "Linter-Pylama: found " + pylamaVersion


  initPythonPath: =>
    sep = path.delimiter
    pythonPath = if process.env['PYTHONPATH'] then process.env.PYTHONPATH else ''
    pythonPath = pythonPath.split sep
    pythonPath = pythonPath.filter(Boolean)

    if @cwd and @cwd not in pythonPath
      pythonPath.push @cwd

    process_path = process.env.PWD
    if process_path and process_path not in pythonPath
      pythonPath.push process_path

    process.env.PYTHONPATH = pythonPath.join sep


  initPylama: =>
    pylamaVersion = atom.config.get 'linter-pylama.pylamaVersion'
    pylamaPath = atom.config.get 'linter-pylama.executablePath'

    if pylamaVersion is 'external' and pylamaPath isnt @pylamaPath
      @pylamaPath = pylamaPath
      exec "#{@pylamaPath} --version", @executionCheckHandler
    else
      @pylamaPath = path.join path.dirname(__dirname), 'bin', 'pylama.py'

    do @initCmd


  initCmd: =>
    if not @pylamaPath
      @cmd = ''
      return
    cmd = [@pylamaPath]
    cmd.push '-F'

    ignoreEW = atom.config.get 'linter-pylama.ignoreErrorsAndWarnings'
    if ignoreEW then cmd.push ['-i', ignoreEW]

    skipFiles = atom.config.get 'linter-pylama.skipFiles'
    if skipFiles then cmd.push ['--skip', skipFiles]

    usePyLint = if atom.config.get 'linter-pylama.usePylint' then 'pylint' else ''
    useMcCabe = if atom.config.get 'linter-pylama.useMccabe' then 'mccabe' else ''
    usePEP8 = if atom.config.get 'linter-pylama.usePep8' then 'pep8' else ''
    usePEP257 = if atom.config.get 'linter-pylama.usePep257' then 'pep257' else ''
    usePyFlakes = if atom.config.get 'linter-pylama.usePyflakes' then 'pyflakes' else ''

    linters = [usePyLint, useMcCabe, usePEP8, usePEP257, usePyFlakes].filter (e) -> e isnt ''
    if linters.length then cmd.push ['-l', do linters.join] else ['-l', 'none']

    @cmd = cmd

  lintFile: (filePath, callback) =>
    if @cmd
      super filePath, callback

  formatMessage: (match) ->
    type = if match.error then match.error else match.warning
    type = if type then type else ''
    code = if match.code then match.code else ''
    "#{type}#{code} #{match.message}"

module.exports = LinterPylama
