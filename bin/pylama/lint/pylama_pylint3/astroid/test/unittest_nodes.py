# copyright 2003-2013 LOGILAB S.A. (Paris, FRANCE), all rights reserved.
# contact http://www.logilab.fr/ -- mailto:contact@logilab.fr
#
# This file is part of astroid.
#
# astroid is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by the
# Free Software Foundation, either version 2.1 of the License, or (at your
# option) any later version.
#
# astroid is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
# for more details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with astroid. If not, see <http://www.gnu.org/licenses/>.
"""tests for specific behaviour of astroid nodes
"""
import sys

from logilab.common import testlib
from astroid.node_classes import unpack_infer
from astroid.bases import BUILTINS, YES, InferenceContext
from astroid.exceptions import AstroidBuildingException, NotFoundError
from astroid import builder, nodes

from data import module as test_module

from os.path import join, abspath, dirname

DATA = join(dirname(abspath(__file__)), 'data')

abuilder = builder.AstroidBuilder()

class AsString(testlib.TestCase):

    def test_tuple_as_string(self):
        def build(string):
            return abuilder.string_build(string).body[0].value

        self.assertEqual(build('1,').as_string(), '(1, )')
        self.assertEqual(build('1, 2, 3').as_string(), '(1, 2, 3)')
        self.assertEqual(build('(1, )').as_string(), '(1, )')
        self.assertEqual(build('1, 2, 3').as_string(), '(1, 2, 3)')

    def test_varargs_kwargs_as_string(self):
        ast = abuilder.string_build( 'raise_string(*args, **kwargs)').body[0]
        self.assertEqual(ast.as_string(), 'raise_string(*args, **kwargs)')

    def test_module_as_string(self):
        """check as_string on a whole module prepared to be returned identically
        """
        data = open(join(DATA, 'module.py')).read()
        self.assertMultiLineEqual(MODULE.as_string(), data)

    def test_module2_as_string(self):
        """check as_string on a whole module prepared to be returned identically
        """
        data = open(join(DATA, 'module2.py')).read()
        self.assertMultiLineEqual(MODULE2.as_string(), data)

    @testlib.require_version('2.7')
    def test_2_7_as_string(self):
        """check as_string for python syntax >= 2.7"""
        code = '''one_two = {1, 2}
b = {v: k for (k, v) in enumerate('string')}
cdd = {k for k in b}\n\n'''
        ast = abuilder.string_build(code)
        self.assertMultiLineEqual(ast.as_string(), code)

    @testlib.require_version('3.0')
    def test_3k_as_string(self):
        """check as_string for python 3k syntax"""
        code = '''print()

def function(var):
    nonlocal counter
    try:
        hello
    except NameError as nexc:
        (*hell, o) = b'hello'
        raise AttributeError from nexc
\n'''
        # TODO : annotations and keywords for class definition are not yet implemented
        _todo = '''
def function(var:int):
    nonlocal counter

class Language(metaclass=Natural):
    """natural language"""
        '''
        ast = abuilder.string_build(code)
        self.assertEqual(ast.as_string(), code)


class _NodeTC(testlib.TestCase):
    """test transformation of If Node"""
    CODE = None
    @property
    def astroid(self):
        try:
            return self.__class__.__dict__['CODE_Astroid']
        except KeyError:
            astroid = abuilder.string_build(self.CODE)
            self.__class__.CODE_Astroid = astroid
            return astroid


class IfNodeTC(_NodeTC):
    """test transformation of If Node"""
    CODE = """
if 0:
    print()

if True:
    print()
else:
    pass

if "":
    print()
elif []:
    raise

if 1:
    print()
elif True:
    print()
elif func():
    pass
else:
    raise
    """

    def test_if_elif_else_node(self):
        """test transformation for If node"""
        self.assertEqual(len(self.astroid.body), 4)
        for stmt in self.astroid.body:
            self.assertIsInstance( stmt, nodes.If)
        self.assertFalse(self.astroid.body[0].orelse) # simple If
        self.assertIsInstance(self.astroid.body[1].orelse[0], nodes.Pass) # If / else
        self.assertIsInstance(self.astroid.body[2].orelse[0], nodes.If) # If / elif
        self.assertIsInstance(self.astroid.body[3].orelse[0].orelse[0], nodes.If)

    def test_block_range(self):
        # XXX ensure expected values
        self.assertEqual(self.astroid.block_range(1), (0, 22))
        self.assertEqual(self.astroid.block_range(10), (0, 22)) # XXX (10, 22) ?
        self.assertEqual(self.astroid.body[1].block_range(5), (5, 6))
        self.assertEqual(self.astroid.body[1].block_range(6), (6, 6))
        self.assertEqual(self.astroid.body[1].orelse[0].block_range(7), (7, 8))
        self.assertEqual(self.astroid.body[1].orelse[0].block_range(8), (8, 8))


