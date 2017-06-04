path = require 'path'

packagePath = path.dirname(__dirname)

module.exports = {
  linter_paths: {
    isort: path.join packagePath, 'bin', 'isort.py'
    pylama: path.join packagePath, 'bin', 'pylama.py'
  }

  linters: {
    pylint: 'pylint'
    mccabe: 'mccabe'
    pep8: 'pep8'
    pep257: 'pep257'
    pyflakes: 'pyflakes'
    radon: 'radon'
    isort: 'isort'
  }

  regex:
    '(?<file_>.+):' +
    '(?<line>\\d+):' +
    '(?<col>\\d+):' +
    '\\s+' +
    '(((?<type>[ECDFINRW])(?<file>\\d+)(:\\s+|\\s+))|(.*?))' +
    '(?<message>.+)'
}
