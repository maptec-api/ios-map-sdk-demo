#import "AppDelegate.h"

#import "MTCExampleTestAccessibility.h"
#import "MTCMapGestureControlViewController.h"
#import "MTCMapGestureListViewController.h"
#import "MTCMapInteractionsViewController.h"
#import "MTCMapListViewController.h"
#import "MTCOverlayListViewController.h"
#import "OverlayBasicCircleExampleViewController.h"
#import "OverlayBasicMarkerExampleViewController.h"
#import "OverlayBasicPolygonExampleViewController.h"
#import "OverlayBasicPolylineExampleViewController.h"
#import <MaptecMapsKit/MaptecMapsKit.h>
#import <notify.h>
#import <objc/runtime.h>

#if __has_include("MTCExampleBuildConfiguration.h")
#import "MTCExampleBuildConfiguration.h"
#else
#define MTC_EXAMPLE_USE_DEFAULT_API_KEY 0
#define MTC_EXAMPLE_DEFAULT_API_KEY @""
#endif

static BOOL MTCExampleIsUITesting(void) {
    return [NSProcessInfo.processInfo.arguments containsObject:MTCExampleTestAccessibilityUITestingArgument];
}

static NSString *MTCExampleUITestingRouteClassName(void) {
    for (NSString *argument in NSProcessInfo.processInfo.arguments) {
        if ([argument hasPrefix:MTCExampleTestAccessibilityUITestingRoutePrefix]) {
            return [argument substringFromIndex:MTCExampleTestAccessibilityUITestingRoutePrefix.length];
        }
    }
    return nil;
}

static const char *kMTCUITestRuntimeRouteNotifyName = "com.maptech.maptecmap.uitest.route";

static uint64_t MTCFNV1a64UTF8(const char *bytes) {
    uint64_t hash = 14695981039346656037ULL;
    if (bytes == NULL) {
        return hash;
    }
    for (const unsigned char *cursor = (const unsigned char *)bytes; *cursor != 0; cursor++) {
        hash ^= *cursor;
        hash *= 1099511628211ULL;
    }
    return hash;
}

static NSString *MTCExampleShortClassName(NSString *name) {
    NSRange dot = [name rangeOfString:@"." options:NSBackwardsSearch];
    if (dot.location == NSNotFound) {
        return name;
    }
    return [name substringFromIndex:dot.location + 1];
}

static void MTCExamplePushViewController(UINavigationController *navigationController, Class viewControllerClass) {
    if (navigationController == nil || viewControllerClass == nil) {
        return;
    }
    UIViewController *viewController = [[viewControllerClass alloc] init];
    [navigationController pushViewController:viewController animated:NO];
}

static void MTCExampleApplyUITestingRoute(UINavigationController *navigationController, NSString *routeClassName) {
    if (navigationController == nil || routeClassName.length == 0) {
        return;
    }

    Class targetClass = NSClassFromString(routeClassName);
    if (![targetClass isSubclassOfClass:UIViewController.class]) {
        return;
    }

    if ([targetClass isSubclassOfClass:OverlayBasicMarkerExampleViewController.class]
        || [targetClass isSubclassOfClass:OverlayBasicCircleExampleViewController.class]
        || [targetClass isSubclassOfClass:OverlayBasicPolylineExampleViewController.class]
        || [targetClass isSubclassOfClass:OverlayBasicPolygonExampleViewController.class]) {
        MTCExamplePushViewController(navigationController, MTCOverlayListViewController.class);
        MTCExamplePushViewController(navigationController, targetClass);
        return;
    }

    if ([targetClass isSubclassOfClass:NSClassFromString(@"MTCMapAddViewController")]
        || [targetClass isSubclassOfClass:NSClassFromString(@"MTCMapStyleViewController")]
        || [targetClass isSubclassOfClass:NSClassFromString(@"MTCRouteConditionViewController")]
        || [targetClass isSubclassOfClass:NSClassFromString(@"MTCMapViewPortController")]) {
        MTCExamplePushViewController(navigationController, MTCMapListViewController.class);
        MTCExamplePushViewController(navigationController, targetClass);
        return;
    }

    if ([targetClass isSubclassOfClass:MTCMapGestureControlViewController.class]) {
        MTCExamplePushViewController(navigationController, MTCMapListViewController.class);
        MTCExamplePushViewController(navigationController, MTCMapInteractionsViewController.class);
        MTCExamplePushViewController(navigationController, MTCMapGestureListViewController.class);
        MTCExamplePushViewController(navigationController, targetClass);
        return;
    }

    if ([targetClass isSubclassOfClass:NSClassFromString(@"MTCMapLimitViewController")]) {
        MTCExamplePushViewController(navigationController, MTCMapListViewController.class);
        MTCExamplePushViewController(navigationController, MTCMapInteractionsViewController.class);
        MTCExamplePushViewController(navigationController, targetClass);
        return;
    }

    MTCExamplePushViewController(navigationController, targetClass);
}

static void MTCExampleApplyUITestingRouteIfNeeded(UINavigationController *navigationController) {
    if (!MTCExampleIsUITesting() || navigationController == nil) {
        return;
    }
    MTCExampleApplyUITestingRoute(navigationController, MTCExampleUITestingRouteClassName());
}

