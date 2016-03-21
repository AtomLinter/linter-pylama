fs = require "fs"
path = require 'path'
temp = require 'temp'
{BufferedProcess} = require 'atom'
{CompositeDisposable} = require 'atom'
XRegExp = require 'xregexp'

regex = XRegExp '(?<file>.+):' +
  '(?<line>\\d+):' +
  '(?<col>\\d+):' +
  '\\s+' +
  '((((?<error>E)|(?<warning>[CDFNW]))(?<code>\\d+)(:\\s+|\\s+))|(.*?))' +
  '(?<message>.+)' +
  '(\r)?\n'

class LinterPylama
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

    @subscriptions.add atom.config.observe 'linter-pylama.skipFiles',
    (skipFiles) =>
      @skipFiles_ = skipFiles

    @subscriptions.add atom.config.observe 'linter-pylama.useMccabe',
    (useMcCabe) =>
      @useMcCabe_ = useMcCabe

    @subscriptions.add atom.config.observe 'linter-pylama.usePep8',
    (usePEP8) =>
      @usePEP8_ = usePEP8

    @subscriptions.add atom.config.observe 'linter-pylama.usePep257',
    (usePEP257) =>
      @usePEP257_ = usePEP257

    @subscriptions.add atom.config.observe 'linter-pylama.usePyflakes',
    (usePyFlakes) =>
      @usePyFlakes_ = usePyFlakes

    @subscriptions.add atom.config.observe 'linter-pylama.usePylint',
    (usePyLint) =>
      @usePyLint_ = usePyLint

    @subscriptions.add atom.config.observe 'linter-pylama.lintOnFly',
    (lintOnFly) =>
      @lintOnFly_ = lintOnFly

    @subscriptions.add atom.config.observe 'linter-pylama.configFileLoad',
    (configFileLoad) =>
      @configFileLoad_ = configFileLoad

    @subscriptions.add atom.config.observe 'linter-pylama.configFileName',
    (configFileName) =>
      @configFileName_ = configFileName

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
        process_path = process.env.PATH or process.env.Path
        process_path.split(path.delimiter).forEach (dir) =>
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
      if /^win/.test process.platform
        @pylamaPath = path.join path.dirname(__dirname), 'bin', 'pylama.bat'
      else
        @pylamaPath = path.join path.dirname(__dirname), 'bin', 'pylama.py'


  initCmd: (curDir) =>
    cmd = [@pylamaPath, '-F']

    configFilePath = false
    if @configFileLoad_ is 'Find config in the current directory'
      configFilePath = @locateConfigFile curDir
    else if @configFileLoad_ is 'Try to find config in the parent directories'
      configFilePath = @locateConfigFile curDir, true

    if configFilePath
      cmd.push ['-o'], [configFilePath]
    else
      if @ignoreErrorsAndWarnings_ then cmd.push ['-i', @ignoreErrorsAndWarnings_]
      if @skipFiles_ then cmd.push ['--skip', @skipFiles_]

      usePyLint = if @usePyLint_ then 'pylint' else ''
      useMcCabe = if @useMcCabe_ then 'mccabe' else ''
      usePEP8 = if @usePEP8_ then 'pep8' else ''
      usePEP257 = if @usePEP257_ then 'pep257' else ''
      usePyFlakes = if @usePyFlakes_ then 'pyflakes' else ''

      linters = [usePyFlakes, usePyLint, useMcCabe, usePEP8, usePEP257].filter (e) -> e isnt ''
      if linters.length then cmd.push ['-l', do linters.join] else ['-l', 'none']

    return cmd


  makeLintInfo: (fileName, originFileName) =>
    if not originFileName
      originFileName = fileName
    curDir = path.dirname originFileName
    cmd = @initCmd curDir
    cmd.push fileName
    console.log cmd if do atom.inDevMode
    info =
      fileName: originFileName
      command: cmd[0]
      args: cmd.slice 1
      options: {cwd: curDir}


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
    if not @pylamaPath
      return []
    @initPythonPath path.dirname do textEditor.getPath
    if @lintOnFly_
      return @lintOnFly textEditor
    else
      return @lintOnSave textEditor


  locateConfigFile: (curDir, recursive=false) =>
    root_dir = if /^win/.test process.platform then /^.:\\$/ else /^\/$/
    directory = path.resolve curDir
    loop
      return path.join directory, @configFileName_ if fs.existsSync path.join directory, @configFileName_
      break if not recursive or root_dir.test directory
      directory = path.resolve path.join(directory, '..')
    return false


module.exports = LinterPylama
