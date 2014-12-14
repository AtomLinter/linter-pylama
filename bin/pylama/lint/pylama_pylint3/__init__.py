""" Description. """

# Module information
# ==================


__version__ = "0.0.1"
__project__ = "pylama_pylint3"
__license__ = "BSD"

import sys
if sys.version_info <= (3, 0, 0):
    raise ImportError("pylama_pylint3 doesnt support python2")

from .main import Linter
assert Linter
