package com.ionicframework.cordova.webview;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.os.Build;
import android.util.Log;
import android.webkit.MimeTypeMap;
import android.webkit.ServiceWorkerController;
import android.webkit.ServiceWorkerClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;

import org.apache.cordova.ConfigXmlParser;
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

import androidx.webkit.WebViewAssetLoader;
import androidx.webkit.internal.AssetHelper;

import java.io.InputStream;

public class IonicWebViewEngine extends SystemWebViewEngine {
    public static final String TAG = "IonicWebViewEngine";
    private String LOCAL_SERVER;
    private String scheme;

    public final static String httpScheme = "http";
    public final static String httpsScheme = "https";

    private WebViewAssetLoader assetLoader;
    private AndroidProtocolHandler protocolHandler;

    /**
     * Used when created via reflection.
     */
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
        ConfigXmlParser parser = new ConfigXmlParser();
        parser.parse(cordova.getActivity());

        this.protocolHandler = new AndroidProtocolHandler(cordova.getActivity().getApplicationContext().getApplicationContext());

        String hostname = preferences.getString("Hostname", "localhost");
        scheme = preferences.getString("Scheme", "https");
        LOCAL_SERVER = scheme + "://" + hostname;

        assetLoader = new WebViewAssetLoader.Builder()
                .setDomain(hostname)
                .setHttpAllowed(true)
                // ---- Path handler
                // Default path handler not working
                // .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
                // .addPathHandler("/res/", new WebViewAssetLoader.ResourcesPathHandler(this))
                //  => implementing custom handler
                .addPathHandler("/", path -> {
                    try {
                        if (path.isEmpty())
                            path = "index.html";
                        InputStream is = protocolHandler.openAsset("www/" + path);
                        String mimeType = "text/html";
                        String extension = MimeTypeMap.getFileExtensionFromUrl(path);
                        if (extension != null) {
                            if (path.endsWith(".js") || path.endsWith(".mjs")) {
                                // Make sure JS files get the proper mimetype to support ES modules
                                mimeType = "application/javascript";
                            } else if (path.endsWith(".wasm")) {
                                mimeType = "application/wasm";
                            } else {
                                mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
                            }
                        }

                        return new WebResourceResponse(mimeType, null, is);
                    } catch (Exception e) {
                        e.printStackTrace();
                        Log.e("WebViewAssetLoader", e.getMessage());
                    }
                    return null;
                })
                // ----
                .build();

        webView.setWebViewClient(new ServerClient(this, parser));

        super.init(parentWebView, cordova, client, resourceApi, pluginManager, nativeToJsMessageQueue);
        if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            final WebSettings settings = webView.getSettings();
            int mode = preferences.getInteger("MixedContentMode", 0);
            settings.setMixedContentMode(mode);
        }
        SharedPreferences prefs = cordova.getActivity().getApplicationContext().getSharedPreferences(IonicWebView.WEBVIEW_PREFS_NAME, Activity.MODE_PRIVATE);
        String path = prefs.getString(IonicWebView.CDV_SERVER_PATH, null);


        boolean setAsServiceWorkerClient = preferences.getBoolean("ResolveServiceWorkerRequests", false);
        ServiceWorkerController controller = null;

        if (setAsServiceWorkerClient && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            controller = ServiceWorkerController.getInstance();
            controller.setServiceWorkerClient(new ServiceWorkerClient() {
                @Override
                public WebResourceResponse shouldInterceptRequest(WebResourceRequest request) {
                    return assetLoader.shouldInterceptRequest(request.getUrl());
                }
            });
        }
    }

    private class ServerClient extends SystemWebViewClient {
        private ConfigXmlParser parser;

        public ServerClient(SystemWebViewEngine parentEngine, ConfigXmlParser parser) {
            super(parentEngine);
            this.parser = parser;
        }

        @Override
        public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
            WebResourceResponse intercept = assetLoader.shouldInterceptRequest(request.getUrl());
            return intercept;
        }

        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            super.onPageStarted(view, url, favicon);
            String launchUrl = parser.getLaunchUrl();
            if (!launchUrl.contains(IonicWebViewEngine.httpsScheme) && !launchUrl.contains(IonicWebViewEngine.httpScheme) && url.equals(launchUrl)) {
                view.stopLoading();
                // When using a custom scheme the app won't load if server start url doesn't end in /
                String startUrl = LOCAL_SERVER;
                if (!scheme.equalsIgnoreCase(IonicWebViewEngine.httpsScheme) && !scheme.equalsIgnoreCase(IonicWebViewEngine.httpScheme)) {
                    startUrl += "/";
                }
                view.loadUrl(startUrl);
            }
        }

        @Override
        public void onPageFinished(WebView view, String url) {
            super.onPageFinished(view, url);
            view.loadUrl("javascript:(function() { " +
                    "window.WEBVIEW_SERVER_URL = '" + LOCAL_SERVER + "';" +
                    "})()");
        }
    }

    public void setServerBasePath(String path) {
        //localServer.hostFiles(path);
        //webView.loadUrl(LOCAL_SERVER);
    }

    public String getServerBasePath() {
        //return this.localServer.getBasePath();
        return LOCAL_SERVER;
    }
}
