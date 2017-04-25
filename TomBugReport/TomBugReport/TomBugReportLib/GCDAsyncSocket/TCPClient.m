//
//  TCPAPI.m
//  GCDAsyncSocket使用
//
//  Created by caokun on 16/7/2.
//  Copyright © 2016年 caokun. All rights reserved.
//

#import "TCPClient.h"
#import "SocketClientManager.h"

@interface TCPClient () <SocketClientManagerDelegate>

@property (strong, nonatomic) dispatch_queue_t APIQueue;
@property (strong, nonatomic) dispatch_semaphore_t semaphore;       // seq 同步信号
@property (strong, nonatomic) dispatch_semaphore_t loginSem;        // 重登录同步信号
@property (assign, nonatomic) UInt32 seq;
@property (strong, nonatomic) NSMutableDictionary *callbackBlock;   // 保存请求回调 {seq: block}, 超时要踢掉
@property (strong, nonatomic) NSLock *dictionaryLock;
@property (strong, nonatomic) NSMutableData *buffer;            // 接收缓冲区
@property (strong, nonatomic) NSTimer *heartTimer;              // 心跳 timer
@property (assign, nonatomic) BOOL shouldHeart;                 // 是否要心跳
@property (assign, nonatomic) BOOL netWorkStatus;               // 网络联通性
@property (assign, nonatomic) BOOL isLogin;                 // 登录状态, 退出，被踢, socket断开，要设为 false
@property (assign, nonatomic) BOOL autoLogin;                   // 自动登录，收到踢人包, 主动退出置为 false, 登录时 true

@end

@implementation TCPClient

static TCPClient *instance = nil;

+ (TCPClient *)instance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TCPClient alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
//        [[NetWorkManager instance] startListen];     // 程序启动要开启网络状态监听
        [SocketClientManager instance].delegate = self;       // 创建 socket
        [[SocketClientManager instance] connectWithIP:@"192.168.1.100" port:5866];
        self.semaphore = dispatch_semaphore_create(1);
        self.APIQueue = dispatch_queue_create("tom.client.api", DISPATCH_QUEUE_SERIAL);
        self.seq = 1000;
        self.dictionaryLock = [[NSLock alloc] init];
        self.callbackBlock = [[NSMutableDictionary alloc] init];
        self.buffer = [[NSMutableData alloc] init];
        [self.buffer setLength:0];
        self.netWorkStatus = YES;      // 首次运行认为有网络，因为 NetWorkManager 启动要时间，假如没网会超时返回
        self.isLogin = NO;
        self.autoLogin = YES;
        self.shouldHeart = YES;        // 默认开启心跳，应该要获取登录状态判断要不要心跳
        if (self.shouldHeart) {
            [self startHeartBeat];
        } else {
            [self closeHeartBeat];
        }
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netWorkStatusChanged:) name:NetWorkDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.semaphore = nil;
    self.APIQueue = nil;
    self.buffer = nil;
}

- (UInt32)seq {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    _seq = _seq + 1;
    dispatch_semaphore_signal(self.semaphore);
    return _seq;
}

// ----------- tcp 打包，并发送, callback 回调 block ------------
- (void)send:(TOMMessageModel *)rootMsg seq:(UInt32)s callback:(TCPBlock)block {
    // 无网络直接返回
    if (self.netWorkStatus == false) {
        if (block) block(nil, @"无网络");
        return ;
    }
//    if (self.loginStatus == false && self.autoLogin == false) {
//        if (block) block(nil, @"被踢不能自动登录");
//        return ;
//    }
    
    // 如果不是登录包，不是心跳包, 并且没登录，可以自动登录，先自动登录，登录失败返回错误
    if ((!self.isLogin || ![[SocketClientManager instance] status])
        && self.autoLogin && rootMsg && rootMsg.type != TOMMessageTypeLogin) {
        NSLog(@"------开始进入自动登录-----");
        self.loginSem = dispatch_semaphore_create(0);
        
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSString *name = [ud objectForKey:@"UserName"];
        NSString *psw = [ud objectForKey:@"Password"];
        if (name && psw) {
            [[SocketClientManager instance] disConnect];      // 再次断开 socket，保证没登录
            [self createLoginAndSend:name password:psw completion:^(id response, NSString *error) {
                NSLog(@"自动登录返回");
                self.isLogin = error == nil ? YES : NO;
                self.autoLogin = self.isLogin;
                
                // 重登录不解析 response，都是一样的
                dispatch_semaphore_signal(self.loginSem);
            }];
        } else {
            self.isLogin = NO;
            self.autoLogin = NO;
            dispatch_semaphore_signal(self.loginSem);
        }
        // 等待重登录信号
        NSLog(@"等待重登录信号");
        dispatch_semaphore_wait(self.loginSem, DISPATCH_TIME_FOREVER);
        NSLog(@"通过重登录信号");
        if (!self.isLogin) {
            if (block) block(nil, @"自动登录失败, 请重新登录");    // 收到自动登录失败的，应该弹框重登录
            return ;
        } else {
            NSLog(@"自动登录成功");
        }
    }

    // 包头是 32 位的整型，表示包体长度
    
    NSData *messageData = [rootMsg getSendData];
    SInt32 length = (SInt32)[messageData length];
    NSMutableData *data = [NSMutableData dataWithBytes:&length length:4];
    [data appendData:messageData];      // 追加包体

    if (block != nil) {
        // 保存回调 block 到字典里，接收时候用到
        NSString *key = [NSString stringWithFormat:@"%u", s];
        [_dictionaryLock lock];
        [_callbackBlock setObject:block forKey:key];
        [_dictionaryLock unlock];
        
        // 30 秒超时, 找到 key 删除
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self timerRemove:key];
        });
    }
    NSLog(@"通知 socket 发送数据");
    [[SocketClientManager instance] send:data];   // 发送
}

