
(function _wk_plugin() {
  // Check if we are running in WKWebView
  if (!window.webkit || !window.webkit.messageHandlers) {
    return;
  }

  // Initialize Ionic
  window.Ionic = window.Ionic || {};

  if (typeof window.wkRewriteURL === 'undefined') {
    window.wkRewriteURL = function (url) {
      console.warn('wkRewriteURL is deprecated, use window.Ionic.WebView.convertFileSrc instead');
      return window.Ionic.WebView.convertFileSrc(url);
    }
  }

  var stopScrollHandler = window.webkit.messageHandlers.stopScroll;
  if (!stopScrollHandler) {
    console.error('Can not find stopScroll handler');
    return;
  }

  var stopScrollFunc = null;
  var stopScroll = {
    stop: function stop(callback) {
      if (!stopScrollFunc) {
        stopScrollFunc = callback;
        stopScrollHandler.postMessage('');
      }
    },
    fire: function fire() {
      stopScrollFunc && stopScrollFunc();
      stopScrollFunc = null;
    },
    cancel: function cancel() {
      stopScrollFunc = null;
    }
  };

  window.Ionic.StopScroll = stopScroll;
  // deprecated
  window.IonicStopScroll = stopScroll;

  console.debug("Ionic Stop Scroll injected!");
})();
