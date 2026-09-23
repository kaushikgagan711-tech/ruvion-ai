#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

// The desktop edition talks to its guarded local RUVION service. Provider
// credentials stay outside the app and people using RUVION never enter a key.
static NSString *const RUVIONAPIURL = @"http://127.0.0.1:18766/v1/chat";

@interface ProfileBridge : NSObject <WKScriptMessageHandler>
@property (nonatomic, strong) NSURL *profileURL;
@end

@interface WorkBridge : NSObject <WKScriptMessageHandler>
@property (nonatomic, weak) WKWebView *webView;
@end

@implementation ProfileBridge
- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"ruvionProfile"] || ![message.body isKindOfClass:NSString.class]) return;
    NSData *input = [(NSString *)message.body dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id parsed = [NSJSONSerialization JSONObjectWithData:input options:0 error:&error];
    if (error || ![parsed isKindOfClass:NSDictionary.class]) return;
    NSDictionary *incoming = parsed;
    NSString *profileID = [incoming[@"profileId"] isKindOfClass:NSString.class] ? incoming[@"profileId"] : @"";
    NSString *displayName = [incoming[@"displayName"] isKindOfClass:NSString.class] ? incoming[@"displayName"] : @"";
    if (profileID.length == 0 || profileID.length > 160 || displayName.length == 0 || displayName.length > 80) return;
    NSDictionary *safeProfile = @{
        @"profileId": profileID,
        @"displayName": [displayName stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet],
        @"onboardingComplete": @YES
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:safeProfile options:NSJSONWritingPrettyPrinted error:&error];
    if (data && !error) [data writeToURL:self.profileURL options:NSDataWritingAtomic error:nil];
}
@end

