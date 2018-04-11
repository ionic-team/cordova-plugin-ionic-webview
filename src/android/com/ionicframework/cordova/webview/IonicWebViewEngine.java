package com.ionicframework.cordova.webview;

import android.content.Context;
import android.util.Log;
import android.view.KeyEvent;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPreferences;
import org.apache.cordova.CordovaResourceApi;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CordovaWebViewEngine;
import org.apache.cordova.NativeToJsMessageQueue;
import org.apache.cordova.PluginManager;
import org.apache.cordova.engine.SystemWebViewClient;
import org.apache.cordova.engine.SystemWebViewEngine;
import org.apache.cordova.engine.SystemWebView;

public class IonicWebViewEngine extends SystemWebViewEngine {
  public static final String TAG = "IonicWebViewEngine";

  private WebViewLocalServer localServer;

  /** Used when created via reflection. */
  public IonicWebViewEngine(Context context, CordovaPreferences preferences) {
    super(new SystemWebView(context), preferences);
    Log.d(TAG, "Ionic Web View Engine Starting Right Up 1...");
  }

  public IonicWebViewEngine(SystemWebView webView) {
    super(webView, null);
    Log.d(TAG, "Ionic Web View Engine Starting Right Up 2...");
  }

  public IonicWebViewEngine(SystemWebView webView, CordovaPreferences preferences) {
    super(webView, preferences);
    Log.d(TAG, "Ionic Web View Engine Starting Right Up 3...");
  }

  @Override
  public void init(CordovaWebView parentWebView, CordovaInterface cordova, final CordovaWebViewEngine.Client client,
                   CordovaResourceApi resourceApi, PluginManager pluginManager,
                   NativeToJsMessageQueue nativeToJsMessageQueue) {
    localServer = new WebViewLocalServer(cordova.getActivity(), "localhost", true);
    WebViewLocalServer.AssetHostingDetails ahd = localServer.hostAssets("www");

    CordovaWebViewEngine.Client webViewClient = new CordovaWebViewEngine.Client() {
      public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
        return localServer.shouldInterceptRequest(request);
      }

      @Override
      public void onPageStarted(String newUrl) {
        Log.d(TAG, "CUSTOM ON PAGE STARTED: " + newUrl);
        client.onPageStarted(newUrl);
      }

      @Override
      public void onPageFinishedLoading(String url) {
        client.onPageFinishedLoading(url);
      }

      @Override
      public void onReceivedError(int errorCode, String description, String failingUrl) {
        client.onReceivedError(errorCode, description, failingUrl);
      }

      @Override
      public Boolean onDispatchKeyEvent(KeyEvent event) {
        return client.onDispatchKeyEvent(event);
      }

      @Override
      public void clearLoadTimeoutTimer() {
        client.clearLoadTimeoutTimer();
      }

      @Override
      public boolean onNavigationAttempt(String url) {
        return client.onNavigationAttempt(url);
      }
    };

    super.init(parentWebView, cordova, webViewClient, resourceApi, pluginManager, nativeToJsMessageQueue);
  }
}
