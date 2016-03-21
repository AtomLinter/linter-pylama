# 0.2.9
* Fix and close #34

# 0.2.7
* Fix and close #32
* Update xregexp

# 0.2.5
* Update pep257 version to 0.7.0
* Update pyflakes version to 1.0.0
* Update six to 1.10.0
* Update Pylama version to 7.0.6
* Correct typo and improved language

# 0.2.2
* Fix #18

# 0.2.1
* Updated pep257 to 0.7.1-alpha (c3f3757434133666c8518bf5e2b64674cdc53e21)

# 0.2.0
* Added support config file. Close #11

# 0.1.6
* Used atom-package-deps for deps. Close #15

# 0.1.5
* Update pep257 to v0.6.0

# 0.1.4
* Force linting files without extensions. Close #10

# 0.1.3
* Update pylama version to 6.3.4 (except PEP257 linter)
* Update PyLint version to 1.4.4

# 0.1.2
* Remove deprecated 'linter-package' from the package.json

# 0.1.1
* Fix #8

# 0.1.0
* Migrate to Linter-plus API (close #5 and close #7).

# 0.0.20
* Temporary fix for Linter 1.0.1.
* Use python from env.
* Added file name in regex message.
* Used @cwd.
* Optimize PYTHONPATH.

# 0.0.19
* Refactoring.

# 0.0.18
* Fix warning about deprecated activationEvents.

# 0.0.17
* Update pylama version to 6.3.1
* Update pylint version to 1.4.3

# 0.0.16
* Fix regex string for Windows line endings. See #4
* Fix detection an external pylama on Windows. See #4

# 0.0.15
* Pylint version updated to 1.4

# 0.0.14
* Remove debug output

# 0.0.13
* Use atom.config.observe for linter settings

# 0.0.12
* Fix issue #3
* Added pylint for python3

# 0.0.11
* Fix issue #2 - checking 'stdout' and 'stderr'
* Update pylint to 6.1.1 and pylama_pylint to 1.0.1

# 0.0.10
* Improved detection of the PYTHONPATH

# 0.0.9
* Removed async mode (because it not be used in the checking of the single files)
* Select linters through checkboxes
* Added internal Pylama

# 0.0.8
* Added Virtualenv detection
* Append PYTHONPATH variable to process.env

# 0.0.7
* Added skip file feature
* Used JSON Schema for linter config
* Disable aync mode for pylint

# 0.0.6
* Replaced null by ''

# 0.0.5
* Improved detection of pyflakes 'invalid syntax' errors

# 0.0.4
* Improved detection of warnings
* Fix detection pep257 warnings
* Added 'async' mode

# 0.0.3
* Separation of messages to errors or warnings
* Added selection of linters
* Added 'executablePath' for pylama linter
* Minor changes

# 0.0.2
* Updated repository url

# 0.0.1
* Implemented first version of 'linter-pylama'
