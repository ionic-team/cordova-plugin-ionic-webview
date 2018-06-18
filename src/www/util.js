var exec = require('cordova/exec');

var WebView = {
  convertFileSrc: function(url) {
    if (!url) {
      return url;
    }
    if (!url.startsWith('file://')) {
      return url;
    }
    url = url.substr(7); // len("file://") == 7
    if (url.length === 0 || url[0] !== '/') { // ensure the new URL starts with /
      url = '/' + url;
    }
    return window.WEBVIEW_SERVER_URL + '/_file_' + url;
  },
  setServerBasePath: function(path) {
    exec(null, null, 'IonicWebView', 'setServerBasePath', [path]);
  },
  getServerBasePath: function(callback) {
    exec(callback, null, 'IonicWebView', 'getServerBasePath', []);
  }
}

module.exports = WebView;