// The MIT License
//
// Copyright (c) 2016 Dariusz Bukowski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DBURLProtocol.h"
#import "DBRequestOutcome.h"

static NSString *const DBURLProtocolHandledKey = @"DBURLProtocolHandled";

@interface DBURLProtocol ()

@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation DBURLProtocol

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task {
    NSURLRequest *request = task.currentRequest;
    return request == nil ? NO : [self canInitWithRequest:request];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
//    if (![DBNetworkToolkit sharedInstance].loggingEnabled) {
//        return NO;
//    }
    
    if ([[self propertyForKey:DBURLProtocolHandledKey inRequest:request] boolValue]) {
        return NO;
    }
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
//    [[DBNetworkToolkit sharedInstance] saveRequest:self.request];
    NSMutableURLRequest *request = [[DBURLProtocol canonicalRequestForRequest:self.request] mutableCopy];
    
    [DBURLProtocol setProperty:@YES forKey:DBURLProtocolHandledKey inRequest:request];
    
    if (!self.urlSession) {
        self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    
    [[self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error != nil) {
            [self finishWithOutcome:[DBRequestOutcome outcomeWithError:error]];
            [self.client URLProtocol:self didFailWithError:error];
        } else {
            [self finishWithOutcome:[DBRequestOutcome outcomeWithResponse:response data:data]];
        }
        
        if (response != nil) {
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        }
        
        if (data != nil) {
            [self.client URLProtocol:self didLoadData:data];
        }
        
        [self.client URLProtocolDidFinishLoading:self];
    }] resume];
}

- (void)stopLoading {
    // Do nothing
}

- (void)finishWithOutcome:(DBRequestOutcome *)requestOutcome {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)requestOutcome.response;
    if (httpResponse.statusCode == 200) {
        NSString *dataString  = [[NSString alloc] initWithData:requestOutcome.data encoding:NSUTF8StringEncoding];
        NSLog(@"Coding Tom:\n%@",dataString);
    }
    
//    [[DBNetworkToolkit sharedInstance] saveRequestOutcome:requestOutcome forRequest:self.request];
}

@end
