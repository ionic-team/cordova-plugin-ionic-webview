/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import <Cordova/NSDictionary+CordovaPreferences.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "CDVWKWebViewEngine.h"
#import "CDVWKWebViewUIDelegate.h"
#import "CDVWKProcessPoolFactory.h"
#import "GCDWebServer.h"
#import "GCDWebServerPrivate.h"
#import "IONAssetHandler.h"

#define CDV_BRIDGE_NAME @"cordova"
#define CDV_IONIC_STOP_SCROLL @"stopScroll"
#define CDV_SERVER_PATH @"serverBasePath"
#define LAST_BINARY_VERSION_CODE @"lastBinaryVersionCode"
#define LAST_BINARY_VERSION_NAME @"lastBinaryVersionName"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000

@implementation UIScrollView (BugIOS11)

+ (void)load {
    if (@available(iOS 11.0, *)) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Class class = [self class];
            SEL originalSelector = @selector(init);
            SEL swizzledSelector = @selector(xxx_init);

            Method originalMethod = class_getInstanceMethod(class, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

            BOOL didAddMethod =
            class_addMethod(class,
                            originalSelector,
                            method_getImplementation(swizzledMethod),
                            method_getTypeEncoding(swizzledMethod));

            if (didAddMethod) {
                class_replaceMethod(class,
                                    swizzledSelector,
                                    method_getImplementation(originalMethod),
                                    method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        });
    }
}

#pragma mark - Method Swizzling

- (id)xxx_init {
    id a = [self xxx_init];
    if (@available(iOS 11.0, *)) {
        NSArray *stack = [NSThread callStackSymbols];
        for(NSString *trace in stack) {
            if([trace containsString:@"WebKit"]) {
                [a setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
                break;
            }
        }
    }
    return a;
}

@end

#endif


@interface CDVWKWeakScriptMessageHandler : NSObject <WKScriptMessageHandler>

@property (nonatomic, weak, readonly) id<WKScriptMessageHandler>scriptMessageHandler;

- (instancetype)initWithScriptMessageHandler:(id<WKScriptMessageHandler>)scriptMessageHandler;

@end


@interface CDVWKWebViewEngine ()

@property (nonatomic, strong, readwrite) UIView* engineWebView;
@property (nonatomic, strong, readwrite) id <WKUIDelegate> uiDelegate;
@property (nonatomic, weak) id <WKScriptMessageHandler> weakScriptMessageHandler;
@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, readwrite) CGRect frame;
@property (nonatomic, strong) NSString *userAgentCreds;
@property (nonatomic, assign) BOOL internalConnectionsOnly;
@property (nonatomic, assign) BOOL useScheme;
@property (nonatomic, strong) IONAssetHandler * handler;

@property (nonatomic, readwrite) NSString *CDV_LOCAL_SERVER;
@end

// expose private configuration value required for background operation
@interface WKWebViewConfiguration ()

@property (setter=_setAlwaysRunsAtForegroundPriority:, nonatomic) bool _alwaysRunsAtForegroundPriority;

@end


// see forwardingTargetForSelector: selector comment for the reason for this pragma
#pragma clang diagnostic ignored "-Wprotocol"

@implementation CDVWKWebViewEngine

@synthesize engineWebView = _engineWebView;

NSTimer *timer;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        if (NSClassFromString(@"WKWebView") == nil) {
            return nil;
        }
        if(!IsAtLeastiOSVersion(@"9.0")) {
            return nil;
        }

        // add to keyWindow to ensure it is 'active'
        [UIApplication.sharedApplication.keyWindow addSubview:self.engineWebView];

        self.frame = frame;
    }
    return self;
}

- (void)initWebServer
{
    [GCDWebServer setLogLevel: kGCDWebServerLoggingLevel_Warning];
    self.webServer = [[GCDWebServer alloc] init];

    [self updateBindPath];
    [self setServerPath:[self getStartPath]];

    [self startServer];
}

-(NSString *) getStartPath {
    NSString * wwwPath = [[NSBundle mainBundle] pathForResource:@"www" ofType: nil];

    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * persistedPath = [userDefaults objectForKey:CDV_SERVER_PATH];
    if (![self isDeployDisabled] && ![self isNewBinary] && persistedPath && ![persistedPath isEqualToString:@""]) {
        NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString * cordovaDataDirectory = [libPath stringByAppendingPathComponent:@"NoCloud"];
        NSString * snapshots = [cordovaDataDirectory stringByAppendingPathComponent:@"ionic_built_snapshots"];
        wwwPath = [snapshots stringByAppendingPathComponent:[persistedPath lastPathComponent]];
    }
    self.basePath = wwwPath;
    return wwwPath;
}