@implementation WorkBridge
- (void)sendResult:(NSDictionary *)result requestID:(NSString *)requestID {
    NSData *data = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"{}";
    NSString *safeID = [requestID stringByReplacingOccurrencesOfString:@"'" withString:@"\\\\'"];
    NSString *script = [NSString stringWithFormat:@"window.__ruvionWorkResult && window.__ruvionWorkResult('%@',%@);", safeID, json];
    dispatch_async(dispatch_get_main_queue(), ^{ [self.webView evaluateJavaScript:script completionHandler:nil]; });
}
- (NSURL *)projectsRoot {
    NSURL *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    return [documents URLByAppendingPathComponent:@"RUVION Projects" isDirectory:YES];
}
- (BOOL)isInsideProjects:(NSURL *)url {
    NSString *root = self.projectsRoot.standardizedURL.path;
    NSString *path = url.standardizedURL.path;
    return [path isEqualToString:root] || [path hasPrefix:[root stringByAppendingString:@"/"]];
}
- (void)confirm:(NSString *)message completion:(void (^)(BOOL))completion {
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Allow RUVION Work Mode to make this change?";
    alert.informativeText = message;
    [alert addButtonWithTitle:@"Allow"]; [alert addButtonWithTitle:@"Cancel"];
    dispatch_async(dispatch_get_main_queue(), ^{ completion([alert runModal] == NSAlertFirstButtonReturn); });
}
- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"ruvionWork"] || ![message.body isKindOfClass:NSDictionary.class]) return;
    NSDictionary *body = message.body;
    NSString *requestID = [body[@"id"] isKindOfClass:NSString.class] ? body[@"id"] : @"";
    NSString *action = [body[@"action"] isKindOfClass:NSString.class] ? body[@"action"] : @"";
    if (requestID.length == 0) return;
    if ([action isEqualToString:@"openApp"]) {
        NSString *bundleID = [body[@"bundleID"] isKindOfClass:NSString.class] ? body[@"bundleID"] : @"";
        NSSet *allowed = [NSSet setWithArray:@[@"com.apple.TextEdit", @"com.apple.dt.Xcode", @"com.apple.Safari", @"com.google.Chrome", @"com.apple.Terminal", @"com.apple.finder"]];
        if (![allowed containsObject:bundleID]) { [self sendResult:@{@"ok": @NO, @"error": @"That app is not in RUVION's safe Work Mode list."} requestID:requestID]; return; }
        NSURL *url = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:bundleID];
        if (!url) { [self sendResult:@{@"ok": @NO, @"error": @"RUVION could not find that app."} requestID:requestID]; return; }
        [NSWorkspace.sharedWorkspace openApplicationAtURL:url configuration:[NSWorkspaceOpenConfiguration new] completionHandler:^(NSRunningApplication *app, NSError *error) {
            [self sendResult:error ? @{@"ok": @NO, @"error": error.localizedDescription ?: @"RUVION could not open that app."} : @{@"ok": @YES, @"message": @"App opened."} requestID:requestID];
        }];
        return;
    }
    if ([action isEqualToString:@"writeFile"]) {
        NSString *relative = [body[@"relativePath"] isKindOfClass:NSString.class] ? body[@"relativePath"] : @"";
        NSString *content = [body[@"content"] isKindOfClass:NSString.class] ? body[@"content"] : @"";
        NSURL *url = [self.projectsRoot URLByAppendingPathComponent:relative];
        if (relative.length == 0 || [relative containsString:@".."] || ![self isInsideProjects:url]) { [self sendResult:@{@"ok": @NO, @"error": @"Files may only be written inside Documents/RUVION Projects."} requestID:requestID]; return; }
        [self confirm:[NSString stringWithFormat:@"Create or replace %@ inside your RUVION Projects folder?", relative] completion:^(BOOL allowed) {
            if (!allowed) { [self sendResult:@{@"ok": @NO, @"cancelled": @YES} requestID:requestID]; return; }
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtURL:[url URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
            BOOL ok = error == nil && [content writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error];
            [self sendResult:ok ? @{@"ok": @YES, @"message": @"File written."} : @{@"ok": @NO, @"error": error.localizedDescription ?: @"Could not write the file."} requestID:requestID];
        }];
        return;
    }
    if ([action isEqualToString:@"buildProject"]) {
        NSString *relative = [body[@"relativePath"] isKindOfClass:NSString.class] ? body[@"relativePath"] : @"";
        NSURL *project = [self.projectsRoot URLByAppendingPathComponent:relative];
        if (relative.length == 0 || [relative containsString:@".."] || ![self isInsideProjects:project] || ![project.pathExtension.lowercaseString isEqualToString:@"xcodeproj"]) { [self sendResult:@{@"ok": @NO, @"error": @"Builds are limited to an .xcodeproj inside Documents/RUVION Projects."} requestID:requestID]; return; }
        [self confirm:[NSString stringWithFormat:@"Run an Xcode build for %@?", relative] completion:^(BOOL allowed) {
            if (!allowed) { [self sendResult:@{@"ok": @NO, @"cancelled": @YES} requestID:requestID]; return; }
            NSTask *task = [NSTask new]; task.launchPath = @"/usr/bin/xcodebuild"; task.arguments = @[@"-project", project.path, @"-configuration", @"Debug", @"build"];
            NSPipe *pipe = [NSPipe pipe]; task.standardOutput = pipe; task.standardError = pipe;
            @try { [task launch]; [task waitUntilExit]; NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile]; NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @""; NSString *tail = output.length > 5000 ? [output substringFromIndex:output.length - 5000] : output; [self sendResult:task.terminationStatus == 0 ? @{@"ok": @YES, @"message": @"Build completed.", @"output": tail} : @{@"ok": @NO, @"error": @"Xcode build failed.", @"output": tail} requestID:requestID]; } @catch (NSException *exception) { [self sendResult:@{@"ok": @NO, @"error": exception.reason ?: @"Could not run Xcode build."} requestID:requestID]; }
        }];
        return;
    }
    [self sendResult:@{@"ok": @NO, @"error": @"Unknown Work Mode action."} requestID:requestID];
}
@end

@interface AppDelegate : NSObject <NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) ProfileBridge *profileBridge;
@property (nonatomic, strong) WorkBridge *workBridge;
@end

@implementation AppDelegate

- (NSURL *)profileURL {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSURL *base = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *directory = [base URLByAppendingPathComponent:@"RUVION" isDirectory:YES];
    [fm createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions: @0700} error:nil];
    return [directory URLByAppendingPathComponent:@"profile.json"];
}

