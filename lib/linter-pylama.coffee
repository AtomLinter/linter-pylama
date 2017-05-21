{ readFile, statSync, realpathSync } = require "fs"
os = require 'os'
path = require 'path'

{ CompositeDisposable } = require 'atom'
{ exec, findCached, tempFile } = require 'atom-linter'
helpers = require './helpers'


class LinterPylama
  constructor: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add \
    atom.config.observe 'linter-pylama.pylamaVersion', (pylamaVersion) =>
      if @pylamaVersion
        @pylamaVersion = pylamaVersion
        do @initPylama
      else
        @pylamaVersion = pylamaVersion

    @subscriptions.add \
    atom.config.observe 'linter-pylama.executablePath', (executablePath) =>
      if @executablePath
        @executablePath = executablePath
        do @initPylama
      else
        @executablePath = executablePath

    @subscriptions.add \
    atom.config.observe 'linter-pylama.interpreter', (interpreter) =>
      @interpreter = interpreter
      do @initPylama

    @subscriptions.add \
    atom.config.observe 'linter-pylama.ignoreErrorsAndWarnings',
    (ignoreErrorsAndWarnings) =>
      if ignoreErrorsAndWarnings
        @ignoreErrorsAndWarnings = ignoreErrorsAndWarnings.replace /\s+/g, ''

    @subscriptions.add \
    atom.config.observe 'linter-pylama.skipFiles', (skipFiles) =>
      @skipFiles = skipFiles

    @subscriptions.add \
    atom.config.observe 'linter-pylama.useMcCabe', (useMcCabe) =>
      @useMcCabe = useMcCabe
      if @useMcCabe
        atom.config.set 'linter-pylama.useRadon', false
      @pylamaLinters = do @initPylamaLinters if @pylamaLinters

    @subscriptions.add \
    atom.config.observe 'linter-pylama.usePep8', (usePEP8) =>
      @usePEP8 = usePEP8
      @pylamaLinters = do @initPylamaLinters if @pylamaLinters

    @subscriptions.add \
    atom.config.observe 'linter-pylama.usePep257', (usePEP257) =>
      @usePEP257 = usePEP257
      @pylamaLinters = do @initPylamaLinters if @pylamaLinters

    @subscriptions.add \
    atom.config.observe 'linter-pylama.usePyflakes', (usePyFlakes) =>
      @usePyFlakes = usePyFlakes
      @pylamaLinters = do @initPylamaLinters if @pylamaLinters

    @subscriptions.add \
    atom.config.observe 'linter-pylama.usePylint', (usePyLint) =>
      @usePyLint = usePyLint
      @pylamaLinters = do @initPylamaLinters if @pylamaLinters

    @subscriptions.add \
    atom.config.observe 'linter-pylama.useRadon', (useRadon) =>
      @useRadon = useRadon
      if @useRadon
        atom.config.set 'linter-pylama.useMcCabe', false
      @pylamaLinters = do @initPylamaLinters if @pylamaLinters

    @subscriptions.add \
    atom.config.observe 'linter-pylama.useIsort', (useIsort) =>
      @useIsort = useIsort
      @pylamaLinters = do @initPylamaLinters if @pylamaLinters

    @subscriptions.add \
    atom.config.observe 'linter-pylama.lintOnFly', (lintOnFly) =>
      @lintOnFly = lintOnFly

    @subscriptions.add \
    atom.config.observe 'linter-pylama.configFileLoad', (configFileLoad) =>
      @configFileLoad = configFileLoad

    @subscriptions.add \
    atom.config.observe 'linter-pylama.configFileName', (configFileName) =>
      @configFileName = configFileName

    @subscriptions.add \
    atom.config.observe 'linter-pylama.isortOnSave', (isortOnSave) =>
      if isortOnSave
        atom.workspace.observeTextEditors (editor) =>
          @isortOnSave = editor.onDidSave =>
            if editor.getGrammar?().scopeName is 'source.python'
              exec @interpreter, [helpers.paths.isort, do editor.getPath]
      else
        do @isortOnSave?.dispose

    @subscriptions.add \
      atom.commands.add 'atom-workspace', 'linter-pylama:isort', =>
        @isortOnFly do atom.workspace.getActiveTextEditor

    @pylamaLinters = do @initPylamaLinters


  destroy: ->
    do @subscriptions?.dispose
    do @isortOnSave?.dispose


  isLintOnFly: ->
    return @lintOnFly


  isortOnFly: (textEditor) =>
    fileName = path.basename do textEditor.getPath
    cursorPosition = do textEditor.getCursorBufferPosition
    bufferText = do textEditor.getText
    tempFile fileName, bufferText, (tmpFilePath) =>
      tmpFilePath = realpathSync tmpFilePath
      exec(@interpreter, [helpers.paths.isort, tmpFilePath]).then (output) ->
        readFile tmpFilePath, (err, data) ->
          if err
            console.log err
          else if data
            dataStr = do data.toString
            if dataStr isnt bufferText
              textEditor.setText do data.toString
              textEditor.setCursorBufferPosition cursorPosition


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
          homedir = os.homedir()
          if homedir
            @executablePath = @executablePath.replace /^~($|\/|\\)/, "#{homedir}$1"
          if not path.isAbsolute @executablePath
            tmp = path.resolve @executablePath
          else
            tmp = @executablePath
          try
            @pylamaPath = tmp if do statSync(tmp).isFile
          catch e

      if not @pylamaPath
        atom.notifications.addError 'Pylama executable not found', {
            detail: "[linter-pylama] `#{@executablePath}` executable file not found.
            \nPlease set the correct path to `pylama`."
          }
    else
      @pylamaPath = helpers.paths.pylama


  initPylamaLinters: =>
    linters = [
      if @usePyLint then 'pylint' else ''
      if @useMcCabe then 'mccabe' else ''
      if @usePEP8 then 'pep8' else ''
      if @usePEP257 then 'pep257' else ''
      if @usePyFlakes then 'pyflakes' else ''
      if @useRadon then 'radon' else ''
      if @useIsort then 'isort' else ''
    ].filter (e) -> e isnt ''
    do linters.join


  initArgs: (curDir) =>
    args = ['-F']

    if @configFileLoad[0] is 'U' # 'Use pylama config'
      configFilePath = findCached curDir, @configFileName

    if configFilePath
      args.push.apply args, ['--options', configFilePath]
    else
      if @ignoreErrorsAndWarnings
        args.push.apply args, ['--ignore', @ignoreErrorsAndWarnings]
      if @skipFiles then args.push.apply args, ['--skip', @skipFiles]

      args.push '--linters'
      if @pylamaLinters then args.push @pylamaLinters else args.push 'none'
    args


  makeLintInfo: (fileName, originFileName) =>
    originFileName = fileName if not originFileName
    filePath = path.normalize path.dirname(originFileName)
    projectPath = atom.project.relativizePath(originFileName)[0]
    if fileName != originFileName
      cwd = path.dirname(fileName)
    else
      cwd = projectPath
    env = helpers.initEnv filePath, projectPath
    args = @initArgs filePath
    args.push fileName
    console.log "#{@pylamaPath} #{args}" if do atom.inDevMode
    if @pylamaVersion is 'external'
      command = @pylamaPath
    else
      command = @interpreter
      args.unshift @pylamaPath
    info = {
      fileName: originFileName
      command: command
      args: args
      options: {
        env: env
        cwd: cwd
        stream: 'both'
      }
    }


  lintFileOnFly: (textEditor) =>
    filePath = do textEditor.getPath
    fileName = path.basename do textEditor.getPath
    tempFile fileName, do textEditor.getText, (tmpFilePath) =>
      tmpFilePath = realpathSync tmpFilePath
      lintInfo = @makeLintInfo tmpFilePath, filePath
      helpers.lintFile lintInfo, textEditor


  lintOnSave: (textEditor) =>
    filePath = do textEditor.getPath
    if process.platform is 'win32'
      if filePath.slice(0, 2) == '\\\\'
        return @lintFileOnFly textEditor
    lintInfo = @makeLintInfo filePath
    helpers.lintFile lintInfo, textEditor


  lint: (textEditor) =>
    return [] if not @pylamaPath
    return @lintFileOnFly textEditor if @lintOnFly
    @lintOnSave textEditor


module.exports = LinterPylama
