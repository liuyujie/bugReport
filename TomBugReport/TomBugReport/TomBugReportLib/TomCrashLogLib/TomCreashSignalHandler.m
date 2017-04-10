//
//  TomCreashSignalHandler.m
//  TomCrashLogLib
//
//  Created by Liuyujie on 2017/2/12.
//  Copyright © 2017年 Tom. All rights reserved.
//

#import "TomCreashSignalHandler.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import <UIKit/UIKit.h>
#import "TomUncaughtExceptionHandler.h"

@interface TomCreashSignalHandler()<UIAlertViewDelegate>

@end

@implementation TomCreashSignalHandler

+ (void)SaveSignalCreash:(NSString *)exceptionInfo
{
    NSString *logPath  = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"TomSignalCrash"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:logPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:logPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDate *date = [NSDate date];
    NSTimeInterval time = [date timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%f",time];
    NSString *savePath = [logPath stringByAppendingFormat:@"/signal_error%@.log",timeString];
    [exceptionInfo writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end

void TomSignalExceptionHandler(int signal)
{
    NSMutableString *creashString = [[NSMutableString alloc] init];
    [creashString appendString:@"Stack:\n"];
    void* callstack[128];
    int i, frames = backtrace(callstack, 128);
    char** strs = backtrace_symbols(callstack, frames);
    for (i = 0; i <frames; ++i) {
        [creashString appendFormat:@"%s\n", strs[i]];
    }
    [TomCreashSignalHandler SaveSignalCreash:creashString];
}

void TomInstallSignalHandler(void)
{
    signal(SIGHUP, TomSignalExceptionHandler);
    signal(SIGINT, TomSignalExceptionHandler);
    signal(SIGQUIT, TomSignalExceptionHandler);
    
    signal(SIGABRT, TomSignalExceptionHandler);
    signal(SIGILL, TomSignalExceptionHandler);
    signal(SIGSEGV, TomSignalExceptionHandler);
    signal(SIGFPE, TomSignalExceptionHandler);
    signal(SIGBUS, TomSignalExceptionHandler);
    signal(SIGPIPE, TomSignalExceptionHandler);
}

