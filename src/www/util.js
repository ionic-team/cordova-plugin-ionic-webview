var exec = require('cordova/exec');

var WebView = {
  convertFileSrc: function(url) {
    if (!url) {
      return url;
    }
    if (url.indexOf('/')===0) {
      return window.WEBVIEW_SERVER_URL + '/_app_file_' + url;
    }
    if (url.indexOf('file://')===0) {
      return window.WEBVIEW_SERVER_URL + url.replace('file://', '/_app_file_');
    }
    if (url.indexOf('content://')===0) {
      return window.WEBVIEW_SERVER_URL + url.replace('content:/', '/_app_content_');
    }
    return url;
  },
  getServerBasePath: function(callback) {
    exec(callback, null, 'IonicWebView', 'getServerBasePath', []);
  }
}

module.exports = WebView;
