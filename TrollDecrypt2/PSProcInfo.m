//
//  PSProcInfo.m
//  TrollDecrypt2
//
//  Created by xiongzai on 2023/12/14.
//

#import "PSProcInfo.h"
#import <mach/mach_init.h>
#import <mach/mach_host.h>
#import <mach/host_info.h>
#import <pwd.h>
#import <sys/sysctl.h>
#import <mach/task.h>

extern int proc_pidpath(int pid, void * buffer, uint32_t  buffersize);

@implementation PSProcInfo
int sort_procs_by_pid(const void *p1, const void *p2)
{
    pid_t kp1 = ((struct kinfo_proc *)p1)->kp_proc.p_pid, kp2 = ((struct kinfo_proc *)p2)->kp_proc.p_pid;
    return kp1 == kp2 ? 0 : kp1 > kp2 ? 1 : -1;
}

- (instancetype)initProcInfoSort:(BOOL)sort
{
    static int maxproc;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        int mib[2];
        size_t len;

        mib[0] = CTL_KERN;
        mib[1] = KERN_MAXPROC;
        len = sizeof(maxproc);
        sysctl(mib, 2, &maxproc, &len, NULL,    0);
    });
    
    self = [super init];
    self->kp = 0;
    self->count = 0;
    
    // Get buffer size
    size_t alloc_size = maxproc * sizeof(struct kinfo_proc);
    size_t bufSize = 0;
    self->kp = (struct kinfo_proc *)malloc(alloc_size);
    static int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    if (self->kp == NULL) {
        if (sysctl(mib, 4, NULL, &alloc_size, NULL, 0) < 0)
            { self->ret = errno; return self; }
        alloc_size *= 2;
        self->kp = (struct kinfo_proc *)malloc(alloc_size);
    }
    bufSize = alloc_size;
    // Get process list
    self->ret = sysctl(mib, 4, self->kp, &bufSize, NULL, 0);
    if (self->ret)
        { free(self->kp); self->kp = 0; return self; }
    self->count = bufSize / sizeof(struct kinfo_proc);
    if (sort)
        qsort(self->kp, self->count, sizeof(*kp), sort_procs_by_pid);
    if (@available(iOS 11, *)) {
    } else if (@available(iOS 10, *)) {
        if (self->kp[self->count - 1].kp_proc.p_pid == 1) {
            if (alloc_size > (self->count + 1) * sizeof(struct kinfo_proc)) {
                static int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, 0 };
                size_t length = sizeof(struct kinfo_proc);
                sysctl(mib, 4, &self->kp[self->count++], &length, NULL, 0);
            }
        }
    }
    return self;
}

+ (instancetype)psProcInfoSort:(BOOL)sort
{
    return [[PSProcInfo alloc] initProcInfoSort:sort];
}

- (void)dealloc
{
    if (self->kp) free(self->kp);
}
@end
