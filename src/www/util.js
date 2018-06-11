if (!window.convertFileSrc) {
  window.convertFileSrc = function(url) {
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
    return WEBVIEW_SERVER_URL + '/_file_' + url;
  };
}