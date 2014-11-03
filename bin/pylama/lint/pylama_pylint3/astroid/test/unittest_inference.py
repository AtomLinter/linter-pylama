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
"""tests for the astroid inference capabilities
"""
from os.path import join, dirname, abspath
import sys
from io import StringIO
from textwrap import dedent

from logilab.common.testlib import TestCase, unittest_main, require_version

from astroid import InferenceError, builder, nodes
from astroid.inference import infer_end as inference_infer_end
from astroid.bases import YES, Instance, BoundMethod, UnboundMethod,\
                                path_wrapper, BUILTINS

def get_name_node(start_from, name, index=0):
    return [n for n in start_from.nodes_of_class(nodes.Name) if n.name == name][index]

def get_node_of_class(start_from, klass):
    return next(start_from.nodes_of_class(klass))

builder = builder.AstroidBuilder()

class InferenceUtilsTC(TestCase):

    def test_path_wrapper(self):
        def infer_default(self, *args):
            raise InferenceError
        infer_default = path_wrapper(infer_default)
        infer_end = path_wrapper(inference_infer_end)
        self.assertRaises(InferenceError,
                              infer_default(1).__next__)
        self.assertEqual(next(infer_end(1)), 1)

if sys.version_info < (3, 0):
    EXC_MODULE = 'exceptions'
else:
    EXC_MODULE = BUILTINS

if sys.version_info < (3, 4):
    SITE = 'site'
else:
    SITE = '_sitebuiltins'

