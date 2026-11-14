// UIKit host for the iOS Red Alert client.
//
// Scaling (this is the contract the rest of the port relies on):
//   * The game framebuffer is the phone's landscape size in POINTS, not a
//     stretched 640x400. A 19.5:9 phone therefore gets a framebuffer of that
//     aspect, and the tactical map is widened to match, so more of the map
//     is visible. Sidebar art stays at the engine's hires size (RESFACTOR 2),
//     which is one point per asset pixel — the same density the desktop
//     hires mode uses.
//   * SDL presents that buffer with SDL_WINDOW_ALLOW_HIGHDPI and nearest
//     filtering. On current iPhones the drawable is exactly points × 2 or
//     points × 3, so each game pixel becomes a square block of device pixels.
//     The destination rectangle is the full drawable: no bars, no non-uniform
//     scale. A one-pixel remainder, if a future panel is not an exact multiple,
//     is snapped onto the drawable rather than left as a bar.
//   * The notch / Dynamic Island is not letterboxed. The map is drawn under
//     it. The sidebar is shifted in by the safe-area inset so its buttons
//     stay tappable. The status bar is hidden and the home indicator is
//     auto-hidden with edge gestures deferred (see the view-controller
//     category below, plus SDL_HINT_IOS_HIDE_HOME_INDICATOR).
#import <UIKit/UIKit.h>

#include "ios_host.h"

#include <cmath>
#include <cstring>
#include <unistd.h>

static int g_width = 0;
static int g_height = 0;
static int g_safe_right = 0;
static int g_safe_bottom = 0;
static bool g_metrics = false;

