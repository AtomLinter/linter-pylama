"""Docstring violation definition."""
from itertools import dropwhile

from .utils import is_blank


__all__ = ('Error', 'ErrorRegistry')


class Error(object):
    """Error in docstring style."""

    # should be overridden by inheriting classes
    code = None
    short_desc = None
    context = None

    # Options that define how errors are printed:
    explain = False
    source = False

    def __init__(self, *parameters):
        """Initialize the object.

        `parameters` are specific to the created error.

        """
        self.parameters = parameters
        self.definition = None
        self.explanation = None

    def set_context(self, definition, explanation):
        """Set the source code context for this error."""
        self.definition = definition
        self.explanation = explanation

    filename = property(lambda self: self.definition.module.name)
    line = property(lambda self: self.definition.start)

    @property
    def message(self):
        """Return the message to print to the user."""
        ret = '{0}: {1}'.format(self.code, self.short_desc)
        if self.context is not None:
            ret += ' (' + self.context.format(*self.parameters) + ')'
        return ret

    @property
    def lines(self):
        """Return the source code lines for this error."""
        source = ''
        lines = self.definition._source[self.definition._slice]
        offset = self.definition.start
        lines_stripped = list(reversed(list(dropwhile(is_blank,
                                                      reversed(lines)))))
        numbers_width = 0
        for n, line in enumerate(lines_stripped):
            numbers_width = max(numbers_width, n + offset)
        numbers_width = len(str(numbers_width))
        numbers_width = 6
        for n, line in enumerate(lines_stripped):
            source += '{{0}}{0}: {{1}}'.format(numbers_width).format(
                n + offset, line)
            source += '%*d: %s' % (numbers_width, n + offset, line)
            if n > 5:
                source += '        ...\n'
                break
        return source

    def __str__(self):
        self.explanation = '\n'.join(l for l in self.explanation.split('\n')
                                     if not is_blank(l))
        template = '{filename}:{line} {definition}:\n        {message}'
        if self.source and self.explain:
            template += '\n\n{explanation}\n\n{lines}\n'
        elif self.source and not self.explain:
            template += '\n\n{lines}\n'
        elif self.explain and not self.source:
            template += '\n\n{explanation}\n\n'
        return template.format(**dict((name, getattr(self, name)) for name in
                               ['filename', 'line', 'definition', 'message',
                                'explanation', 'lines']))

    def __repr__(self):
        return str(self)

    def __lt__(self, other):
        return (self.filename, self.line) < (other.filename, other.line)


class ErrorRegistry(object):
    """A registry of all error codes, divided to groups."""

    groups = []

    class ErrorGroup(object):
        """A group of similarly themed errors."""

        def __init__(self, prefix, name):
            """Initialize the object.

            `Prefix` should be the common prefix for errors in this group,
            e.g., "D1".
            `name` is the name of the group (its subject).

            """
            self.prefix = prefix
            self.name = name
            self.errors = []

        def create_error(self, error_code, error_desc, error_context=None):
            """Create an error, register it to this group and return it."""
            # TODO: check prefix

            class _Error(Error):
                code = error_code
                short_desc = error_desc
                context = error_context

            self.errors.append(_Error)
            return _Error

    @classmethod
    def create_group(cls, prefix, name):
        """Create a new error group and return it."""
        group = cls.ErrorGroup(prefix, name)
        cls.groups.append(group)
        return group

    @classmethod
    def get_error_codes(cls):
        """Yield all registered codes."""
        for group in cls.groups:
            for error in group.errors:
                yield error.code

    @classmethod
    def to_rst(cls):
        """Output the registry as reStructuredText, for documentation."""
        sep_line = '+' + 6 * '-' + '+' + '-' * 71 + '+\n'
        blank_line = '|' + 78 * ' ' + '|\n'
        table = ''
        for group in cls.groups:
            table += sep_line
            table += blank_line
            table += '|' + '**{0}**'.format(group.name).center(78) + '|\n'
            table += blank_line
            for error in group.errors:
                table += sep_line
                table += ('|' + error.code.center(6) + '| ' +
                          error.short_desc.ljust(70) + '|\n')
        table += sep_line
        return table


D1xx = ErrorRegistry.create_group('D1', 'Missing Docstrings')
D100 = D1xx.create_error('D100', 'Missing docstring in public module')
D101 = D1xx.create_error('D101', 'Missing docstring in public class')
D102 = D1xx.create_error('D102', 'Missing docstring in public method')
D103 = D1xx.create_error('D103', 'Missing docstring in public function')
D104 = D1xx.create_error('D104', 'Missing docstring in public package')
D105 = D1xx.create_error('D105', 'Missing docstring in magic method')

D2xx = ErrorRegistry.create_group('D2', 'Whitespace Issues')
D200 = D2xx.create_error('D200', 'One-line docstring should fit on one line '
                                 'with quotes', 'found {0}')
D201 = D2xx.create_error('D201', 'No blank lines allowed before function '
                                 'docstring', 'found {0}')
D202 = D2xx.create_error('D202', 'No blank lines allowed after function '
                                 'docstring', 'found {0}')
D203 = D2xx.create_error('D203', '1 blank line required before class '
                                 'docstring', 'found {0}')
D204 = D2xx.create_error('D204', '1 blank line required after class '
                                 'docstring', 'found {0}')
D205 = D2xx.create_error('D205', '1 blank line required between summary line '
                                 'and description', 'found {0}')
D206 = D2xx.create_error('D206', 'Docstring should be indented with spaces, '
                                 'not tabs')
D207 = D2xx.create_error('D207', 'Docstring is under-indented')
D208 = D2xx.create_error('D208', 'Docstring is over-indented')
D209 = D2xx.create_error('D209', 'Multi-line docstring closing quotes should '
                                 'be on a separate line')
D210 = D2xx.create_error('D210', 'No whitespaces allowed surrounding '
                                 'docstring text')
D211 = D2xx.create_error('D211', 'No blank lines allowed before class '
                                 'docstring', 'found {0}')
D212 = D2xx.create_error('D212', 'Multi-line docstring summary should start '
                                 'at the first line')
D213 = D2xx.create_error('D213', 'Multi-line docstring summary should start '
                                 'at the second line')

D3xx = ErrorRegistry.create_group('D3', 'Quotes Issues')
D300 = D3xx.create_error('D300', 'Use """triple double quotes"""',
                         'found {0}-quotes')
D301 = D3xx.create_error('D301', 'Use r""" if any backslashes in a docstring')
D302 = D3xx.create_error('D302', 'Use u""" for Unicode docstrings')

D4xx = ErrorRegistry.create_group('D4', 'Docstring Content Issues')
D400 = D4xx.create_error('D400', 'First line should end with a period',
                         'not {0!r}')
D401 = D4xx.create_error('D401', 'First line should be in imperative mood',
                         '{0!r}, not {1!r}')
D402 = D4xx.create_error('D402', 'First line should not be the function\'s '
                                 '"signature"')
D403 = D4xx.create_error('D403', 'First word of the first line should be '
                                 'properly capitalized', '{0!r}, not {1!r}')
D404 = D4xx.create_error('D404', 'First word of the docstring should not '
                                 'be `This`')


class AttrDict(dict):
    def __getattr__(self, item):
        return self[item]


conventions = AttrDict({
    'pep257': set(ErrorRegistry.get_error_codes()) - set(['D203',
                                                          'D212',
                                                          'D213',
                                                          'D404'])
})