class TryExceptNodeTC(_NodeTC):
    CODE = """
try:
    print ('pouet')
except IOError:
    pass
except UnicodeError:
    print()
else:
    print()
    """
    def test_block_range(self):
        # XXX ensure expected values
        self.assertEqual(self.astroid.body[0].block_range(1), (1, 8))
        self.assertEqual(self.astroid.body[0].block_range(2), (2, 2))
        self.assertEqual(self.astroid.body[0].block_range(3), (3, 8))
        self.assertEqual(self.astroid.body[0].block_range(4), (4, 4))
        self.assertEqual(self.astroid.body[0].block_range(5), (5, 5))
        self.assertEqual(self.astroid.body[0].block_range(6), (6, 6))
        self.assertEqual(self.astroid.body[0].block_range(7), (7, 7))
        self.assertEqual(self.astroid.body[0].block_range(8), (8, 8))


class TryFinallyNodeTC(_NodeTC):
    CODE = """
try:
    print ('pouet')
finally:
    print ('pouet')
    """
    def test_block_range(self):
        # XXX ensure expected values
        self.assertEqual(self.astroid.body[0].block_range(1), (1, 4))
        self.assertEqual(self.astroid.body[0].block_range(2), (2, 2))
        self.assertEqual(self.astroid.body[0].block_range(3), (3, 4))
        self.assertEqual(self.astroid.body[0].block_range(4), (4, 4))


class TryFinally25NodeTC(_NodeTC):
    CODE = """
try:
    print('pouet')
except Exception:
    print ('oops')
finally:
    print ('pouet')
    """
    def test_block_range(self):
        # XXX ensure expected values
        self.assertEqual(self.astroid.body[0].block_range(1), (1, 6))
        self.assertEqual(self.astroid.body[0].block_range(2), (2, 2))
        self.assertEqual(self.astroid.body[0].block_range(3), (3, 4))
        self.assertEqual(self.astroid.body[0].block_range(4), (4, 4))
        self.assertEqual(self.astroid.body[0].block_range(5), (5, 5))
        self.assertEqual(self.astroid.body[0].block_range(6), (6, 6))


class TryExcept2xNodeTC(_NodeTC):
    CODE = """
try:
    hello
except AttributeError, (retval, desc):
    pass
    """
    def test_tuple_attribute(self):
        if sys.version_info >= (3, 0):
            self.skipTest('syntax removed from py3.x')
        handler = self.astroid.body[0].handlers[0]
        self.assertIsInstance(handler.name, nodes.Tuple)


MODULE = abuilder.module_build(test_module)
MODULE2 = abuilder.file_build(join(DATA, 'module2.py'), 'data.module2')


class ImportNodeTC(testlib.TestCase):

    def test_import_self_resolve(self):
        myos = next(MODULE2.igetattr('myos'))
        self.assertTrue(isinstance(myos, nodes.Module), myos)
        self.assertEqual(myos.name, 'os')
        self.assertEqual(myos.qname(), 'os')
        self.assertEqual(myos.pytype(), '%s.module' % BUILTINS)

    def test_from_self_resolve(self):
        pb = next(MODULE.igetattr('pb'))
        self.assertTrue(isinstance(pb, nodes.Class), pb)
        self.assertEqual(pb.root().name, 'logilab.common.shellutils')
        self.assertEqual(pb.qname(), 'logilab.common.shellutils.ProgressBar')
        if pb.newstyle:
            self.assertEqual(pb.pytype(), '%s.type' % BUILTINS)
        else:
            self.assertEqual(pb.pytype(), '%s.classobj' % BUILTINS)
        abspath = next(MODULE2.igetattr('abspath'))
        self.assertTrue(isinstance(abspath, nodes.Function), abspath)
        self.assertEqual(abspath.root().name, 'os.path')
        self.assertEqual(abspath.qname(), 'os.path.abspath')
        self.assertEqual(abspath.pytype(), '%s.function' % BUILTINS)

    def test_real_name(self):
        from_ = MODULE['pb']
        self.assertEqual(from_.real_name('pb'), 'ProgressBar')
        imp_ = MODULE['os']
        self.assertEqual(imp_.real_name('os'), 'os')
        self.assertRaises(NotFoundError, imp_.real_name, 'os.path')
        imp_ = MODULE['pb']
        self.assertEqual(imp_.real_name('pb'), 'ProgressBar')
        self.assertRaises(NotFoundError, imp_.real_name, 'ProgressBar')
        imp_ = MODULE2['YO']
        self.assertEqual(imp_.real_name('YO'), 'YO')
        self.assertRaises(NotFoundError, imp_.real_name, 'data')

    def test_as_string(self):
        ast = MODULE['modutils']
        self.assertEqual(ast.as_string(), "from astroid import modutils")
        ast = MODULE['pb']
        self.assertEqual(ast.as_string(), "from logilab.common.shellutils import ProgressBar as pb")
        ast = MODULE['os']
        self.assertEqual(ast.as_string(), "import os.path")
        code = """from . import here
from .. import door
from .store import bread
from ..cave import wine\n\n"""
        ast = abuilder.string_build(code)
        self.assertMultiLineEqual(ast.as_string(), code)

    def test_bad_import_inference(self):
        # Explication of bug
        '''When we import PickleError from nonexistent, a call to the infer
        method of this From node will be made by unpack_infer.
        inference.infer_from will try to import this module, which will fail and
        raise a InferenceException (by mixins.do_import_module). The infer_name
        will catch this exception and yield and YES instead.
        '''

        code = '''try:
    from pickle import PickleError
except ImportError:
    from nonexistent import PickleError

try:
    pass
except PickleError:
    pass
        '''

        astroid = abuilder.string_build(code)
        from_node = astroid.body[1].handlers[0].body[0]
        handler_type = astroid.body[1].handlers[0].type

        excs = list(unpack_infer(handler_type))

    def test_absolute_import(self):
        astroid = abuilder.file_build(self.datapath('absimport.py'))
        ctx = InferenceContext()
        ctx.lookupname = 'message'
        # will fail if absolute import failed
        next(astroid['message'].infer(ctx))
        ctx.lookupname = 'email'
        m = next(astroid['email'].infer(ctx))
        self.assertFalse(m.file.startswith(self.datapath('email.py')))

    def test_more_absolute_import(self):
        sys.path.insert(0, self.datapath('moreabsimport'))
        try:
            astroid = abuilder.file_build(self.datapath('module1abs/__init__.py'))
            self.assertIn('sys', astroid.locals)
        finally:
            sys.path.pop(0)


