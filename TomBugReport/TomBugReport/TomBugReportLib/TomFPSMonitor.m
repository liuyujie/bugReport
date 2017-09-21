//
//  TomFPSMonitor.m
//  TomBugReport
//
//  Created by Liuyujie on 2017/5/10.
//  Copyright © 2017年 Chemi Technologies(Beijing)Co.,ltd. All rights reserved.
//

#import "TomFPSMonitor.h"
#import "TomDeviceInfoUtil.h"

@interface TomFPSMonitor ()
{
    BOOL            _isPause;
    CADisplayLink   *_displayLink;
    CFTimeInterval  _lastUpdateTimestamp;
    NSUInteger      _historyCount;
    NSInteger       _currentFPS;
    
    NSTimeInterval  _lastReportTime;
    BOOL            _isGeneratingReport;
}

@end

@implementation TomFPSMonitor

+ (instancetype)shareInstance {
    static TomFPSMonitor *fpsMonitor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fpsMonitor = [[TomFPSMonitor alloc] init];
    });
    return fpsMonitor;
}

- (id)init {
    self = [super init];
    if( self ){
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick)];
        _displayLink.frameInterval = 2;
        [_displayLink setPaused:YES];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)displayLinkTick
{
    if (_lastUpdateTimestamp <= 0) {
        _lastUpdateTimestamp = _displayLink.timestamp;
        return;
    }
    _historyCount += _displayLink.frameInterval;
    CFTimeInterval interval = _displayLink.timestamp - _lastUpdateTimestamp;
    if(interval >= 0.5) {
        _lastUpdateTimestamp = _displayLink.timestamp;
        _currentFPS = _historyCount / interval;
        _historyCount = 0;
        [self fpsUpdated:_currentFPS];
    }
}

- (void)fpsUpdated:(NSInteger)currentFPS
{
    NSLog(@"current fpsUpdated %ld ",currentFPS);
    
    if (currentFPS <= 40 && currentFPS > 0){
        [self reportFPSLow];
    }
    NSLog(@"%@\n%@\n%@",[TomDeviceInfoUtil getIPAddress],[TomDeviceInfoUtil getAppCPUUsage],[TomDeviceInfoUtil getAppMemoryUsage]);

}

- (void)startFPSMonitor {
    NSLog(@"FPS monitor start");
    _isPause = NO;
    _historyCount = 0;
    _lastUpdateTimestamp = 0;
    [_displayLink setPaused:NO];
}

- (void)stopFPSMonitor {
    NSLog(@"FPS monitor stop");
    _isPause = YES;
    _historyCount = 0;
    _lastUpdateTimestamp = 0;
    [_displayLink setPaused:YES];
}

#pragma mark - 卡顿上报

- (void )reportFPSLow
{
    if (_isPause || _isGeneratingReport) {
        return;
    }
    CFTimeInterval currentTime = CACurrentMediaTime() * 1000.0;
    if (currentTime - _lastReportTime <= 5 * 1000.0) {
        return;
    }
    _isGeneratingReport = YES;
    _lastReportTime = currentTime;

    NSLog(@"start gen report");
//    NSString *crashReport = [GYMonitorUtils genCrashReport];
    
    _isGeneratingReport = NO;
}

- (NSInteger)getCurrentFPS
{
    return _currentFPS;
}

@end
