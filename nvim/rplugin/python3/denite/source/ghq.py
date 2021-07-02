from .base import Base
import os
import subprocess

class Source(Base):
    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'ghq'
        self.kind = 'directory'
        self.default_action = 'cd'
        self.gopath = self._gopath()

    def gather_candidates(self, context):
        return [{
            'word': path,
            'action__path': self.gopath + '/' + path,
        } for path in self._ghq_list()]

    def _gopath(self):
        return subprocess.run(['ghq', 'root'],
            check=True,
            universal_newlines=True,
            stdout=subprocess.PIPE
        ).stdout.strip()

    def _ghq_list(self):
        return subprocess.run(['ghq', 'list'],
            check=True,
            universal_newlines=True,
            stdout=subprocess.PIPE
        ).stdout.split()
