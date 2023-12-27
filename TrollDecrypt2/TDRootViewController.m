//
//  TDRootViewController.m
//  trolldecrypt2
//
//  Created by xiongzai on 2023/12/13.
//

#import <sys/sysctl.h>
#import <mach/task.h>
#import <mach/mach_init.h>
#import <mach/mach_host.h>
#import <mach/host_info.h>
#import "TDRootViewController.h"
#import "PSProcInfo.h"
#import "DumpDecrypted.h"

#define PROC_PIDPATHINFO_MAXSIZE    (4*MAXPATHLEN)
int proc_pidpath(int pid, void *buffer, uint32_t buffersize);

typedef void(^decryptCompleteCallBack)(void);

@interface TDRootViewController ()
@property(nonatomic, strong) UITextField *pidTextField;
@property(nonatomic, strong) UITextField *identifierTextField;
@property(nonatomic, strong) UIButton *button;;
@end

@implementation TDRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _button = [UIButton buttonWithType:UIButtonTypeSystem];
    _button.frame = CGRectMake(UIScreen.mainScreen.bounds.size.width / 2 - 30,
                             UIScreen.mainScreen.bounds.size.height / 2 - 25, 60, 100);
    [_button setTitle:@"Decrypt" forState:UIControlStateNormal];
    [_button addTarget:self action:@selector(buttonPressed:)
      forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_button];

    _pidTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 100, UIScreen.mainScreen.bounds.size.width - 40, 40)];
    _pidTextField.placeholder = @"Enter App PID";
    _pidTextField.borderStyle = UITextBorderStyleRoundedRect;
    _pidTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:_pidTextField];
    
    _identifierTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 180, UIScreen.mainScreen.bounds.size.width - 40, 40)];
    _identifierTextField.placeholder = @"Enter App Identifier";
    _identifierTextField.borderStyle = UITextBorderStyleRoundedRect;
    _identifierTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:_identifierTextField];
}

- (void)buttonPressed:(UIButton *)sender {
    NSString *pidString = _pidTextField.text;
    pid_t pid = [pidString intValue];
    if (pid) {
        [self decryptWithPid:pid callBack:nil];
    } else {
        NSString *identifier = _identifierTextField.text;
        if(identifier.length) {
            [self waitAndSuspendWithIdentifier:identifier];
        }
    }
}

- (void)waitAndSuspendWithIdentifier:(NSString *)identifier {
    __block UIWindow *alertWindow = [[UIWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];
    alertWindow.rootViewController = [UIViewController new];
    alertWindow.windowLevel = UIWindowLevelAlert + 1;
    [alertWindow makeKeyAndVisible];
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Wait for Launch"
                                          message:@"Process is not launched,wait to Launch?"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"Yes", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
        NSLog(@"OK action");
        [alertController dismissViewControllerAnimated:NO completion:nil];
        [alertWindow removeFromSuperview];
        alertWindow.hidden = YES;
        alertWindow = nil;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self waitForLaunch:identifier];
        });
    }];
    UIAlertAction *cancelAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"NO", @"Cancel action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
        NSLog(@"cancel action");
        [alertController dismissViewControllerAnimated:NO completion:nil];
        [alertWindow removeFromSuperview];
        alertWindow.hidden = YES;
        alertWindow = nil;
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    UIViewController *root = [alertWindow rootViewController];
    root.modalPresentationStyle = UIModalPresentationFullScreen;
    [root presentViewController:alertController animated:YES completion:nil];
}

- (void)waitForLaunch:(NSString *)identifier {
    while(true) {
        @autoreleasepool {
            PSProcInfo *procs = [PSProcInfo psProcInfoSort:NO];
            if(procs->ret) {
                continue;
            }
            for (int i = 0; i < procs->count; i++) {
                pid_t pid = procs->kp[i].kp_proc.p_pid;
                char buffer[MAXPATHLEN];
                if (!proc_pidpath(pid, buffer, sizeof(buffer))) {
                    continue;
                }
                NSString *executable = [NSString stringWithUTF8String:buffer];
                if(!executable.length) {
                    continue;
                }
                NSString *path = [executable stringByDeletingLastPathComponent];
                NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"Info.plist"]];
                NSString *curIdentifier = info[@"CFBundleIdentifier"];
                if(!curIdentifier.length || ![curIdentifier isEqualToString:identifier]) {
                    continue;
                }
                mach_port_t task;
                if(!task_for_pid(mach_task_self(), pid, &task)) {
                    NSLog(@"Find pid for:%@",identifier);
                    [self suspendTask:task decrypt:pid];
                    return;
                }
            }
        }
        [NSThread sleepForTimeInterval:0.1f];
    }
}

- (void)suspendTask:(mach_port_t)task decrypt:(pid_t)pid {
    if(!task_suspend(task)) {
        NSLog(@"suspend %d success",pid);
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        if(state == UIApplicationStateActive) {
            NSLog(@"UIApplicationStateActive");
            [self decryptWithPid:pid callBack:^{
                if(!task_resume(task)) {
                    NSLog(@"resume %d success",pid);
                }
            }];
        } else if(state == UIApplicationStateBackground) {
            NSLog(@"UIApplicationStateBackground");
            [self backgroundDecryptWithPid:pid callBack:^{
                if(!task_resume(task)) {
                    NSLog(@"resume %d success",pid);
                }
            }];
        }
    }
}