- (NSDictionary *)loadProfileAtURL:(NSURL *)url {
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (!data) return @{@"profileId": @"", @"displayName": @"", @"onboardingComplete": @NO};
    id value = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![value isKindOfClass:NSDictionary.class]) return @{@"profileId": @"", @"displayName": @"", @"onboardingComplete": @NO};
    return value;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self buildMainWindow];
}

- (void)buildMainWindow {
    if (self.window) return;
    NSURL *profileURL = [self profileURL];
    NSDictionary *profile = [self loadProfileAtURL:profileURL];
    NSData *profileData = [NSJSONSerialization dataWithJSONObject:profile options:0 error:nil];
    NSString *profileJSON = [[NSString alloc] initWithData:profileData encoding:NSUTF8StringEncoding] ?: @"{}";

    self.profileBridge = [ProfileBridge new];
    self.profileBridge.profileURL = profileURL;
    self.workBridge = [WorkBridge new];
    WKUserContentController *controller = [WKUserContentController new];
    [controller addScriptMessageHandler:self.profileBridge name:@"ruvionProfile"];
    [controller addScriptMessageHandler:self.workBridge name:@"ruvionWork"];
    NSString *bootstrap = [NSString stringWithFormat:@"window.RUVION_NATIVE_PROFILE=%@;window.RUVION_API_URL='%@';", profileJSON, RUVIONAPIURL];
    WKUserScript *script = [[WKUserScript alloc] initWithSource:bootstrap injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    [controller addUserScript:script];
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.userContentController = controller;
    WKWebView *webView = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, 1280, 820) configuration:configuration];
    self.workBridge.webView = webView;
    webView.navigationDelegate = self;
    webView.UIDelegate = self;
    webView.allowsBackForwardNavigationGestures = NO;

    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1280, 820) styleMask:style backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"RUVION";
    self.window.minSize = NSMakeSize(980, 640);
    self.window.contentView = webView;
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];

    NSURL *page = [NSBundle.mainBundle URLForResource:@"index" withExtension:@"html" subdirectory:@"web"];
    NSURL *webDirectory = [page URLByDeletingLastPathComponent];
    [webView loadFileURL:page allowingReadAccessToURL:webDirectory];
}

- (void)webView:(WKWebView *)webView runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSArray<NSURL *> * _Nullable URLs))completionHandler {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = parameters.allowsMultipleSelection;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        completionHandler(result == NSModalResponseOK ? panel.URLs : @[]);
    }];
}

- (void)webView:(WKWebView *)webView requestMediaCapturePermissionForOrigin:(WKSecurityOrigin *)origin initiatedByFrame:(WKFrameInfo *)frame type:(WKMediaCaptureType)type decisionHandler:(void (^)(WKPermissionDecision))decisionHandler API_AVAILABLE(macos(12.0)) {
    // The app only permits camera capture for its bundled file UI, after the
    // person explicitly presses the selfie button. External navigation is
    // blocked above, so no website can request this permission.
    if ([origin.protocol isEqualToString:@"file"] && (type & WKMediaCaptureTypeCamera)) {
        decisionHandler(WKPermissionDecisionGrant);
    } else {
        decisionHandler(WKPermissionDecisionDeny);
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)action decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = action.request.URL;
    // RUVION itself is local. Never permit a login or provider page to replace the app UI.
    if ([url.scheme isEqualToString:@"file"] || url == nil) { decisionHandler(WKNavigationActionPolicyAllow); return; }
    // Student verification is an explicit user action. Open only Didit's hosted
    // verification page in the system browser, never during normal startup.
    if ([url.scheme isEqualToString:@"https"] && [url.host isEqualToString:@"verify.didit.me"]) {
        [[NSWorkspace sharedWorkspace] openURL:url];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyCancel);
}
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = NSApplication.sharedApplication;
        app.activationPolicy = NSApplicationActivationPolicyRegular;
        AppDelegate *delegate = [AppDelegate new];
        app.delegate = delegate;
        [delegate buildMainWindow];
        [app run];
    }
    return 0;
}