-(BOOL) isNewBinary
{
    NSString * versionCode = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    NSString * versionName = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
    NSString * lastVersionCode = [prefs stringForKey:LAST_BINARY_VERSION_CODE];
    NSString * lastVersionName = [prefs stringForKey:LAST_BINARY_VERSION_NAME];
    if (![versionCode isEqualToString:lastVersionCode] || ![versionName isEqualToString:lastVersionName]) {
        [prefs setObject:versionCode forKey:LAST_BINARY_VERSION_CODE];
        [prefs setObject:versionName forKey:LAST_BINARY_VERSION_NAME];
        [prefs setObject:@"" forKey:CDV_SERVER_PATH];
        [prefs synchronize];
        return YES;
    }
    return NO;
}

-(BOOL) isDeployDisabled {
    return [[self.commandDelegate.settings objectForKey:[@"DisableDeploy" lowercaseString]] boolValue];
}

-(void)updateBindPath
{
    NSDictionary * settings = self.commandDelegate.settings;
    //bind to designated hostname or default to localhost
    NSString *bind = [settings cordovaSettingForKey:@"WKBind"];
    if(bind == nil){
        bind = @"localhost";
    }

    //bind to designated port or default to 8080
    int portNumber = [settings cordovaFloatSettingForKey:@"WKPort" defaultValue:8080];

    //set the local server name
    self.CDV_LOCAL_SERVER = [NSString stringWithFormat:@"http://%@:%d", bind, portNumber];
}

-(void)startServer
{
    NSDictionary * settings = self.commandDelegate.settings;

    //bind to designated port or default to 8080
    int portNumber = [settings cordovaFloatSettingForKey:@"WKPort" defaultValue:8080];

    //enable suspend in background if set in config
    BOOL suspendInBackground = [settings cordovaBoolSettingForKey:@"WKSuspendInBackground" defaultValue:YES];
    int waitTime = 10;

    //extend default connection coalescing time when background enabled
    if(!suspendInBackground){
        NSLog(@"CDVWKWebViewEngine: Suspend in background disabled");
        waitTime = 60;
    }

    NSDictionary *options = @{
                              GCDWebServerOption_AutomaticallySuspendInBackground: @(suspendInBackground),
                              GCDWebServerOption_ConnectedStateCoalescingInterval: @(waitTime),
                              GCDWebServerOption_Port: @(portNumber),
                              GCDWebServerOption_BindToLocalhost: @(YES),
                              GCDWebServerOption_ServerName: @"Ionic"
                              };

    [self.webServer startWithOptions:options error:nil];
}

- (WKWebViewConfiguration*) createConfigurationFromSettings:(NSDictionary*)settings
{
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    configuration.processPool = [[CDVWKProcessPoolFactory sharedFactory] sharedProcessPool];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
    if(@available(iOS 10.0, *)) {
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    }else{
        configuration.mediaPlaybackRequiresUserAction = YES;
    }
#else
    configuration.mediaPlaybackRequiresUserAction = YES;
#endif

    if (settings == nil) {
        return configuration;
    }

    //required to stop wkwebview suspending in background too eagerly (as used in background mode plugin)
    configuration._alwaysRunsAtForegroundPriority = ![settings cordovaBoolSettingForKey:@"WKSuspendInBackground" defaultValue:YES];
    configuration.allowsInlineMediaPlayback = [settings cordovaBoolSettingForKey:@"AllowInlineMediaPlayback" defaultValue:YES];
    configuration.suppressesIncrementalRendering = [settings cordovaBoolSettingForKey:@"SuppressesIncrementalRendering" defaultValue:NO];
    configuration.allowsAirPlayForMediaPlayback = [settings cordovaBoolSettingForKey:@"MediaPlaybackAllowsAirPlay" defaultValue:YES];
    return configuration;
}

