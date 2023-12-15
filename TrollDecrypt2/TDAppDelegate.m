//
//  AppDelegate.m
//  trolldecrypt2
//
//  Created by xiongzai on 2023/12/13.
//

#import "TDAppDelegate.h"
#import "TDRootViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface TDAppDelegate ()
@property(nonatomic,assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) AVAudioPlayer *silentPlayer;
@property(nonatomic,assign) NSInteger count;
@end

@implementation TDAppDelegate
@synthesize window=_window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UINavigationController *rootViewController = [[UINavigationController alloc] initWithRootViewController:[[TDRootViewController alloc] init]];
    _window.rootViewController = rootViewController;
    [_window makeKeyAndVisible];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(silentPlayerDidInterrupted:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"applicationWillEnterForeground");
    [self.silentPlayer pause];
    [self.timer invalidate];
    self.timer = nil;
    self.count = 0;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"applicationDidEnterBackground");
    [self.silentPlayer play];
    __weak typeof(self) weakSelf = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        typeof(weakSelf) strongSelf = weakSelf;
        NSLog(@"Enter Background Time:%zd",strongSelf.count);
        strongSelf.count +=1;
    }];
}

- (void)silentPlayerDidInterrupted:(NSNotification *)notification {
    NSNumber *value = notification.userInfo[AVAudioSessionInterruptionTypeKey];
    if([value integerValue] == AVAudioSessionInterruptionTypeEnded && [UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        [self.silentPlayer play];
    }
}

-(AVAudioPlayer *)silentPlayer {
    if(!_silentPlayer) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault options:AVAudioSessionCategoryOptionMixWithOthers error:nil];
        [session setActive:YES error:nil];
        _silentPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"silent" withExtension:@"mp3"] error:nil];
        [_silentPlayer prepareToPlay];
        _silentPlayer.numberOfLoops = -1;
    }
    return _silentPlayer;
}

@end
