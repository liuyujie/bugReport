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

@end
