""" Description. """

# Module information
# ==================


__version__ = "1.0.1"
__project__ = "pylama_pylint"
__author__ = "horneds <horneds@gmail.com>"
__license__ = "BSD"

import sys
if sys.version_info >= (3, 0, 0):
    raise ImportError("pylama_pylint doesnt support python3")

from .main import Linter
assert Linter