static NSString* Documents_NSString()
{
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

// Find a MIX file up to a few folders down and rename a case-mismatched copy
// to the uppercase name the engine opens.
static NSString* Find_Mix(NSString* root, NSString* wanted)
{
    NSFileManager* fm = NSFileManager.defaultManager;
    NSDirectoryEnumerator* enumerator = [fm enumeratorAtPath:root];
    for (NSString* item in enumerator) {
        if (item.pathComponents.count > 5) {
            [enumerator skipDescendants];
            continue;
        }
        if ([item.lastPathComponent caseInsensitiveCompare:wanted] != NSOrderedSame) {
            continue;
        }
        NSString* full = [root stringByAppendingPathComponent:item];
        BOOL directory = NO;
        if (![fm fileExistsAtPath:full isDirectory:&directory] || directory) {
            continue;
        }
        if (![item.lastPathComponent isEqualToString:wanted]) {
            NSString* dest = [[full stringByDeletingLastPathComponent] stringByAppendingPathComponent:wanted];
            if (![fm fileExistsAtPath:dest]) {
                [fm moveItemAtPath:full toPath:dest error:nil];
                full = dest;
            } else {
                full = dest;
            }
        }
        return full;
    }
    return nil;
}

static BOOL Has_Game_Data()
{
    NSString* root = Documents_NSString();
    return Find_Mix(root, @"REDALERT.MIX") != nil && Find_Mix(root, @"MAIN.MIX") != nil;
}

static void Capture_Screen_Size()
{
    CGFloat native_scale = UIScreen.mainScreen.nativeScale;
    CGRect native = UIScreen.mainScreen.nativeBounds;
    int scale = (int)std::llround(native_scale);
    if (scale < 1) {
        scale = 1;
    }
    int pixels_w = (int)std::llround(MAX(native.size.width, native.size.height));
    int pixels_h = (int)std::llround(MIN(native.size.width, native.size.height));
    g_width = pixels_w / scale;
    g_height = pixels_h / scale;
    if (g_width < 320) {
        g_width = pixels_w;
    }
    if (g_height < 200) {
        g_height = pixels_h;
    }
}

static void Capture_Safe_Area(UIEdgeInsets insets)
{
    // Portrait reports the island as the top inset; landscape reports it on
    // the left or right. The larger of those is the inset the sidebar needs
    // in either rotation.
    CGFloat side = MAX(insets.left, insets.right);
    side = MAX(side, insets.top);
    g_safe_right = (int)std::llround(side);
    g_safe_bottom = (int)std::llround(insets.bottom);
    // Wide phones (19.5:9 class) have an island even if UIKit has not
    // published insets yet. Classic 16:9 phones do not.
    if (g_height > 0 && (float)g_width / (float)g_height > 2.0f) {
        if (g_safe_right < 44) {
            g_safe_right = 47;
        }
        if (g_safe_bottom < 12) {
            g_safe_bottom = 21;
        }
    }
    if (g_width > 0 && g_safe_right > g_width / 5) {
        g_safe_right = g_width / 5;
    }
    if (g_height > 0 && g_safe_bottom > g_height / 5) {
        g_safe_bottom = g_height / 5;
    }
    g_metrics = true;
}

@interface RAChromeController : UIViewController
@end

@implementation RAChromeController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures
{
    return UIRectEdgeAll;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

@end

@interface RADataController : RAChromeController
@property(nonatomic, assign) BOOL acknowledged;
@property(nonatomic, retain) UILabel* statusLabel;
@end

@implementation RADataController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.05 green:0.04 blue:0.03 alpha:1.0];

    UILabel* title = [[[UILabel alloc] init] autorelease];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"未找到红色警戒游戏数据";
    title.textColor = [UIColor colorWithRed:0.93 green:0.78 blue:0.35 alpha:1.0];
    title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    title.numberOfLines = 0;

    UILabel* body = [[[UILabel alloc] init] autorelease];
    body.translatesAutoresizingMaskIntoConstraints = NO;
    body.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    body.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    body.numberOfLines = 0;
    body.text = @"这个应用只有游戏引擎，不含任何原版资源。\n\n"
                @"请用「文件」App 打开本应用的目录（与「红色警戒」同名的文件夹），把你合法获得的 MIX 文件复制进去。\n\n"
                @"必须有：\n"
                @"• REDALERT.MIX\n"
                @"• MAIN.MIX（可以放在根目录，也可以放在 allied 或 soviet 文件夹里）\n\n"
                @"高清界面还需要 HIRES.MIX。很多安装目录里它已经在 REDALERT.MIX 里面，那就不用再单独复制。\n\n"
                @"可选扩展：EXPAND.MIX（隐秘行动）、EXPAND2.MIX（劫后余生），以及其他原版目录里的 MIX。\n\n"
                @"2008 年 EA 把红色警戒原版数据作为免费软件发布。请使用你自己合法取得的文件。";

    UIButton* retry = [UIButton buttonWithType:UIButtonTypeSystem];
    retry.translatesAutoresizingMaskIntoConstraints = NO;
    [retry setTitle:@"我已放入文件，继续" forState:UIControlStateNormal];
    retry.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    [retry setTitleColor:[UIColor colorWithRed:0.08 green:0.05 blue:0.02 alpha:1.0] forState:UIControlStateNormal];
    retry.backgroundColor = [UIColor colorWithRed:0.93 green:0.78 blue:0.35 alpha:1.0];
    retry.layer.cornerRadius = 10;
    [retry addTarget:self action:@selector(retry:) forControlEvents:UIControlEventTouchUpInside];

    self.statusLabel = [[[UILabel alloc] init] autorelease];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.textColor = [UIColor colorWithRed:0.95 green:0.55 blue:0.35 alpha:1.0];
    self.statusLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.text = @"正在等待 REDALERT.MIX 和 MAIN.MIX。";

    UIStackView* stack = [[UIStackView alloc] initWithArrangedSubviews:@[title, body, retry, self.statusLabel]];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    [self.view addSubview:stack];

    UILayoutGuide* guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:28],
        [stack.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-28],
        [stack.topAnchor constraintGreaterThanOrEqualToAnchor:guide.topAnchor constant:16],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:guide.bottomAnchor constant:-16],
        [stack.centerYAnchor constraintEqualToAnchor:guide.centerYAnchor],
        [retry.heightAnchor constraintEqualToConstant:48],
    ]];
    [stack release];
}

- (void)retry:(id)sender
{
    (void)sender;
    if (Has_Game_Data()) {
        self.acknowledged = YES;
        self.statusLabel.text = @"已经找到游戏数据。";
    } else {
        self.statusLabel.text = @"还是没有找到 REDALERT.MIX 和 MAIN.MIX。请把文件放进「文件」App 里本应用的目录，不要放进别的文件夹。";
    }
}

- (void)dealloc
{
    [_statusLabel release];
    [super dealloc];
}

@end

// SDL's view controller only honors one of these at a time via its hint.
// Both are required: hide the home indicator, and defer the edge swipe so it
// does not steal map scrolling.
@interface SDL_uikitviewcontroller : UIViewController
@end

