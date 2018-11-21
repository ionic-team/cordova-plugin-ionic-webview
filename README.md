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

This plugin defaults to using WKWebView on iOS and the latest evergreen webview on Android. Additionally, this plugin makes it easy to use HTML5 style routing
that web developers expect for building single-page apps.

Note: This repo and its documentation are for `cordova-plugin-ionic-webview` @ `2.x`, which uses the new features that may not work with all apps. See [Requirements](#requirements) and [Migrating to 2.x](#migrating-to-2x).

:book: **Documentation**: [https://beta.ionicframework.com/docs/building/webview][ionic-webview-docs]

:mega: **Support/Questions?** Please see our [Support Page][ionic-support] for general support questions. The issues on GitHub should be reserved for bug reports and feature requests.

:sparkling_heart: **Want to contribute?** Please see [CONTRIBUTING.md](https://github.com/ionic-team/cordova-plugin-ionic-webview/blob/master/CONTRIBUTING.md).

## Configuration

This plugin has several configuration options that can be set in `config.xml`. Important: some configuration options should be adjusted for production apps, especially `WKPort`:

### iOS and Android Preferences

Preferences available for both iOS and Android platforms

#### WKPort 

```xml
<preference name="WKPort" value="8080" />
```

The default port the server will listen on. _You should change this to a random port number!_

### iOS Preferences

Preferences only available for iOS platform

#### WKSuspendInBackground

```xml
<preference name="WKSuspendInBackground" value="false" />
```

Whether to try to keep the server running when the app is backgrounded. Note: the server will likely be suspended by the OS after a few minutes. In particular, long-lived background tasks are not allowed on iOS outside of select audio and geolocation tasks.

#### WKBind

```xml
<preference name="WKBind" value="localhost" />
```

The hostname the server will bind to. There aren't a lot of other valid options, but some prefer binding to "127.0.0.1"

#### WKInternalConnectionsOnly (New in 2.2.0)

```xml
<preference name="WKInternalConnectionsOnly" value="true" />
```

Whether to restrict access to this server to the app itself. Previous versions of this plugin did not restrict access to the app itself. In 2.2.0 and above,
the plugin now restricts access to only the app itself.

#### KeyboardAppearanceDark

```xml
<preference name="KeyboardAppearanceDark" value="false" />
```

Whether to use a dark styled keyboard on iOS

## Plugin Requirements

* **iOS**: iOS 10+ and `cordova-ios` 4+
* **Android**: Android 4.4+ and `cordova-android` 6.4+

## Migrating to 2.x

1. Remove and re-add the Web View plugin:

    ```
    cordova plugin rm cordova-plugin-ionic-webview
    cordova plugin add cordova-plugin-ionic-webview@latest
    ```

1. Apps are now served from HTTP on Android.

    * The origin for requests from the Web View is `http://localhost:8080`.

1. Replace any usages of `window.Ionic.normalizeURL()` with `window.Ionic.WebView.convertFileSrc()`.

    * For Ionic Angular projects, there is an [Ionic Native wrapper](https://beta.ionicframework.com/docs/native/ionic-webview):

        ```
        npm install @ionic-native/ionic-webview@beta
        ```

[ionic-homepage]: https://ionicframework.com
[ionic-docs]: https://ionicframework.com/docs
[ionic-webview-docs]: https://beta.ionicframework.com/docs/building/webview
[ionic-support]: https://ionicframework.com/support
