# Changelog

<a name="2.0.0"></a>
### 2.0.0 (2018-07-23)

* **BREAKING**: HTTP server now runs for iOS **and** Android, instead of just iOS. The server is configured the same for both platforms.
* **BREAKING**: HTTP server now loads the app from a base href of `/`. The app URL behaves like `http://localhost:8080/index.html` instead of `http://localhost:8080/Users/.../index.html`.
* **BREAKING**: HTTP server is configured to run in HTML5 routing mode (push state) by default.
* **BREAKING**: File access through the Web View must be served by the HTTP server to avoid security errors in the Web View. Loading files via `file://` is not allowed by the Web View. The HTTP server will serve files via the `_file_` prefix, e.g. `http://localhost:8080/_file_/Users/.../file.png`.
* `window.Ionic.normalizeURL()` has been deprecated. Use `window.Ionic.WebView.convertFileSrc()`.
* iOS update HTTP server to latest upstream version (GCDwebserve 3.4.2)
* iOS update HTTP server to restart sockets with error state when resuming from background
* iOS enable HTTP server to continue running in background if the webview is running.
* iOS enable Webview to continue running in background. Requires background mode capability enabled in xcode + valid use case as per app store requirements. If your app is not performing valid background tasks it will still be suspended by the OS as usual. As long as valid background tasks are running the webview will continue to function as expected.
* iOS add config.xml options:
    * WKSuspendInBackground - defaults to true, if set to false then the webview and HTTP server will continue to run when the app is in the background or screen is locked
    * WKPort - defaults to 8080, define the port that the HTTP server will listen on
    * WKBind - defaults to localhost, if set to 127.0.0.1 then this IP will be used instead of the localhost hostname for the HTTP server

See [Github releases](https://github.com/ionic-team/cordova-plugin-ionic-webview/releases) for earlier changes.
