//
//  URLSchemeProrocol.m
//  MYIURLMediator
//
//  Created by MasterYi on 2020/9/23.
//

#import "URLSchemeProrocol.h"
#import <objc/runtime.h>


@implementation URLSchemeProrocol

// 在拦截到网络请求后会调用这一方法，可以再次处理拦截的逻辑
+ (BOOL)canInitWithRequest:(NSURLRequest *)request{
    NSString *scheme = request.URL.scheme;
    if ([scheme isEqualToString:loacalHost]) {
        // 看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:loacalHost inRequest:request]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request{
    return request;
}


+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b{
    return NO;
}

- (void)startLoading{
    // 转成可变对象
    NSMutableURLRequest *request = [self.request mutableCopy];
    // 标志tag
    [NSURLProtocol setProperty:@YES forKey:loacalHost inRequest:request];
    __weak typeof(self) weakSelf = self;
    [self dealRequestWithUrl:request.URL callback:^(NSData *data, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf responseWithData:data error:error];
    }];
}

- (void)stopLoading{
    // 清空请求

}

-(void)dealRequestWithUrl:(NSURL *)url callback:(void(^)(NSData *data,NSError *error))callback{
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    NSString *path = components.path;
    NSString *className = components.host;
    NSArray *cmsArray = [path componentsSeparatedByString:@"/"];
    if (cmsArray.count < 2) {
        if (callback) {
            callback(nil, [self getErrorWithInfo:className]);
        }
    }
    Class tagClass = NSClassFromString(className);
    NSString *methodName = [NSString stringWithFormat:@"%@:", cmsArray[1]];
    SEL sel = NSSelectorFromString(methodName);
    Method method = class_getClassMethod(tagClass, sel);
    if (!method) {
        if (callback) {
            callback(nil, [self getErrorWithInfo:className]);
            return;
        }
    }
    NSString *paramString = cmsArray[2];
    void(*call_func)(id, SEL, NSString*) = (void *)method_getImplementation(method);
    call_func(tagClass, sel, paramString);
    if (callback) {
        callback(nil, nil);
    }
    
}

- (NSError *)getErrorWithInfo:(NSString *)info{
    return [NSError errorWithDomain:NSOSStatusErrorDomain code:-500 userInfo:@{NSLocalizedDescriptionKey:info}];
}

- (void)responseWithData:(NSData*)data error:(NSError*)error{
    if(error){
        // 数据加载失败
        [self.client URLProtocol:self didFailWithError:error];
    }else{
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:nil expectedContentLength:data?data.length:0 textEncodingName:@"utf-8"];
        // 刚接收到 response 信息
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        // 数据加载成功
        [self.client URLProtocol:self didLoadData:data];
        // 数据完成加载
        [self.client URLProtocolDidFinishLoading:self];
    }
}

@end
