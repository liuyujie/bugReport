//
//  ViewController.m
//  TomBugReport
//
//  Created by Liuyujie on 2017/3/8.
//  Copyright © 2017年 Chemi Technologies(Beijing)Co.,ltd. All rights reserved.
//

#import "ViewController.h"
#import "TCPClient.h"
#import "TomFPSMonitor.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[TCPClient instance] requestLogin:@"" password:@"" completion:^(id response, NSString *error) {
        
    }];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"1" message:@"1" delegate:nil cancelButtonTitle:@"2" otherButtonTitles:nil];
    [alertView show];
    
    [[TomFPSMonitor shareInstance] startFPSMonitor];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onTestBtnClicked:(UIButton *)sender
{
//    [self sendRequest:@"https://api.fir.im/apps?api_token=123"];
    
    TOMMessageModel *model = [[TOMMessageModel alloc] initWithType:TOMMessageTypeRunJS andMessageDic:@{@"run":@"tom.js"}];
    [[TCPClient instance] sendTomMessage:model completion:^(id response, NSString *error) {
        
    }];
//
}

- (void)sendRequest:(NSString *)url
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (result) {
            NSLog(@"%s_%s:\n%@",__FILE__,__func__,result);
        }
    }];
    [dataTask resume];
}

@end
