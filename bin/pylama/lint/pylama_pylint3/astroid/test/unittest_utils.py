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
from logilab.common.testlib import TestCase, unittest_main

from astroid import builder, nodes
from astroid.node_classes import are_exclusive

builder = builder.AstroidBuilder()

class AreExclusiveTC(TestCase):
    def test_not_exclusive(self):
        astroid = builder.string_build("""
x = 10
for x in range(5):
    print (x)

if x > 0:
    print ('#' * x)
        """, __name__, __file__)
        xass1 = astroid.locals['x'][0]
        assert xass1.lineno == 2
        xnames = [n for n in astroid.nodes_of_class(nodes.Name) if n.name == 'x']
        assert len(xnames) == 3
        assert xnames[1].lineno == 6
        self.assertEqual(are_exclusive(xass1, xnames[1]), False)
        self.assertEqual(are_exclusive(xass1, xnames[2]), False)

    def test_if(self):
        astroid = builder.string_build('''

if 1:
    a = 1
    a = 2
elif 2:
    a = 12
    a = 13
else:
    a = 3
    a = 4
        ''')
        a1 = astroid.locals['a'][0]
        a2 = astroid.locals['a'][1]
        a3 = astroid.locals['a'][2]
        a4 = astroid.locals['a'][3]
        a5 = astroid.locals['a'][4]
        a6 = astroid.locals['a'][5]
        self.assertEqual(are_exclusive(a1, a2), False)
        self.assertEqual(are_exclusive(a1, a3), True)
        self.assertEqual(are_exclusive(a1, a5), True)
        self.assertEqual(are_exclusive(a3, a5), True)
        self.assertEqual(are_exclusive(a3, a4), False)
        self.assertEqual(are_exclusive(a5, a6), False)

    def test_try_except(self):
        astroid = builder.string_build('''
try:
    def exclusive_func2():
        "docstring"
except TypeError:
    def exclusive_func2():
        "docstring"
except:
    def exclusive_func2():
        "docstring"
else:
    def exclusive_func2():
        "this one redefine the one defined line 42"

        ''')
        f1 = astroid.locals['exclusive_func2'][0]
        f2 = astroid.locals['exclusive_func2'][1]
        f3 = astroid.locals['exclusive_func2'][2]
        f4 = astroid.locals['exclusive_func2'][3]
        self.assertEqual(are_exclusive(f1, f2), True)
        self.assertEqual(are_exclusive(f1, f3), True)
        self.assertEqual(are_exclusive(f1, f4), False)
        self.assertEqual(are_exclusive(f2, f4), True)
        self.assertEqual(are_exclusive(f3, f4), True)
        self.assertEqual(are_exclusive(f3, f2), True)

        self.assertEqual(are_exclusive(f2, f1), True)
        self.assertEqual(are_exclusive(f4, f1), False)
        self.assertEqual(are_exclusive(f4, f2), True)

if __name__ == '__main__':
    unittest_main()

