# 0.9.3
* Fix #79
* Update Travis CI configuration, fix path comparison in specs, а few minor cleanups (@Arcanemagus)

# 0.9.2
* Added default values (python.exe and pylama.exe) for Windows
* Fix #77

# 0.9.1
* Fixed shadowing of the global variable
* Fix camelCase typo

# 0.9.0
* Refactoring and other enhancements
* Close #38

# 0.8.20
* Fix and close #75

# 0.8.18
* Unbreak external pylama (@ddaanet)

# 0.8.17
* Allow Pyflakes with Radon. Close #71
* Update pylint to version 1.7.1
* Update astroid to version 1.5.2
* Update wrapt to version 1.10.10

# 0.8.16
* Fix and close #67

# 0.8.15
* Fix and close #61

# 0.8.14
* Expand and resolving '~' for pylama path
* Update radon version to 1.5.0
* Remove unused mando package
* fix(package): update atom-linter to version 9.0.0 (#60)

# 0.8.13
* Update pylint version to 1.6.5
* Update flake8 version to 3.3.0
* Update pycodestyle to version 2.3.1
* Update mccabe version to 0.6.1
* Fix and close #59

# 0.8.12
* Update pylama_pylint to version 3.0.1
* Update pylama to version 7.3.3
* Update pyflakes to version 1.5.0

# 0.8.11
* Update astroid to version 1.4.9
* Update mccabe to version 0.5.3

# 0.8.10
* Fix and close #57

# 0.8.9
*  Update pylama to version 7.3.1

# 0.8.8
* Update flake8 to version 3.2.1

# 0.8.7
* Update pycodestyle to version 2.2.0
* Update flake8 to version 3.2.0

# 0.8.6
* Update pycodestyle to version 2.1.0
* Add shortcut for isort

# 0.8.5
* Update pylama version to 7.2.3
* Add Radon - complexity checker

# 0.8.0
* Add a custom interpreter setting for internal pylama (@Evpok)

# 0.7.6
* Use isort for sorting imports on save

# 0.7.5
* Add isort support (close #53)

# 0.7.4
* Update pydocstyle to version 1.1.1

# 0.7.3
* Minor changes

# 0.7.2
* Fix and close #52
* Prevent double initialization

# 0.7.1
* Fix and close #51

# 0.7.0
* Update pylama to version 7.10
* Update atom-package-deps to version 4.3.1

# 0.6.0
* Fix and close #50
* Update internal pyflakes to version 1.3.0

# 0.5.8
* Reorder sys.path. Fix and close #48
* Update atom-linter to version 8.0.0

# 0.5.7
* Don't import external linters
* Fix import Linter from pylam_pylint
* Update mccabe to version 0.5.2

# 0.5.4
* Add specs (close #23)
* Fix and close #41
* Fix and close #37
* Update pylint to version 1.6.4

# 0.5.3
* Update atom-linter to version 7.0.0
* Add project path into PYTHONPATH
* Show linters errors from stderr
* Fix typo

# 0.5.2
* Fix #41
* Add R and I error codes

# 0.5.0
* Mark (F)ailed errors as errors
* Update pylint to version 1.6.1
* Migrate to pycodestyle/pydocstyle

# 0.4.4
* Fix #39 (UNC paths) for lintOnSave
* Remove unused import

# 0.4.0
* Refactoring and simplify code

# 0.3.0
* Change default pylamaVersion
* Update pylint to 1.5.6
* Update pyflakes to 1.2.3
* Update pep8 to 1.7.0
* Update mccabe to 0.5.0
* Update pylama to 7.0.9

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
