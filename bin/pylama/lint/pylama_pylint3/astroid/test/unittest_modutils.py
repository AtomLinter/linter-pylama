# copyright 2003-2014 LOGILAB S.A. (Paris, FRANCE), all rights reserved.
# contact http://www.logilab.fr/ -- mailto:contact@logilab.fr
#
# This file is part of astroid.
#
# astroid is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation, either version 2.1 of the License, or (at your option) any
# later version.
#
# astroid is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with astroid.  If not, see <http://www.gnu.org/licenses/>.
"""
unit tests for module modutils (module manipulation utilities)
"""

import sys
try:
    __file__
except NameError:
    __file__ = sys.argv[0]

from logilab.common.testlib import TestCase, unittest_main

from os import path, getcwd, sep
from astroid import modutils

sys.path.insert(0, path.dirname(__file__))
DATADIR = path.abspath(path.normpath(path.join(path.dirname(__file__), 'data')))


class ModuleFileTC(TestCase):
    package = "mypypa"

    def tearDown(self):
        super(ModuleFileTC, self).tearDown()
        for k in list(sys.path_importer_cache.keys()):
            if 'MyPyPa' in k:
                del sys.path_importer_cache[k]

    def test_find_zipped_module(self):
        mtype, mfile = modutils._module_file([self.package], [path.join(DATADIR, 'MyPyPa-0.1.0-py2.5.zip')])
        self.assertEqual(mtype, modutils.ZIPFILE)
        self.assertEqual(mfile.split(sep)[-4:], ["test", "data", "MyPyPa-0.1.0-py2.5.zip", self.package])

    def test_find_egg_module(self):
        mtype, mfile = modutils._module_file([self.package], [path.join(DATADIR, 'MyPyPa-0.1.0-py2.5.egg')])
        self.assertEqual(mtype, modutils.ZIPFILE)
        self.assertEqual(mfile.split(sep)[-4:], ["test", "data", "MyPyPa-0.1.0-py2.5.egg", self.package])


class load_module_from_name_tc(TestCase):
    """ load a python module from it's name """

    def test_knownValues_load_module_from_name_1(self):
        self.assertEqual(modutils.load_module_from_name('sys'), sys)

    def test_knownValues_load_module_from_name_2(self):
        self.assertEqual(modutils.load_module_from_name('os.path'), path)

    def test_raise_load_module_from_name_1(self):
        self.assertRaises(ImportError,
                          modutils.load_module_from_name, 'os.path', use_sys=0)


class get_module_part_tc(TestCase):
    """given a dotted name return the module part of the name"""

    def test_knownValues_get_module_part_1(self):
        self.assertEqual(modutils.get_module_part('astroid.modutils'),
                         'astroid.modutils')

    def test_knownValues_get_module_part_2(self):
        self.assertEqual(modutils.get_module_part('astroid.modutils.get_module_part'),
                         'astroid.modutils')

    def test_knownValues_get_module_part_3(self):
        """relative import from given file"""
        self.assertEqual(modutils.get_module_part('node_classes.AssName',
                                                  modutils.__file__), 'node_classes')

    def test_knownValues_get_compiled_module_part(self):
        self.assertEqual(modutils.get_module_part('math.log10'), 'math')
        self.assertEqual(modutils.get_module_part('math.log10', __file__), 'math')

    def test_knownValues_get_builtin_module_part(self):
        self.assertEqual(modutils.get_module_part('sys.path'), 'sys')
        self.assertEqual(modutils.get_module_part('sys.path', '__file__'), 'sys')

    def test_get_module_part_exception(self):
        self.assertRaises(ImportError, modutils.get_module_part, 'unknown.module',
                          modutils.__file__)


class modpath_from_file_tc(TestCase):
    """ given an absolute file path return the python module's path as a list """

    def test_knownValues_modpath_from_file_1(self):
        self.assertEqual(modutils.modpath_from_file(modutils.__file__),
                         ['astroid', 'modutils'])

    def test_knownValues_modpath_from_file_2(self):
        self.assertEqual(modutils.modpath_from_file('unittest_modutils.py',
                                                    {getcwd(): 'arbitrary.pkg'}),
                         ['arbitrary', 'pkg', 'unittest_modutils'])

    def test_raise_modpath_from_file_Exception(self):
        self.assertRaises(Exception, modutils.modpath_from_file, '/turlututu')


class load_module_from_path_tc(TestCase):

    def test_do_not_load_twice(self):
        sys.path.insert(0, self.datadir)
        foo = modutils.load_module_from_modpath(['lmfp', 'foo'])
        lmfp = modutils.load_module_from_modpath(['lmfp'])
        self.assertEqual(len(sys.just_once), 1)
        sys.path.pop(0)
        del sys.just_once