class InferenceTC(TestCase):

    CODE = '''

class C(object):
    "new style"
    attr = 4

    def meth1(self, arg1, optarg=0):
        var = object()
        print ("yo", arg1, optarg)
        self.iattr = "hop"
        return var

    def meth2(self):
        self.meth1(*self.meth3)

    def meth3(self, d=attr):
        b = self.attr
        c = self.iattr
        return b, c

ex = Exception("msg")
v = C().meth1(1)
m_unbound = C.meth1
m_bound = C().meth1
a, b, c = ex, 1, "bonjour"
[d, e, f] = [ex, 1.0, ("bonjour", v)]
g, h = f
i, (j, k) = "glup", f

a, b= b, a # Gasp !
'''

    astroid = builder.string_build(CODE, __name__, __file__)

    def test_module_inference(self):
        infered = self.astroid.infer()
        obj = next(infered)
        self.assertEqual(obj.name, __name__)
        self.assertEqual(obj.root().name, __name__)
        self.assertRaises(StopIteration, infered.__next__)

    def test_class_inference(self):
        infered = self.astroid['C'].infer()
        obj = next(infered)
        self.assertEqual(obj.name, 'C')
        self.assertEqual(obj.root().name, __name__)
        self.assertRaises(StopIteration, infered.__next__)

    def test_function_inference(self):
        infered = self.astroid['C']['meth1'].infer()
        obj = next(infered)
        self.assertEqual(obj.name, 'meth1')
        self.assertEqual(obj.root().name, __name__)
        self.assertRaises(StopIteration, infered.__next__)

    def test_builtin_name_inference(self):
        infered = self.astroid['C']['meth1']['var'].infer()
        var = next(infered)
        self.assertEqual(var.name, 'object')
        self.assertEqual(var.root().name, BUILTINS)
        self.assertRaises(StopIteration, infered.__next__)

    def test_tupleassign_name_inference(self):
        infered = self.astroid['a'].infer()
        exc = next(infered)
        self.assertIsInstance(exc, Instance)
        self.assertEqual(exc.name, 'Exception')
        self.assertEqual(exc.root().name, EXC_MODULE)
        self.assertRaises(StopIteration, infered.__next__)
        infered = self.astroid['b'].infer()
        const = next(infered)
        self.assertIsInstance(const, nodes.Const)
        self.assertEqual(const.value, 1)
        self.assertRaises(StopIteration, infered.__next__)
        infered = self.astroid['c'].infer()
        const = next(infered)
        self.assertIsInstance(const, nodes.Const)
        self.assertEqual(const.value, "bonjour")
        self.assertRaises(StopIteration, infered.__next__)

    def test_listassign_name_inference(self):
        infered = self.astroid['d'].infer()
        exc = next(infered)
        self.assertIsInstance(exc, Instance)
        self.assertEqual(exc.name, 'Exception')
        self.assertEqual(exc.root().name, EXC_MODULE)
        self.assertRaises(StopIteration, infered.__next__)
        infered = self.astroid['e'].infer()
        const = next(infered)
        self.assertIsInstance(const, nodes.Const)
        self.assertEqual(const.value, 1.0)
        self.assertRaises(StopIteration, infered.__next__)
        infered = self.astroid['f'].infer()
        const = next(infered)
        self.assertIsInstance(const, nodes.Tuple)
        self.assertRaises(StopIteration, infered.__next__)

    def test_advanced_tupleassign_name_inference1(self):
        infered = self.astroid['g'].infer()
        const = next(infered)
        self.assertIsInstance(const, nodes.Const)
        self.assertEqual(const.value, "bonjour")
        self.assertRaises(StopIteration, infered.__next__)
        infered = self.astroid['h'].infer()
        var = next(infered)
        self.assertEqual(var.name, 'object')
        self.assertEqual(var.root().name, BUILTINS)
        self.assertRaises(StopIteration, infered.__next__)

    def test_advanced_tupleassign_name_inference2(self):
        infered = self.astroid['i'].infer()
        const = next(infered)
        self.assertIsInstance(const, nodes.Const)
        self.assertEqual(const.value, "glup")
        self.assertRaises(StopIteration, infered.__next__)
        infered = self.astroid['j'].infer()
        const = next(infered)
        self.assertIsInstance(const, nodes.Const)
        self.assertEqual(const.value, "bonjour")
        self.assertRaises(StopIteration, infered.__next__)
        infered = self.astroid['k'].infer()
        var = next(infered)
        self.assertEqual(var.name, 'object')
        self.assertEqual(var.root().name, BUILTINS)
        self.assertRaises(StopIteration, infered.__next__)

    def test_swap_assign_inference(self):
        infered = self.astroid.locals['a'][1].infer()
        const = next(infered)
        self.assertIsInstance(const, nodes.Const)
        self.assertEqual(const.value, 1)
        self.assertRaises(StopIteration, infered.__next__)
        infered = self.astroid.locals['b'][1].infer()
        exc = next(infered)
        self.assertIsInstance(exc, Instance)
        self.assertEqual(exc.name, 'Exception')
        self.assertEqual(exc.root().name, EXC_MODULE)
        self.assertRaises(StopIteration, infered.__next__)

    def test_getattr_inference1(self):
        infered = self.astroid['ex'].infer()
        exc = next(infered)
        self.assertIsInstance(exc, Instance)
        self.assertEqual(exc.name, 'Exception')
        self.assertEqual(exc.root().name, EXC_MODULE)
        self.assertRaises(StopIteration, infered.__next__)

    def test_getattr_inference2(self):
        infered = get_node_of_class(self.astroid['C']['meth2'], nodes.Getattr).infer()
        meth1 = next(infered)
        self.assertEqual(meth1.name, 'meth1')
        self.assertEqual(meth1.root().name, __name__)
        self.assertRaises(StopIteration, infered.__next__)

    def test_getattr_inference3(self):
        infered = self.astroid['C']['meth3']['b'].infer()
        const = next(infered)
        self.assertIsInstance(const, nodes.Const)
        self.assertEqual(const.value, 4)
        self.assertRaises(StopIteration, infered.__next__)

    def test_getattr_inference4(self):
        infered = self.astroid['C']['meth3']['c'].infer()
        const = next(infered)
        self.assertIsInstance(const, nodes.Const)
        self.assertEqual(const.value, "hop")
        self.assertRaises(StopIteration, infered.__next__)

    def test_callfunc_inference(self):
        infered = self.astroid['v'].infer()
        meth1 = next(infered)
        self.assertIsInstance(meth1, Instance)
        self.assertEqual(meth1.name, 'object')
        self.assertEqual(meth1.root().name, BUILTINS)
        self.assertRaises(StopIteration, infered.__next__)

    def test_unbound_method_inference(self):
        infered = self.astroid['m_unbound'].infer()
        meth1 = next(infered)
        self.assertIsInstance(meth1, UnboundMethod)
        self.assertEqual(meth1.name, 'meth1')
        self.assertEqual(meth1.parent.frame().name, 'C')
        self.assertRaises(StopIteration, infered.__next__)

    def test_bound_method_inference(self):
        infered = self.astroid['m_bound'].infer()
        meth1 = next(infered)
        self.assertIsInstance(meth1, BoundMethod)
        self.assertEqual(meth1.name, 'meth1')
        self.assertEqual(meth1.parent.frame().name, 'C')
        self.assertRaises(StopIteration, infered.__next__)

    def test_args_default_inference1(self):
        optarg = get_name_node(self.astroid['C']['meth1'], 'optarg')
        infered = optarg.infer()
        obj1 = next(infered)
        self.assertIsInstance(obj1, nodes.Const)
        self.assertEqual(obj1.value, 0)
        obj1 = next(infered)
        self.assertIs(obj1, YES, obj1)
        self.assertRaises(StopIteration, infered.__next__)

    def test_args_default_inference2(self):
        infered = self.astroid['C']['meth3'].ilookup('d')
        obj1 = next(infered)
        self.assertIsInstance(obj1, nodes.Const)
        self.assertEqual(obj1.value, 4)
        obj1 = next(infered)
        self.assertIs(obj1, YES, obj1)
        self.assertRaises(StopIteration, infered.__next__)

    def test_inference_restrictions(self):
        infered = get_name_node(self.astroid['C']['meth1'], 'arg1').infer()
        obj1 = next(infered)
        self.assertIs(obj1, YES, obj1)
        self.assertRaises(StopIteration, infered.__next__)

    def test_ancestors_inference(self):
        code = '''
class A:
    pass

class A(A):
    pass
        '''
        astroid = builder.string_build(code, __name__, __file__)
        a1 = astroid.locals['A'][0]
        a2 = astroid.locals['A'][1]
        a2_ancestors = list(a2.ancestors())
        self.assertEqual(len(a2_ancestors), 1)
        self.assertIs(a2_ancestors[0], a1)

    def test_ancestors_inference2(self):
        code = '''
class A:
    pass

class B(A): pass

class A(B):
    pass
        '''
        astroid = builder.string_build(code, __name__, __file__)
        a1 = astroid.locals['A'][0]
        a2 = astroid.locals['A'][1]
        a2_ancestors = list(a2.ancestors())
        self.assertEqual(len(a2_ancestors), 2)
        self.assertIs(a2_ancestors[0], astroid.locals['B'][0])
        self.assertIs(a2_ancestors[1], a1)


    def test_f_arg_f(self):
        code = '''
def f(f=1):
    return f

a = f()
        '''
        astroid = builder.string_build(code, __name__, __file__)
        a = astroid['a']
        a_infered = a.infered()
        self.assertEqual(a_infered[0].value, 1)
        self.assertEqual(len(a_infered), 1)

    def test_exc_ancestors(self):
        code = '''
def f():
    raise NotImplementedError
        '''
        astroid = builder.string_build(code, __name__, __file__)
        error = next(astroid.nodes_of_class(nodes.Name))
        nie = error.infered()[0]
        self.assertIsInstance(nie, nodes.Class)
        nie_ancestors = [c.name for c in nie.ancestors()]
        if sys.version_info < (3, 0):
            self.assertEqual(nie_ancestors, ['RuntimeError', 'StandardError', 'Exception', 'BaseException', 'object'])
        else:
            self.assertEqual(nie_ancestors, ['RuntimeError', 'Exception', 'BaseException', 'object'])

    def test_except_inference(self):
        code = '''
try:
    print (hop)
except NameError, ex:
    ex1 = ex
except Exception, ex:
    ex2 = ex
    raise
        '''
        if sys.version_info >= (3, 0):
            code = code.replace(', ex:', ' as ex:')
        astroid = builder.string_build(code, __name__, __file__)
        ex1 = astroid['ex1']
        ex1_infer = ex1.infer()
        ex1 = next(ex1_infer)
        self.assertIsInstance(ex1, Instance)
        self.assertEqual(ex1.name, 'NameError')
        self.assertRaises(StopIteration, ex1_infer.__next__)
        ex2 = astroid['ex2']
        ex2_infer = ex2.infer()
        ex2 = next(ex2_infer)
        self.assertIsInstance(ex2, Instance)
        self.assertEqual(ex2.name, 'Exception')
        self.assertRaises(StopIteration, ex2_infer.__next__)

    def test_del1(self):
        code = '''
del undefined_attr
        '''
        delete = builder.string_build(code, __name__, __file__).body[0]
        self.assertRaises(InferenceError, delete.infer)

    def test_del2(self):
        code = '''
a = 1
b = a
del a
c = a
a = 2
d = a
        '''
        astroid = builder.string_build(code, __name__, __file__)
        n = astroid['b']
        n_infer = n.infer()
        infered = next(n_infer)
        self.assertIsInstance(infered, nodes.Const)
        self.assertEqual(infered.value, 1)
        self.assertRaises(StopIteration, n_infer.__next__)
        n = astroid['c']
        n_infer = n.infer()
        self.assertRaises(InferenceError, n_infer.__next__)
        n = astroid['d']
        n_infer = n.infer()
        infered = next(n_infer)
        self.assertIsInstance(infered, nodes.Const)
        self.assertEqual(infered.value, 2)
        self.assertRaises(StopIteration, n_infer.__next__)

    def test_builtin_types(self):
        code = '''
l = [1]
t = (2,)
d = {}
s = ''
s2 = '_'
        '''
        astroid = builder.string_build(code, __name__, __file__)
        n = astroid['l']
        infered = next(n.infer())
        self.assertIsInstance(infered, nodes.List)
        self.assertIsInstance(infered, Instance)
        self.assertEqual(infered.getitem(0).value, 1)
        self.assertIsInstance(infered._proxied, nodes.Class)
        self.assertEqual(infered._proxied.name, 'list')
        self.assertIn('append', infered._proxied.locals)
        n = astroid['t']
        infered = next(n.infer())
        self.assertIsInstance(infered, nodes.Tuple)
        self.assertIsInstance(infered, Instance)
        self.assertEqual(infered.getitem(0).value, 2)
        self.assertIsInstance(infered._proxied, nodes.Class)
        self.assertEqual(infered._proxied.name, 'tuple')
        n = astroid['d']
        infered = next(n.infer())
        self.assertIsInstance(infered, nodes.Dict)
        self.assertIsInstance(infered, Instance)
        self.assertIsInstance(infered._proxied, nodes.Class)
        self.assertEqual(infered._proxied.name, 'dict')
        self.assertIn('get', infered._proxied.locals)
        n = astroid['s']
        infered = next(n.infer())
        self.assertIsInstance(infered, nodes.Const)
        self.assertIsInstance(infered, Instance)
        self.assertEqual(infered.name, 'str')
        self.assertIn('lower', infered._proxied.locals)
        n = astroid['s2']
        infered = next(n.infer())
        self.assertEqual(infered.getitem(0).value, '_')

    @require_version('2.7')
    def test_builtin_types_py27(self):
        code = 's = {1}'
        astroid = builder.string_build(code, __name__, __file__)
        n = astroid['s']
        infered = next(n.infer())
        self.assertIsInstance(infered, nodes.Set)
        self.assertIsInstance(infered, Instance)
        self.assertEqual(infered.name, 'set')
        self.assertIn('remove', infered._proxied.locals)

    def test_unicode_type(self):
        if sys.version_info >= (3, 0):
            self.skipTest('unicode removed on py >= 3.0')
        code = '''u = u""'''
        astroid = builder.string_build(code, __name__, __file__)
        n = astroid['u']
        infered = next(n.infer())
        self.assertIsInstance(infered, nodes.Const)
        self.assertIsInstance(infered, Instance)
        self.assertEqual(infered.name, 'unicode')
        self.assertIn('lower', infered._proxied.locals)

    def test_descriptor_are_callable(self):
        code = '''
class A:
    statm = staticmethod(open)
    clsm = classmethod('whatever')
        '''
        astroid = builder.string_build(code, __name__, __file__)
        statm = next(astroid['A'].igetattr('statm'))
        self.assertTrue(statm.callable())
        clsm = next(astroid['A'].igetattr('clsm'))
        self.assertTrue(clsm.callable())

    def test_bt_ancestor_crash(self):
        code = '''
class Warning(Warning):
    pass
        '''
        astroid = builder.string_build(code, __name__, __file__)
        w = astroid['Warning']
        ancestors = w.ancestors()
        ancestor = next(ancestors)
        self.assertEqual(ancestor.name, 'Warning')
        self.assertEqual(ancestor.root().name, EXC_MODULE)
        ancestor = next(ancestors)
        self.assertEqual(ancestor.name, 'Exception')
        self.assertEqual(ancestor.root().name, EXC_MODULE)
        ancestor = next(ancestors)
        self.assertEqual(ancestor.name, 'BaseException')
        self.assertEqual(ancestor.root().name, EXC_MODULE)
        ancestor = next(ancestors)
        self.assertEqual(ancestor.name, 'object')
        self.assertEqual(ancestor.root().name, BUILTINS)
        self.assertRaises(StopIteration, ancestors.__next__)

    def test_qqch(self):
        code = '''
from astroid.modutils import load_module_from_name
xxx = load_module_from_name('__pkginfo__')
        '''
        astroid = builder.string_build(code, __name__, __file__)
        xxx = astroid['xxx']
        self.assertSetEqual(set(n.__class__ for n in xxx.infered()),
                            set([nodes.Const, YES.__class__]))

    def test_method_argument(self):
        code = '''
class ErudiEntitySchema:
    """a entity has a type, a set of subject and or object relations"""
    def __init__(self, e_type, **kwargs):
        kwargs['e_type'] = e_type.capitalize().encode()

    def meth(self, e_type, *args, **kwargs):
        kwargs['e_type'] = e_type.capitalize().encode()
        print(args)
        '''
        astroid = builder.string_build(code, __name__, __file__)
        arg = get_name_node(astroid['ErudiEntitySchema']['__init__'], 'e_type')
        self.assertEqual([n.__class__ for n in arg.infer()],
                         [YES.__class__])
        arg = get_name_node(astroid['ErudiEntitySchema']['__init__'], 'kwargs')
        self.assertEqual([n.__class__ for n in arg.infer()],
                         [nodes.Dict])
        arg = get_name_node(astroid['ErudiEntitySchema']['meth'], 'e_type')
        self.assertEqual([n.__class__ for n in arg.infer()],
                         [YES.__class__])
        arg = get_name_node(astroid['ErudiEntitySchema']['meth'], 'args')
        self.assertEqual([n.__class__ for n in arg.infer()],
                         [nodes.Tuple])
        arg = get_name_node(astroid['ErudiEntitySchema']['meth'], 'kwargs')
        self.assertEqual([n.__class__ for n in arg.infer()],
                         [nodes.Dict])


    def test_tuple_then_list(self):
        code = '''
def test_view(rql, vid, tags=()):
    tags = list(tags)
    tags.append(vid)
        '''
        astroid = builder.string_build(code, __name__, __file__)
        name = get_name_node(astroid['test_view'], 'tags', -1)
        it = name.infer()
        tags = next(it)
        self.assertEqual(tags.__class__, Instance)
        self.assertEqual(tags._proxied.name, 'list')
        self.assertRaises(StopIteration, it.__next__)



    def test_mulassign_inference(self):
        code = '''

def first_word(line):
    """Return the first word of a line"""

    return line.split()[0]

def last_word(line):
    """Return last word of a line"""

    return line.split()[-1]

def process_line(word_pos):
    """Silly function: returns (ok, callable) based on argument.

       For test purpose only.
    """

    if word_pos > 0:
        return (True, first_word)
    elif word_pos < 0:
        return  (True, last_word)
    else:
        return (False, None)

if __name__ == '__main__':

    line_number = 0
    for a_line in file('test_callable.py'):
        tupletest  = process_line(line_number)
        (ok, fct)  = process_line(line_number)
        if ok:
            fct(a_line)
'''
        astroid = builder.string_build(code, __name__, __file__)
        self.assertEqual(len(list(astroid['process_line'].infer_call_result(
                                                                None))), 3)
        self.assertEqual(len(list(astroid['tupletest'].infer())), 3)
        values = ['Function(first_word)', 'Function(last_word)', 'Const(NoneType)']
        self.assertEqual([str(infered)
                          for infered in astroid['fct'].infer()], values)

    def test_float_complex_ambiguity(self):
        code = '''
def no_conjugate_member(magic_flag):
    """should not raise E1101 on something.conjugate"""
    if magic_flag:
        something = 1.0
    else:
        something = 1.0j
    if isinstance(something, float):
        return something
    return something.conjugate()
        '''
        astroid = builder.string_build(code, __name__, __file__)
        self.assertEqual([i.value for i in
            astroid['no_conjugate_member'].ilookup('something')], [1.0, 1.0j])
        self.assertEqual([i.value for i in
                get_name_node(astroid, 'something', -1).infer()], [1.0, 1.0j])

    def test_lookup_cond_branches(self):
        code = '''
def no_conjugate_member(magic_flag):
    """should not raise E1101 on something.conjugate"""
    something = 1.0
    if magic_flag:
        something = 1.0j
    return something.conjugate()
        '''
        astroid = builder.string_build(code, __name__, __file__)
        self.assertEqual([i.value for i in
                get_name_node(astroid, 'something', -1).infer()], [1.0, 1.0j])


    def test_simple_subscript(self):
        code = '''
a = [1, 2, 3][0]
b = (1, 2, 3)[1]
c = (1, 2, 3)[-1]
d = a + b + c
print (d)
e = {'key': 'value'}
f = e['key']
print (f)
        '''
        astroid = builder.string_build(code, __name__, __file__)
        self.assertEqual([i.value for i in
                                get_name_node(astroid, 'a', -1).infer()], [1])
        self.assertEqual([i.value for i in
                                get_name_node(astroid, 'b', -1).infer()], [2])
        self.assertEqual([i.value for i in
                                get_name_node(astroid, 'c', -1).infer()], [3])
        self.assertEqual([i.value for i in
                                get_name_node(astroid, 'd', -1).infer()], [6])
        self.assertEqual([i.value for i in
                          get_name_node(astroid, 'f', -1).infer()], ['value'])

    #def test_simple_tuple(self):
        #"""test case for a simple tuple value"""
        ## XXX tuple inference is not implemented ...
        #code = """