- (void)decryptWithPid:(pid_t)pid callBack:(decryptCompleteCallBack)callBack {
    dispatch_async(dispatch_get_main_queue(), ^{
        __block UIWindow *alertWindow = [[UIWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];
        alertWindow.rootViewController = [UIViewController new];
        alertWindow.windowLevel = UIWindowLevelAlert + 1;
        [alertWindow makeKeyAndVisible];
        
        // Show a "Decrypting!" alert on the device and block the UI
        __block UIAlertController *alertController = [UIAlertController
            alertControllerWithTitle:@"Decrypting"
            message:@"Please wait, this will take a few seconds..."
            preferredStyle:UIAlertControllerStyleAlert];
        
        UIViewController *root = [alertWindow rootViewController];
        root.modalPresentationStyle = UIModalPresentationFullScreen;
        [root presentViewController:alertController animated:YES completion:nil];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            char pathbuf[PROC_PIDPATHINFO_MAXSIZE];
            proc_pidpath(pid, pathbuf, sizeof(pathbuf));
            const char *fullPathStr = pathbuf;
            NSString *executable = [NSString stringWithUTF8String:fullPathStr];
            NSString *path = [executable stringByDeletingLastPathComponent];
            NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"Info.plist"]];
            NSString *name = info[@"CFBundleIdentifier"];
            NSString *version = info[@"CFBundleShortVersionString"];
            DumpDecrypted *dd = [[DumpDecrypted alloc] initWithPathToBinary:[NSString stringWithUTF8String:fullPathStr] appName:name appVersion:version];
            if(!dd) {
                NSLog(@"ERROR: failed to get DumpDecrypted instance");
                return;
            }
            // Do the decryption
            [dd createIPAFile:pid];
            if(callBack) {
                callBack();
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertController dismissViewControllerAnimated:NO completion:^{
                    alertController = [UIAlertController
                                       alertControllerWithTitle:@"Decryption Complete!"
                                       message:@"You can find it in Documents Path"
                                       preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *okAction = [UIAlertAction
                                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                               style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action) {
                        [alertController dismissViewControllerAnimated:NO completion:nil];
                        NSLog(@"OK action");
                        [alertWindow removeFromSuperview];
                        alertWindow.hidden = YES;
                        alertWindow = nil;
                    }];
                    UIAlertAction *goFilzaAction = [UIAlertAction
                                               actionWithTitle:NSLocalizedString(@"GoFilza", @"GoFilza action")
                                               style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action) {
                        [alertController dismissViewControllerAnimated:NO completion:nil];
                        NSLog(@"GoFilza action");
                        [alertWindow removeFromSuperview];
                        alertWindow.hidden = YES;
                        alertWindow = nil;
                        NSString *urlString = [NSString stringWithFormat:@"filza://view%@", [[dd IPAPath] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
                    }];
                    [alertController addAction:okAction];
                    [alertController addAction:goFilzaAction];
                    [root presentViewController:alertController animated:YES completion:nil];
                }];
            });
        });
    });
}


- (void)backgroundDecryptWithPid:(pid_t)pid callBack:(decryptCompleteCallBack)callBack {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        char pathbuf[PROC_PIDPATHINFO_MAXSIZE];
        proc_pidpath(pid, pathbuf, sizeof(pathbuf));
        const char *fullPathStr = pathbuf;
        NSString *executable = [NSString stringWithUTF8String:fullPathStr];
        NSString *path = [executable stringByDeletingLastPathComponent];
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"Info.plist"]];
        NSString *name = info[@"CFBundleDisplayName"];
        NSString *version = info[@"CFBundleShortVersionString"];
        DumpDecrypted *dd = [[DumpDecrypted alloc] initWithPathToBinary:[NSString stringWithUTF8String:fullPathStr] appName:name appVersion:version];
        if(!dd) {
            NSLog(@"ERROR: failed to get DumpDecrypted instance");
            return;
        }
        // Do the decryption
        [dd createIPAFile:pid];
        if(callBack) {
            callBack();
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            __block UIWindow *alertWindow = [[UIWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];
            alertWindow.rootViewController = [UIViewController new];
            alertWindow.windowLevel = UIWindowLevelAlert + 1;
            [alertWindow makeKeyAndVisible];
            UIViewController *root = [alertWindow rootViewController];
            root.modalPresentationStyle = UIModalPresentationFullScreen;
            
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Decryption Complete!"
                                                  message:@"You can find it in Documents Path"
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                [alertController dismissViewControllerAnimated:NO completion:nil];
                NSLog(@"OK action");
                [alertWindow removeFromSuperview];
                alertWindow.hidden = YES;
                alertWindow = nil;
            }];
            UIAlertAction *goFilzaAction = [UIAlertAction
                                            actionWithTitle:NSLocalizedString(@"GoFilza", @"GoFilza action")
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                [alertController dismissViewControllerAnimated:NO completion:nil];
                NSLog(@"GoFilza action");
                [alertWindow removeFromSuperview];
                alertWindow.hidden = YES;
                alertWindow = nil;
                NSString *urlString = [NSString stringWithFormat:@"filza://view%@", [[dd IPAPath] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
            }];
            [alertController addAction:okAction];
            [alertController addAction:goFilzaAction];
            [root presentViewController:alertController animated:YES completion:nil];
        });
    });
}

@end
