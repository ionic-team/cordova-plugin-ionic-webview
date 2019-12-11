var exec = require('cordova/exec');

var WebView = {
  convertFileSrc: function(url) {
    const convertHttp = !location.protocol.startsWith("http") && !location.protocol.startsWith("https")

    if (!url) {
      return url;
    }
    if (url.startsWith('/')) {
      return window.WEBVIEW_SERVER_URL + '/_app_file_' + url;
    }
    if (url.startsWith('file://')) {
      return window.WEBVIEW_SERVER_URL + url.replace('file://', '/_app_file_');
    }
    if (url.startsWith('http://') && convertHttp) {
      return window.WEBVIEW_SERVER_URL + url.replace('http://', '/_http_proxy_');
    }
    if (url.startsWith('https://') && convertHttp) {
      return window.WEBVIEW_SERVER_URL + url.replace('https://', '/_https_proxy_');
    }
    if (url.startsWith('content://')) {
      return window.WEBVIEW_SERVER_URL + url.replace('content:/', '/_app_content_');
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