- (void)pluginInitialize
{
    // viewController would be available now. we attempt to set all possible delegates to it, by default
    NSDictionary* settings = self.commandDelegate.settings;
    if (@available(iOS 11.0, *)) {
        self.useScheme = [settings cordovaBoolSettingForKey:@"UseScheme" defaultValue:NO];
    } else {
        self.useScheme = NO;
    }

    self.internalConnectionsOnly = [settings cordovaBoolSettingForKey:@"WKInternalConnectionsOnly" defaultValue:YES];
    if (self.useScheme) {
        NSString *bind = [settings cordovaSettingForKey:@"HostName"];
        if(bind == nil){
            bind = @"app";
        }
        self.CDV_LOCAL_SERVER = [NSString stringWithFormat:@"ionic://%@", bind];
    } else {
        [self initWebServer];
    }

    self.uiDelegate = [[CDVWKWebViewUIDelegate alloc] initWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];

    CDVWKWeakScriptMessageHandler *weakScriptMessageHandler = [[CDVWKWeakScriptMessageHandler alloc] initWithScriptMessageHandler:self];

    WKUserContentController* userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:weakScriptMessageHandler name:CDV_BRIDGE_NAME];
    [userContentController addScriptMessageHandler:weakScriptMessageHandler name:CDV_IONIC_STOP_SCROLL];

    // Inject XHR Polyfill
    NSLog(@"CDVWKWebViewEngine: trying to inject XHR polyfill");
    WKUserScript *wkScript = [self wkPluginScript];
    if (wkScript) {
        [userContentController addUserScript:wkScript];
    }

    WKUserScript *configScript = [self configScript];
    if (configScript) {
        [userContentController addUserScript:configScript];
    }

    BOOL autoCordova = [settings cordovaBoolSettingForKey:@"AutoInjectCordova" defaultValue:NO];
    if (autoCordova){
        NSLog(@"CDVWKWebViewEngine: trying to inject XHR polyfill");
        WKUserScript *cordova = [self autoCordovify];
        if (cordova) {
            [userContentController addUserScript:cordova];
        }
    }

    BOOL audioCanMix = [settings cordovaBoolSettingForKey:@"AudioCanMix" defaultValue:NO];
    if (audioCanMix) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                         withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                               error:nil];
    }

    WKWebViewConfiguration* configuration = [self createConfigurationFromSettings:settings];
    configuration.userContentController = userContentController;

    if (@available(iOS 11.0, *)) {
        if (self.useScheme) {
            self.handler = [[IONAssetHandler alloc] init];
            [self.handler setAssetPath:[self getStartPath]];
            [configuration setURLSchemeHandler:self.handler forURLScheme:@"ionic"];
            [configuration setURLSchemeHandler:self.handler forURLScheme:@"ionic-asset"];
        }
    }

    // re-create WKWebView, since we need to update configuration
    // remove from keyWindow before recreating
    [self.engineWebView removeFromSuperview];
    WKWebView* wkWebView = [[WKWebView alloc] initWithFrame:self.frame configuration:configuration];

    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
    if (@available(iOS 11.0, *)) {
      [wkWebView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    }
    #endif

    wkWebView.UIDelegate = self.uiDelegate;
    self.engineWebView = wkWebView;
    // add to keyWindow to ensure it is 'active'
    [UIApplication.sharedApplication.keyWindow addSubview:self.engineWebView];

    if (IsAtLeastiOSVersion(@"9.0") && [self.viewController isKindOfClass:[CDVViewController class]]) {
        wkWebView.customUserAgent = ((CDVViewController*) self.viewController).userAgent;
    }
    if (self.internalConnectionsOnly) {
        wkWebView.customUserAgent = [NSString stringWithFormat:@"%@/%@",wkWebView.customUserAgent, [self getUserAgentCredentials]];
    }

    if ([self.viewController conformsToProtocol:@protocol(WKUIDelegate)]) {
        wkWebView.UIDelegate = (id <WKUIDelegate>)self.viewController;
    }

    if ([self.viewController conformsToProtocol:@protocol(WKNavigationDelegate)]) {
        wkWebView.navigationDelegate = (id <WKNavigationDelegate>)self.viewController;
    } else {
        wkWebView.navigationDelegate = (id <WKNavigationDelegate>)self;
    }

    if ([self.viewController conformsToProtocol:@protocol(WKScriptMessageHandler)]) {
        [wkWebView.configuration.userContentController addScriptMessageHandler:(id < WKScriptMessageHandler >)self.viewController name:CDV_BRIDGE_NAME];
    }

    //if (![settings cordovaBoolSettingForKey:@"KeyboardDisplayRequiresUserAction" defaultValue:NO]) {
    [self keyboardDisplayDoesNotRequireUserAction];
    //}

    if ([settings cordovaBoolSettingForKey:@"KeyboardAppearanceDark" defaultValue:NO]) {
        [self setKeyboardAppearanceDark];
    }

    [self updateSettings:settings];

    // check if content thread has died on resume
    NSLog(@"%@", @"CDVWKWebViewEngine will reload WKWebView if required on resume");
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(onAppWillEnterForeground:)
     name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(onSocketError:)
     name:@"socketUnknownError" object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(onSocketError:)
     name:@"socketInUseError" object:nil];

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(keyboardWillHide)
     name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(keyboardWillShow)
     name:UIKeyboardWillShowNotification object:nil];


    NSLog(@"Using Ionic WKWebView");

    [self addURLObserver];
}

