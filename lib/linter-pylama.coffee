linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"

{exec} = require 'child_process'
{log, warn} = require "#{linterPath}/lib/utils"


class LinterPylama extends Linter
  @enable: false
  @syntax: 'source.python'
  @cmd: ''
  @cfg: null
  linterName: 'pylama'
  regex: ':(?<line>\\d+):(?<col>\\d+):\\s+((((?<error>E)|(?<warning>[CDFNW]))(?<code>\\d+)(:\\s+|\\s+))|(.*?))(?<message>.+)\n'

  constructor: (@editor) ->
    super @editor
    @cfg = atom.config.get('linter-pylama')
    @cmd = @cfg['executablePath']
    exec "#{@cmd} --version", @executionCheckHandler

  executionCheckHandler: (error, stdout, stderr) =>
    versionRegEx = /pylama ([\d\.]+)/
    if not versionRegEx.test(stderr)
      result = if error? then '#' + error.code + ': ' else ''
      result += 'stdout: ' + stdout if stdout.length > 0
      result += 'stderr: ' + stderr if stderr.length > 0
      result = result.replace(/\r\n|\n|\r/, '')
      console.error "Linter-Pylama: \"#{@cmd}\" \
      was not executable: \"#{result}\". \
      Please, check executable path in the linter settings."
    else
      @enabled = true
      log "Linter-Pylama: found pylama " + versionRegEx.exec(stderr)[1]
      do @initCmd

  initCmd: =>
      if @enabled
        ignoreErrors = @cfg['ignoreErrorsAndWarnings']
        if ignoreErrors and ignoreErrors.length > 0
          @cmd = "#{@cmd} -i #{ignoreErrors}"
        selectLinters = @cfg['selectLinters']
        if selectLinters and selectLinters.length > 0
          @cmd = "#{@cmd} -l #{selectLinters}"
        asyncMode = @cfg['enableAsyncMode']
        if asyncMode and /pylint/i.test selectLinters
          warn "Async mode don't supported with PyLint"
          asyncMode = false
        if asyncMode
          @cmd = "#{@cmd} --async"
        skipFiles = @cfg['skipFiles']
        if skipFiles
          @cmd = "#{@cmd} --skip #{skipFiles}"
        console.log @cmd
        log 'Linter-Pylama: initialization completed'

  lintFile: (filePath, callback) =>
    if @enabled
      super filePath, callback
    else
      @processMessage "", callback

  formatMessage: (match) ->
    type = if match.error then match.error else match.warning
    type = if type then type else ''
    code = if match.code then match.code else ''
    "#{type}#{code} #{match.message}"

module.exports = LinterPylama
