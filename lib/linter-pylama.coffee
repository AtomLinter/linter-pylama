fs = require "fs"
path = require 'path'
helpers = require 'atom-linter'
{CompositeDisposable} = require 'atom'

regex = '(?<file_>.+):' +
  '(?<line>\\d+):' +
  '(?<col>\\d+):' +
  '\\s+' +
  '(((?<type>[ECDFINRW])(?<file>\\d+)(:\\s+|\\s+))|(.*?))' +
  '(?<message>.+)'

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


  initEnv: (filePath, projectPath) ->
    pythonPath = []

    if filePath
      pythonPath.push filePath

    if projectPath and projectPath not in pythonPath
      pythonPath.push projectPath

    env = Object.create process.env
    if env.PWD
      processPath = path.normalize env.PWD
      if processPath and processPath not in pythonPath
        pythonPath.push processPath

    env.PYLAMA = pythonPath.join path.delimiter
    env


  initPylama: =>
    pylamaVersion = atom.config.get 'linter-pylama.pylamaVersion'
    pylamaPath = atom.config.get 'linter-pylama.executablePath'

    if pylamaVersion is 'external' and pylamaPath isnt @pylamaPath
      if /^(pylama|pylama\.exe)$/.test pylamaPath
        processPath = process.env.PATH or process.env.Path
        processPath.split(path.delimiter).forEach (dir) =>
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
      if process.platform is 'win32'
        @pylamaPath = path.join path.dirname(__dirname), 'bin', 'pylama.bat'
      else
        @pylamaPath = path.join path.dirname(__dirname), 'bin', 'pylama.py'


  initArgs: (curDir) =>
    args = ['-F']

    if @configFileLoad_[0] is 'U' # 'Use pylama config'
      configFilePath = helpers.findCached curDir, @configFileName_

    if configFilePath
      args.push.apply args, ['--options', configFilePath]
    else
      if @ignoreErrorsAndWarnings_ then args.push.apply args, ['--ignore', @ignoreErrorsAndWarnings_]
      if @skipFiles_ then args.push.apply args, ['--skip', @skipFiles]

      usePyLint = if @usePyLint_ then 'pylint' else ''
      useMcCabe = if @useMcCabe_ then 'mccabe' else ''
      usePEP8 = if @usePEP8_ then 'pep8' else ''
      usePEP257 = if @usePEP257_ then 'pep257' else ''
      usePyFlakes = if @usePyFlakes_ then 'pyflakes' else ''

      linters = [usePyFlakes, usePyLint, useMcCabe, usePEP8, usePEP257].filter (e) -> e isnt ''
      args.push '--linters'
      if linters.length then args.push do linters.join else args.push 'none'

    args


  makeLintInfo: (fileName, originFileName) =>
    if not originFileName
      originFileName = fileName
    filePath = path.normalize path.dirname(originFileName)
    projectPath = atom.project.relativizePath(originFileName)[0]
    env = @initEnv filePath, projectPath
    args = @initArgs filePath
    args.push fileName
    console.log "#{@pylamaPath} #{args}" if do atom.inDevMode
    info =
      fileName: originFileName
      command: @pylamaPath
      args: args
      options:
        env: env
        stream: 'both'


  lintFile: (lintInfo, textEditor) ->
    helpers.exec(lintInfo.command, lintInfo.args, lintInfo.options).then (output) =>
      if output['stderr']
        atom.notifications.addWarning output['stderr']
      console.log output['stdout'] if do atom.inDevMode
      helpers.parse(output['stdout'], regex).map (message) ->
        message.type = '' if not message.type
        message.filePath = '' if not message.filePath
        code = "#{message.type}#{message.filePath}"
        message.type = if message.type in ['E', 'F']
          'Error'
        else
          'Warning'
        message.filePath = lintInfo.fileName
        message.text = if code then "#{code} #{message.text}" else "#{message.text}"
        line = message.range[0][0]
        col = message.range[0][1]
        editorLine = textEditor.buffer.lines[line]
        if not editorLine or not editorLine.length
          colEnd = 0
        else
          colEnd = editorLine.indexOf(' ', col+1)
          if colEnd == -1
            colEnd = editorLine.length
          else
            colEnd = 3 if colEnd - col < 3
            colEnd = if colEnd < editorLine.length then colEnd else editorLine.length
        message.range = [
          [line, col]
          [line, colEnd]
        ]
        message


  lintOnFly: (textEditor) =>
    filePath = do textEditor.getPath
    fileName = path.basename do textEditor.getPath
    helpers.tempFile fileName, do textEditor.getText, (tmpFilePath) =>
      lintInfo = @makeLintInfo tmpFilePath, filePath
      @lintFile lintInfo, textEditor


  lintOnSave: (textEditor) =>
    filePath = do textEditor.getPath
    if process.platform is 'win32'
      if filePath.slice(0, 2) == '\\\\'
        return @lintOnFly textEditor
    lintInfo = @makeLintInfo filePath
    @lintFile lintInfo, textEditor


  lint: (textEditor) =>
    if not @pylamaPath
      return []
    if @lintOnFly_
      return @lintOnFly textEditor
    @lintOnSave textEditor


module.exports = LinterPylama
