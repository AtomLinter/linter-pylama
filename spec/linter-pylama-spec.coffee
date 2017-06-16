path = require 'path'

errwarnPath = path.join __dirname, 'fixtures', 'errwarn.py'
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
        expect(messages.length).toEqual 1

    it 'finds the right things to complain about', ->
      messages = null
      waitsForPromise ->
        lint(editor).then (data) ->
          messages = data
      runs ->
        err0 = "E0100 SyntaxError: invalid syntax [pylama]"

        expect(messages[0].excerpt).toBe(err0)
        expect(messages[0].location.position).toEqual([[0, 0], [0, 1]])
        expect(messages[0].severity).toBe('error')
        expect(messages[0].location.file).toBe(badPath)


  describe "reads errwarn.py and", ->
    editor = null
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open(errwarnPath).then (data) ->
          editor = data

    it 'finds something to complain about', ->
      messages = []
      waitsForPromise ->
        lint(editor).then (results) ->
          messages = results
      runs ->
        expect(messages.length).toEqual 16

    it 'finds the right things to complain about', ->
      messages = null
      waitsForPromise ->
        lint(editor).then (data) ->
          messages = data
      runs ->
        err = [
          "D100 Missing docstring in public module [pep257]"
          "W0611 'path' imported but unused [pyflakes]"
          "E302 expected 2 blank lines, found 1 [pep8]"
          "D401 First line should be in imperative mood ('Add', not 'Adds') [pep257]"
          "D400 First line should end with a period (not 's') [pep257]"
          "W0621 import 'path' from line 1 shadowed by loop variable [pyflakes]"
          "E305 expected 2 blank lines after class or function definition, found 1 [pep8]"
          "E225 missing whitespace around operator [pep8]"
          "D209 Multi-line docstring closing quotes should be on a separate line [pep257]"
          "D205 1 blank line required between summary line and description (found 0) [pep257]"
          "D208 Docstring is over-indented [pep257]"
          "D102 Missing docstring in public method [pep257]"
          "E0602 undefined name 'i' [pyflakes]"
          "W0612 local variable 'i' is assigned to but never used [pyflakes]"
          "E0602 local variable 'b' (defined in enclosing scope on line 8) referenced before assignment [pyflakes]"
          "W0612 local variable 'b' is assigned to but never used [pyflakes]"
        ]


        expect(messages[0].excerpt).toBe(err[0])
        expect(messages[0].location.position).toEqual([[0, 0], [0, 6]])
        expect(messages[0].severity).toBe('warning')
        expect(messages[0].location.file).toBe(errwarnPath)

        expect(messages[1].excerpt).toBe(err[1])
        expect(messages[1].location.position).toEqual([[0, 0], [0, 6]])
        expect(messages[1].severity).toBe('warning')
        expect(messages[1].location.file).toBe(errwarnPath)

        expect(messages[2].excerpt).toBe(err[2])
        expect(messages[2].location.position).toEqual([[2, 0], [2, 3]])
        expect(messages[2].severity).toBe('error')
        expect(messages[2].location.file).toBe(errwarnPath)

        expect(messages[3].excerpt).toBe(err[3])
        expect(messages[3].location.position).toEqual([[2, 0], [2, 3]])
        expect(messages[3].severity).toBe('warning')
        expect(messages[3].location.file).toBe(errwarnPath)

        expect(messages[4].excerpt).toBe(err[4])
        expect(messages[4].location.position).toEqual([[2, 0], [2, 3]])
        expect(messages[4].severity).toBe('warning')
        expect(messages[4].location.file).toBe(errwarnPath)

        expect(messages[5].excerpt).toBe(err[5])
        expect(messages[5].location.position).toEqual([[4, 0], [4, 3]])
        expect(messages[5].severity).toBe('warning')
        expect(messages[5].location.file).toBe(errwarnPath)

        expect(messages[6].excerpt).toBe(err[6])
        expect(messages[6].location.position).toEqual([[7, 0], [7, 3]])
        expect(messages[6].severity).toBe('error')
        expect(messages[6].location.file).toBe(errwarnPath)

        expect(messages[7].excerpt).toBe(err[7])
        expect(messages[7].location.position).toEqual([[7, 3], [7, 4]])
        expect(messages[7].severity).toBe('error')
        expect(messages[7].location.file).toBe(errwarnPath)

        expect(messages[8].excerpt).toBe(err[8])
        expect(messages[8].location.position).toEqual([[10, 0], [10, 5]])
        expect(messages[8].severity).toBe('warning')
        expect(messages[8].location.file).toBe(errwarnPath)

        expect(messages[9].excerpt).toBe(err[9])
        expect(messages[9].location.position).toEqual([[10, 0], [10, 5]])
        expect(messages[9].severity).toBe('warning')
        expect(messages[9].location.file).toBe(errwarnPath)

        expect(messages[10].excerpt).toBe(err[10])
        expect(messages[10].location.position).toEqual([[10, 0], [10, 5]])
        expect(messages[10].severity).toBe('warning')
        expect(messages[10].location.file).toBe(errwarnPath)

        expect(messages[11].excerpt).toBe(err[11])
        expect(messages[11].location.position).toEqual([[15, 0], [15, 3]])
        expect(messages[11].severity).toBe('warning')
        expect(messages[11].location.file).toBe(errwarnPath)

        expect(messages[12].excerpt).toBe(err[12])
        expect(messages[12].location.position).toEqual([[16, 0], [16, 3]])
        expect(messages[12].severity).toBe('error')
        expect(messages[12].location.file).toBe(errwarnPath)

        expect(messages[13].excerpt).toBe(err[13])
        expect(messages[13].location.position).toEqual([[16, 0], [16, 3]])
        expect(messages[13].severity).toBe('warning')
        expect(messages[13].location.file).toBe(errwarnPath)

        expect(messages[14].excerpt).toBe(err[14])
        expect(messages[14].location.position).toEqual([[17, 0], [17, 3]])
        expect(messages[14].severity).toBe('error')
        expect(messages[14].location.file).toBe(errwarnPath)

        expect(messages[15].excerpt).toBe(err[15])
        expect(messages[15].location.position).toEqual([[17, 0], [17, 3]])
        expect(messages[15].severity).toBe('warning')
        expect(messages[15].location.file).toBe(errwarnPath)
