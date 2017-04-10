//
//  TomEditImageViewController.m
//  TomBugReport
//
//  Created by Liuyujie on 2017/4/10.
//  Copyright © 2017年 Chemi Technologies(Beijing)Co.,ltd. All rights reserved.
//

#import "TomEditImageViewController.h"

@interface TomEditImageViewController ()
{
    CGSize   mainSize;
}

@property (nonatomic,strong)UILabel *titleLabel;

@end

@implementation TomEditImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    mainSize = [[UIScreen mainScreen] bounds].size;
    // Do any additional setup after loading the view.
    [self initBackAndDoneBtn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initBackAndDoneBtn
{
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(0, 0, 60, 32);
    [closeBtn addTarget:self action:@selector(onCloseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [closeBtn setTitle:@"返回" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [self.view addSubview:closeBtn];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, mainSize.width - 120, 32)];
    _titleLabel.font = [UIFont systemFontOfSize:13];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.text = @"点击底部工具开始标注";
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_titleLabel];
    
    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.frame = CGRectMake(mainSize.width - 60, 0, 60, 32);
    [doneBtn addTarget:self action:@selector(onCloseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [doneBtn setTitle:@"完成" forState:UIControlStateNormal];
    [doneBtn setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [self.view addSubview:doneBtn];
}

- (void)onCloseBtnClicked:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
