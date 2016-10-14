#!/usr/bin/env python

# -*- coding: utf-8 -*-
import os
import re
import sys

sys.path.insert(0, os.path.join(
    os.path.abspath(os.path.dirname(__file__)),
    'deps'
))
from isort.main import main


if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw|\.exe)?$', '', sys.argv[0])
    sys.exit(main())