// https://github.com/Telerik-Verified-Plugins/WKWebView/commit/04e8296adeb61f289f9c698045c19b62d080c7e3#L609-L620
- (void) keyboardDisplayDoesNotRequireUserAction {
    Class class = NSClassFromString(@"WKContentView");
    NSOperatingSystemVersion iOS_11_3_0 = (NSOperatingSystemVersion){11, 3, 0};

    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_11_3_0]) {
        SEL selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:");
        Method method = class_getInstanceMethod(class, selector);
        IMP original = method_getImplementation(method);
        IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, BOOL arg3, id arg4) {
            ((void (*)(id, SEL, void*, BOOL, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3, arg4);
        });
        method_setImplementation(method, override);
    } else {
        SEL selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:");
        Method method = class_getInstanceMethod(class, selector);
        IMP original = method_getImplementation(method);
        IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, id arg3) {
            ((void (*)(id, SEL, void*, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3);
        });
        method_setImplementation(method, override);
    }
}

- (NSString*)getUserAgentCredentials {
    if (self.userAgentCreds == nil) {
        self.userAgentCreds = [self generateRandomString:32];
    }
    return self.userAgentCreds;
}

- (NSString*)generateRandomString:(int)num {
    NSMutableString* string = [NSMutableString stringWithCapacity:num];
    for (int i = 0; i < num; i++) {
        [string appendFormat:@"%C", (unichar)('a' + arc4random_uniform(26))];
    }
    return string;
}

- (void)setKeyboardAppearanceDark
{
    IMP darkImp = imp_implementationWithBlock(^(id _s) {
        return UIKeyboardAppearanceDark;
    });
    for (NSString* classString in @[@"WKContentView", @"UITextInputTraits"]) {
        Class c = NSClassFromString(classString);
        Method m = class_getInstanceMethod(c, @selector(keyboardAppearance));
        if (m != NULL) {
            method_setImplementation(m, darkImp);
        } else {
            class_addMethod(c, @selector(keyboardAppearance), darkImp, "l@:");
        }
    }
}

- (void)onReset
{
    [self addURLObserver];
}

static void * KVOContext = &KVOContext;

