//
//  TOMMessageModel.m
//  TomService
//
//  Created by CodingTom on 2017/4/25.
//  Copyright © 2017年 CodingTom. All rights reserved.
//

#import "TOMMessageModel.h"

@implementation TOMMessageModel

- (instancetype)initWithSocketData:(NSData *)socketData
{
    self = [super init];
    if (self) {
        NSDictionary *dic = [self JSONToDic:socketData];
        if (dic) {
            _type = [(NSString *)dic[@"mType"] integerValue];
            _tag = (UInt32)[(NSString *)dic[@"mTag"] integerValue];
            _dataDic = dic;
        }
    }
    return self;
}

- (instancetype)initWithType:(TOMMessageType)type andMessageDic:(NSDictionary *)dataDic
{
    self = [super init];
    if (self) {
        _type = type;
        _dataDic = dataDic;
    }
    return self;
}

- (NSData *)getSendData
{
    NSMutableDictionary *socketDic = [[NSMutableDictionary alloc] init];
    [socketDic setObject:[NSString stringWithFormat:@"%lu",self.type] forKey:@"mType"];
    [socketDic setObject:[NSString stringWithFormat:@"%u",self.tag] forKey:@"mTag"];
    [socketDic addEntriesFromDictionary:self.dataDic];
    NSString *dataString = [self dicToJSONString:socketDic];
    NSUInteger length = [dataString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *data = [[NSMutableData alloc] initWithLength:0];
    [data appendBytes:[dataString cStringUsingEncoding:NSUTF8StringEncoding] length:length];
    return data;
}

- (NSString *)dicToJSONString:(NSDictionary *)dic
{
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    if (jsonData) {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

- (NSDictionary *)JSONToDic:(NSData *)socketData
{
    NSError *error;
    id result = [NSJSONSerialization JSONObjectWithData:socketData options:NSJSONReadingMutableContainers error:&error];
    if ([result isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)result;
    }
    return nil;
}

@end
