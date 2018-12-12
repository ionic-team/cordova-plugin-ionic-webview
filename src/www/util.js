var exec = require('cordova/exec');

var WebView = {
  convertFileSrc: function(url) {
    if (!url) {
      return url;
    }
    if (url.startsWith('file://')) {
      return url.replace('file', 'ionic-file');;
    }
    if (url.startsWith('content://')) {
        return url.replace('content://', 'ionic-content:///');;
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