- (void)addURLObserver
{
    if(!IsAtLeastiOSVersion(@"9.0")){
        [self.webView addObserver:self forKeyPath:@"URL" options:0 context:KVOContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == KVOContext) {
        if (object == [self webView] && [keyPath isEqualToString: @"URL"] && [object valueForKeyPath:keyPath] == nil){
            NSLog(@"URL is nil. Reloading WKWebView");
            if ([self isSafeToReload]) {
                [(WKWebView*)_engineWebView reload];
            } else {
                [self loadErrorPage:nil];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)onAppWillEnterForeground:(NSNotification *)notification {
    if ([self shouldReloadWebView]) {
        if ([self isSafeToReload]) {
            NSLog(@"%@", @"CDVWKWebViewEngine reloading!");
            [(WKWebView*)_engineWebView reload];
        } else {
            [self loadErrorPage:nil];
        }
    }
}


-(void)keyboardWillHide
{
    if (@available(iOS 12.0, *)) {
        timer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(keyboardDisplacementFix) userInfo:nil repeats:false];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
}

-(void)keyboardWillShow
{
    if (timer != nil) {
        [timer invalidate];
    }
}

-(void)keyboardDisplacementFix
{
    // https://stackoverflow.com/a/9637807/824966
    [UIView animateWithDuration:.25 animations:^{
        self.webView.scrollView.contentOffset = CGPointMake(0, 0);
    }];

}

- (void)onSocketError:(NSNotification *)notification {
    [self loadErrorPage:nil];
}

- (BOOL)shouldReloadWebView
{
    WKWebView* wkWebView = (WKWebView*)_engineWebView;
    return [self shouldReloadWebView:wkWebView.URL title:wkWebView.title];
}

- (BOOL)isSafeToReload
{
    return [self.webServer isRunning] || self.useScheme;
}

- (BOOL)shouldReloadWebView:(NSURL *)location title:(NSString*)title
{
    BOOL title_is_nil = (title == nil);
    BOOL location_is_blank = [[location absoluteString] isEqualToString:@"about:blank"];

    BOOL reload = (title_is_nil || location_is_blank);

#ifdef DEBUG
    NSLog(@"%@", @"CDVWKWebViewEngine shouldReloadWebView::");
    NSLog(@"CDVWKWebViewEngine shouldReloadWebView title: %@", title);
    NSLog(@"CDVWKWebViewEngine shouldReloadWebView location: %@", [location absoluteString]);
    NSLog(@"CDVWKWebViewEngine shouldReloadWebView reload: %u", reload);
#endif

    return reload;
}


- (id)loadRequest:(NSURLRequest *)request
{
    if (request.URL.fileURL) {
        NSURL* startURL = [NSURL URLWithString:((CDVViewController *)self.viewController).startPage];
        NSString* startFilePath = [self.commandDelegate pathForResource:[startURL path]];
        NSURL *url = [[NSURL URLWithString:self.CDV_LOCAL_SERVER] URLByAppendingPathComponent:request.URL.path];
        if ([request.URL.path isEqualToString:startFilePath]) {
            url = [NSURL URLWithString:self.CDV_LOCAL_SERVER];
        }
        if(request.URL.query) {
            url = [NSURL URLWithString:[@"?" stringByAppendingString:request.URL.query] relativeToURL:url];
        }
        if(request.URL.fragment) {
            url = [NSURL URLWithString:[@"#" stringByAppendingString:request.URL.fragment] relativeToURL:url];
        }
        request = [NSURLRequest requestWithURL:url];
    }
    if ([self isSafeToReload]) {
        return [(WKWebView*)_engineWebView loadRequest:request];
    } else {
        return [self loadErrorPage:request];
    }
}

- (id)loadErrorPage:(NSURLRequest *)request
{
    if (!request) {
        request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.CDV_LOCAL_SERVER]];
    }
    NSString* errorHtml = [NSString stringWithFormat:
                           @"<html>"
                           @"<head><title>Error</title></head>"
                           @"   <div style='font-size:2em'>"
                           @"       <p><b>Error</b></p>"
                           @"       <p>Unable to load app.</p>"
                           @"   </div>"
                           @"</html>"
                           ];
    return [self loadHTMLString:errorHtml baseURL:request.URL];
}

- (id)loadHTMLString:(NSString *)string baseURL:(NSURL*)baseURL
{
    return [(WKWebView*)_engineWebView loadHTMLString:string baseURL:baseURL];
}

- (NSURL*) URL
{
    return [(WKWebView*)_engineWebView URL];
}

- (BOOL)canLoadRequest:(NSURLRequest *)request
{
    return TRUE;
}

- (void)updateSettings:(NSDictionary *)settings
{
    WKWebView* wkWebView = (WKWebView *)_engineWebView;

    // By default, DisallowOverscroll is false (thus bounce is allowed)
    BOOL bounceAllowed = !([settings cordovaBoolSettingForKey:@"DisallowOverscroll" defaultValue:NO]);

    // prevent webView from bouncing
    if (!bounceAllowed) {
        if ([wkWebView respondsToSelector:@selector(scrollView)]) {
            ((UIScrollView*)[wkWebView scrollView]).bounces = NO;
        } else {
            for (id subview in wkWebView.subviews) {
                if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
                    ((UIScrollView*)subview).bounces = NO;
                }
            }
        }
    }

    wkWebView.configuration.preferences.minimumFontSize = [settings cordovaFloatSettingForKey:@"MinimumFontSize" defaultValue:0.0];
    wkWebView.allowsLinkPreview = [settings cordovaBoolSettingForKey:@"AllowLinkPreview" defaultValue:NO];
    wkWebView.scrollView.scrollEnabled = [settings cordovaBoolSettingForKey:@"ScrollEnabled" defaultValue:NO];
    wkWebView.allowsBackForwardNavigationGestures = [settings cordovaBoolSettingForKey:@"AllowBackForwardNavigationGestures" defaultValue:NO];
}

- (void)updateWithInfo:(NSDictionary *)info
{
    NSDictionary* scriptMessageHandlers = [info objectForKey:kCDVWebViewEngineScriptMessageHandlers];
    NSDictionary* settings = [info objectForKey:kCDVWebViewEngineWebViewPreferences];
    id navigationDelegate = [info objectForKey:kCDVWebViewEngineWKNavigationDelegate];
    id uiDelegate = [info objectForKey:kCDVWebViewEngineWKUIDelegate];

    WKWebView* wkWebView = (WKWebView*)_engineWebView;

    if (scriptMessageHandlers && [scriptMessageHandlers isKindOfClass:[NSDictionary class]]) {
        NSArray* allKeys = [scriptMessageHandlers allKeys];

        for (NSString* key in allKeys) {
            id object = [scriptMessageHandlers objectForKey:key];
            if ([object conformsToProtocol:@protocol(WKScriptMessageHandler)]) {
                [wkWebView.configuration.userContentController addScriptMessageHandler:object name:key];
            }
        }
    }

    if (navigationDelegate && [navigationDelegate conformsToProtocol:@protocol(WKNavigationDelegate)]) {
        wkWebView.navigationDelegate = navigationDelegate;
    }

    if (uiDelegate && [uiDelegate conformsToProtocol:@protocol(WKUIDelegate)]) {
        wkWebView.UIDelegate = uiDelegate;
    }

    if (settings && [settings isKindOfClass:[NSDictionary class]]) {
        [self updateSettings:settings];
    }
}

// This forwards the methods that are in the header that are not implemented here.
// Both WKWebView and UIWebView implement the below:
//     loadHTMLString:baseURL:
//     loadRequest:
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return _engineWebView;
}

