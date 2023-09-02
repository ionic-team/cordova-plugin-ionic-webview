var exec = require('cordova/exec');

var WebView = {
  convertFileSrc: function(url) {
    const convertHttp = !location.protocol.startsWith("http") && !location.protocol.startsWith("https")

    if (!url) {
      return url;
    }
    if (url.indexOf('/')===0) {
      return window.WEBVIEW_SERVER_URL + '/_app_file_' + url;
    }
    if (url.indexOf('file://')===0) {
      return window.WEBVIEW_SERVER_URL + url.replace('file://', '/_app_file_');
    }
    if (convertHttp && url.url.indexOf('http://')===0) {
      return window.WEBVIEW_SERVER_URL + '/_http_proxy_' + encodeURIComponent(url.replace('http://', ''));
    }
    if (convertHttp && url.url.indexOf('https://')===0) {
      return window.WEBVIEW_SERVER_URL + '/_https_proxy_' + encodeURIComponent(url.replace('https://', ''));
    }
    if (url.indexOf('content://')===0) {
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
