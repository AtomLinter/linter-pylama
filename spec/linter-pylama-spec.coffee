path = require 'path'

goodPath = path.join __dirname, 'fixtures', 'good.py'
badPath = path.join __dirname, 'fixtures', 'bad.py'

describe 'Tpe pylama provider for Linter', ->
  lint = require('../lib/init').provideLinter().lint
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage 'linter-pylama'
    waitsForPromise ->
      atom.packages.activatePackage 'language-python'

  it 'should be in the package list', ->
    expect(atom.packages.isPackageLoaded 'linter-pylama').toBe true

  it 'should have activated the package', ->
    expect(atom.packages.isPackageActive 'linter-pylama').toBe true


  describe "reads good.py and", ->
    editor = null
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open(goodPath).then (data) ->
          editor = data

    it 'finds nothing to complain about', ->
      messages = []
      waitsForPromise ->
        lint(editor).then (results) ->
          messages = results
      runs ->
        expect(messages.length).toEqual 0


  describe "reads bad.py and", ->
    editor = null
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open(badPath).then (data) ->
          editor = data

    it 'finds something to complain about', ->
      messages = []
      waitsForPromise ->
        lint(editor).then (results) ->
          messages = results
      runs ->
        expect(messages.length).toEqual 7

    it 'finds the right things to complain about', ->
      messages = null
      waitsForPromise ->
        lint(editor).then (data) ->
          messages = data
      runs ->
        err0 = "D100 Missing docstring in public module [pep257]"
        err1 = "E0100 SyntaxError: invalid syntax [pylama]"
        err2 = "E203 whitespace before ':' [pep8]"
        err3 = "E231 missing whitespace after ':' [pep8]"
        err4 = "E225 missing whitespace around operator [pep8]"
        err5 = "E302 expected 2 blank lines, found 1 [pep8]"
        err6 = "D101 Missing docstring in public class [pep257]"

        expect(messages[0].text).toBe(err0)
        expect(messages[0].range).toEqual([[0,0], [0,1]])
        expect(messages[0].type).toBe('Warning')
        expect(messages[0].filePath).toMatch(badPath)

        expect(messages[1].text).toBe(err1)
        expect(messages[1].range).toEqual([[0,0], [0,1]])
        expect(messages[1].type).toBe('Error')
        expect(messages[1].filePath).toMatch(badPath)

        expect(messages[2].text).toBe(err2)
        expect(messages[2].range).toEqual([[2,1], [2,4]])
        expect(messages[2].type).toBe('Error')
        expect(messages[2].filePath).toMatch(badPath)

        expect(messages[3].text).toBe(err3)
        expect(messages[3].range).toEqual([[2,2], [2,3]])
        expect(messages[3].type).toBe('Error')
        expect(messages[3].filePath).toMatch(badPath)

        expect(messages[4].text).toBe(err4)
        expect(messages[4].range).toEqual([[2,3], [2,3]])
        expect(messages[4].type).toBe('Error')
        expect(messages[4].filePath).toMatch(badPath)

        expect(messages[5].text).toBe(err5)
        expect(messages[5].range).toEqual([[4,0], [4,5]])
        expect(messages[5].type).toBe('Error')
        expect(messages[5].filePath).toMatch(badPath)

        expect(messages[6].text).toBe(err6)
        expect(messages[6].range).toEqual([[4,0], [4,5]])
        expect(messages[6].type).toBe('Warning')
        expect(messages[6].filePath).toMatch(badPath)