- (UIView *)webView
{
    return self.engineWebView;
}

- (WKUserScript *)wkPluginScript
{
    NSString *scriptFile = [[NSBundle mainBundle] pathForResource:@"www/wk-plugin" ofType:@"js"];
    if (scriptFile == nil) {
        NSLog(@"CDVWKWebViewEngine: WK plugin was not found");
        return nil;
    }
    NSError *error = nil;
    NSString *source = [NSString stringWithContentsOfFile:scriptFile encoding:NSUTF8StringEncoding error:&error];
    if (source == nil || error != nil) {
        NSLog(@"CDVWKWebViewEngine: WK plugin can not be loaded: %@", error);
        return nil;
    }
    source = [source stringByAppendingString:[NSString stringWithFormat:@"window.WEBVIEW_SERVER_URL = '%@';", self.CDV_LOCAL_SERVER]];

    return [[WKUserScript alloc] initWithSource:source
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                               forMainFrameOnly:YES];
}

- (WKUserScript *)configScript
{
    Class keyboard = NSClassFromString(@"CDVIonicKeyboard");
    BOOL keyboardPlugin = keyboard != nil;
    if(!keyboardPlugin) {
        return nil;
    }

    BOOL keyboardResizes = [self.commandDelegate.settings cordovaBoolSettingForKey:@"KeyboardResize" defaultValue:YES];
    NSString *source = [NSString stringWithFormat:
                        @"window.Ionic = window.Ionic || {};"
                        @"window.Ionic.keyboardPlugin=true;"
                        @"window.Ionic.keyboardResizes=%@",
                        keyboardResizes ? @"true" : @"false"];

    return [[WKUserScript alloc] initWithSource:source
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                               forMainFrameOnly:YES];
}

- (WKUserScript *)autoCordovify
{
    NSURL *cordovaURL = [[NSBundle mainBundle] URLForResource:@"www/cordova" withExtension:@"js"];
    if (cordovaURL == nil) {
        NSLog(@"CDVWKWebViewEngine: cordova.js WAS NOT FOUND");
        return nil;
    }
    NSError *error = nil;
    NSString *source = [NSString stringWithContentsOfURL:cordovaURL encoding:NSUTF8StringEncoding error:&error];
    if (source == nil || error != nil) {
        NSLog(@"CDVWKWebViewEngine: cordova.js can not be loaded: %@", error);
        return nil;
    }
    NSLog(@"CDVWKWebViewEngine: auto injecting cordova");
    NSString *cordovaPath = [self.CDV_LOCAL_SERVER stringByAppendingString:cordovaURL.URLByDeletingLastPathComponent.path];
    NSString *replacement = [NSString stringWithFormat:@"var pathPrefix = '%@/';", cordovaPath];
    source = [source stringByReplacingOccurrencesOfString:@"var pathPrefix = findCordovaPath();" withString:replacement];

    return [[WKUserScript alloc] initWithSource:source
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                               forMainFrameOnly:YES];
}

#pragma mark WKScriptMessageHandler implementation

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:CDV_BRIDGE_NAME]) {
        [self handleCordovaMessage: message];
    } else if ([message.name isEqualToString:CDV_IONIC_STOP_SCROLL]) {
        [self handleStopScroll];
    }
}

- (void)handleCordovaMessage:(WKScriptMessage*)message
{
    CDVViewController *vc = (CDVViewController*)self.viewController;

    NSArray *jsonEntry = message.body; // NSString:callbackId, NSString:service, NSString:action, NSArray:args
    CDVInvokedUrlCommand* command = [CDVInvokedUrlCommand commandFromJson:jsonEntry];
    CDV_EXEC_LOG(@"Exec(%@): Calling %@.%@", command.callbackId, command.className, command.methodName);

    if (![vc.commandQueue execute:command]) {
#ifdef DEBUG
        NSError* error = nil;
        NSString* commandJson = nil;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonEntry
                                                           options:0
                                                             error:&error];

        if (error == nil) {
            commandJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }

        static NSUInteger maxLogLength = 1024;
        NSString* commandString = ([commandJson length] > maxLogLength) ?
        [NSString stringWithFormat : @"%@[...]", [commandJson substringToIndex:maxLogLength]] :
        commandJson;

        NSLog(@"FAILED pluginJSON = %@", commandString);
#endif
    }
}

- (void)handleStopScroll
{
    WKWebView* wkWebView = (WKWebView*)_engineWebView;
    NSLog(@"CDVWKWebViewEngine: handleStopScroll");
    [self recursiveStopScroll:[wkWebView scrollView]];
    [wkWebView evaluateJavaScript:@"window.IonicStopScroll.fire()" completionHandler:nil];
}

