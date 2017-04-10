//
//  UncaughtExceptionHandler.m
//  UncaughtExceptionDemo
//
//  Created by  tomxiang on 15/8/28.
//  Copyright (c) 2015年  tomxiang. All rights reserved.
//

#import "TomUncaughtExceptionHandler.h"
#import <UIKit/UIKit.h>

@implementation TomUncaughtExceptionHandler

+ (void)SaveExceptionCreash:(NSString *)exceptionInfo
{
    NSString *logPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"OCExceptionCrash"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:logPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:logPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDate *date = [NSDate date];
    NSTimeInterval time = [date timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%f",time];
    
    NSString *savePath = [logPath stringByAppendingFormat:@"/OC_error%@.log",timeString];
    [exceptionInfo writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end

void TomHandleException(NSException *exception)
{
    NSArray *stackArray = [exception callStackSymbols];    // 异常的堆栈信息
    NSString *reason = [exception reason];    // 出现异常的原因
    NSString *name = [exception name];    // 异常名称
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@",name, reason, stackArray];
    [TomUncaughtExceptionHandler SaveExceptionCreash:exceptionInfo];
}

void TomInstallUncaughtExceptionHandler(void)
{
    NSSetUncaughtExceptionHandler(&TomHandleException);
}
