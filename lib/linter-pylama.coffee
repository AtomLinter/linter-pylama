os = require 'os'
path = require 'path'
{ readFile, statSync, realpathSync } = require "fs"

helpers = require './helpers'
{ CompositeDisposable } = require 'atom'
{ exec, findCached, tempFile } = require 'atom-linter'
{ linters, linter_paths } = require './constants.coffee'


class LinterPylama
  constructor: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add \
    atom.config.observe 'linter-pylama.pylamaVersion', (pylamaVersion) =>
      if @pylamaVersion
        @pylamaVersion = pylamaVersion
        @pylamaPath = null
      else
        @pylamaVersion = pylamaVersion

    @subscriptions.add \
    atom.config.observe 'linter-pylama.executablePath', (executablePath) =>
      if @executablePath
        @executablePath = executablePath
        @pylamaPath = null
      else
        @executablePath = executablePath

    @subscriptions.add \
    atom.config.observe 'linter-pylama.interpreter', (interpreter) =>
      if @interpreter
        @interpreterPath = @interpreter = interpreter
        @pylamaPath = null
      else
        @interpreterPath = @interpreter = interpreter

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
              exec @interpreter, [linter_paths.isort, do editor.getPath]
      else
        do @isortOnSave?.dispose

    @subscriptions.add \
      atom.commands.add 'atom-workspace', 'linter-pylama:isort', =>
        @isortOnFly do atom.workspace.getActiveTextEditor


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
      exec(@interpreter, [linter_paths.isort, tmpFilePath]).then (output) ->
        readFile tmpFilePath, (err, data) ->
          if err
            console.log err
          else if data
            dataStr = do data.toString
            if dataStr isnt bufferText
              textEditor.setText do data.toString
              textEditor.setCursorBufferPosition cursorPosition


  initPylama: =>
    if @pylamaVersion is 'external'
      [@pylamaPath, @virtualEnv] = helpers.getExecutable @executablePath
      if not @pylamaPath
        atom.notifications.addError 'Pylama executable not found', {
            detail: "[linter-pylama] Pylama executable not found in `#{@executablePath}`.
            \nPlease set the correct path to `pylama`."
          }
    else
      [@interpreter, @virtualEnv] = helpers.getExecutable @interpreter
      @pylamaPath = linter_paths.pylama
      if not @interpreter
        atom.notifications.addError 'Python executable not found', {
            detail: "[linter-pylama] Python executable not found in `#{@interpreterPath}`.
            \nPlease set the correct path to `python`."
          }


  initPylamaLinters: =>
    linters_args = [
      if @usePyLint then linters.pylint else ''
      if @useMcCabe then linters.mccabe else ''
      if @usePEP8 then linters.pep8 else ''
      if @usePEP257 then linters.pep257 else ''
      if @usePyFlakes then linters.pyflakes else ''
      if @useRadon then linters.radon else ''
      if @useIsort then linters.isort else ''
    ].filter (e) -> e isnt ''
    do linters_args.join


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

      if not @pylamaLinters then @pylamaLinters = do @initPylamaLinters
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
    env = helpers.initEnv filePath, projectPath, @virtualEnv
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
    do @initPylama if not @pylamaPath
    return [] if not @pylamaPath
    if @lintOnFly then @lintFileOnFly textEditor else @lintOnSave textEditor


module.exports = LinterPylama