#a = (1,)
#b = (22,)
#some = a + b
#"""
        #astroid = builder.string_build(code, __name__, __file__)
        #self.assertEqual(astroid['some'].infer.next().as_string(), "(1, 22)")

    def test_simple_for(self):
        code = '''
for a in [1, 2, 3]:
    print (a)
for b,c in [(1,2), (3,4)]:
    print (b)
    print (c)

print ([(d,e) for e,d in ([1,2], [3,4])])
        '''
        astroid = builder.string_build(code, __name__, __file__)
        self.assertEqual([i.value for i in
                            get_name_node(astroid, 'a', -1).infer()], [1, 2, 3])
        self.assertEqual([i.value for i in
                            get_name_node(astroid, 'b', -1).infer()], [1, 3])
        self.assertEqual([i.value for i in
                            get_name_node(astroid, 'c', -1).infer()], [2, 4])
        self.assertEqual([i.value for i in
                            get_name_node(astroid, 'd', -1).infer()], [2, 4])
        self.assertEqual([i.value for i in
                            get_name_node(astroid, 'e', -1).infer()], [1, 3])


    def test_simple_for_genexpr(self):
        code = '''
print ((d,e) for e,d in ([1,2], [3,4]))
        '''
        astroid = builder.string_build(code, __name__, __file__)
        self.assertEqual([i.value for i in
                            get_name_node(astroid, 'd', -1).infer()], [2, 4])
        self.assertEqual([i.value for i in
                            get_name_node(astroid, 'e', -1).infer()], [1, 3])


    def test_builtin_help(self):
        code = '''
help()
        '''
        # XXX failing since __builtin__.help assignment has
        #     been moved into a function...
        astroid = builder.string_build(code, __name__, __file__)
        node = get_name_node(astroid, 'help', -1)
        infered = list(node.infer())
        self.assertEqual(len(infered), 1, infered)
        self.assertIsInstance(infered[0], Instance)
        self.assertEqual(str(infered[0]),
                             'Instance of %s._Helper' % SITE)

    def test_builtin_open(self):
        code = '''
open("toto.txt")
        '''
        astroid = builder.string_build(code, __name__, __file__)
        node = get_name_node(astroid, 'open', -1)
        infered = list(node.infer())
        self.assertEqual(len(infered), 1)
        if hasattr(sys, 'pypy_version_info'):
            self.assertIsInstance(infered[0], nodes.Class)
            self.assertEqual(infered[0].name, 'file')
        else:
            self.assertIsInstance(infered[0], nodes.Function)
            self.assertEqual(infered[0].name, 'open')

    def test_callfunc_context_func(self):
        code = '''
def mirror(arg=None):
    return arg

un = mirror(1)
        '''
        astroid = builder.string_build(code, __name__, __file__)
        infered = list(astroid.igetattr('un'))
        self.assertEqual(len(infered), 1)
        self.assertIsInstance(infered[0], nodes.Const)
        self.assertEqual(infered[0].value, 1)

    def test_callfunc_context_lambda(self):
        code = '''
mirror = lambda x=None: x

un = mirror(1)
        '''
        astroid = builder.string_build(code, __name__, __file__)
        infered = list(astroid.igetattr('mirror'))
        self.assertEqual(len(infered), 1)
        self.assertIsInstance(infered[0], nodes.Lambda)
        infered = list(astroid.igetattr('un'))
        self.assertEqual(len(infered), 1)
        self.assertIsInstance(infered[0], nodes.Const)
        self.assertEqual(infered[0].value, 1)

    def test_factory_method(self):
        code = '''
class Super(object):
      @classmethod
      def instance(cls):
              return cls()

class Sub(Super):
      def method(self):
              print ('method called')

sub = Sub.instance()
        '''
        astroid = builder.string_build(code, __name__, __file__)
        infered = list(astroid.igetattr('sub'))
        self.assertEqual(len(infered), 1)
        self.assertIsInstance(infered[0], Instance)
        self.assertEqual(infered[0]._proxied.name, 'Sub')


    def test_import_as(self):
        code = '''
import os.path as osp
print (osp.dirname(__file__))

from os.path import exists as e
assert e(__file__)

from new import code as make_code
print (make_code)
        '''
        astroid = builder.string_build(code, __name__, __file__)
        infered = list(astroid.igetattr('osp'))
        self.assertEqual(len(infered), 1)
        self.assertIsInstance(infered[0], nodes.Module)
        self.assertEqual(infered[0].name, 'os.path')
        infered = list(astroid.igetattr('e'))
        self.assertEqual(len(infered), 1)
        self.assertIsInstance(infered[0], nodes.Function)
        self.assertEqual(infered[0].name, 'exists')
        if sys.version_info >= (3, 0):
            self.skipTest('<new> module has been removed')
        infered = list(astroid.igetattr('make_code'))
        self.assertEqual(len(infered), 1)
        self.assertIsInstance(infered[0], Instance)
        self.assertEqual(str(infered[0]),
                             'Instance of %s.type' % BUILTINS)

    def _test_const_infered(self, node, value):
        infered = list(node.infer())
        self.assertEqual(len(infered), 1)
        self.assertIsInstance(infered[0], nodes.Const)
        self.assertEqual(infered[0].value, value)

    def test_unary_not(self):
        for code in ('a = not (1,); b = not ()',
                     'a = not {1:2}; b = not {}'):
            astroid = builder.string_build(code, __name__, __file__)
            self._test_const_infered(astroid['a'], False)
            self._test_const_infered(astroid['b'], True)

    def test_binary_op_int_add(self):
        astroid = builder.string_build('a = 1 + 2', __name__, __file__)
        self._test_const_infered(astroid['a'], 3)

    def test_binary_op_int_sub(self):
        astroid = builder.string_build('a = 1 - 2', __name__, __file__)
        self._test_const_infered(astroid['a'], -1)

    def test_binary_op_float_div(self):
        astroid = builder.string_build('a = 1 / 2.', __name__, __file__)
        self._test_const_infered(astroid['a'], 1 / 2.)

    def test_binary_op_str_mul(self):
        astroid = builder.string_build('a = "*" * 40', __name__, __file__)
        self._test_const_infered(astroid['a'], "*" * 40)

    def test_binary_op_bitand(self):
        astroid = builder.string_build('a = 23&20', __name__, __file__)
        self._test_const_infered(astroid['a'], 23&20)

    def test_binary_op_bitor(self):
        astroid = builder.string_build('a = 23|8', __name__, __file__)
        self._test_const_infered(astroid['a'], 23|8)

    def test_binary_op_bitxor(self):
        astroid = builder.string_build('a = 23^9', __name__, __file__)
        self._test_const_infered(astroid['a'], 23^9)

    def test_binary_op_shiftright(self):
        astroid = builder.string_build('a = 23 >>1', __name__, __file__)
        self._test_const_infered(astroid['a'], 23>>1)

    def test_binary_op_shiftleft(self):
        astroid = builder.string_build('a = 23 <<1', __name__, __file__)
        self._test_const_infered(astroid['a'], 23<<1)


    def test_binary_op_list_mul(self):
        for code in ('a = [[]] * 2', 'a = 2 * [[]]'):
            astroid = builder.string_build(code, __name__, __file__)
            infered = list(astroid['a'].infer())
            self.assertEqual(len(infered), 1)
            self.assertIsInstance(infered[0], nodes.List)
            self.assertEqual(len(infered[0].elts), 2)
            self.assertIsInstance(infered[0].elts[0], nodes.List)
            self.assertIsInstance(infered[0].elts[1], nodes.List)

    def test_binary_op_list_mul_none(self):
        'test correct handling on list multiplied by None'
        astroid = builder.string_build( 'a = [1] * None\nb = [1] * "r"')
        infered = astroid['a'].infered()
        self.assertEqual(len(infered), 1)
        self.assertEqual(infered[0], YES)
        infered = astroid['b'].infered()
        self.assertEqual(len(infered), 1)
        self.assertEqual(infered[0], YES)


    def test_binary_op_tuple_add(self):
        astroid = builder.string_build('a = (1,) + (2,)', __name__, __file__)
        infered = list(astroid['a'].infer())
        self.assertEqual(len(infered), 1)
        self.assertIsInstance(infered[0], nodes.Tuple)
        self.assertEqual(len(infered[0].elts), 2)
        self.assertEqual(infered[0].elts[0].value, 1)
        self.assertEqual(infered[0].elts[1].value, 2)

    def test_binary_op_custom_class(self):
        code = '''
class myarray:
    def __init__(self, array):
        self.array = array
    def __mul__(self, x):
        return myarray([2,4,6])
    def astype(self):
        return "ASTYPE"

def randint(maximum):
    if maximum is not None:
        return myarray([1,2,3]) * 2
    else:
        return int(5)

x = randint(1)
        '''
        astroid = builder.string_build(code, __name__, __file__)
        infered = list(astroid.igetattr('x'))
        self.assertEqual(len(infered), 2)
        value = [str(v) for v in infered]
        # The __name__ trick here makes it work when invoked directly
        # (__name__ == '__main__') and through pytest (__name__ ==
        # 'unittest_inference')
        self.assertEqual(value, ['Instance of %s.myarray' % __name__,
                                 'Instance of %s.int' % BUILTINS])

    def test_nonregr_lambda_arg(self):
        code = '''
def f(g = lambda: None):
        g().x
'''
        astroid = builder.string_build(code, __name__, __file__)
        callfuncnode = astroid['f'].body[0].value.expr
        infered = list(callfuncnode.infer())
        self.assertEqual(len(infered), 2, infered)
        infered.remove(YES)
        self.assertIsInstance(infered[0], nodes.Const)
        self.assertIsNone(infered[0].value)

    def test_nonregr_getitem_empty_tuple(self):
        code = '''
def f(x):
        a = ()[x]
        '''
        astroid = builder.string_build(code, __name__, __file__)
        infered = list(astroid['f'].ilookup('a'))
        self.assertEqual(len(infered), 1)
        self.assertEqual(infered[0], YES)

    def test_nonregr_instance_attrs(self):
        """non regression for instance_attrs infinite loop : pylint / #4"""

        code = """
class Foo(object):

    def set_42(self):
        self.attr = 42

class Bar(Foo):

    def __init__(self):
        self.attr = 41
        """
        astroid = builder.string_build(code, __name__, __file__)
        foo_class = astroid['Foo']
        bar_class = astroid['Bar']
        bar_self = astroid['Bar']['__init__']['self']
        assattr = bar_class.instance_attrs['attr'][0]
        self.assertEqual(len(foo_class.instance_attrs['attr']), 1)
        self.assertEqual(len(bar_class.instance_attrs['attr']), 1)
        self.assertEqual(bar_class.instance_attrs, {'attr': [assattr]})
        # call 'instance_attr' via 'Instance.getattr' to trigger the bug:
        instance = bar_self.infered()[0]
        _attr = instance.getattr('attr')
        self.assertEqual(len(bar_class.instance_attrs['attr']), 1)
        self.assertEqual(len(foo_class.instance_attrs['attr']), 1)
        self.assertEqual(bar_class.instance_attrs, {'attr': [assattr]})

    def test_python25_generator_exit(self):
        sys.stderr = StringIO()
        data = "b = {}[str(0)+''].a"
        astroid = builder.string_build(data, __name__, __file__)
        list(astroid['b'].infer())
        output = sys.stderr.getvalue()
        # I have no idea how to test for this in another way...
        self.assertNotIn("RuntimeError", output, "Exception exceptions.RuntimeError: 'generator ignored GeneratorExit' in <generator object> ignored")
        sys.stderr = sys.__stderr__

    def test_python25_relative_import(self):
        data = "from ...logilab.common import date; print (date)"
        # !! FIXME also this relative import would not work 'in real' (no __init__.py in test/)
        # the test works since we pretend we have a package by passing the full modname
        astroid = builder.string_build(data, 'astroid.test.unittest_inference', __file__)
        infered = next(get_name_node(astroid, 'date').infer())
        self.assertIsInstance(infered, nodes.Module)
        self.assertEqual(infered.name, 'logilab.common.date')

    def test_python25_no_relative_import(self):
        fname = join(abspath(dirname(__file__)), 'regrtest_data', 'package', 'absimport.py')
        astroid = builder.file_build(fname, 'absimport')
        self.assertTrue(astroid.absolute_import_activated(), True)
        infered = next(get_name_node(astroid, 'import_package_subpackage_module').infer())
        # failed to import since absolute_import is activated
        self.assertIs(infered, YES)

    def test_nonregr_absolute_import(self):
        fname = join(abspath(dirname(__file__)), 'regrtest_data', 'absimp', 'string.py')
        astroid = builder.file_build(fname, 'absimp.string')
        self.assertTrue(astroid.absolute_import_activated(), True)
        infered = next(get_name_node(astroid, 'string').infer())
        self.assertIsInstance(infered, nodes.Module)
        self.assertEqual(infered.name, 'string')
        self.assertIn('ascii_letters', infered.locals)

    def test_mechanize_open(self):
        try:
            import mechanize
        except ImportError:
            self.skipTest('require mechanize installed')
        data = '''from mechanize import Browser
print (Browser)
b = Browser()
'''
        astroid = builder.string_build(data, __name__, __file__)
        browser = next(get_name_node(astroid, 'Browser').infer())
        self.assertIsInstance(browser, nodes.Class)
        bopen = list(browser.igetattr('open'))
        self.skipTest('the commit said: "huum, see that later"')
        self.assertEqual(len(bopen), 1)
        self.assertIsInstance(bopen[0], nodes.Function)
        self.assertTrue(bopen[0].callable())
        b = next(get_name_node(astroid, 'b').infer())
        self.assertIsInstance(b, Instance)
        bopen = list(b.igetattr('open'))
        self.assertEqual(len(bopen), 1)
        self.assertIsInstance(bopen[0], BoundMethod)
        self.assertTrue(bopen[0].callable())

    def test_property(self):
        code = '''
from smtplib import SMTP
class SendMailController(object):

    @property
    def smtp(self):
        return SMTP(mailhost, port)

    @property
    def me(self):
        return self

my_smtp = SendMailController().smtp
my_me = SendMailController().me
'''
        decorators = set(['%s.property' % BUILTINS])
        astroid = builder.string_build(code, __name__, __file__)
        self.assertEqual(astroid['SendMailController']['smtp'].decoratornames(),
                          decorators)
        propinfered = list(astroid.body[2].value.infer())
        self.assertEqual(len(propinfered), 1)
        propinfered = propinfered[0]
        self.assertIsInstance(propinfered, Instance)
        self.assertEqual(propinfered.name, 'SMTP')
        self.assertEqual(propinfered.root().name, 'smtplib')
        self.assertEqual(astroid['SendMailController']['me'].decoratornames(),
                          decorators)
        propinfered = list(astroid.body[3].value.infer())
        self.assertEqual(len(propinfered), 1)
        propinfered = propinfered[0]
        self.assertIsInstance(propinfered, Instance)
        self.assertEqual(propinfered.name, 'SendMailController')
        self.assertEqual(propinfered.root().name, __name__)


    def test_im_func_unwrap(self):
        code = '''
class EnvBasedTC:
    def pactions(self):
        pass
pactions = EnvBasedTC.pactions.im_func
print (pactions)

class EnvBasedTC2:
    pactions = EnvBasedTC.pactions.im_func
    print (pactions)

'''
        astroid = builder.string_build(code, __name__, __file__)
        pactions = get_name_node(astroid, 'pactions')
        infered = list(pactions.infer())
        self.assertEqual(len(infered), 1)
        self.assertIsInstance(infered[0], nodes.Function)
        pactions = get_name_node(astroid['EnvBasedTC2'], 'pactions')
        infered = list(pactions.infer())
        self.assertEqual(len(infered), 1)
        self.assertIsInstance(infered[0], nodes.Function)

    def test_augassign(self):
        code = '''
a = 1
a += 2
print (a)
'''
        astroid = builder.string_build(code, __name__, __file__)
        infered = list(get_name_node(astroid, 'a').infer())

        self.assertEqual(len(infered), 1)
        self.assertIsInstance(infered[0], nodes.Const)
        self.assertEqual(infered[0].value, 3)

    def test_nonregr_func_arg(self):
        code = '''
def foo(self, bar):
    def baz():
        pass
    def qux():
        return baz
    spam = bar(None, qux)
    print (spam)
'''
        astroid = builder.string_build(code, __name__, __file__)
        infered = list(get_name_node(astroid['foo'], 'spam').infer())
        self.assertEqual(len(infered), 1)
        self.assertIs(infered[0], YES)

    def test_nonregr_func_global(self):
        code = '''
active_application = None

def get_active_application():
  global active_application
  return active_application

class Application(object):
  def __init__(self):
     global active_application
     active_application = self

class DataManager(object):
  def __init__(self, app=None):
     self.app = get_active_application()
  def test(self):
     p = self.app
     print (p)
        '''
        astroid = builder.string_build(code, __name__, __file__)
        infered = list(Instance(astroid['DataManager']).igetattr('app'))
        self.assertEqual(len(infered), 2, infered) # None / Instance(Application)
        infered = list(get_name_node(astroid['DataManager']['test'], 'p').infer())
        self.assertEqual(len(infered), 2, infered)
        for node in infered:
            if isinstance(node, Instance) and node.name == 'Application':
                break
        else:
            self.fail('expected to find an instance of Application in %s' % infered)

    def test_list_inference(self):
        """#20464"""
        code = '''
import optparse

A = []
B = []

def test():
  xyz = [
    "foobar=%s" % options.ca,
  ] + A + B

  if options.bind is not None:
    xyz.append("bind=%s" % options.bind)
  return xyz

def main():
  global options

  parser = optparse.OptionParser()
  (options, args) = parser.parse_args()

Z = test()
        '''
        astroid = builder.string_build(code, __name__, __file__)
        infered = list(astroid['Z'].infer())
        self.assertEqual(len(infered), 1, infered)
        self.assertIsInstance(infered[0], Instance)
        self.assertIsInstance(infered[0]._proxied, nodes.Class)
        self.assertEqual(infered[0]._proxied.name, 'list')

    def test__new__(self):
        code = '''
class NewTest(object):
    "doc"
    def __new__(cls, arg):
        self = object.__new__(cls)
        self.arg = arg
        return self

n = NewTest()
        '''
        astroid = builder.string_build(code, __name__, __file__)
        self.assertRaises(InferenceError, list, astroid['NewTest'].igetattr('arg'))
        n = next(astroid['n'].infer())
        infered = list(n.igetattr('arg'))
        self.assertEqual(len(infered), 1, infered)


    def test_two_parents_from_same_module(self):
        code = '''
from data import nonregr
class Xxx(nonregr.Aaa, nonregr.Ccc):
    "doc"
        '''
        astroid = builder.string_build(code, __name__, __file__)
        parents = list(astroid['Xxx'].ancestors())
        self.assertEqual(len(parents), 3, parents) # Aaa, Ccc, object

    def test_pluggable_inference(self):
        code = '''
from collections import namedtuple
A = namedtuple('A', ['a', 'b'])
B = namedtuple('B', 'a b')
        '''
        astroid = builder.string_build(code, __name__, __file__)
        aclass = astroid['A'].infered()[0]
        self.assertIsInstance(aclass, nodes.Class)
        self.assertIn('a', aclass.instance_attrs)
        self.assertIn('b', aclass.instance_attrs)
        bclass = astroid['B'].infered()[0]
        self.assertIsInstance(bclass, nodes.Class)
        self.assertIn('a', bclass.instance_attrs)
        self.assertIn('b', bclass.instance_attrs)

    def test_infer_arguments(self):
        code = '''
class A(object):
    def first(self, arg1, arg2):
        return arg1
    @classmethod
    def method(cls, arg1, arg2):
        return arg2
    @classmethod
    def empty(cls):
        return 2
    @staticmethod
    def static(arg1, arg2):
        return arg1
    def empty_method(self):
        return []
x = A().first(1, [])
y = A.method(1, [])
z = A.static(1, [])
empty = A.empty()
empty_list = A().empty_method()
        '''
        astroid = builder.string_build(code, __name__, __file__)
        int_node = astroid['x'].infered()[0]
        self.assertIsInstance(int_node, nodes.Const)
        self.assertEqual(int_node.value, 1)
        list_node = astroid['y'].infered()[0]
        self.assertIsInstance(list_node, nodes.List)
        int_node = astroid['z'].infered()[0]
        self.assertIsInstance(int_node, nodes.Const)
        self.assertEqual(int_node.value, 1)
        empty = astroid['empty'].infered()[0]
        self.assertIsInstance(empty, nodes.Const)
        self.assertEqual(empty.value, 2)
        empty_list = astroid['empty_list'].infered()[0]
        self.assertIsInstance(empty_list, nodes.List)

    def test_infer_variable_arguments(self):
        code = '''
def test(*args, **kwargs):
    vararg = args
    kwarg = kwargs
        '''
        astroid = builder.string_build(code, __name__, __file__)
        func = astroid['test']
        vararg = func.body[0].value
        kwarg = func.body[1].value

        kwarg_infered = kwarg.infered()[0]
        self.assertIsInstance(kwarg_infered, nodes.Dict)
        self.assertIs(kwarg_infered.parent, func.args)

        vararg_infered = vararg.infered()[0]
        self.assertIsInstance(vararg_infered, nodes.Tuple)
        self.assertIs(vararg_infered.parent, func.args)

    def test_infer_nested(self):
        code = dedent("""
        def nested():
            from threading import Thread
    
            class NestedThread(Thread):
                def __init__(self):
                    Thread.__init__(self)
        """)
        # Test that inferring Thread.__init__ looks up in
        # the nested scope.
        astroid = builder.string_build(code, __name__, __file__)
        callfunc = next(astroid.nodes_of_class(nodes.CallFunc))
        func = callfunc.func
        infered = func.infered()[0]
        self.assertIsInstance(infered, UnboundMethod)

    def test_instance_binary_operations(self):
        code = dedent("""
        class A(object):
            def __mul__(self, other):
                return 42
        a = A()
        b = A()
        sub = a - b
        mul = a * b
        """)
        astroid = builder.string_build(code, __name__, __file__)
        sub = astroid['sub'].infered()[0]
        mul = astroid['mul'].infered()[0]
        self.assertIs(sub, YES)
        self.assertIsInstance(mul, nodes.Const)
        self.assertEqual(mul.value, 42)

    def test_instance_binary_operations_parent(self):
        code = dedent("""
        class A(object):
            def __mul__(self, other):
                return 42
        class B(A):
            pass
        a = B()
        b = B()
        sub = a - b
        mul = a * b
        """)
        astroid = builder.string_build(code, __name__, __file__)
        sub = astroid['sub'].infered()[0]
        mul = astroid['mul'].infered()[0]
        self.assertIs(sub, YES)
        self.assertIsInstance(mul, nodes.Const)
        self.assertEqual(mul.value, 42)

    def test_instance_binary_operations_multiple_methods(self):
        code = dedent("""
        class A(object):
            def __mul__(self, other):
                return 42
        class B(A):
            def __mul__(self, other):
                return [42]
        a = B()
        b = B()
        sub = a - b
        mul = a * b
        """)
        astroid = builder.string_build(code, __name__, __file__)
        sub = astroid['sub'].infered()[0]
        mul = astroid['mul'].infered()[0]
        self.assertIs(sub, YES)
        self.assertIsInstance(mul, nodes.List)
        self.assertIsInstance(mul.elts[0], nodes.Const)
        self.assertEqual(mul.elts[0].value, 42)

    def test_infer_call_result_crash(self):
        # Test for issue 11.
        code = dedent("""
        class A(object):
            def __mul__(self, other):
                return type.__new__()

        a = A()
        b = A()
        c = a * b
        """)
        astroid = builder.string_build(code, __name__, __file__)
        node = astroid['c']
        self.assertEqual(node.infered(), [YES])


if __name__ == '__main__':
    unittest_main()
