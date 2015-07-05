fs = require "fs"
{exec} = require 'child_process'
path = require 'path'
temp = require 'temp'
{BufferedProcess} = require 'atom'
{CompositeDisposable} = require 'atom'
XRegExp = require('xregexp').XRegExp

regex = XRegExp('(?<file>.+):(?<line>\\d+):(?<col>\\d+):\\s+((((?<error>E)|(?<warning>[CDFNW]))(?<code>\\d+)(:\\s+|\\s+))|(.*?))(?<message>.+)(\r)?\n')

class LinterPylama
  @cmd: ''
  @pylamaPath: ''

  constructor: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-pylama.pylamaVersion',
    (pylamaVersion) =>
      @pylamaVersion_ = pylamaVersion
      do @initPylama

    @subscriptions.add atom.config.observe 'linter-pylama.executablePath',
    (executablePath) =>
      @executablePath_ = executablePath
      do @initPylama

    @subscriptions.add atom.config.observe 'linter-pylama.ignoreErrorsAndWarnings',
    (ignoreErrorsAndWarnings) =>
      @ignoreErrorsAndWarnings_ = ignoreErrorsAndWarnings
      do @initCmd

    @subscriptions.add atom.config.observe 'linter-pylama.skipFiles',
    (skipFiles) =>
      @skipFiles_ = skipFiles
      do @initCmd


    @subscriptions.add atom.config.observe 'linter-pylama.useMccabe',
    (useMcCabe) =>
      @useMcCabe_ = useMcCabe
      do @initCmd

    @subscriptions.add atom.config.observe 'linter-pylama.usePep8',
    (usePEP8) =>
      @usePEP8_ = usePEP8
      do @initCmd

    @subscriptions.add atom.config.observe 'linter-pylama.usePep257',
    (usePEP257) =>
      @usePEP257_ = usePEP257
      do @initCmd

    @subscriptions.add atom.config.observe 'linter-pylama.usePyflakes',
    (usePyFlakes) =>
      @usePyFlakes_ = usePyFlakes
      do @initCmd

    @subscriptions.add atom.config.observe 'linter-pylama.usePylint',
    (usePyLint) =>
      @usePyLint_ = usePyLint
      do @initCmd

    @subscriptions.add atom.config.observe 'linter-pylama.lintOnFly',
    (lintOnFly) =>
      @lintOnFly_ = lintOnFly

    do @initPythonPath
    do @initPylama


  destroy: ->
    super
    do @subscriptions.dispose


  isLintOnFly: ->
    return @lintOnFly_


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

    ignoreEW = atom.config.get 'linter-pylama.ignoreErrorsAndWarnings'
    if ignoreEW then cmd.push ['-i', ignoreEW]

    skipFiles = atom.config.get 'linter-pylama.skipFiles'
    if skipFiles then cmd.push ['--skip', skipFiles]

    usePyLint = if atom.config.get 'linter-pylama.usePylint' then 'pylint' else ''
    useMcCabe = if atom.config.get 'linter-pylama.useMccabe' then 'mccabe' else ''
    usePEP8 = if atom.config.get 'linter-pylama.usePep8' then 'pep8' else ''
    usePEP257 = if atom.config.get 'linter-pylama.usePep257' then 'pep257' else ''
    usePyFlakes = if atom.config.get 'linter-pylama.usePyflakes' then 'pyflakes' else ''

    linters = [usePyFlakes, usePyLint, useMcCabe, usePEP8, usePEP257].filter (e) -> e isnt ''
    if linters.length then cmd.push ['-l', do linters.join] else ['-l', 'none']

    @cmd = cmd


  makeLintInfo: (fileName, originFileName) =>
    if not originFileName
      originFileName = fileName
    cmd = @cmd[0..]
    cmd.push fileName
    console.log cmd if do atom.inDevMode
    info =
      fileName: originFileName
      command: cmd[0]
      args: cmd.slice 1
      options: {cwd: path.dirname originFileName}


  lintFile: (lintInfo, callback) ->
    results = []
    stdout = (data) ->
      console.log data if do atom.inDevMode
      results.push data
    stderr = (err) ->
      console.log err if do atom.inDevMode
    exit = (code) ->
      messages = []
      XRegExp.forEach results.join(''), regex, (match) =>
        type = if match.error
          "Error"
        else if match.warning
          "Warning"
        messages.push {
          type: type or 'Warning'
          text: match.message
          filePath: lintInfo.fileName
          range: [
            [match.line - 1, 0]
            [match.line - 1, 0]
          ]
        }
      callback(messages)

    command = lintInfo.command
    args = lintInfo.args
    options = lintInfo.options
    @lint_process = new BufferedProcess({command, args, options, stdout, stderr, exit})
    @lint_process.onWillThrowError ({error, handle}) ->
      atom.notifications.addError "Failed to run #{command}",
        detail: "#{error.message}"
        dismissable: true
      handle()
      callback []


  lintOnFly: (textEditor) =>
    return new Promise (resolve, reject) =>
      tmpOptions = {
        prefix: 'AtomLinter'
        suffix: "-#{path.basename do textEditor.getPath}"
      }

      temp.open(tmpOptions, (err, info) =>
        return reject(err) if err

        fs.write(info.fd, textEditor.getText())
        fs.close(info.fd, (err) =>
          return reject(err) if err

          lintInfo = @makeLintInfo info.path, do textEditor.getPath
          @lintFile lintInfo, (results) ->
            fs.unlink(info.path)
            resolve(results)
        )
      )


  lintOnSave: (textEditor) =>
    return new Promise (resolve, reject) =>
      lintInfo = @makeLintInfo do textEditor.getPath
      @lintFile lintInfo, (results) ->
        resolve(results)


  lint: (textEditor) =>
    if not @cmd
      return
    if @lintOnFly_
      return @lintOnFly textEditor
    else
      return @lintOnSave textEditor


module.exports = LinterPylama
