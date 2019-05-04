import shlex
import subprocess
import re

from denite import util, process
from .base import Base

_HEADER_SYNTAX = (
    'syntax match deniteSource_i18nflowHeader '
    r'/\v(\S+) \[([^\]]+)\] \(([^\):]+):(\d+):(\d+)\)/ '
    'contained keepend'
)
_HEADER_KEY_SYNTAX = (
    'syntax match deniteSource_i18nflowHeaderKey '
    r'/\v(\S+)\ze \[/ '
    'contained containedin=deniteSource_i18nflowHeader'
)
_HEADER_LOCALE_SYNTAX = (
    'syntax match deniteSource_i18nflowHeaderLocale '
    r'/\v\[\zs[^\]]+\ze\]/ '
    'contained containedin=deniteSource_i18nflowHeader'
)
_HEADER_LOCATION_SYNTAX = (
    'syntax match deniteSource_i18nflowHeaderLocation '
    r'/\v\(\zs[^\)]+\ze\)/ '
    'contained containedin=deniteSource_i18nflowHeader'
)

_HEADER_KEY_HIGHLIGHT = 'highlight default link deniteSource_i18nflowHeaderKey String'
_HEADER_LOCALE_HIGHLIGHT = 'highlight default link deniteSource_i18nflowHeaderLocale Function'
_HEADER_LOCATION_HIGHLIGHT = 'highlight default link deniteSource_i18nflowHeaderLocation Comment'
_PATTERNS_HIGHLIGHT = 'highlight default link deniteI18nflowPatterns Constant'

def _candidate(result, base_path):
    m = re.match(r'^(\S+) \[([^\]]+)\] \(([^\):]+):(\d+):(\d+)\)', result)
    if not m:
        return None

    path = base_path + '/' + m[3]

    return {
        'word': result,
        'action__text': m[1],
        'action__path': path,
        'action__line': m[4],
        'action__col': m[5],
    }

class Source(Base):
    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'i18n_flow'
        self.kind = 'file'
        self.matchers = ['matcher/ignore_globs', 'matcher/regexp']

    def on_init(self, context):
        context['__proc'] = None

        args = dict(enumerate(context['args']))

        context['__paths'] = self._init_paths(context, args)
        context['__arguments'] = self._init_arguments(context, args)
        context['__patterns'] = self._init_patterns(context, args)

    def on_close(self, context):
        if context['__proc']:
            context['__proc'].kill()
            context['__proc'] = None

    def highlight(self):
        self.vim.command(_HEADER_SYNTAX)
        self.vim.command(_HEADER_KEY_SYNTAX)
        self.vim.command(_HEADER_LOCALE_SYNTAX)
        self.vim.command(_HEADER_LOCATION_SYNTAX)

        self.vim.command(_HEADER_KEY_HIGHLIGHT)
        self.vim.command(_HEADER_LOCALE_HIGHLIGHT)
        self.vim.command(_HEADER_LOCATION_HIGHLIGHT)
        self.vim.command(_PATTERNS_HIGHLIGHT)

    def define_syntax(self):
        self.vim.command(
            'syntax region ' + self.syntax_name + ' start=// end=/$/ '
            'contains=deniteSource_i18nflowHeader,deniteMatchedRange contained')
        if self.context['__patterns']:
            self.vim.command(
                'syntax match deniteI18nflowPatterns ' +
                r'/%s/ ' % r'\|'.join(
                    util.regex_convert_str_vim(pattern)
                    for pattern in self.context['__patterns']) +
                'contained containedin=' + self.syntax_name)

    def gather_candidates(self, context):
        if context['event'] == 'interactive':
            # Update input
            self.on_close(context)

            if not context['input']:
                return []

            context['__patterns'] = [
                '.*'.join(util.split_input(context['input']))]

        if context['__proc']:
            return self._async_gather_candidates(
                context, context['async_timeout'])

        if not context['__patterns']:
            return []

        args = ['bundle', 'exec', 'i18n_flow', 'search', '--format=oneline', '--nocolor']
        args += context['__patterns']

        self.print_message(context, args)

        context['__config_base_path'] = self._base_path()

        context['__proc'] = process.Process(args, context, context['path'])
        return self._async_gather_candidates(context, 0.5)

    def _async_gather_candidates(self, context, timeout):
        outs, errs = context['__proc'].communicate(timeout=timeout)
        if errs:
            self.error_message(context, errs)
        context['is_async'] = not context['__proc'].eof()
        if context['__proc'].eof():
            context['__proc'] = None

        candidates = []

        for line in outs:
            candidate = _candidate(line, context['__config_base_path'])
            if not candidate:
                continue
            candidates.append(candidate)

        return candidates

    def _base_path(self):
        args = ['bundle', 'exec', 'i18n_flow', 'read_config', 'base_path']
        return subprocess.run(args,
            check=True,
            universal_newlines=True,
            stdout=subprocess.PIPE
        ).stdout.strip()

    def _init_paths(self, context, args):
        paths = []
        arg = args.get(0, [])
        if arg:
            if isinstance(arg, str):
                paths = [arg]
            elif isinstance(arg, list):
                paths = arg[:]
            else:
                raise AttributeError(
                    '`args[0]` needs to be a `str` or `list`')
        elif context['path']:
            paths = [context['path']]
        return [util.abspath(self.vim, x) for x in paths]

    def _init_arguments(self, context, args):
        arguments = []
        arg = args.get(1, [])
        if arg:
            if isinstance(arg, str):
                if arg == '!':
                    arg = util.input(self.vim, context, 'Argument: ')
                arguments = shlex.split(arg)
            elif isinstance(arg, list):
                arguments = arg[:]
            else:
                raise AttributeError(
                    '`args[1]` needs to be a `str` or `list`')
        return arguments

    def _init_patterns(self, context, args):
        patterns = []
        arg = args.get(2, [])
        if arg:
            if isinstance(arg, str):
                if arg == '!':
                    # Interactive mode
                    context['is_interactive'] = True
                    patterns = [context['input']]
                else:
                    patterns = [arg]
            elif isinstance(arg, list):
                patterns = arg[:]
            else:
                raise AttributeError(
                    '`args[2]` needs to be a `str` or `list`')
        elif context['input']:
            patterns = [context['input']]
        else:
            patterns = [util.input(self.vim, context, 'Pattern: ')]
        return [x for x in patterns if x]
