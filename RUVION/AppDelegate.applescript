use framework "Foundation"
use framework "AppKit"
use framework "WebKit"
use scripting additions

property NSWindow : a reference to current application's NSWindow
property NSWindowStyleMaskTitled : a reference to current application's NSWindowStyleMaskTitled
property NSWindowStyleMaskClosable : a reference to current application's NSWindowStyleMaskClosable
property NSWindowStyleMaskMiniaturizable : a reference to current application's NSWindowStyleMaskMiniaturizable
property NSWindowStyleMaskResizable : a reference to current application's NSWindowStyleMaskResizable
property NSBackingStoreBuffered : a reference to current application's NSBackingStoreBuffered
property NSUTF8StringEncoding : a reference to current application's NSUTF8StringEncoding
property parent : class "NSObject"

script AppDelegate
    property parent : class "NSObject"
    property mainWindow : missing value
    property webView : missing value
    property profilePath : missing value

    on applicationWillFinishLaunching:aNotification
        set appSupport to (POSIX path of ((path to application support from user domain) as alias)) & "RUVION"
        set profilePath to appSupport & "/profile.json"
        do shell script "/bin/mkdir -p " & quoted form of appSupport

        set frame to current application's NSMakeRect(0, 0, 1280, 820)
        set mask to (NSWindowStyleMaskTitled + NSWindowStyleMaskClosable + NSWindowStyleMaskMiniaturizable + NSWindowStyleMaskResizable)
        set mainWindow to NSWindow's alloc()'s initWithContentRect:frame styleMask:mask backing:NSBackingStoreBuffered defer:false
        mainWindow's setTitle:"RUVION"
        mainWindow's setMinSize:(current application's NSMakeSize(980, 640))

        set controller to current application's WKUserContentController's alloc()'s init()
        set nativeProfileJSON to my loadProfileJSON()
        set bootstrap to "window.RUVION_NATIVE_PROFILE=" & nativeProfileJSON & ";window.RUVION_API_URL='https://api.ruvion.app/v1/chat';"
        set userScript to current application's WKUserScript's alloc()'s initWithSource:bootstrap injectionTime:(current application's WKUserScriptInjectionTimeAtDocumentStart) forMainFrameOnly:true
        controller's addUserScript:userScript
        set configuration to current application's WKWebViewConfiguration's alloc()'s init()
        configuration's setUserContentController:controller
        set webView to current application's WKWebView's alloc()'s initWithFrame:frame configuration:configuration
        webView's setAllowsBackForwardNavigationGestures:false
        mainWindow's setContentView:webView

        set bundlePath to POSIX path of (path to me)
        set pageURL to current application's NSURL's fileURLWithPath:(bundlePath & "Contents/Resources/web/index.html")
        set readURL to current application's NSURL's fileURLWithPath:(bundlePath & "Contents/Resources/web")
        webView's loadFileURL:pageURL allowingReadAccessToURL:readURL
        mainWindow's makeKeyAndOrderFront:me
        (current application's NSApplication's sharedApplication())'s activateIgnoringOtherApps:true
    end applicationWillFinishLaunching:

    on applicationShouldTerminateAfterLastWindowClosed:sender
        return true
    end applicationShouldTerminateAfterLastWindowClosed:

    on userContentController:controller didReceiveScriptMessage:message
        try
            set jsonText to (message's body()) as text
            set nsText to current application's NSString's stringWithString:jsonText
            nsText's writeToFile:profilePath atomically:true encoding:NSUTF8StringEncoding |error|:(missing value)
        end try
    end userContentController:didReceiveScriptMessage:

    on loadProfileJSON()
        try
            return do shell script "/bin/cat " & quoted form of profilePath
        on error
            return "{\"profileId\":\"\",\"displayName\":\"\",\"onboardingComplete\":false}"
        end try
    end loadProfileJSON
end script

set theDelegate to AppDelegate's alloc()'s init()
set ruvionApp to current application's NSApplication's sharedApplication()
ruvionApp's setDelegate:theDelegate
ruvionApp's performSelector:"run"
