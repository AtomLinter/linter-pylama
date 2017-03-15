{statSync, realpathSync} = require "fs"
os = require 'os'
path = require 'path'

{CompositeDisposable} = require 'atom'
helpers = require 'atom-linter'

regex =
  '(?<file_>.+):' +
  '(?<line>\\d+):' +
  '(?<col>\\d+):' +
  '\\s+' +
  '(((?<type>[ECDFINRW])(?<file>\\d+)(:\\s+|\\s+))|(.*?))' +
  '(?<message>.+)'


class LinterPylama
  constructor: ->
    @isortPath = path.join path.dirname(__dirname), 'bin', 'isort.py'

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-pylama.pylamaVersion',
    (pylamaVersion) =>
      if @pylamaVersion
        @pylamaVersion = pylamaVersion
        do @initPylama
      else
        @pylamaVersion = pylamaVersion

    @subscriptions.add atom.config.observe 'linter-pylama.executablePath',
    (executablePath) =>
      if @executablePath
        @executablePath = executablePath
        do @initPylama
      else
        @executablePath = executablePath

    @subscriptions.add atom.config.observe 'linter-pylama.interpreter',
    (interpreter) =>
      @interpreter = interpreter
      do @initPylama

    @subscriptions.add atom.config.observe 'linter-pylama.ignoreErrorsAndWarnings',
    (ignoreErrorsAndWarnings) =>
      ignoreErrorsAndWarnings = ignoreErrorsAndWarnings.replace /\s+/g, '' if ignoreErrorsAndWarnings
      @ignoreErrorsAndWarnings = ignoreErrorsAndWarnings

    @subscriptions.add atom.config.observe 'linter-pylama.skipFiles',
    (skipFiles) =>
      @skipFiles = skipFiles

    @subscriptions.add atom.config.observe 'linter-pylama.useMcCabe',
    (useMcCabe) =>
      @useMcCabe = useMcCabe
      if @useMcCabe
        atom.config.set 'linter-pylama.useRadon', false

    @subscriptions.add atom.config.observe 'linter-pylama.usePep8',
    (usePEP8) =>
      @usePEP8 = usePEP8

    @subscriptions.add atom.config.observe 'linter-pylama.usePep257',
    (usePEP257) =>
      @usePEP257 = usePEP257

    @subscriptions.add atom.config.observe 'linter-pylama.usePyflakes',
    (usePyFlakes) =>
      @usePyFlakes = usePyFlakes
      if @usePyflakes
        atom.config.set 'linter-pylama.useRadon', false

    @subscriptions.add atom.config.observe 'linter-pylama.usePylint',
    (usePyLint) =>
      @usePyLint = usePyLint

    @subscriptions.add atom.config.observe 'linter-pylama.useRadon',
    (useRadon) =>
      @useRadon = useRadon
      if @useRadon
        atom.config.set 'linter-pylama.useMcCabe', false
        atom.config.set 'linter-pylama.usePyflakes', false

    @subscriptions.add atom.config.observe 'linter-pylama.useIsort',
    (useIsort) =>
      @useIsort = useIsort

    @subscriptions.add atom.config.observe 'linter-pylama.lintOnFly',
    (lintOnFly) =>
      @lintOnFly = lintOnFly

    @subscriptions.add atom.config.observe 'linter-pylama.configFileLoad',
    (configFileLoad) =>
      @configFileLoad = configFileLoad

    @subscriptions.add atom.config.observe 'linter-pylama.configFileName',
    (configFileName) =>
      @configFileName = configFileName

    @subscriptions.add atom.config.observe 'linter-pylama.isortOnSave',
    (isortOnSave) =>
      if isortOnSave
        atom.workspace.observeTextEditors (editor) =>
          @isortOnSave = editor.onDidSave =>
            if editor.getGrammar?().scopeName is 'source.python'
              helpers.exec @interpreter, [@isortPath, do editor.getPath]
      else
        do @isortOnSave?.dispose

    @subscriptions.add atom.commands.add 'atom-workspace', 'linter-pylama:isort', =>
      editor = atom.workspace.getActiveTextEditor()
      helpers.exec @interpreter, [@isortPath, do editor.getPath]


  destroy: ->
    do @subscriptions?.dispose
    do @isortOnSave?.dispose


  isLintOnFly: ->
    return @lintOnFly


  initEnv: (filePath, projectPath) ->
    pythonPath = []

    pythonPath.push filePath if filePath
    pythonPath.push projectPath if projectPath and projectPath not in pythonPath

    env = Object.create process.env
    if env.PWD
      processPath = path.normalize env.PWD
      pythonPath.push processPath if processPath and processPath not in pythonPath

    env.PYLAMA = pythonPath.join path.delimiter
    env


  initPylama: =>
    if @pylamaVersion is 'external' and @executablePath isnt @pylamaPath
      @pylamaPath = ''
      if /^(pylama|pylama\.exe)$/.test @executablePath
        processPath = process.env.PATH or process.env.Path
        for dir in processPath.split path.delimiter
          tmp = path.join dir, @executablePath
          try
            @pylamaPath = tmp if do statSync(tmp).isFile
            break
          catch e
      else
        if @executablePath
          homedir = os.homedir();
          if homedir
            @executablePath = @executablePath.replace /^~($|\/|\\)/, "#{homedir}$1"
          tmp = if not path.isAbsolute @executablePath then path.resolve @executablePath else @executablePath
          try
            @pylamaPath = tmp if do statSync(tmp).isFile
          catch e

      if not @pylamaPath
        atom.notifications.addError 'Pylama executable not found',
        detail: "[linter-pylama] `#{@executablePath}` executable file not found.
        \nPlease set the correct path to `pylama`."
    else
      @pylamaPath = path.join path.dirname(__dirname), 'bin', 'pylama.py',


  initArgs: (curDir) =>
    args = ['-F']

    if @configFileLoad[0] is 'U' # 'Use pylama config'
      configFilePath = helpers.findCached curDir, @configFileName

    if configFilePath then args.push.apply args, ['--options', configFilePath]
    else
      if @ignoreErrorsAndWarnings then args.push.apply args, ['--ignore', @ignoreErrorsAndWarnings]
      if @skipFiles then args.push.apply args, ['--skip', @skipFiles]

      usePyLint = if @usePyLint then 'pylint' else ''
      useMcCabe = if @useMcCabe then 'mccabe' else ''
      usePEP8 = if @usePEP8 then 'pep8' else ''
      usePEP257 = if @usePEP257 then 'pep257' else ''
      usePyFlakes = if @usePyFlakes then 'pyflakes' else ''
      useRadon = if @useRadon then 'radon' else ''
      useIsort = if @useIsort then 'isort' else ''

      linters = [usePEP8, usePEP257, usePyLint, usePyFlakes, useMcCabe, useRadon, useIsort].filter (e) -> e isnt ''
      args.push '--linters'
      if linters.length then args.push do linters.join else args.push 'none'

    args


  makeLintInfo: (fileName, originFileName) =>
    originFileName = fileName if not originFileName
    filePath = path.normalize path.dirname(originFileName)
    tmpFilePath =  if fileName != originFileName then path.dirname(fileName) else filePath
    projectPath = atom.project.relativizePath(originFileName)[0]
    env = @initEnv filePath, projectPath
    args = @initArgs filePath
    args.push fileName
    console.log "#{@pylamaPath} #{args}" if do atom.inDevMode
    if @pylamaVersion is 'external'
      command = @pylamaPath
    else
      command = @interpreter
      args.unshift @pylamaPath
    info =
      fileName: originFileName
      command: command
      args: args
      options:
        env: env
        cwd: tmpFilePath
        stream: 'both'


  lintFile: (lintInfo, textEditor) ->
    helpers.exec(lintInfo.command, lintInfo.args, lintInfo.options).then (output) =>
      atom.notifications.addWarning output['stderr'] if output['stderr']
      console.log output['stdout'] if do atom.inDevMode
      helpers.parse(output['stdout'], regex).map (message) ->
        message.type = '' if not message.type
        message.filePath = '' if not message.filePath
        code = "#{message.type}#{message.filePath}"
        message.type = if message.type in ['E', 'F'] then 'Error' else 'Warning'
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


  lintFileOnFly: (textEditor) =>
    filePath = do textEditor.getPath
    fileName = path.basename do textEditor.getPath
    helpers.tempFile fileName, do textEditor.getText, (tmpFilePath) =>
      tmpFilePath = realpathSync tmpFilePath
      lintInfo = @makeLintInfo tmpFilePath, filePath
      @lintFile lintInfo, textEditor


  lintOnSave: (textEditor) =>
    filePath = do textEditor.getPath
    if process.platform is 'win32'
      if filePath.slice(0, 2) == '\\\\'
        return @lintFileOnFly textEditor
    lintInfo = @makeLintInfo filePath
    @lintFile lintInfo, textEditor


  lint: (textEditor) =>
    return [] if not @pylamaPath
    return @lintFileOnFly textEditor if @lintOnFly
    @lintOnSave textEditor


module.exports = LinterPylama
