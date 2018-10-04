# Changelog

<a name="2.2.0"></a>
### 2.2.0 (PENDING)

* Fix issue where two apps running on the same port could conflict with each other ([#169](https://github.com/ionic-team/cordova-plugin-ionic-webview/issues/165) & [#186](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/186))
* Add kitkat support (API 19) ([#144](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/144)) [@leo6104](https://github.com/leo6104)
* Fix issue where local server was being used if launch URL is external ([#169](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/169))

<a name="2.1.4"></a>
### 2.1.4 (2018-09-13)

* Allow Ionic Deploy `DisableDeploy` preference to disable loading of deploy updates ([#172](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/172))

<a name="2.1.3"></a>
### 2.1.3 (2018-09-06)

* Make server path relative ([#164](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/164))

<a name="2.1.2"></a>
### 2.1.2 (2018-09-05)

* Return 404 response when file doesn't exist ([#162](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/162))
* Load local assets if the app is a freshly installed binary ([#155](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/155))
* Reset stored server path on new binary ([#161](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/161))

<a name="2.1.1"></a>
### 2.1.1 (2018-09-04)

* Allow range requests for local files ([#154](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/154))

<a name="2.1.0"></a>
### 2.1.0 (2018-08-23)

* Add support for `cordova-android` 6 ([#150](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/150))

<a name="2.0.3"></a>
### 2.0.3 (2018-08-14)

* Fix nil reference by setting up the server URL before routes are set up. ([#135](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/135)) [@matejkramny](https://github.com/matejkramny)
* Resolve issue when app is launched in background. ([#124](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/124)) [@ghenry22](https://github.com/ghenry22)

<a name="2.0.2"></a>
### 2.0.2 (2018-07-30)

* Immediately load new server base path upon setting it. ([#132](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/132))

<a name="2.0.1"></a>
### 2.0.1 (2018-07-25)

* Avoid "not modified" response on iOS by always overriding last modified date. ([#127](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/127))

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
