"""Astroid hooks for the Python 2 qt4 module.

Currently help understanding of :

* PyQT4.QtCore
"""

from astroid import MANAGER
from astroid.builder import AstroidBuilder


def pyqt4_qtcore_transform(module):
    fake = AstroidBuilder(MANAGER).string_build('''

def SIGNAL(signal_name): pass

class QObject(object):
    def emit(self, signal): pass
''')
    for klass in ('QObject',):
        module.locals[klass] = fake.locals[klass]


import py2stdlib
py2stdlib.MODULE_TRANSFORMS['PyQt4.QtCore'] = pyqt4_qtcore_transform
