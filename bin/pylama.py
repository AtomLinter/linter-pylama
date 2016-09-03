#!/usr/bin/env python

# -*- coding: utf-8 -*-
import os
import re
import sys

python_path = os.environ.get('PYLAMA', '').split(os.pathsep)
sys.path = [p for p in sys.path if p not in python_path]
sys.path.extend(python_path)

from pylama.main import shell


if __name__ == '__main__':
    try:
        virtual_env = os.environ.get('VIRTUAL_ENV', '')
        activate_this = os.path.join(virtual_env, 'bin', 'activate_this.py')
        with open(activate_this) as f:
            from deps import six
            six.exec_(f.read(), dict(__file__=activate_this))
    except IOError:
        pass

    sys.argv[0] = re.sub(r'(-script\.pyw|\.exe)?$', '', sys.argv[0])
    sys.exit(shell())
