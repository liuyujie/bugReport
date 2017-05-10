//
//  TomFPSMonitor.h
//  TomBugReport
//
//  Created by Liuyujie on 2017/5/10.
//  Copyright © 2017年 Chemi Technologies(Beijing)Co.,ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TomFPSMonitor : NSObject

+ (instancetype)shareInstance;

- (void)startFPSMonitor;

- (void)stopFPSMonitor;

- (NSInteger)getCurrentFPS;

@end
