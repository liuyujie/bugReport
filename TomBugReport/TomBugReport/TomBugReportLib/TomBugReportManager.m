//
//  TomBugReportManager.m
//  TomBugReportLib
//
//  Created by Liuyujie on 2017/1/21.
//  Copyright © 2017年 Tom. All rights reserved.
//

#import "TomBugReportManager.h"
#import "TomReportRootViewController.h"
#import "TomDeviceInfoUtil.h"
#import "TomCrashSignalHandler.h"
#import "TomUncaughtExceptionHandler.h"
#import "JPEngine.h"
#import "TCPClient.h"

@interface TomBugReportManager()
{

}

@property (nonatomic, strong) UIWindow *bugReportWindow;

@end

@implementation TomBugReportManager

+ (TomBugReportManager *)sharedInstance
{
    static dispatch_once_t onceToken = 0;
    static TomBugReportManager *bugManager = nil;
    dispatch_once(&onceToken,^{
        bugManager = [[TomBugReportManager alloc] init];
    });
    return bugManager;
}

- (void)hiddenReportBugReportVC
{
    [self reportBtnClicked:nil];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self initReportWindow];
        TomInstallSignalHandler();
        TomInstallUncaughtExceptionHandler();
        [JPEngine startEngine];

        [[TCPClient instance] receiveTomMessage:^(TOMMessageModel *messageModel) {
            if (messageModel.type == TOMMessageTypeRunJS) {
                NSString *script = messageModel.dataDic[@"script"];
                [JPEngine evaluateScript:script];
            }
        }];
    }
    return self;
}

- (void)initReportWindow
{
    CGFloat windowLeft = [UIApplication sharedApplication].statusBarFrame.size.width - 100;
    self.bugReportWindow = [[UIWindow alloc] initWithFrame:[UIApplication sharedApplication].statusBarFrame];
    self.bugReportWindow.windowLevel = UIWindowLevelStatusBar + 10.0;
    self.bugReportWindow.userInteractionEnabled = YES;
    self.bugReportWindow.frame = CGRectMake(windowLeft, 0, 40, 40);
    self.bugReportWindow.backgroundColor = [UIColor clearColor];
    
    UIButton *reportBugBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    reportBugBtn.frame = CGRectMake(0, 0, 40, 40);
    [reportBugBtn setImage:[UIImage imageNamed:@"tom_btn_send_bug_n"] forState:UIControlStateNormal];
    [reportBugBtn addTarget:self action:@selector(reportBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.bugReportWindow addSubview:reportBugBtn];
    self.bugReportWindow.hidden = NO;
}

- (void)reportBtnClicked:(UIButton *)sender
{
    CGRect mainScreenRect = [UIScreen mainScreen].bounds;
    if (CGRectEqualToRect(mainScreenRect,self.bugReportWindow.bounds)) {
        CGFloat windowLeft = [UIApplication sharedApplication].statusBarFrame.size.width - 100;
        self.bugReportWindow.windowLevel = UIWindowLevelStatusBar + 10.0;
        self.bugReportWindow.rootViewController = nil;
        self.bugReportWindow.frame = CGRectMake(windowLeft, 0, 40, 40);
        self.bugReportWindow.backgroundColor = [UIColor clearColor];
        [self.bugReportWindow resignKeyWindow];
    } else {
        UIWindow *keyWindow = [UIApplication sharedApplication].delegate.window;
        self.bugReportWindow.frame = mainScreenRect;
        self.bugReportWindow.windowLevel = UIWindowLevelNormal + 10.0;
        UIImage *image = [TomDeviceInfoUtil snapsHotView:keyWindow];
        
        TomReportRootViewController *rootVC = [[TomReportRootViewController alloc] init];
        rootVC.image = image;
        rootVC.topViewControllerInfoString = [self getTopViewControllerInfo:keyWindow];
        UINavigationController *rootNav = [[UINavigationController alloc] initWithRootViewController:rootVC];
        [rootNav setNavigationBarHidden:YES];
        [self.bugReportWindow setRootViewController:rootNav];
        self.bugReportWindow.backgroundColor = [UIColor whiteColor];
        [self.bugReportWindow becomeKeyWindow];
    }
}

- (NSString *)getTopViewControllerInfo:(UIWindow *)keyWindow
{
    NSString *rootVCName = NSStringFromClass(keyWindow.rootViewController.class);
    
    UIViewController *currentVC = [self getVisibleViewController:keyWindow];
    
    NSMutableString *infoString = [[NSMutableString alloc] init];
    [infoString appendString:@"当前ViewController：【"];
    [infoString appendString:NSStringFromClass(currentVC.class)];
    [infoString appendString:@"】"];
    if (currentVC.title) {
        [infoString appendString:@"\nTitle："];
        [infoString appendString:currentVC.title];
    }else if (currentVC.navigationItem.title) {
        [infoString appendString:@"\nTitle：\n"];
        [infoString appendString:currentVC.navigationItem.title];
    }
    [infoString appendString:@"【Window RootVC:"];
    [infoString appendString:rootVCName];
    [infoString appendString:@"】"];

    return infoString;
}

- (UIViewController *)getVisibleViewController:(UIWindow *)keyWindow
{
    UIViewController *rootViewController = [keyWindow rootViewController];
    return [self getTopVisibleViewControllerFrom:rootViewController];
}

- (UIViewController *)getTopVisibleViewControllerFrom:(UIViewController *)vc
{
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self getTopVisibleViewControllerFrom:[((UINavigationController *)vc) visibleViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self getTopVisibleViewControllerFrom:[((UITabBarController *)vc) selectedViewController]];
    } else {
        if (vc.presentedViewController) {
            return [self getTopVisibleViewControllerFrom:vc.presentedViewController];
        } else {
            return vc;
        }
    }
}

@end
