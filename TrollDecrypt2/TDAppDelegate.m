//
//  AppDelegate.m
//  trolldecrypt2
//
//  Created by xiongzai on 2023/12/13.
//

#import "TDAppDelegate.h"
#import "TDRootViewController.h"

@implementation TDAppDelegate
@synthesize window=_window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UINavigationController *rootViewController = [[UINavigationController alloc] initWithRootViewController:[[TDRootViewController alloc] init]];
    _window.rootViewController = rootViewController;
    [_window makeKeyAndVisible];
    return YES;
}

@end
