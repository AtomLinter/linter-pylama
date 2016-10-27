"""Option handling polyfill for Flake8 2.x and 3.x."""
import optparse
import os


def register(parser, *args, **kwargs):
    r"""Register an option for the Option Parser provided by Flake8.

    :param parser:
        The option parser being used by Flake8 to handle command-line options.
    :param \*args:
        Positional arguments that you might otherwise pass to ``add_option``.
    :param \*\*kwargs:
        Keyword arguments you might otherwise pass to ``add_option``.
    """
    try:
        # Flake8 3.x registration
        parser.add_option(*args, **kwargs)
    except (optparse.OptionError, TypeError):
        # Flake8 2.x registration
        # Pop Flake8 3 parameters out of the kwargs so they don't cause a
        # conflict.
        parse_from_config = kwargs.pop('parse_from_config', False)
        comma_separated_list = kwargs.pop('comma_separated_list', False)
        normalize_paths = kwargs.pop('normalize_paths', False)
        # In the unlikely event that the developer has specified their own
        # callback, let's pop that and deal with that as well.
        preexisting_callback = kwargs.pop('callback', None)
        callback = generate_callback_from(comma_separated_list,
                                          normalize_paths,
                                          preexisting_callback)

        if callback:
            kwargs['callback'] = callback
            kwargs['action'] = 'callback'

        # We've updated our args and kwargs and can now rather confidently
        # call add_option.
        option = parser.add_option(*args, **kwargs)
        if parse_from_config:
            parser.config_options.append(option.get_opt_string().lstrip('-'))


def parse_comma_separated_list(value):
    """Parse a comma-separated list.

    :param value:
        String or list of strings to be parsed and normalized.
    :returns:
        List of values with whitespace stripped.
    :rtype:
        list
    """
    if not value:
        return []

    if not isinstance(value, (list, tuple)):
        value = value.split(',')

    return [item.strip() for item in value]


def normalize_path(path, parent=os.curdir):
    """Normalize a single-path.

    :returns:
        The normalized path.
    :rtype:
        str
    """
    # NOTE(sigmavirus24): Using os.path.sep allows for Windows paths to
    # be specified and work appropriately.
    separator = os.path.sep
    if separator in path:
        path = os.path.abspath(os.path.join(parent, path))
    return path.rstrip(separator)


def generate_callback_from(comma_separated_list, normalize_paths,
                           preexisting_callback):
    """Generate a callback from parameters provided for the option.

    This uses composition to handle mixtures of the flags provided as well as
    callbacks specified by the user.
    """
    if comma_separated_list and normalize_paths:
        callback_list = [comma_separated_callback,
                         normalize_paths_callback]
        if preexisting_callback:
            callback_list.append(preexisting_callback)
        callback = compose_callbacks(*callback_list)
    elif comma_separated_list:
        callback = comma_separated_callback
        if preexisting_callback:
            callback = compose_callbacks(callback, preexisting_callback)
    elif normalize_paths:
        callback = normalize_paths_callback
        if preexisting_callback:
            callback = compose_callbacks(callback, preexisting_callback)
    elif preexisting_callback:
        callback = preexisting_callback
    else:
        callback = None
    return callback


def compose_callbacks(*callback_functions):
    """Compose the callbacks provided as arguments."""
    def _callback(option, opt_str, value, parser, *args, **kwargs):
        """Callback that encompasses the other callbacks."""
        for callback in callback_functions:
            callback(option, opt_str, value, parser, *args, **kwargs)

    return _callback


def comma_separated_callback(option, opt_str, value, parser):
    """Parse the value into a comma-separated list."""
    value = getattr(parser.values, option.dest, value)
    comma_separated_list = parse_comma_separated_list(value)
    setattr(parser.values, option.dest, comma_separated_list)


def normalize_paths_callback(option, opt_str, value, parser):
    """Normalize the path(s) value."""
    value = getattr(parser.values, option.dest, value)
    if isinstance(value, list):
        normalized = [normalize_path(s) for s in value]
    else:
        normalized = normalize_path(value)
    setattr(parser.values, option.dest, normalized)
