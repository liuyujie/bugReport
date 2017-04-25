//
//  TOMMessageModel.h
//  TomService
//
//  Created by CodingTom on 2017/4/25.
//  Copyright © 2017年 CodingTom. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TOMMessageType) {
    TOMMessageTypeLogin = 0,
    TOMMessageTypeRunJS,
    TOMMessageTypePing
};

@interface TOMMessageModel : NSObject

- (instancetype)initWithSocketData:(NSData *)socketData;

- (instancetype)initWithType:(TOMMessageType)type andMessageDic:(NSDictionary *)dataDic;

@property (nonatomic,assign) TOMMessageType type;
@property (nonatomic,strong) NSDictionary *dataDic;
@property (nonatomic,assign) UInt32 tag;

- (NSData *)getSendData;

@end