class file_from_modpath_tc(TestCase):
    """given a mod path (i.e. splited module / package name), return the
    corresponding file, giving priority to source file over precompiled file
    if it exists"""

    def test_site_packages(self):
        self.assertEqual(path.realpath(modutils.file_from_modpath(['astroid', 'modutils'])),
                         path.realpath(modutils.__file__.replace('.pyc', '.py')))

    def test_std_lib(self):
        from os import path
        self.assertEqual(path.realpath(modutils.file_from_modpath(['os', 'path']).replace('.pyc', '.py')),
                         path.realpath(path.__file__.replace('.pyc', '.py')))

    def test_xmlplus(self):
        try:
            # don't fail if pyxml isn't installed
            from xml.dom import ext
        except ImportError:
            pass
        else:
            self.assertEqual(path.realpath(modutils.file_from_modpath(['xml', 'dom', 'ext']).replace('.pyc', '.py')),
                             path.realpath(ext.__file__.replace('.pyc', '.py')))

    def test_builtin(self):
        self.assertEqual(modutils.file_from_modpath(['sys']),
                         None)


    def test_unexisting(self):
        self.assertRaises(ImportError, modutils.file_from_modpath, ['turlututu'])


class get_source_file_tc(TestCase):

    def test(self):
        from os import path
        self.assertEqual(modutils.get_source_file(path.__file__),
                         path.normpath(path.__file__.replace('.pyc', '.py')))

    def test_raise(self):
        self.assertRaises(modutils.NoSourceFile, modutils.get_source_file, 'whatever')


class is_standard_module_tc(TestCase):
    """
    return true if the module may be considered as a module from the standard
    library
    """

    def test_builtins(self):
        if sys.version_info < (3, 0):
            self.assertEqual(modutils.is_standard_module('__builtin__'), True)
            self.assertEqual(modutils.is_standard_module('builtins'), False)
        else:
            self.assertEqual(modutils.is_standard_module('__builtin__'), False)
            self.assertEqual(modutils.is_standard_module('builtins'), True)

    def test_builtin(self):
        self.assertEqual(modutils.is_standard_module('sys'), True)

    def test_nonstandard(self):
        self.assertEqual(modutils.is_standard_module('logilab'), False)

    def test_unknown(self):
        self.assertEqual(modutils.is_standard_module('unknown'), False)

    def test_builtin(self):
        self.assertEqual(modutils.is_standard_module('marshal'), True)

    def test_4(self):
        import astroid
        if sys.version_info > (3, 0):
            skip = sys.platform.startswith('win') or '.tox' in astroid.__file__
            if skip:
                self.skipTest('imp module has a broken behaviour in Python 3 on '
                              'Windows, returning the module path with different '
                              'case than it should be.')
        self.assertEqual(modutils.is_standard_module('hashlib'), True)
        self.assertEqual(modutils.is_standard_module('pickle'), True)
        self.assertEqual(modutils.is_standard_module('email'), True)
        self.assertEqual(modutils.is_standard_module('io'), sys.version_info >= (2, 6))
        self.assertEqual(modutils.is_standard_module('StringIO'), sys.version_info < (3, 0))

    def test_custom_path(self):
        if DATADIR.startswith(modutils.EXT_LIB_DIR):
            self.skipTest('known breakage of is_standard_module on installed package')
        print(repr(DATADIR))
        print(modutils.EXT_LIB_DIR)
        self.assertEqual(modutils.is_standard_module('data.module', (DATADIR,)), True)
        self.assertEqual(modutils.is_standard_module('data.module', (path.abspath(DATADIR),)), True)

    def test_failing_edge_cases(self):
        from logilab import common
        # using a subpackage/submodule path as std_path argument
        self.assertEqual(modutils.is_standard_module('logilab.common', common.__path__), False)
        # using a module + object name as modname argument
        self.assertEqual(modutils.is_standard_module('sys.path'), True)
        # this is because only the first package/module is considered
        self.assertEqual(modutils.is_standard_module('sys.whatever'), True)
        self.assertEqual(modutils.is_standard_module('logilab.whatever', common.__path__), False)


class is_relative_tc(TestCase):


    def test_knownValues_is_relative_1(self):
        import astroid
        self.assertEqual(modutils.is_relative('modutils', astroid.__path__[0]),
                         True)

    def test_knownValues_is_relative_2(self):
        from logilab.common import tree
        self.assertEqual(modutils.is_relative('modutils', tree.__file__),
                         True)

    def test_knownValues_is_relative_3(self):
        import astroid
        self.assertEqual(modutils.is_relative('astroid', astroid.__path__[0]),
                         False)


class get_module_files_tc(TestCase):

    def test_knownValues_get_module_files_1(self): #  XXXFIXME: TOWRITE
        """given a directory return a list of all available python module's files, even
        in subdirectories
        """
        import data
        modules = sorted(modutils.get_module_files(path.join(DATADIR, 'find_test'),
                                                   data.__path__[0]))
        self.assertEqual(modules,
                         [path.join(DATADIR, 'find_test', x) for x in ['__init__.py', 'module.py', 'module2.py', 'noendingnewline.py', 'nonregr.py']])

    def test_load_module_set_attribute(self):
        import logilab.common.fileutils
        import logilab
        del logilab.common.fileutils
        del sys.modules['logilab.common.fileutils']
        m = modutils.load_module_from_modpath(['logilab', 'common', 'fileutils'])
        self.assertTrue( hasattr(logilab, 'common') )
        self.assertTrue( hasattr(logilab.common, 'fileutils') )
        self.assertTrue( m is logilab.common.fileutils )


from logilab.common.testlib import DocTest

class ModuleDocTest(DocTest):
    """test doc test in this module"""
    from astroid import modutils as module

del DocTest # necessary if we don't want it to be executed (we don't...)


if __name__ == '__main__':
    unittest_main()