- (void)recursiveStopScroll:(UIView *)node
{
    if([node isKindOfClass: [UIScrollView class]]) {
        UIScrollView *nodeAsScroll = (UIScrollView *)node;

        if([nodeAsScroll isScrollEnabled] && ![nodeAsScroll isHidden]) {
            [nodeAsScroll setScrollEnabled: NO];
            [nodeAsScroll setScrollEnabled: YES];
        }
    }

    // iterate tree recursivelly
    for (UIView *child in [node subviews]) {
        [self recursiveStopScroll:child];
    }
}


#pragma mark WKNavigationDelegate implementation

- (void)webView:(WKWebView*)webView didStartProvisionalNavigation:(WKNavigation*)navigation
{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginResetNotification object:webView]];
}

- (void)webView:(WKWebView*)webView didFinishNavigation:(WKNavigation*)navigation
{
    CDVViewController* vc = (CDVViewController*)self.viewController;
    [CDVUserAgentUtil releaseLock:vc.userAgentLockToken];

    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPageDidLoadNotification object:webView]];
}

- (void)webView:(WKWebView*)theWebView didFailProvisionalNavigation:(WKNavigation*)navigation withError:(NSError*)error
{
    [self webView:theWebView didFailNavigation:navigation withError:error];
}

- (void)webView:(WKWebView*)theWebView didFailNavigation:(WKNavigation*)navigation withError:(NSError*)error
{
    CDVViewController* vc = (CDVViewController*)self.viewController;
    [CDVUserAgentUtil releaseLock:vc.userAgentLockToken];

    NSString* message = [NSString stringWithFormat:@"Failed to load webpage with error: %@", [error localizedDescription]];
    NSLog(@"%@", message);

    NSURL* errorUrl = vc.errorURL;
    if (errorUrl) {
        errorUrl = [NSURL URLWithString:[NSString stringWithFormat:@"?error=%@", [message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] relativeToURL:errorUrl];
        NSLog(@"%@", [errorUrl absoluteString]);
        [theWebView loadRequest:[NSURLRequest requestWithURL:errorUrl]];
    }
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    if ([self isSafeToReload]) {
        [webView reload];
    } else {
        [self loadErrorPage:nil];
    }
}

- (BOOL)defaultResourcePolicyForURL:(NSURL*)url
{
    // all file:// urls are allowed
    if ([url isFileURL]) {
        return YES;
    }

    return NO;
}

- (void) webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction*)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL* url = [navigationAction.request URL];
    CDVViewController* vc = (CDVViewController*)self.viewController;

    /*
     * Give plugins the chance to handle the url
     */
    BOOL anyPluginsResponded = NO;
    BOOL shouldAllowRequest = NO;

    for (NSString* pluginName in vc.pluginObjects) {
        CDVPlugin* plugin = [vc.pluginObjects objectForKey:pluginName];
        SEL selector = NSSelectorFromString(@"shouldOverrideLoadWithRequest:navigationType:");
        if ([plugin respondsToSelector:selector]) {
            anyPluginsResponded = YES;
            // https://issues.apache.org/jira/browse/CB-12497
            int navType = (int)navigationAction.navigationType;
            if (WKNavigationTypeOther == navigationAction.navigationType) {
                navType = (int)UIWebViewNavigationTypeOther;
            }
            shouldAllowRequest = (((BOOL (*)(id, SEL, id, int))objc_msgSend)(plugin, selector, navigationAction.request, navType));
            if (!shouldAllowRequest) {
                break;
            }
        }
    }

    if (!anyPluginsResponded) {
        /*
         * Handle all other types of urls (tel:, sms:), and requests to load a url in the main webview.
         */
        shouldAllowRequest = [self defaultResourcePolicyForURL:url];
        if (!shouldAllowRequest) {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
        }
    }

    if (shouldAllowRequest) {
        NSString *scheme = url.scheme;
        if ([scheme isEqualToString:@"tel"] ||
            [scheme isEqualToString:@"mailto"] ||
            [scheme isEqualToString:@"facetime"] ||
            [scheme isEqualToString:@"sms"] ||
            [scheme isEqualToString:@"maps"] ||
            [scheme isEqualToString:@"itms-services"]) {
            [[UIApplication sharedApplication] openURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
        } else {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

-(void)getServerBasePath:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:self.basePath]  callbackId:command.callbackId];
}

-(void)setServerBasePath:(CDVInvokedUrlCommand*)command
{
    NSString * path = [command argumentAtIndex:0];
    if (self.useScheme) {
        self.basePath = path;
        [self.handler setAssetPath:path];
    } else {
        [self setServerPath:path];
    }

    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.CDV_LOCAL_SERVER]];
    if ([self isSafeToReload]) {
        [(WKWebView*)_engineWebView loadRequest:request];
    } else {
        [self loadErrorPage:request];
    }
}

