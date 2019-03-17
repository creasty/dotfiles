import os
import re

from .base import Base

class Source(Base):

    def __init__(self, vim):
        Base.__init__(self, vim)

        self.name = 'minisnip'
        self.mark = '[minisnip]'
        self.min_pattern_length = 0
        self.minisnip_dir = None
        self.snippets = []

    def gather_candidates(self, context):
        if not self.minisnip_dir:
            self.minisnip_dir = self.vim.eval('g:minisnip_dir')
            self.snippets = os.listdir(os.path.expanduser(self.minisnip_dir))

        ft = context['filetype']
        ft_reg = '^_(' + format(ft.replace('.', '|')) + ')_'

        candidates = []

        for snippet in self.snippets:
            if snippet.startswith('_'):
                m = re.search(ft_reg, snippet)
                if m:
                    candidates.append(snippet[len(m.group(0)):])
            else:
                candidates.append(snippet)

        return [{'word': c} for c in candidates]
