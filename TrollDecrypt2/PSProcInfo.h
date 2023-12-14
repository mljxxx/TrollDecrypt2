//
//  PSProcInfo.h
//  TrollDecrypt2
//
//  Created by xiongzai on 2023/12/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PSProcInfo : NSObject
{
@public struct kinfo_proc *kp;
@public size_t count;
@public int ret;
}
+ (instancetype)psProcInfoSort:(BOOL)sort;
@end

NS_ASSUME_NONNULL_END
