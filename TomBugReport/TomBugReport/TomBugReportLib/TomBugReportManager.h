//
//  TomBugReportManager.h
//  TomBugReportLib
//
//  Created by Liuyujie on 2017/1/21.
//  Copyright © 2017年 Tom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TomBugReportManager : NSObject

+ (TomBugReportManager *)sharedInstance;

+ (UIImage *)snapsHotView:(UIView *)view;

- (void)hiddenReportBugReportVC;

@end