static void MTCExampleResetAndApplyUITestingRoute(UINavigationController *navigationController, NSString *routeClassName) {
    if (navigationController == nil || routeClassName.length == 0) {
        return;
    }
    if (navigationController.presentedViewController != nil) {
        [navigationController dismissViewControllerAnimated:NO completion:nil];
    }
    [navigationController popToRootViewControllerAnimated:NO];
    MTCExampleApplyUITestingRoute(navigationController, routeClassName);
}

static Class MTCExampleViewControllerClassForHash(uint64_t target) {
    static NSMutableDictionary<NSNumber *, NSString *> *classNamesByHash;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNamesByHash = [NSMutableDictionary dictionary];
        int total = objc_getClassList(NULL, 0);
        if (total <= 0) {
            return;
        }
        Class *classes = (Class *)malloc((size_t)total * sizeof(Class));
        if (classes == NULL) {
            return;
        }
        total = objc_getClassList(classes, total);
        Class uiViewControllerClass = UIViewController.class;
        for (int index = 0; index < total; index++) {
            Class cls = classes[index];
            if (cls == Nil || class_isMetaClass(cls)) {
                continue;
            }
            Class cursor = cls;
            BOOL isViewController = NO;
            while (cursor != Nil) {
                if (cursor == uiViewControllerClass) {
                    isViewController = YES;
                    break;
                }
                cursor = class_getSuperclass(cursor);
            }
            if (!isViewController) {
                continue;
            }
            NSString *name = NSStringFromClass(cls);
            const char *utf8 = name.UTF8String;
            if (utf8 != NULL) {
                classNamesByHash[@(MTCFNV1a64UTF8(utf8))] = MTCExampleShortClassName(name);
            }
            NSString *shortName = MTCExampleShortClassName(name);
            if (shortName != name) {
                const char *shortUTF8 = shortName.UTF8String;
                if (shortUTF8 != NULL) {
                    classNamesByHash[@(MTCFNV1a64UTF8(shortUTF8))] = shortName;
                }
            }
        }
        free(classes);
    });
    return NSClassFromString(classNamesByHash[@(target)]);
}

static UINavigationController *MTCExampleForegroundNavigationController(void) {
    UIWindow *keyWindow = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive &&
            scene.activationState != UISceneActivationStateForegroundInactive) {
            continue;
        }
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
            if (keyWindow == nil) {
                keyWindow = window;
            }
        }
        if (keyWindow != nil) {
            break;
        }
    }
    UIViewController *root = keyWindow.rootViewController;
    return [root isKindOfClass:UINavigationController.class] ? (UINavigationController *)root : nil;
}

static void MTCExampleRegisterUITestingRuntimeRouteListener(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        int token = 0;
        notify_register_dispatch(kMTCUITestRuntimeRouteNotifyName, &token, dispatch_get_main_queue(), ^(int notifyToken) {
            uint64_t hash = 0;
            notify_get_state(notifyToken, &hash);
            if (hash == 0) {
                return;
            }
            Class cls = MTCExampleViewControllerClassForHash(hash);
            if (cls == Nil) {
                return;
            }
            UINavigationController *navigationController = MTCExampleForegroundNavigationController();
            if (navigationController == nil) {
                return;
            }
            MTCExampleResetAndApplyUITestingRoute(navigationController,
                                                  MTCExampleShortClassName(NSStringFromClass(cls)));
        });
    });
}

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)application;
    (void)launchOptions;

    if (MTCExampleIsUITesting()) {
        [UIView setAnimationsEnabled:NO];
    }

    [self configureNavigationBarAppearance];

    if (MTCExampleIsUITesting()) {
        MTCExampleRegisterUITestingRuntimeRouteListener();
    }

    if (MTC_EXAMPLE_USE_DEFAULT_API_KEY && [MTC_EXAMPLE_DEFAULT_API_KEY length] > 0) {
        MTCMapServices.sharedServices.apiKey = MTC_EXAMPLE_DEFAULT_API_KEY;
    }
    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application
configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                             options:(UISceneConnectionOptions *)options {
    (void)application;
    (void)options;
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration"
                                          sessionRole:connectingSceneSession.role];
}

+ (void)applyUITestingRouteIfNeeded:(UINavigationController *)navigationController {
    if (!MTCExampleIsUITesting()) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        MTCExampleApplyUITestingRouteIfNeeded(navigationController);
    });
}

- (void)configureNavigationBarAppearance {
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = UIColor.systemBackgroundColor;
    appearance.titleTextAttributes = @{
        NSForegroundColorAttributeName : UIColor.labelColor,
    };
    appearance.largeTitleTextAttributes = @{
        NSForegroundColorAttributeName : UIColor.labelColor,
    };

    UINavigationBar *navigationBarAppearance = UINavigationBar.appearance;
    navigationBarAppearance.standardAppearance = appearance;
    navigationBarAppearance.scrollEdgeAppearance = appearance;
    navigationBarAppearance.compactAppearance = appearance;
    if (@available(iOS  15.0 , *)) {
        navigationBarAppearance.compactScrollEdgeAppearance = appearance;
    }
    navigationBarAppearance.tintColor = UIColor.labelColor;
}

@end
