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

Ionic's Webview
======

This plugin is an extension of the [Apache Cordova WKWebView plugin](https://github.com/apache/cordova-plugin-wkwebview-engine). It includes enhancements to resolve some of the issues surrounding XHR requests, along with some DOM exception issues.

This plugin only supports iOS 9 and above and will fall back to UIWebView on iOS 8.

The WKWebView plugin is only used by iOS, so ensure the `cordova-ios` platform is installed. Additionly, the `cordova-ios` platform version must be `4.0` or greater.

Installation Instructions
-------------------

Ensure the latest Cordova CLI is installed:  (Sudo may be required)

```
npm install cordova -g
```

Ensure the `ios` platform has been added:

```
ionic cordova platform ls
```

If the iOS platform is not listed, run the following command:

```
ionic cordova platform add ios
```

If the iOS platform is installed but the version is < `4.x`, run the following commands:

```
ionic cordova platform update ios
ionic cordova plugin save           # creates backup of existing plugins
rm -rf ./plugins            # delete plugins directory
ionic cordova prepare               # re-install plugins compatible with cordova-ios 4.x
```

Install the WKWebViewPlugin:

```
ionic cordova plugin add cordova-plugin-ionic-webview --save
```

**Note:**

If you already had [apache/cordova-plugin-wkwebview-engine](https://github.com/apache/cordova-plugin-wkwebview-engine) install make sure that is removed before using this version.

```
ionic cordova plugin rm cordova-plugin-wkwebview-engine
```


Build the platform:

```
ionic cordova prepare
```

Test the app on an iOS 9 or 10 device:

```
ionic cordova run ios
```


Required Permissions
-------------------
WKWebView may not fully launch (the deviceready event may not fire) unless if the following is included in config.xml:
#### config.xml

```xml
<allow-navigation href="http://localhost:8080/*"/>
<feature name="CDVWKWebViewEngine">
  <param name="ios-package" value="CDVWKWebViewEngine" />
</feature>

<preference name="CordovaWebViewEngine" value="CDVWKWebViewEngine" />
```

Bind hostname
--------------

By default, the server binds to "localhost" which becomes the hostname for the running app instance. To configure this, set `WKBind` to a different value.

For example, to use `127.0.0.1` instead of `localhost` (which may fix some VPN issues with MDM solutions, set this in your `config.xml`:

```xml
<preference name="WKBind" value="127.0.0.1" />
```

The plugin adds `127.0.0.1` as an allowed navigation by default, but if that's not working, set it manually using

```xml
<allow-navigation href="http://127.0.0.1:8080/*"/>
```


Webserver port
--------------
You can set the port that the built-in local webserver will listen on (default is 8080) using the "WKPort" preference.

If you change the port, be sure to also update your `<allow-navigation>` `href` attribute to match, as mentioned above in the Required Permissions section.

#### config.xml
```
<preference name="WKPort" value="12345" />
<allow-navigation href="http://localhost:12345/*"/>
```

Application Transport Security (ATS) in iOS 9
-----------

The next released version of the [cordova-cli 5.4.0](https://www.npmjs.com/package/cordova) will support automatic conversion of the [&lt;access&gt;](http://cordova.apache.org/docs/en/edge/guide/appdev/whitelist/index.html) tags in config.xml to Application Transport Security [ATS](https://developer.apple.com/library/prerelease/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW33) directives. Upgrade to the version 5.4.0 to use this new functionality.

Apple Issues
-------

The `AllowInlineMediaPlayback` preference will not work because of this [Apple bug](http://openradar.appspot.com/radar?id=6673091526656000). This bug [has been fixed](https://issues.apache.org/jira/browse/CB-11452) in [iOS 10](https://twitter.com/shazron/status/745546355796389889).

Limitations
--------

There are several [known issues](https://issues.apache.org/jira/issues/?jql=project%20%3D%20CB%20AND%20labels%20%3D%20wkwebview-known-issues) with the official Cordova WKWebView plugin. The Ionic team thinks we have resolved several of the major issues. Please [let us know](https://github.com/driftyco/cordova-plugin-wkwebview-engine/issues) if something isn't working as expected.

External API Endpoints
-------------------

If your app accesses external API endpoints, and you're using `ionic serve` with `proxyURL` configured in `ionic.config.json`, now is a good time to handle CORS issues as WKWebView won't allow you to access external API endpoints directly anymore like UIWebView.

Issues and solutions for working with CORS is explained in this [blog](http://blog.ionic.io/handling-cors-issues-in-ionic/), but unfortunately we can't ignore CORS anymore and now need to manage preflight checks by adding the following HTTP headers as a response to client requests on any external API endpoints:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Accept, Origin, Content-Type
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
```

The best way to troubleshoot any CORS external API endpoint configuration problems is by getting your app to work in the browser using `ionic serve` without `proxyURL` as you'll be able to see the header responses easily in common browser debug console and networking tools.
