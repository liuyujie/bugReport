//
//  TomDeviceInfoUtil.h
//  TomBugReportLib
//
//  Created by Liuyujie on 2017/3/8.
//  Copyright © 2017年 Tom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TomDeviceInfoUtil : NSObject

+ (NSString *)getDeviceName;

+ (NSString *)getSystemNameAndVersion;

+ (NSString *)getAppPath;

+ (NSString *)getAppMemoryUsage;

+ (NSString *)getAppCPUUsage;

+ (NSString *)getIPAddress;

+ (UIImage *)snapsHotView:(UIView *)view;

@end
