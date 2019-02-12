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
        # NOTE: This only works because the messages are unique
        err = new Map([
          [
            "D100 Missing docstring in public module [pep257]",
            {
              severity: 'warning',
              position: [[0, 0], [0, 6]]
            }
          ],
          [
            "W0611 'path' imported but unused [pyflakes]",
            {
              severity: 'warning',
              position: [[0, 0], [0, 6]]
            }
          ],
          [
            "E302 expected 2 blank lines, found 1 [pep8]",
            {
              severity: 'error',
              position: [[2, 0], [2, 3]]
            }
          ],
          [
            "D401 First line should be in imperative mood ('Add', not 'Adds') [pep257]",
            {
              severity: 'warning',
              position: [[2, 0], [2, 3]]
            }
          ],
          [
            "D400 First line should end with a period (not 's') [pep257]",
            {
              severity: 'warning',
              position: [[2, 0], [2, 3]]
            }
          ],
          [
            "W0621 import 'path' from line 1 shadowed by loop variable [pyflakes]",
            {
              severity: 'warning',
              position: [[4, 0], [4, 3]]
            }
          ],
          [
            "E305 expected 2 blank lines after class or function definition, found 1 [pep8]",
            {
              severity: 'error',
              position: [[7, 0], [7, 3]]
            }
          ],
          [
            "E225 missing whitespace around operator [pep8]",
            {
              severity: 'error',
              position: [[7, 3], [7, 4]]
            }
          ],
          [
            "D209 Multi-line docstring closing quotes should be on a separate line [pep257]",
            {
              severity: 'warning',
              position: [[10, 0], [10, 5]]
            }
          ],
          [
            "D205 1 blank line required between summary line and description (found 0) [pep257]",
            {
              severity: 'warning',
              position: [[10, 0], [10, 5]]
            }
          ],
          [
            "D208 Docstring is over-indented [pep257]",
            {
              severity: 'warning',
              position: [[10, 0], [10, 5]]
            }
          ],
          [
            "D102 Missing docstring in public method [pep257]",
            {
              severity: 'warning',
              position: [[15, 0], [15, 3]]
            }
          ],
          [
            "E0602 undefined name 'i' [pyflakes]",
            {
              severity: 'error',
              position: [[16, 0], [16, 3]]
            }
          ],
          [
            "W0612 local variable 'i' is assigned to but never used [pyflakes]",
            {
              severity: 'warning',
              position: [[16, 0], [16, 3]]
            }
          ],
          [
            "E0602 local variable 'b' (defined in enclosing scope on line 8) referenced before assignment [pyflakes]",
            {
              severity: 'error',
              position: [[17, 0], [17, 3]]
            }
          ],
          [
            "W0612 local variable 'b' is assigned to but never used [pyflakes]",
            {
              severity: 'warning',
              position: [[17, 0], [17, 3]]
            }
          ]
        ])

        expect(messages.length).toBe(err.size)

        messages.forEach((message) ->
          expect(err.has(message.excerpt)).toBe(true)
          expected = err.get(message.excerpt)
          expect(message.severity).toBe(expected.severity)
          expect(message.location.file).toBe(errwarnPath)
          expect(message.location.position).toEqual(expected.position)
        )