-(void)setServerPath:(NSString *) path
{
    self.basePath = path;
    BOOL restart = [self.webServer isRunning];
    if (restart) {
        [self.webServer stop];
    }

    __block NSString* serverUrl = self.CDV_LOCAL_SERVER;
    if (self.internalConnectionsOnly) {
        [self internalConnectionsGetHandlerForPath:path];
    } else {
        [self.webServer addGETHandlerForBasePath:@"/" directoryPath:path indexFilename:((CDVViewController *)self.viewController).startPage cacheAge:0 allowRangeRequests:YES];
    }
    [self.webServer addHandlerForMethod:@"GET" pathRegex:@"_file_/" requestClass:GCDWebServerFileRequest.class asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
        NSString *urlToRemove = [serverUrl stringByAppendingString:@"/_file_"];
        NSString *absUrl = [[[request URL] absoluteString] stringByReplacingOccurrencesOfString:urlToRemove withString:@""];

        NSRange range = [absUrl rangeOfString:@"?"];
        if (range.location != NSNotFound) {
            absUrl = [absUrl substringToIndex:range.location];
        }
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:absUrl]) {
            GCDWebServerResponse* response = [GCDWebServerResponse responseWithStatusCode:kGCDWebServerHTTPStatusCode_NotFound];
            completionBlock(response);
        } else {
            GCDWebServerFileResponse *response = [GCDWebServerFileResponse responseWithFile:absUrl byteRange:request.byteRange];
            [response setValue:@"bytes" forAdditionalHeader:@"Accept-Ranges"];
            completionBlock(response);
        }
    }];
    if (restart) {
        [self startServer];
    }
}

-(void) internalConnectionsGetHandlerForPath:(NSString*)directoryPath {
    __weak CDVWKWebViewEngine * weakSelf = self;
    [self.webServer addHandlerWithMatchBlock:^GCDWebServerRequest*(NSString* requestMethod, NSURL* requestURL, NSDictionary* requestHeaders, NSString* urlPath, NSDictionary* urlQuery) {
        if (![requestMethod isEqualToString:@"GET"]) {
            return nil;
        }
        return [[GCDWebServerRequest alloc] initWithMethod:requestMethod url:requestURL headers:requestHeaders path:urlPath query:urlQuery];
    }
    processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
        GCDWebServerResponse* response = nil;
        NSString* userAgent = [request.headers objectForKey:@"User-Agent"];
        if ([userAgent containsString:[weakSelf getUserAgentCredentials]]) {
            NSString* filePath = [directoryPath stringByAppendingPathComponent:[request.path substringFromIndex:1]];
            NSString* fileType = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL] fileType];
            if (fileType) {
                if ([fileType isEqualToString:NSFileTypeDirectory]) {
                    NSString* indexPath = [filePath stringByAppendingPathComponent:((CDVViewController *)weakSelf.viewController).startPage];
                    NSString* indexType = [[[NSFileManager defaultManager] attributesOfItemAtPath:indexPath error:NULL] fileType];
                    if ([indexType isEqualToString:NSFileTypeRegular]) {
                        response = [GCDWebServerFileResponse responseWithFile:indexPath];
                    }
                } else if ([fileType isEqualToString:NSFileTypeRegular]) {
                    response = [GCDWebServerFileResponse responseWithFile:filePath byteRange:request.byteRange];
                    [response setValue:@"bytes" forAdditionalHeader:@"Accept-Ranges"];
                }
            }
            if (response) {
                response.cacheControlMaxAge = 0;
            } else {
                response = [GCDWebServerResponse responseWithStatusCode:kGCDWebServerHTTPStatusCode_NotFound];
            }
            [response setValue:@"*" forAdditionalHeader:@"Access-Control-Allow-Origin"];
        } else {
            response = [GCDWebServerResponse responseWithStatusCode:kGCDWebServerHTTPStatusCode_Unauthorized];
        }
        return response;
    }];
}

-(void)persistServerBasePath:(CDVInvokedUrlCommand*)command
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[self.basePath lastPathComponent] forKey:CDV_SERVER_PATH];
    [userDefaults synchronize];
}

@end

#pragma mark - CDVWKWeakScriptMessageHandler

@implementation CDVWKWeakScriptMessageHandler

- (instancetype)initWithScriptMessageHandler:(id<WKScriptMessageHandler>)scriptMessageHandler
{
    self = [super init];
    if (self) {
        _scriptMessageHandler = scriptMessageHandler;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    [self.scriptMessageHandler userContentController:userContentController didReceiveScriptMessage:message];
}

@end
