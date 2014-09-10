linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"

{config} = atom
{exec} = require 'child_process'
{log, warn} = require "#{linterPath}/lib/utils"


class LinterPylama extends Linter
  @enable: false
  @syntax: 'source.python'
  cmd: 'pylama'
  executablePath: null
  linterName: 'pylama'
  regex: ':(?<line>\\d+):(?<col>\\d+):\\s+((?<error>E)|(?<warning>[CDFNW]))(?<code>\\d+)(:\\s+|\\s+)(?<message>.+)\n'

  constructor: (@editor) ->
    super @editor
    @executablePath = config.getSettings()['linter-pylama']['Executable path']
    @cmd = if @executablePath then @executablePath else @cmd
    exec "#{@cmd} --version", @executionCheckHandler
    ignoreErrors = config.getSettings()['linter-pylama']['Ignore errors and warnings (comma-separated)']
    if ignoreErrors and ignoreErrors.length > 0
      @cmd = "#{@cmd} -i #{ignoreErrors}"
    selectLinters = config.getSettings()['linter-pylama']['Select linters (comma-separated)']
    if selectLinters and selectLinters.length > 0
      @cmd = "#{@cmd} -l #{selectLinters}"
    log 'Linter-Pylama: initialization completed'

  executionCheckHandler: (error, stdout, stderr) =>
    versionRegEx = /pylama ([\d\.]+)/
    if not versionRegEx.test(stderr)
      result = if error? then '#' + error.code + ': ' else ''
      result += 'stdout: ' + stdout if stdout.length > 0
      result += 'stderr: ' + stderr if stderr.length > 0
      console.error "Linter-Pylama: #{@cmd} was not executable: #{result}"
    else
      @enabled = true
      log "Linter-Pylama: found pylama " + versionRegEx.exec(stderr)[1]

  lintFile: (filePath, callback) =>
    if @enabled
      super filePath, callback
    else
      @processMessage "", callback

  formatMessage: (match) ->
    type = if match.error then match.error else match.warning
    "#{type}#{match.code} #{match.message}"

module.exports = LinterPylama
