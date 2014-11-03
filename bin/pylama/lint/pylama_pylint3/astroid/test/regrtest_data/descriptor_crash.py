
import urllib.request, urllib.parse, urllib.error

class Page(object):
    _urlOpen = staticmethod(urllib.request.urlopen)

    def getPage(self, url):
        handle = self._urlOpen(url)
        data = handle.read()
        handle.close()
        return data