- (void)timerRemove:(NSString *)key {
    if (key) {
        [_dictionaryLock lock];
        TCPBlock complete = [self.callbackBlock objectForKey:key];
        if (complete != nil) {
            complete(nil, @"null");
        }
        [_callbackBlock removeObjectForKey:key];
        [_dictionaryLock unlock];
    }
}

// ----------- tcp 拆包 ------------
// 上层调用者，同步队列回调该函数，所以不用加锁
- (void)socket:(GCDAsyncSocket *)socket didReadData:(NSData *)data {
    [_buffer appendData:data];
    
    while (_buffer.length >= 4) {
        SInt32 length = 0;
        [_buffer getBytes:&length length:4];    // 读取长度
        
        if (length == 0) {
            if (_buffer.length >= 4) {          // 长度够不够心跳包
                NSData *tmp = [_buffer subdataWithRange:NSMakeRange(4, _buffer.length - 4)];
                [_buffer setLength:0];      // 清零
                [_buffer appendData:tmp];
            } else {
                [_buffer setLength:0];
            }
            [self receive:nil];    // 分发数据包
        } else {
            NSUInteger packageLength = 4 + length;
            if (packageLength <= _buffer.length) {     // 长度判断
                NSData *rootData = [_buffer subdataWithRange:NSMakeRange(4, length)];
                TOMMessageModel *root = [[TOMMessageModel alloc] initWithSocketData:rootData];
                // 截取
                NSData *tmp = [_buffer subdataWithRange:NSMakeRange(packageLength, _buffer.length - packageLength)];
                [_buffer setLength:0];      // 清零
                [_buffer appendData:tmp];
                [self receive:root];    // 分发包
            } else {
                break;
            }
        }
    }
}

//// 收到包进行分发
- (void)receive:(TOMMessageModel *)root {
    if (root == nil) {
        return ;
    }
    NSString *key = [NSString stringWithFormat:@"%u", root.tag];
    [_dictionaryLock lock];
    id obj = [self.callbackBlock objectForKey:key];
    [self.callbackBlock removeObjectForKey:key];
    [_dictionaryLock unlock];
    
    TCPBlock complete = nil;
    if (obj != nil) {
        complete = (TCPBlock)obj;
    }
    
    switch (root.type) {
        case TOMMessageTypeLogin:
            [self receiveLogin:root completion:complete];
            break;
            
        case TOMMessageTypeRunJS:
            [self receiveRunJS:root completion:complete];
            break;
        case TOMMessageTypePing:
            NSLog(@"收到心跳包 %ld %@", (long)root.type,root.dataDic);
            break;
        default:
            NSLog(@"收到未知包 %ld", (long)root.type);
            break;
    }
}

// 网络状态变化
- (void)netWorkStatusChanged:(NSNotification *)nofiy {
    dispatch_async(self.APIQueue, ^{
        NSDictionary *info = nofiy.userInfo;
        if (info && info[@"status"]) {
            NSNumber *status = info[@"status"];
            self.netWorkStatus = [status boolValue];
            if (self.netWorkStatus) {
                [self tryOpenPingTimer];
            } else {
                [self closeTimer];
                // 网络断开，清空发送回调队列，登录状态为 false
                self.isLogin = NO;
                [self cleanSendQueue];
            }
        }
    });
}

