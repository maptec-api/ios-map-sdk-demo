#import "SceneDelegate.h"

#import "AppDelegate.h"
#import "ExampleHomeViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    (void)session;
    (void)connectionOptions;
    if (![scene isKindOfClass:UIWindowScene.class]) {
        return;
    }

    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    ExampleHomeViewController *homeViewController = [[ExampleHomeViewController alloc] init];
    UINavigationController *navigationController =
        [[UINavigationController alloc] initWithRootViewController:homeViewController];
    window.rootViewController = navigationController;
    self.window = window;
    [window makeKeyAndVisible];
    [AppDelegate applyUITestingRouteIfNeeded:navigationController];
}

@end
