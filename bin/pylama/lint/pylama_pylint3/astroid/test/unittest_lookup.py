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
"""tests for the astroid variable lookup capabilities
"""
import sys
from os.path import join, abspath, dirname

from logilab.common.testlib import TestCase, unittest_main, require_version

from astroid import builder, nodes, scoped_nodes, \
     InferenceError, NotFoundError, UnresolvableName
from astroid.scoped_nodes import builtin_lookup, Function
from astroid.bases import YES
from unittest_inference import get_name_node

builder = builder.AstroidBuilder()
DATA = join(dirname(abspath(__file__)), 'data')
MODULE = builder.file_build(join(DATA, 'module.py'), 'data.module')
MODULE2 = builder.file_build(join(DATA, 'module2.py'), 'data.module2')
NONREGR = builder.file_build(join(DATA, 'nonregr.py'), 'data.nonregr')

class LookupTC(TestCase):

    def test_limit(self):
        code = '''
l = [a
     for a,b in list]

a = 1
b = a
a = None

def func():
    c = 1
        '''
        astroid = builder.string_build(code, __name__, __file__)
        # a & b
        a = next(astroid.nodes_of_class(nodes.Name))
        self.assertEqual(a.lineno, 2)
        if sys.version_info < (3, 0):
            self.assertEqual(len(astroid.lookup('b')[1]), 2)
            self.assertEqual(len(astroid.lookup('a')[1]), 3)
            b = astroid.locals['b'][1]
        else:
            self.assertEqual(len(astroid.lookup('b')[1]), 1)
            self.assertEqual(len(astroid.lookup('a')[1]), 2)
            b = astroid.locals['b'][0]
        stmts = a.lookup('a')[1]
        self.assertEqual(len(stmts), 1)
        self.assertEqual(b.lineno, 6)
        b_infer = b.infer()
        b_value = next(b_infer)
        self.assertEqual(b_value.value, 1)
        # c
        self.assertRaises(StopIteration, b_infer.__next__)
        func = astroid.locals['func'][0]
        self.assertEqual(len(func.lookup('c')[1]), 1)

    def test_module(self):
        astroid = builder.string_build('pass', __name__, __file__)
        # built-in objects
        none = next(astroid.ilookup('None'))
        self.assertIsNone(none.value)
        obj = next(astroid.ilookup('object'))
        self.assertIsInstance(obj, nodes.Class)
        self.assertEqual(obj.name, 'object')
        self.assertRaises(InferenceError, astroid.ilookup('YOAA').__next__)

        # XXX
        self.assertEqual(len(list(NONREGR.ilookup('enumerate'))), 2)

    def test_class_ancestor_name(self):
        code = '''
class A:
    pass

class A(A):
    pass
        '''
        astroid = builder.string_build(code, __name__, __file__)
        cls1 = astroid.locals['A'][0]
        cls2 = astroid.locals['A'][1]
        name = next(cls2.nodes_of_class(nodes.Name))
        self.assertEqual(next(name.infer()), cls1)

    ### backport those test to inline code
    def test_method(self):
        method = MODULE['YOUPI']['method']
        my_dict = next(method.ilookup('MY_DICT'))
        self.assertTrue(isinstance(my_dict, nodes.Dict), my_dict)
        none = next(method.ilookup('None'))
        self.assertIsNone(none.value)
        self.assertRaises(InferenceError, method.ilookup('YOAA').__next__)


    def test_function_argument_with_default(self):
        make_class = MODULE2['make_class']
        base = next(make_class.ilookup('base'))
        self.assertTrue(isinstance(base, nodes.Class), base.__class__)
        self.assertEqual(base.name, 'YO')
        self.assertEqual(base.root().name, 'data.module')


    def test_class(self):
        klass = MODULE['YOUPI']
        my_dict = next(klass.ilookup('MY_DICT'))
        self.assertIsInstance(my_dict, nodes.Dict)
        none = next(klass.ilookup('None'))
        self.assertIsNone(none.value)
        obj = next(klass.ilookup('object'))
        self.assertIsInstance(obj, nodes.Class)
        self.assertEqual(obj.name, 'object')
        self.assertRaises(InferenceError, klass.ilookup('YOAA').__next__)


    def test_inner_classes(self):
        ddd = list(NONREGR['Ccc'].ilookup('Ddd'))
        self.assertEqual(ddd[0].name, 'Ddd')


    def test_loopvar_hiding(self):
        astroid = builder.string_build("""
x = 10
for x in range(5):
    print (x)

if x > 0:
    print ('#' * x)
        """, __name__, __file__)
        xnames = [n for n in astroid.nodes_of_class(nodes.Name) if n.name == 'x']
        # inside the loop, only one possible assignment
        self.assertEqual(len(xnames[0].lookup('x')[1]), 1)
        # outside the loop, two possible assignments
        self.assertEqual(len(xnames[1].lookup('x')[1]), 2)
        self.assertEqual(len(xnames[2].lookup('x')[1]), 2)

    def test_list_comps(self):
        astroid = builder.string_build("""
print ([ i for i in range(10) ])
print ([ i for i in range(10) ])
print ( list( i for i in range(10) ) )
        """, __name__, __file__)
        xnames = [n for n in astroid.nodes_of_class(nodes.Name) if n.name == 'i']
        self.assertEqual(len(xnames[0].lookup('i')[1]), 1)
        self.assertEqual(xnames[0].lookup('i')[1][0].lineno, 2)
        self.assertEqual(len(xnames[1].lookup('i')[1]), 1)
        self.assertEqual(xnames[1].lookup('i')[1][0].lineno, 3)
        self.assertEqual(len(xnames[2].lookup('i')[1]), 1)
        self.assertEqual(xnames[2].lookup('i')[1][0].lineno, 4)

    def test_list_comp_target(self):
        """test the list comprehension target"""
        astroid = builder.string_build("""
ten = [ var for var in range(10) ]
var
        """)
        var = astroid.body[1].value
        if sys.version_info < (3, 0):
            self.assertEqual(var.infered(), [YES])
        else:
            self.assertRaises(UnresolvableName, var.infered)

    @require_version('2.7')
    def test_dict_comps(self):
        astroid = builder.string_build("""
print ({ i: j for i in range(10) for j in range(10) })
print ({ i: j for i in range(10) for j in range(10) })
        """, __name__, __file__)
        xnames = [n for n in astroid.nodes_of_class(nodes.Name) if n.name == 'i']
        self.assertEqual(len(xnames[0].lookup('i')[1]), 1)
        self.assertEqual(xnames[0].lookup('i')[1][0].lineno, 2)
        self.assertEqual(len(xnames[1].lookup('i')[1]), 1)
        self.assertEqual(xnames[1].lookup('i')[1][0].lineno, 3)

        xnames = [n for n in astroid.nodes_of_class(nodes.Name) if n.name == 'j']
        self.assertEqual(len(xnames[0].lookup('i')[1]), 1)
        self.assertEqual(xnames[0].lookup('i')[1][0].lineno, 2)
        self.assertEqual(len(xnames[1].lookup('i')[1]), 1)
        self.assertEqual(xnames[1].lookup('i')[1][0].lineno, 3)

    @require_version('2.7')
    def test_set_comps(self):
        astroid = builder.string_build("""
print ({ i for i in range(10) })
print ({ i for i in range(10) })
        """, __name__, __file__)
        xnames = [n for n in astroid.nodes_of_class(nodes.Name) if n.name == 'i']
        self.assertEqual(len(xnames[0].lookup('i')[1]), 1)
        self.assertEqual(xnames[0].lookup('i')[1][0].lineno, 2)
        self.assertEqual(len(xnames[1].lookup('i')[1]), 1)
        self.assertEqual(xnames[1].lookup('i')[1][0].lineno, 3)

    @require_version('2.7')
    def test_set_comp_closure(self):
        astroid = builder.string_build("""
ten = { var for var in range(10) }
var
        """)
        var = astroid.body[1].value
        self.assertRaises(UnresolvableName, var.infered)

    def test_generator_attributes(self):
        tree = builder.string_build("""
def count():
    "test"
    yield 0

iterer = count()
num = iterer.next()
        """)
        next = tree.body[2].value.func # Getattr
        gener = next.expr.infered()[0] # Generator
        if sys.version_info < (3, 0):
            self.assertIsInstance(gener.getattr('next')[0], Function)
        else:
            self.assertIsInstance(gener.getattr('__next__')[0], Function)
        self.assertIsInstance(gener.getattr('send')[0], Function)
        self.assertIsInstance(gener.getattr('throw')[0], Function)
        self.assertIsInstance(gener.getattr('close')[0], Function)

    def test_explicit___name__(self):
        code = '''
class Pouet:
    __name__ = "pouet"
p1 = Pouet()

class PouetPouet(Pouet): pass
p2 = Pouet()

class NoName: pass
p3 = NoName()
'''
        astroid = builder.string_build(code, __name__, __file__)
        p1 = next(astroid['p1'].infer())
        self.assertTrue(p1.getattr('__name__'))
        p2 = next(astroid['p2'].infer())
        self.assertTrue(p2.getattr('__name__'))
        self.assertTrue(astroid['NoName'].getattr('__name__'))
        p3 = next(astroid['p3'].infer())
        self.assertRaises(NotFoundError, p3.getattr, '__name__')


    def test_function_module_special(self):
        astroid = builder.string_build('''
def initialize(linter):
    """initialize linter with checkers in this package """
    package_load(linter, __path__[0])
        ''', 'data.__init__', 'data/__init__.py')
        path = [n for n in astroid.nodes_of_class(nodes.Name) if n.name == '__path__'][0]
        self.assertEqual(len(path.lookup('__path__')[1]), 1)


    def test_builtin_lookup(self):
        self.assertEqual(builtin_lookup('__dict__')[1], ())
        intstmts = builtin_lookup('int')[1]
        self.assertEqual(len(intstmts), 1)
        self.assertIsInstance(intstmts[0], nodes.Class)
        self.assertEqual(intstmts[0].name, 'int')
        self.assertIs(intstmts[0], nodes.const_factory(1)._proxied)


    def test_decorator_arguments_lookup(self):
        code = '''
def decorator(value):
    def wrapper(function):
        return function
    return wrapper

class foo:
    member = 10

    @decorator(member) #This will cause pylint to complain
    def test(self):
        pass
        '''
        astroid = builder.string_build(code, __name__, __file__)
        member = get_name_node(astroid['foo'], 'member')
        it = member.infer()
        obj = next(it)
        self.assertIsInstance(obj, nodes.Const)
        self.assertEqual(obj.value, 10)
        self.assertRaises(StopIteration, it.__next__)


    def test_inner_decorator_member_lookup(self):
        code = '''
class FileA:
    def decorator(bla):
        return bla

    @decorator
    def funcA():
        return 4
        '''
        astroid = builder.string_build(code, __name__, __file__)
        decname = get_name_node(astroid['FileA'], 'decorator')
        it = decname.infer()
        obj = next(it)
        self.assertIsInstance(obj, nodes.Function)
        self.assertRaises(StopIteration, it.__next__)


    def test_static_method_lookup(self):
        code = '''
class FileA:
    @staticmethod
    def funcA():
        return 4


class Test:
    FileA = [1,2,3]

    def __init__(self):
        print (FileA.funcA())
        '''
        astroid = builder.string_build(code, __name__, __file__)
        it = astroid['Test']['__init__'].ilookup('FileA')
        obj = next(it)
        self.assertIsInstance(obj, nodes.Class)
        self.assertRaises(StopIteration, it.__next__)


    def test_global_delete(self):
        code = '''
def run2():
    f = Frobble()

class Frobble:
    pass
Frobble.mumble = True

del Frobble

def run1():
    f = Frobble()
'''
        astroid = builder.string_build(code, __name__, __file__)
        stmts = astroid['run2'].lookup('Frobbel')[1]
        self.assertEqual(len(stmts), 0)
        stmts = astroid['run1'].lookup('Frobbel')[1]
        self.assertEqual(len(stmts), 0)

if __name__ == '__main__':
    unittest_main()