@implementation SDL_uikitviewcontroller (RedAlertChrome)

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures
{
    return UIRectEdgeAll;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

@end

static UIWindow* Make_Window(UIViewController* controller)
{
    UIWindowScene* scene = nil;
    for (UIScene* candidate in UIApplication.sharedApplication.connectedScenes) {
        if ([candidate isKindOfClass:[UIWindowScene class]]) {
            scene = (UIWindowScene*)candidate;
            break;
        }
    }
    UIWindow* window = scene != nil ? [[UIWindow alloc] initWithWindowScene:scene]
                                    : [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    window.backgroundColor = [UIColor colorWithRed:0.05 green:0.04 blue:0.03 alpha:1.0];
    window.rootViewController = controller;
    return window;
}

const char* IOS_Documents_Directory(void)
{
    static char path[1024];
    static bool ready = false;
    if (!ready) {
        NSString* documents = Documents_NSString();
        if (documents.length == 0) {
            path[0] = '.';
            path[1] = '\0';
        } else {
            std::strncpy(path, documents.UTF8String, sizeof(path) - 1);
            path[sizeof(path) - 1] = '\0';
        }
        if (chdir(path) != 0) {
            // The game also searches this path explicitly; a failed chdir is not fatal.
        }
        ready = true;
    }
    return path;
}

void IOS_Choose_Resolution(int* width, int* height)
{
    if (!g_metrics) {
        // UIScreen only. A UIWindow created here becomes the key window and
        // SDL_CreateWindow then fails, which used to exit with a black screen.
        Capture_Screen_Size();
        Capture_Safe_Area(UIEdgeInsetsZero);
    }
    if (width != nullptr) {
        *width = g_width;
    }
    if (height != nullptr) {
        *height = g_height;
    }
}

void IOS_Show_Fatal(const char* message)
{
    static bool showing = false;
    if (showing) {
        while (true) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, false);
        }
    }
    showing = true;

    @autoreleasepool {
        NSString* detail = message != nullptr ? [NSString stringWithUTF8String:message] : @"";
        if (detail == nil) {
            detail = @"";
        }
        NSString* text = [NSString
            stringWithFormat:@"红色警戒没能进入游戏，所以停在这个画面，避免直接闪退。\n\n%@", detail];

        RAChromeController* controller = [[RAChromeController alloc] init];
        UIWindow* window = Make_Window(controller);
        [controller release];
        window.windowLevel = UIWindowLevelAlert + 1;
        [window makeKeyAndVisible];

        UILabel* label = [[[UILabel alloc] init] autorelease];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.text = text;
        label.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        label.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
        label.numberOfLines = 0;
        label.backgroundColor = [UIColor colorWithRed:0.05 green:0.04 blue:0.03 alpha:1.0];
        [window.rootViewController.view addSubview:label];
        UILayoutGuide* guide = window.rootViewController.view.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [label.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:24],
            [label.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-24],
            [label.topAnchor constraintEqualToAnchor:guide.topAnchor constant:24],
            [label.bottomAnchor constraintLessThanOrEqualToAnchor:guide.bottomAnchor constant:-24],
        ]];

        while (true) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, false);
        }
    }
}

int IOS_Safe_Right_Pixels(void)
{
    return g_safe_right;
}

int IOS_Safe_Bottom_Pixels(void)
{
    return g_safe_bottom;
}

void IOS_Wait_For_Game_Data(void)
{
    IOS_Documents_Directory();
    UIApplication.sharedApplication.idleTimerDisabled = YES;

    if (Has_Game_Data()) {
        IOS_Choose_Resolution(nullptr, nullptr);
        return;
    }

    @autoreleasepool {
        RADataController* controller = [[RADataController alloc] init];
        UIWindow* window = Make_Window(controller);
        [window makeKeyAndVisible];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, false);
        Capture_Screen_Size();
        Capture_Safe_Area(window.safeAreaInsets);

        while (!Has_Game_Data() && !controller.acknowledged) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.2, false);
        }
        // acknowledged can be set by the button just as the files appear; recheck.
        while (!Has_Game_Data()) {
            controller.acknowledged = NO;
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.2, false);
        }

        window.hidden = YES;
        window.rootViewController = nil;
        [window release];
        [controller release];
    }
}
