//
//  main.m
//  trolldecrypt2
//
//  Created by xiongzai on 2023/12/13.
//

#import <UIKit/UIKit.h>
#import "TDAppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([TDAppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
