{exec} = require 'child_process'
linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"
{log, warn} = require "#{linterPath}/lib/utils"


class LinterPylama extends Linter
  @enable: false
  @syntax: 'source.python'
  cmd: 'pylama'
  executablePath: null
  linterName: 'pylama'
  regex: ':(?<line>\\d+):(?<col>\\d+): (?<message>.*?)\n'


  constructor: (@editor) ->
    super @editor  # sets @cwd to the dirname of the current file
    exec 'pylama --version', @executionCheckHandler
    log 'Linter-Pylama: initialization completed'
    ignoreErrors = atom.config.getSettings()['linter-pylama']['Ignore errors and warnings (comma-separated)']
    if ignoreErrors and ignoreErrors.length > 0
      @cmd = "#{@cmd} --ignore #{ignoreErrors}"

  executionCheckHandler: (error, stdout, stderr) =>
    versionRegEx = /pylama ([\d\.]+)/
    if not versionRegEx.test(stderr)
      result = if error? then '#' + error.code + ': ' else ''
      result += 'stdout: ' + stdout if stdout.length > 0
      result += 'stderr: ' + stderr if stderr.length > 0
      console.error "Linter-Pylama: #{cmd} was not executable: #{result}"
    else
      log "Linter-Pylama: found pylama " + versionRegEx.exec(stderr)[1]
      @enabled = true

  lintFile: (filePath, callback) =>
    if @enabled
      super filePath, callback
    else
      @processMessage "", callback

  formatMessage: (match) ->
    "#{match.message}"

module.exports = LinterPylama