class CmpNodeTC(testlib.TestCase):
    def test_as_string(self):
        ast = abuilder.string_build("a == 2").body[0]
        self.assertEqual(ast.as_string(), "a == 2")


class ConstNodeTC(testlib.TestCase):

    def _test(self, value):
        node = nodes.const_factory(value)
        self.assertIsInstance(node._proxied, nodes.Class)
        self.assertEqual(node._proxied.name, value.__class__.__name__)
        self.assertIs(node.value, value)
        self.assertTrue(node._proxied.parent)
        self.assertEqual(node._proxied.root().name, value.__class__.__module__)

    def test_none(self):
        self._test(None)

    def test_bool(self):
        self._test(True)

    def test_int(self):
        self._test(1)

    def test_float(self):
        self._test(1.0)

    def test_complex(self):
        self._test(1.0j)

    def test_str(self):
        self._test('a')

    def test_unicode(self):
        self._test('a')


class NameNodeTC(testlib.TestCase):
    def test_assign_to_True(self):
        """test that True and False assignements don't crash"""
        code = """True = False
def hello(False):
    pass
del True
    """
        if sys.version_info >= (3, 0):
            self.assertRaises(SyntaxError,#might become AstroidBuildingException
                              abuilder.string_build, code)
        else:
            ast = abuilder.string_build(code)
            ass_true = ast['True']
            self.assertIsInstance(ass_true, nodes.AssName)
            self.assertEqual(ass_true.name, "True")
            del_true = ast.body[2].targets[0]
            self.assertIsInstance(del_true, nodes.DelName)
            self.assertEqual(del_true.name, "True")


class ArgumentsNodeTC(testlib.TestCase):
    def test_linenumbering(self):
        ast = abuilder.string_build('''
def func(a,
    b): pass
x = lambda x: None
        ''')
        self.assertEqual(ast['func'].args.fromlineno, 2)
        self.assertFalse(ast['func'].args.is_statement)
        xlambda = next(ast['x'].infer())
        self.assertEqual(xlambda.args.fromlineno, 4)
        self.assertEqual(xlambda.args.tolineno, 4)
        self.assertFalse(xlambda.args.is_statement)
        if sys.version_info < (3, 0):
            self.assertEqual(ast['func'].args.tolineno, 3)
        else:
            self.skipTest('FIXME  http://bugs.python.org/issue10445 '
                          '(no line number on function args)')


class SliceNodeTC(testlib.TestCase):
    def test(self):
        for code in ('a[0]', 'a[1:3]', 'a[:-1:step]', 'a[:,newaxis]',
                     'a[newaxis,:]', 'del L[::2]', 'del A[1]', 'del Br[:]'):
            ast = abuilder.string_build(code).body[0]
            self.assertEqual(ast.as_string(), code)

    def test_slice_and_subscripts(self):
        code = """a[:1] = bord[2:]
a[:1] = bord[2:]
del bree[3:d]
bord[2:]
del av[d::f], a[df:]
a[:1] = bord[2:]
del SRC[::1,newaxis,1:]
tous[vals] = 1010
del thousand[key]
del a[::2], a[:-1:step]
del Fee.form[left:]
aout.vals = miles.of_stuff
del (ccok, (name.thing, foo.attrib.value)), Fee.form[left:]
if all[1] == bord[0:]:
    pass\n\n"""
        ast = abuilder.string_build(code)
        self.assertEqual(ast.as_string(), code)

class EllipsisNodeTC(testlib.TestCase):
    def test(self):
        ast = abuilder.string_build('a[...]').body[0]
        self.assertEqual(ast.as_string(), 'a[...]')

if __name__ == '__main__':
    testlib.unittest_main()
