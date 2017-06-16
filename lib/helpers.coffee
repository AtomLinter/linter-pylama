path = require 'path'
os = require 'os'
{ statSync } = require 'fs'

{ exec, parse } = require 'atom-linter'
{ regex } = require './constants.coffee'


homeDirSubstitution = (pth) ->
  homedir = os.homedir()
  if homedir
    pth = pth.replace /^~($|\/|\\)/, "#{homedir}$1"
  if not path.isAbsolute pth
    pth = path.resolve pth
  pth


pathSubstitution = (pth) ->
  [project, ...] = do atom.project.getPaths
  if not project
    return pth
  [..., projectName] = project.split path.sep
  pth = pth.replace /\$PROJECT_NAME/i, projectName
  pth.replace /\$PROJECT/i, project


isValidExecutable = (pth) ->
  try
    do statSync(pth).isFile
  catch e
    false


where = (pth) ->
  [projectPath, ...] = do atom.project.getPaths
  paths = if projectPath then [projectPath] else []
  paths.push.apply paths, (process.env.PATH or process.env.Path).split path.delimiter
  for dir in paths
    tmp = path.join dir, pth
    return tmp if isValidExecutable tmp
  null


getVenvPath = (pth) ->
  i = pth.indexOf '$PROJECT_NAME'
  if i != -1
    return pth.substr(0, i + '$PROJECT_NAME'.length)
  i = pth.indexOf '$PROJECT'
  if i != -1
    return pth.substr(0, i + '$PROJECT'.length)
  ''


module.exports = {
  getExecutable: (executable) ->
    if not executable
      return [null, null]
    pths = executable.split ','
    for pth in pths
      pth = do pth.trim
      if pth.split(path.sep).length == 1
        p = where pth
        if p then return [p, null] else continue
      pth = homeDirSubstitution pth
      p = pathSubstitution pth
      if isValidExecutable p
        @pylamaPath = p
        if p isnt pth
          return [p, pathSubstitution getVenvPath pth]
        return [p, null]
    return [null, null]


  initEnv: (filePath, projectPath, virtualEnv = null) ->
    pythonPath = []

    pythonPath.push filePath if filePath
    pythonPath.push projectPath if projectPath and projectPath not in pythonPath

    env = Object.create process.env
    if env.PWD
      pwd = path.normalize env.PWD
      pythonPath.push pwd if pwd and pwd not in pythonPath

    if virtualEnv
      env.VIRTUAL_ENV = virtualEnv

    env.PYLAMA = pythonPath.join path.delimiter
    env


  lintFile: (lintInfo, textEditor) ->
    exec(lintInfo.command, lintInfo.args, lintInfo.options).then (output) ->
      atom.notifications.addWarning output['stderr'] if output['stderr']
      console.log output['stdout'] if do atom.inDevMode
      parse(output['stdout'], regex).map (message) ->
        linter_msg = {}

        if message.type
          linter_msg.severity = if message.type in ['E', 'F'] then 'error' else 'warning'
        else
          linter_msg.severity = 'info'

        code = message.filePath or ''
        code = "#{message.type}#{code}" if message.type
        linter_msg.excerpt = if code then "#{code} #{message.text}" else "#{message.text}"

        line = message.range[0][0]
        col = message.range[0][1]
        editorLine = textEditor.lineTextForBufferRow(line)
        if not editorLine or not editorLine.length
          colEnd = 0
        else
          colEnd = editorLine.indexOf ' ', col + 1
          if colEnd == -1
            colEnd = editorLine.length
          else
            colEnd = 3 if colEnd - col < 3
            colEnd = if colEnd < editorLine.length then colEnd else editorLine.length

        linter_msg.location = {
          file: lintInfo.fileName
          position: [
            [line, col]
            [line, colEnd]
          ]
        }
        linter_msg
}
