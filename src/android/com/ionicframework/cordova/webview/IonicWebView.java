package com.ionicframework.cordova.webview;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;

public class IonicWebView extends CordovaPlugin  {

  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
  
    if (action.equals("getServerBasePath")) {
      callbackContext.success(((IonicWebViewEngine)webView.getEngine()).getServerBasePath());
      return true;
    }
    return false;
  }

}

