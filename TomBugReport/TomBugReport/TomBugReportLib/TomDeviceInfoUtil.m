//
//  TomDeviceInfoUtil.m
//  TomBugReportLib
//
//  Created by Liuyujie on 2017/3/8.
//  Copyright © 2017年 Tom. All rights reserved.
//

#import "TomDeviceInfoUtil.h"
#import "sys/utsname.h"
#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/task_info.h>
#import <mach/task.h>
#import <mach/vm_map.h>
#import <mach/mach_init.h>
#import <mach/thread_act.h>
#import <mach/thread_info.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
@implementation TomDeviceInfoUtil

+ (NSString *)getDeviceName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"设备型号：%@",deviceString];
}

+ (NSString *)getSystemNameAndVersion
{
    NSString *systemName = [UIDevice currentDevice].systemName;
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
    return [NSString stringWithFormat:@"系统名称：%@  系统版本：%@",systemName,systemVersion];
}

+ (NSString *)getAppPath
{
    char buf[0];
    uint32_t size = 0;
    _NSGetExecutablePath(buf,&size);
    char* path = (char*)malloc(size+1);
    path[size] = 0;
    _NSGetExecutablePath(path,&size);
    char* pCur = strrchr(path, '/');
    *pCur = 0;
    NSString *appPWDPath = [NSString stringWithUTF8String:path];
    free(path);
    path = NULL;
    return appPWDPath;
}

+ (NSString *)getAppMemoryUsage
{
    struct mach_task_basic_info info;
    mach_msg_type_number_t count = sizeof(info) / sizeof(integer_t);
    if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &count) == KERN_SUCCESS) {
        CGFloat usage = info.resident_size / 1024 / 1024;
        return [NSString stringWithFormat:@"%0.2fMB",usage];
    }
    return @"";
}

+ (NSString *)getAppCPUUsage
{
    double usageRatio = 0;
    thread_info_data_t thinfo;
    thread_act_array_t threads;
    thread_basic_info_t basic_info_t;
    mach_msg_type_number_t count = 0;
    mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;
    
    if (task_threads(mach_task_self(), &threads, &count) == KERN_SUCCESS) {
        for (int idx = 0; idx < count; idx++) {
            if (thread_info(threads[idx], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count) == KERN_SUCCESS) {
                basic_info_t = (thread_basic_info_t)thinfo;
                if (!(basic_info_t->flags & TH_FLAGS_IDLE)) {
                    usageRatio += basic_info_t->cpu_usage / (double)TH_USAGE_SCALE;
                }
            }
        }
        assert(vm_deallocate(mach_task_self(), (vm_address_t)threads, count * sizeof(thread_t)) == KERN_SUCCESS);
    }
    
    usageRatio = usageRatio * 100;
    
    return [NSString stringWithFormat:@"%0.2lf%%",usageRatio];
}

+ (NSString *)getIPAddress
{
    NSString *address = @"Error.";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString
                               stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    
    return address;
}


#pragma mark - 屏幕快照

+ (UIImage *)snapsHotView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size,YES,[UIScreen mainScreen].scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)convertViewToImage:(UIView *)view
{
    //https://github.com/alskipp/ASScreenRecorder 录屏代码
    // 第二个参数表示是否非透明。如果需要显示半透明效果，需传NO，否则YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(view.bounds.size,YES,[UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
