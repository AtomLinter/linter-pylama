# Copyright 2013 Google Inc. All Rights Reserved.
#
# This file is part of astroid.
#
# logilab-astng is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by the
# Free Software Foundation, either version 2.1 of the License, or (at your
# option) any later version.
#
# logilab-astng is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
# for more details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with logilab-astng. If not, see <http://www.gnu.org/licenses/>.
"""Tests for basic functionality in astroid.brain."""
import sys

from logilab.common.testlib import TestCase, unittest_main

from astroid import MANAGER
from astroid import bases
from astroid import test_utils
import astroid

class HashlibTC(TestCase):
    def test_hashlib(self):
        """Tests that brain extensions for hashlib work."""
        hashlib_module = MANAGER.ast_from_module_name('hashlib')
        for class_name in ['md5', 'sha1']:
            class_obj = hashlib_module[class_name]
            self.assertIn('update', class_obj)
            self.assertIn('digest', class_obj)
            self.assertIn('hexdigest', class_obj)
            self.assertEqual(len(class_obj['__init__'].args.args), 2)
            self.assertEqual(len(class_obj['__init__'].args.defaults), 1)
            self.assertEqual(len(class_obj['update'].args.args), 2)
            self.assertEqual(len(class_obj['digest'].args.args), 1)
            self.assertEqual(len(class_obj['hexdigest'].args.args), 1)


class NamedTupleTest(TestCase):
    def test_namedtuple_base(self):
        klass = test_utils.extract_node("""
        from collections import namedtuple

        class X(namedtuple("X", ["a", "b", "c"])):
           pass
        """)
        self.assertEqual(
            [anc.name for anc in klass.ancestors()],
            ['X', 'tuple', 'object'])
        for anc in klass.ancestors():
            self.assertFalse(anc.parent is None)

    def test_namedtuple_inference(self):
        klass = test_utils.extract_node("""
        from collections import namedtuple

        name = "X"
        fields = ["a", "b", "c"]
        class X(namedtuple(name, fields)):
           pass
        """)
        for base in klass.ancestors():
            if base.name == 'X':
                break
        self.assertCountEqual(["a", "b", "c"], list(base.instance_attrs.keys()))

    def test_namedtuple_inference_failure(self):
        klass = test_utils.extract_node("""
        from collections import namedtuple

        def foo(fields):
           return __(namedtuple("foo", fields))
        """)
        self.assertIs(bases.YES, next(klass.infer()))


    def test_namedtuple_advanced_inference(self):
        if sys.version_info[0] > 2:
            self.skipTest('Currently broken for Python 3.')
        # urlparse return an object of class ParseResult, which has a
        # namedtuple call and a mixin as base classes
        result = test_utils.extract_node("""
        import urlparse

        result = __(urlparse.urlparse('gopher://'))
        """)
        instance = next(result.infer())
        self.assertEqual(len(instance.getattr('scheme')), 1)
        self.assertEqual(len(instance.getattr('port')), 1)
        with self.assertRaises(astroid.NotFoundError):
            instance.getattr('foo')


if __name__ == '__main__':
    unittest_main()
