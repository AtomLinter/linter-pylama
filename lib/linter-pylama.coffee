fs = require "fs"
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

    do @initPylama


  destroy: ->
    do @subscriptions.dispose


  isLintOnFly: ->
    return @lintOnFly_


  initPythonPath: (cwd) ->
    pythonPath = if process.env['PYTHONPATH'] then process.env.PYTHONPATH else ''
    pythonPath = pythonPath.split path.delimiter
    pythonPath = pythonPath.filter(Boolean)

    if cwd and cwd not in pythonPath
      pythonPath.push cwd

    process_path = process.env.PWD
    if process_path and process_path not in pythonPath
      pythonPath.push process_path

    process.env.PYTHONPATH = pythonPath.join path.delimiter


  initPylama: =>
    pylamaVersion = atom.config.get 'linter-pylama.pylamaVersion'
    pylamaPath = atom.config.get 'linter-pylama.executablePath'

    if pylamaVersion is 'external' and pylamaPath isnt @pylamaPath
      if /^(pylama|pylama\.exe)$/.test pylamaPath
        process.env.PATH.split(path.delimiter).forEach (dir) =>
          tmp = path.join dir, pylamaPath
          if fs.existsSync tmp
            pylamaPath = tmp

      if not path.isAbsolute pylamaPath
        pylamaPath = path.resolve pylamaPath

      if not fs.existsSync pylamaPath or not do fs.statSync(pylamaPath).isFile
        atom.notifications.addError 'Pylama executable not found',
        detail: "[linter-pylama] `#{pylamaPath}` executable file not found. \
        Please set the correct path to `pylama`."
        @pylamaPath = ''
      else
        @pylamaPath = pylamaPath
    else
      @pylamaPath = path.join path.dirname(__dirname), 'bin', 'pylama.py'
    do @initCmd


  initCmd: =>
    if not @pylamaPath
      @cmd = ''
      return
    cmd = [@pylamaPath, '-F']

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


  lintFile: (lintInfo, textEditor, callback) ->
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
        line = textEditor.buffer.lines[match.line-1]
        colEnd = line.length if line
        code = match.error or match.warning or ''
        code = "#{code}#{match.code} " if code
        messages.push {
          type: type or 'Warning'
          text: code + match.message
          filePath: lintInfo.fileName
          range: [
            [match.line - 1, 0]
            [match.line - 1, colEnd]
          ]
        }
      callback(messages)

    lint_process = new BufferedProcess(
      command: lintInfo.command
      args: lintInfo.args
      options: lintInfo.options
      stdout: stdout
      stderr: stderr
      exit: exit
    )
    lint_process.onWillThrowError ({error, handle}) ->
      atom.notifications.addError "Failed to run #{command}",
        detail: "#{error.message}"
        dismissable: true
      handle()
      callback []


  lintOnFly: (textEditor) =>
    return new Promise (resolve, reject) =>
      filePath = do textEditor.getPath
      tmpOptions =
        prefix: 'AtomLinter-'
        suffix: "-#{path.basename filePath}"

      temp.open tmpOptions, (err, tmpInfo) =>
        return reject(err) if err
        fs.write tmpInfo.fd, do textEditor.getText, (err) =>
          return reject(err) if err
          lintInfo = @makeLintInfo tmpInfo.path, filePath
          @lintFile lintInfo, textEditor, (results) ->
            fs.unlink tmpInfo.path
            resolve results


  lintOnSave: (textEditor) =>
    return new Promise (resolve, reject) =>
      lintInfo = @makeLintInfo do textEditor.getPath
      @lintFile lintInfo, textEditor, (results) ->
        resolve(results)


  lint: (textEditor) =>
    if not @cmd
      return []
    @initPythonPath path.dirname do textEditor.getPath
    if @lintOnFly_
      return @lintOnFly textEditor
    else
      return @lintOnSave textEditor


module.exports = LinterPylama
