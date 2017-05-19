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

        expect(messages[0].excerpt).toBe(err0)
        expect(messages[0].location.position).toEqual([[0,0], [0,1]])
        expect(messages[0].severity).toBe('warning')
        expect(messages[0].location.file).toMatch(badPath)

        expect(messages[1].excerpt).toBe(err1)
        expect(messages[1].location.position).toEqual([[0,0], [0,1]])
        expect(messages[1].severity).toBe('error')
        expect(messages[1].location.file).toMatch(badPath)

        expect(messages[2].excerpt).toBe(err2)
        expect(messages[2].location.position).toEqual([[2,1], [2,4]])
        expect(messages[2].severity).toBe('error')
        expect(messages[2].location.file).toMatch(badPath)

        expect(messages[3].excerpt).toBe(err3)
        expect(messages[3].location.position).toEqual([[2,2], [2,3]])
        expect(messages[3].severity).toBe('error')
        expect(messages[3].location.file).toMatch(badPath)

        expect(messages[4].excerpt).toBe(err4)
        expect(messages[4].location.position).toEqual([[2,3], [2,3]])
        expect(messages[4].severity).toBe('error')
        expect(messages[4].location.file).toMatch(badPath)

        expect(messages[5].excerpt).toBe(err5)
        expect(messages[5].location.position).toEqual([[4,0], [4,5]])
        expect(messages[5].severity).toBe('error')
        expect(messages[5].location.file).toMatch(badPath)

        expect(messages[6].excerpt).toBe(err6)
        expect(messages[6].location.position).toEqual([[4,0], [4,5]])
        expect(messages[6].severity).toBe('warning')
        expect(messages[6].location.file).toMatch(badPath)
