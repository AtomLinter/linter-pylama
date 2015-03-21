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
