var exec = require('cordova/exec');

var WebView = {
  convertFileSrc: function(url) {
    if (!url) {
      return url;
    }
    if (url.startsWith('file://')) {
      return url.replace('file', window.WEBVIEW_FILE_PREFIX);
    }
    if (url.startsWith('content://')) {
        return url.replace('content://', window.WEBVIEW_CONTENT_PREFIX + ':///');
    }

    return url;
  },
  setServerBasePath: function(path) {
    exec(null, null, 'IonicWebView', 'setServerBasePath', [path]);
  },
  getServerBasePath: function(callback) {
    exec(callback, null, 'IonicWebView', 'getServerBasePath', []);
  },
  persistServerBasePath: function() {
    exec(null, null, 'IonicWebView', 'persistServerBasePath', []);
  }
}

module.exports = WebView;