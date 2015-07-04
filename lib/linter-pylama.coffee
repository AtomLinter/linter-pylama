fs = require "fs"
{exec} = require 'child_process'
path = require 'path'
{BufferedProcess} = require 'atom'
{CompositeDisposable} = require 'atom'
XRegExp = require('xregexp').XRegExp

regex = XRegExp('(?<file>.+):(?<line>\\d+):(?<col>\\d+):\\s+((((?<error>E)|(?<warning>[CDFNW]))(?<code>\\d+)(:\\s+|\\s+))|(.*?))(?<message>.+)(\r)?\n')

class LinterPylama
  @cmd: ''
  @pylamaPath: ''

  constructor: ->
    console.log 'Constructor'
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
    cmd.push '-F'

    ignoreEW = atom.config.get 'linter-pylama.ignoreErrorsAndWarnings'
    if ignoreEW then cmd.push ['-i', ignoreEW]

    skipFiles = atom.config.get 'linter-pylama.skipFiles'
    if skipFiles then cmd.push ['--skip', skipFiles]

    usePyLint = if atom.config.get 'linter-pylama.usePylint' then 'pylint' else ''
    useMcCabe = if atom.config.get 'linter-pylama.useMccabe' then 'mccabe' else ''
    usePEP8 = if atom.config.get 'linter-pylama.usePep8' then 'pep8' else ''
    usePEP257 = if atom.config.get 'linter-pylama.usePep257' then 'pep257' else ''
    usePyFlakes = if atom.config.get 'linter-pylama.usePyflakes' then 'pyflakes' else ''

    linters = [usePyLint, useMcCabe, usePEP8, usePEP257, usePyFlakes].filter (e) -> e isnt ''
    if linters.length then cmd.push ['-l', do linters.join] else ['-l', 'none']

    @cmd = cmd


  lintOnFly: (textEditor) =>
    console.log 'lintOnFly'
    return new Promise (resolve, reject) =>
      results = []

      file = do textEditor.getPath
      curDir = path.dirname file
      console.log file
      cmd = @cmd[0..]
      cmd.push file
      console.log cmd
      command = cmd[0]
      options = {cwd: curDir}
      args = cmd.slice 1

      stdout = (data) ->
        console.log data
        results.push data
      stderr = (err) ->
        console.log err
      exit = (code) ->
        messages = []
        console.log code

        XRegExp.forEach results.join(''), regex, (match) =>
          type = if match.error
            "Error"
          else if match.warning
            "Warning"
          messages.push {
            type: type or 'Warning'
            text: match.message
            filePath: if path.isAbsolute match.file then match.file else path.join curDir, match.file
            range: [
              [match.line - 1, 0]
              [match.line - 1, 0]
            ]
          }
        resolve(messages)

      @lint_process = new BufferedProcess({command, args, options, stdout, stderr, exit})
      @lint_process.onWillThrowError ({error, handle}) ->
        atom.notifications.addError "Failed to run #{command}",
          detail: "#{error.message}"
          dismissable: true
        handle()
        resolve []


  lintOnSave: (textEditor) =>
    console.log 'lintOnSave'
    return new Promise (resolve, reject) =>
      results = []

      file = do textEditor.getPath
      curDir = path.dirname file
      console.log file
      cmd = @cmd[0..]
      cmd.push file
      console.log cmd
      command = cmd[0]
      options = {cwd: curDir}
      args = cmd.slice 1

      stdout = (data) ->
        console.log data
        results.push data
      stderr = (err) ->
        console.log err
      exit = (code) ->
        messages = []
        console.log code

        XRegExp.forEach results.join(''), regex, (match) =>
          type = if match.error
            "Error"
          else if match.warning
            "Warning"
          messages.push {
            type: type or 'Warning'
            text: match.message
            filePath: if path.isAbsolute match.file then match.file else path.join curDir, match.file
            range: [
              [match.line - 1, 0]
              [match.line - 1, 0]
            ]
          }
        resolve(messages)

      @lint_process = new BufferedProcess({command, args, options, stdout, stderr, exit})
      @lint_process.onWillThrowError ({error, handle}) ->
        atom.notifications.addError "Failed to run #{command}",
          detail: "#{error.message}"
          dismissable: true
        handle()
        resolve []


  lint: (textEditor) =>
    if not @cmd
      return
    if @lintOnFly_
      return @lintOnFly textEditor
    else
      return @lintOnSave textEditor


module.exports = LinterPylama
