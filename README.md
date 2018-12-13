<!--
# license: Licensed to the Apache Software Foundation (ASF) under one
#         or more contributor license agreements.  See the NOTICE file
#         distributed with this work for additional information
#         regarding copyright ownership.  The ASF licenses this file
#         to you under the Apache License, Version 2.0 (the
#         "License"); you may not use this file except in compliance
#         with the License.  You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#         Unless required by applicable law or agreed to in writing,
#         software distributed under the License is distributed on an
#         "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#         KIND, either express or implied.  See the License for the
#         specific language governing permissions and limitations
#         under the License.
-->

<!-- TODO: remove beta in README.md and CONTRIBUTING.md -->

[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![Dependabot Status](https://api.dependabot.com/badges/status?host=github&identifier=104773211)](https://dependabot.com)
[![npm](https://img.shields.io/npm/v/cordova-plugin-ionic-webview.svg)](https://www.npmjs.com/package/cordova-plugin-ionic-webview)

# Ionic Web View for Cordova

A Web View plugin for Cordova, focused on providing the highest performance experience for Ionic apps (but can be used with any Cordova app).

This plugin uses WKWebView on iOS and the latest evergreen webview on Android. Additionally, this plugin makes it easy to use HTML5 style routing
that web developers expect for building single-page apps.

Note: This repo and its documentation are for `cordova-plugin-ionic-webview` @ `3.x`, which uses the new features that may not work with all apps. See [Requirements](#requirements) and [Migrating to 3.x](#migrating-to-3x).

:book: **Documentation**: [https://beta.ionicframework.com/docs/building/webview][ionic-webview-docs]

:mega: **Support/Questions?** Please see our [Support Page][ionic-support] for general support questions. The issues on GitHub should be reserved for bug reports and feature requests.

:sparkling_heart: **Want to contribute?** Please see [CONTRIBUTING.md](https://github.com/ionic-team/cordova-plugin-ionic-webview/blob/master/CONTRIBUTING.md).

## Configuration

This plugin has several configuration options that can be set in `config.xml`.

### Android Preferences

Preferences only available Android platform

#### WKPort 

```xml
<preference name="WKPort" value="8080" />
```

The default port the server will listen on. If you change it, add an `allow-navigation`
 entry in the `config.xml` for the new url (i.e `<allow-navigation href="http://localhost:8888/*"/>` if `WKPort` is set to 8888)

#### MixedContentMode


```xml
<preference name="MixedContentMode" value="2" />
```

Configures the WebView's behavior when an origin attempts to load a resource from a different origin.

Default value is `0` (`MIXED_CONTENT_ALWAYS_ALLOW`), which allows loading resources from other origins.

Other possible values are `1` (`MIXED_CONTENT_NEVER_ALLOW`) and `2` (`MIXED_CONTENT_COMPATIBILITY_MODE`)


[Android documentation](https://developer.android.com/reference/android/webkit/WebSettings.html#setMixedContentMode(int))


### iOS Preferences

Preferences only available for iOS platform

#### HostName

`<preference name="HostName" value="myHostName" />`

Default value is `app`.

If `UseScheme` is set to yes, it will use the `HostName` value as the host of the starting url.

Example `ionic://app`

#### WKSuspendInBackground

```xml
<preference name="WKSuspendInBackground" value="false" />
```

Set to false to stop WKWebView suspending in background too eagerly.

#### KeyboardAppearanceDark

```xml
<preference name="KeyboardAppearanceDark" value="false" />
```

Whether to use a dark styled keyboard on iOS

## Plugin Requirements

* **iOS**: iOS 11+ and `cordova-ios` 4+
* **Android**: Android 4.4+ and `cordova-android` 6.4+

## Migrating to 3.x

1. Remove and re-add the Web View plugin:

    ```
    cordova plugin rm cordova-plugin-ionic-webview
    cordova plugin add cordova-plugin-ionic-webview@latest
    ```

1. Apps are now served from HTTP on Android.

    * The default origin for requests from the WebView is `http://localhost:8080`. If `WKPort` preference is set, then origin will be  `http://localhost:WKPortValue`.

1. Apps are now served from `ionic://` scheme on iOS.

    * The default origin for requests from the WebView is `ionic://app`. If `HostName` preference is set, then origin will be `ionic://HostNameValue`.

1. Replace any usages of `window.Ionic.normalizeURL()` with `window.Ionic.WebView.convertFileSrc()`.

    * For Ionic Angular projects, there is an [Ionic Native wrapper](https://beta.ionicframework.com/docs/native/ionic-webview):

        ```
        npm install @ionic-native/ionic-webview@beta
        ```

[ionic-homepage]: https://ionicframework.com
[ionic-docs]: https://ionicframework.com/docs
[ionic-webview-docs]: https://beta.ionicframework.com/docs/building/webview
[ionic-support]: https://ionicframework.com/support