// socket 状态变化
- (void)socket:(GCDAsyncSocket *)socket didConnect:(NSString *)host port:(uint16_t)port {
    [self tryOpenPingTimer];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket {
    self.isLogin = NO;
    [self closeTimer];
    [self.buffer setLength:0];
}

// 清空发送队列
- (void)cleanSendQueue {
    [_dictionaryLock lock];
    NSLog(@"清空发送队列");
    for (NSString *key in self.callbackBlock) {
        TCPBlock complete = [self.callbackBlock objectForKey:key];
        if (complete != nil) {
            complete(nil, @"null");
        }
    }
    [self.callbackBlock removeAllObjects];
    [_dictionaryLock unlock];
}

// 开启心跳
- (void)startHeartBeat {
    self.shouldHeart = true;
    [self tryOpenPingTimer];
}

// 关闭心跳
- (void)closeHeartBeat {
    self.shouldHeart = false;
    [self closeTimer];
}

- (void)tryOpenPingTimer {
    // 有网，tcp登录了，并且调用层要打开心跳时，才开启心跳
    if (self.netWorkStatus && [[SocketClientManager instance] status] && self.shouldHeart) {
        [self sendHeart];
        [self closeTimer];
        // timer 要在主线程中开启才有效
        dispatch_async(dispatch_get_main_queue(), ^{
            self.heartTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(sendHeart) userInfo:nil repeats:true];
        });
    }
}

- (void)closeTimer {
    if (self.heartTimer != nil) {
        [self.heartTimer invalidate];
        self.heartTimer = nil;
    }
}

- (void)sendHeart
{
    UInt32 tag = self.seq;
    TOMMessageModel *pingModel = [[TOMMessageModel alloc] initWithType:TOMMessageTypePing andMessageDic:nil];
    pingModel.tag = tag;
    [self send:pingModel seq:tag callback:nil];
}

#pragma - mark 以下是请求 api
// 登录请求包
- (void)requestLogin:(NSString *)name password:(NSString *)psw completion:(TCPBlock)block {
    dispatch_async(self.APIQueue, ^{
        self.autoLogin = true;      // 主动登录，设置自动登录
        // 如果登录了，先下线
        if ([[SocketClientManager instance] status] && self.isLogin) {
            [[SocketClientManager instance] disConnect];
        }
        // 保存用户名密码到文件，应该加密保存
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:name forKey:@"UserName"];
        [ud setObject:psw forKey:@"Password"];
        
        [self createLoginAndSend:name password:psw completion:block];
    });
}

// 创建并发送登录包
- (void)createLoginAndSend:(NSString *)name password:(NSString *)psw completion:(TCPBlock)block{
    
    UInt32 tag = self.seq;
    TOMMessageModel *model = [[TOMMessageModel alloc] initWithType:TOMMessageTypeLogin andMessageDic:@{@"username":@"刘裕杰",@"password":@"liuyujie"}];
    model.tag = tag;
    [self send:model seq:tag callback:block];
}

// 登录返回包
- (void)receiveLogin:(TOMMessageModel *)root completion:(TCPBlock)block {
    
    if (root.dataDic[@"loginStatus"]) {
        self.isLogin = YES;
        self.autoLogin = YES;
        [self startHeartBeat];
        NSLog(@"---------Login Success-------------");
        if (block) block(root.dataDic, nil);
        if (block) block(nil, @"登录成功");
    } else {
        NSLog(@"---------Login Error-------------");
        self.isLogin = NO;
        self.autoLogin = NO;
        if (block) block(nil, @"登录失败");
    }
}

// 登录返回包
- (void)receiveRunJS:(TOMMessageModel *)root completion:(TCPBlock)block {
    
    if (root.dataDic[@"Run"]) {
        if (block) block(root.dataDic, nil);
    } else {
        if (block) block(nil, @"");
    }
}

- (void)sendTomMessage:(TOMMessageModel *)messageModel completion:(TCPBlock)block
{
    dispatch_async(self.APIQueue, ^{
        UInt32 tag = self.seq;
        messageModel.tag = tag;
        [self send:messageModel seq:tag callback:block];
    });
}

// 收到踢人包
- (void)receiveKick {
    [[SocketClientManager instance] disConnect];
    [self closeHeartBeat];
    self.isLogin = NO;
    self.autoLogin = NO;
}

@end

