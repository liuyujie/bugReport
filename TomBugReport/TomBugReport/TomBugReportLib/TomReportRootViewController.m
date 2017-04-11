//
//  TomReportRootViewController.m
//  Demo
//
//  Created by Liuyujie on 2017/1/21.
//  Copyright © 2017年 Tom. All rights reserved.
//

#import "TomReportRootViewController.h"
#import "TomBugReportManager.h"
#import "TomClientInfoUtil.h"

@interface TomReportRootViewController ()<UIAlertViewDelegate>
{
    CGSize   mainSize;
}

@end

@implementation TomReportRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    mainSize = [[UIScreen mainScreen] bounds].size;

    [self initImageView:self.image];
    [self initDesLabel:[self getDesText]];
    [self initBottomView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)getDesText
{
    NSMutableString *text = [[NSMutableString alloc] initWithString:self.topViewControllerInfoString];
    [text appendString:[TomClientInfoUtil getSystemNameAndVersion]];
    [text appendString:[TomClientInfoUtil getDeviceName]];
    return text;
}

#pragma mark - UIButton Action

- (void)onReportBtnClicked:(UIButton *)sender
{
    UIImage *savedImage = [TomBugReportManager snapsHotView:self.view.window];
    [self saveImageToPhotos:savedImage];
}

- (void)onCloseBtnClicked:(UIButton *)sender
{
    [[TomBugReportManager sharedInstance] hiddenReportBugReportVC];
}

- (void)saveImageToPhotos:(UIImage *)savedImage
{
    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *) contextInfo
{
    NSString *msg = nil ;
    if(error != NULL){
        msg = @"保存图片失败" ;
    } else {
        msg = @"保存图片成功" ;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"保存结果" message:msg delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}

#pragma mark - UIAlertViewDeleage
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self onCloseBtnClicked:nil];
}

#pragma mark - init View

- (void)initImageView:(UIImage *)image
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(mainSize.width * 0.15f, 20, mainSize.width * 0.7f, mainSize.height * 0.7f)];
    imageView.layer.masksToBounds = YES;
    imageView.layer.cornerRadius = 4;
    imageView.layer.borderWidth = 2;
    imageView.layer.borderColor = [UIColor orangeColor].CGColor;
    imageView.image = image;
    
    [self.view addSubview:imageView];
}

- (void)initDesLabel:(NSString *)text
{
    UILabel *desLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, mainSize.height * 0.7f + 20, mainSize.width - 20,mainSize.height * 0.2f)];
    desLabel.font = [UIFont systemFontOfSize:14];
    desLabel.numberOfLines = 0;
    desLabel.textColor = [UIColor darkTextColor];
    desLabel.text = text;
    [self.view addSubview:desLabel];
}

- (void)initBottomView
{
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, mainSize.height - 60, mainSize.width, 60)];
    
    UIButton *reportBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    reportBtn.frame = CGRectMake(mainSize.width / 2 + 5, 10, mainSize.width / 2 - 20, 40);
    [reportBtn setTitle:@"存到相册" forState:UIControlStateNormal];
    reportBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    reportBtn.titleLabel.textColor = [UIColor whiteColor];
    reportBtn.backgroundColor = [UIColor redColor];
    reportBtn.layer.masksToBounds = YES;
    reportBtn.layer.cornerRadius = 4;
    [reportBtn addTarget:self action:@selector(onReportBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:reportBtn];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(15, 10, mainSize.width / 2 - 20, 40);
    [closeBtn setTitle:@"关闭页面" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    closeBtn.titleLabel.textColor = [UIColor whiteColor];
    closeBtn.backgroundColor = [UIColor grayColor];
    closeBtn.layer.masksToBounds = YES;
    closeBtn.layer.cornerRadius = 4;
    [closeBtn addTarget:self action:@selector(onCloseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:closeBtn];
    
    [self.view addSubview:bottomView];
}

@end
