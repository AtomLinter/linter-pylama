fs = require "fs"
path = require 'path'
helpers = require 'atom-linter'
{BufferedProcess} = require 'atom'
{CompositeDisposable} = require 'atom'

regex = '(?<file_>.+):' +
  '(?<line>\\d+):' +
  '(?<col>\\d+):' +
  '\\s+' +
  '((((?<type>E)|(?<type>[CDFNW]))(?<file>\\d+)(:\\s+|\\s+))|(.*?))' +
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


  initEnv: (cwd) ->
    pythonPath = if process.env['PYTHONPATH'] then process.env.PYTHONPATH else ''
    pythonPath = pythonPath.split path.delimiter
    pythonPath = pythonPath.filter(Boolean)

    if cwd and cwd not in pythonPath
      pythonPath.push cwd

    process_path = process.env.PWD
    if process_path and process_path not in pythonPath
      pythonPath.push process_path

    process.env.PYTHONPATH = pythonPath.join path.delimiter
    process.env


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
      if linters.length then args.push do linters.join else args.push 'nane'

    args


  makeLintInfo: (fileName, originFileName) =>
    if not originFileName
      originFileName = fileName
    curDir = path.dirname originFileName
    env = @initEnv curDir
    args = @initArgs curDir
    args.push fileName
    console.log "#{@pylamaPath} #{args}" if do atom.inDevMode
    info =
      fileName: originFileName
      command: @pylamaPath
      args: args
      options: {env: env, stream: 'stdout', ignoreExitCode: true}


  lintFile: (lintInfo, textEditor) ->
    helpers.exec(lintInfo.command, lintInfo.args, lintInfo.options).then (output) ->
      console.log output if do atom.inDevMode
      helpers.parse(output, regex).map (message) ->
        code = "#{message.type}#{message.filePath}"
        message.type = if message.type == 'E'
          'Error'
        else
          'Warning'
        message.filePath = lintInfo.fileName
        message.text = "#{code} #{message.text}"
        line = message.range[0][0]
        col = message.range[0][1]
        message.range = helpers.rangeFromLineNumber(textEditor, line, col)
        message


  lintOnFly: (textEditor) =>
    filePath = do textEditor.getPath
    fileName = path.basename do textEditor.getPath
    helpers.tempFile fileName, do textEditor.getText, (tmpFilePath) =>
      lintInfo = @makeLintInfo tmpFilePath, filePath
      @lintFile lintInfo, textEditor


  lintOnSave: (textEditor) =>
    lintInfo = @makeLintInfo do textEditor.getPath
    @lintFile lintInfo, textEditor


  lint: (textEditor) =>
    if not @pylamaPath
      return []
    if @lintOnFly_
      return @lintOnFly textEditor
    @lintOnSave textEditor


module.exports = LinterPylama
