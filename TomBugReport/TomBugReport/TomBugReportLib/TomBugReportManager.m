//
//  TomBugReportManager.m
//  Demo
//
//  Created by Liuyujie on 2017/1/21.
//  Copyright © 2017年 Tom. All rights reserved.
//

#import "TomBugReportManager.h"
#import "TomReportRootViewController.h"

@interface TomBugReportManager()
{

}

@property (nonatomic, strong) UIWindow *bugReportWindow;


@end

@implementation TomBugReportManager

+ (TomBugReportManager *)sharedInstance
{
    static dispatch_once_t onceToken;
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
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 40, 40);
    [btn setImage:[UIImage imageNamed:@"tom_btn_send_bug_n"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(reportBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.bugReportWindow addSubview:btn];
    self.bugReportWindow.hidden = NO;
}

- (void)reportBtnClicked:(UIButton *)sender
{
    CGRect mainScreenRect = [UIScreen mainScreen].bounds;
    if (self.bugReportWindow.frame.size.height == mainScreenRect.size.height) {
        CGFloat windowLeft = [UIApplication sharedApplication].statusBarFrame.size.width - 100;
        self.bugReportWindow.windowLevel = UIWindowLevelStatusBar + 10.0;
        self.bugReportWindow.rootViewController = nil;
        self.bugReportWindow.frame = CGRectMake(windowLeft, 0, 40, 40);
        self.bugReportWindow.backgroundColor = [UIColor clearColor];
        [self.bugReportWindow resignKeyWindow];
    }else{
        UIWindow *keyWindow = [UIApplication sharedApplication].delegate.window;
        self.bugReportWindow.frame = mainScreenRect;
        self.bugReportWindow.windowLevel = UIWindowLevelNormal + 10.0;
        UIImage *image = [TomBugReportManager snapsHotView:keyWindow];
        TomReportRootViewController *rootVC = [[TomReportRootViewController alloc] init];
        rootVC.image = image;
        rootVC.windowInfoString = [self getWindowInfo:keyWindow];
        [self.bugReportWindow setRootViewController:rootVC];
        self.bugReportWindow.backgroundColor = [UIColor whiteColor];
        [self.bugReportWindow becomeKeyWindow];
    }
}

- (NSString *)getWindowInfo:(UIWindow *)keyWindow
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
    return [self getVisibleViewControllerFrom:rootViewController];
}

- (UIViewController *)getVisibleViewControllerFrom:(UIViewController *)vc
{
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self getVisibleViewControllerFrom:[((UINavigationController *) vc) visibleViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self getVisibleViewControllerFrom:[((UITabBarController *) vc) selectedViewController]];
    } else {
        if (vc.presentedViewController) {
            return [self getVisibleViewControllerFrom:vc.presentedViewController];
        } else {
            return vc;
        }
    }
//    - (UINavigationController *)visibleNavigationController
//    {
//        return [[self visibleViewController] navigationController];
//    }
}



#pragma mark - 屏幕快照

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

+ (UIImage *)snapsHotView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size,YES,[UIScreen mainScreen].scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
