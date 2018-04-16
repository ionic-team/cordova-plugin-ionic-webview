var exec = require('cordova/exec');

var PLUGIN_NAME = 'CDVWKWebViewEngine';

module.exports = {
  setWebRoot: function(webRoot) {
    exec(null, null, PLUGIN_NAME, 'setWebRoot', [webRoot]);
  }
}