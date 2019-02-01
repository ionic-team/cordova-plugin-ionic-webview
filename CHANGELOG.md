# [2.3.3](https://github.com/ionic-team/cordova-plugin-ionic-webview/compare/v2.3.2...v2.3.3) (2019-02-01)


### Bug Fixes

* **Android:** Handle range requests ([#295](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/295))

## [2.3.2](https://github.com/ionic-team/cordova-plugin-ionic-webview/compare/v2.3.1...v2.3.2) (2019-01-18)


### Bug Fixes

* **ios:** Fix video playback of files with uppercase extension ([#277](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/277)), closes [#260](https://github.com/ionic-team/cordova-plugin-ionic-webview/issues/260)
* Use a single scheme for all files ([#278](https://github.com/ionic-team/cordova-plugin-ionic-webview/pull/278)), closes [#258](https://github.com/ionic-team/cordova-plugin-ionic-webview/issues/258)



## [2.3.1](https://github.com/ionic-team/cordova-plugin-ionic-webview/compare/v2.3.0...v2.3.1) (2018-12-06)


### Bug Fixes

* Handle convertFileSrc when using ionic:// scheme ([#236](https://github.com/ionic-team/cordova-plugin-ionic-webview/issues/236)) ([89ce899](https://github.com/ionic-team/cordova-plugin-ionic-webview/commit/89ce899))

## [2.3.0](https://github.com/ionic-team/cordova-plugin-ionic-webview/compare/v2.2.5...v2.3.0) (2018-12-05)


### Features

* **ios:** Add URLSchemeHandler for iOS 11+ ([#221](https://github.com/ionic-team/cordova-plugin-ionic-webview/issues/221)) ([4a973f4](https://github.com/ionic-team/cordova-plugin-ionic-webview/commit/4a973f4))

## [2.2.5](https://github.com/ionic-team/cordova-plugin-ionic-webview/compare/v2.2.4...v2.2.5) (2018-11-20)


### Bug Fixes

* Add option for Dark keyboard appearance ([#44](https://github.com/ionic-team/cordova-plugin-ionic-webview/issues/44)) ([6c0fe56](https://github.com/ionic-team/cordova-plugin-ionic-webview/commit/6c0fe56))

## [2.2.4](https://github.com/ionic-team/cordova-plugin-ionic-webview/compare/v2.2.3...v2.2.4) (2018-11-20)


### Bug Fixes

* fix keyboard displacement bug in iOS 12 WKWebView ([#201](https://github.com/ionic-team/cordova-plugin-ionic-webview/issues/201)) ([a670568](https://github.com/ionic-team/cordova-plugin-ionic-webview/commit/a670568))

## [2.2.3](https://github.com/ionic-team/cordova-plugin-ionic-webview/compare/v2.2.2...v2.2.3) (2018-11-09)


### Bug Fixes

* Remove main and fix description ([d52db66](https://github.com/ionic-team/cordova-plugin-ionic-webview/commit/d52db66))

## [2.2.2](https://github.com/ionic-team/cordova-plugin-ionic-webview/compare/v2.2.1...v2.2.2) (2018-11-09)

### Bug Fixes

* Add more server checks before loading urls or reloading ([#211](https://github.com/ionic-team/cordova-plugin-ionic-webview/issues/211)) ([60eff2f](https://github.com/ionic-team/cordova-plugin-ionic-webview/commit/60eff2f))

## [2.2.1](https://github.com/ionic-team/cordova-plugin-ionic-webview/compare/v2.2.0...v2.2.1) (2018-11-07)


### Bug Fixes

* Show error page if server is not running ([#207](https://github.com/ionic-team/cordova-plugin-ionic-webview/issues/207)) ([6a2e07e](https://github.com/ionic-team/cordova-plugin-ionic-webview/commit/6a2e07e))

<a name="2.2.0"></a>
### 2.2.0 (2018-10-04)

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
