//
//  URLSchemeProrocol.m
//  MYIURLMediator
//
//  Created by MasterYi on 2020/9/23.
//

#import "URLSchemeProrocol.h"
#import <objc/runtime.h>

#define LoacalKey @"localcall"

@implementation URLSchemeProrocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request{
    
    NSString *scheme = request.URL.scheme;
    
    NSLog(@"%s, scheme = %@", __func__, scheme);
    return [scheme isEqualToString:LoacalKey] ? YES : NO;

}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request{
    return request;
}


+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b{
    return NO;
}

- (void)startLoading{
    
    __weak typeof(self) weakSelf = self;
    [self dealRequestWithUrl:self.request.URL callback:^(NSData *data, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf responseWithData:data error:error];
    }];
}

- (void)stopLoading{
    
}

-(void)dealRequestWithUrl:(NSURL *)url callback:(void(^)(NSData *data,NSError *error))callback{
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    NSString *scheme = components.scheme;
    if ([scheme isEqualToString:LoacalKey]) {
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
            }
            return;
        }
        NSString *paramString = cmsArray[2];
        void(*call_func)(id, SEL, NSString*) = (void *)method_getImplementation(method);
        call_func(tagClass, sel, paramString);
        if (callback) {
            callback(nil, nil);
        }
        return;
    }
    if (callback) {
        callback(nil, [self getErrorWithInfo:@""]);
    }
}

- (NSError *)getErrorWithInfo:(NSString *)info{
    return [NSError errorWithDomain:NSOSStatusErrorDomain code:-500 userInfo:@{NSLocalizedDescriptionKey:info}];
}

- (void)responseWithData:(NSData*)data error:(NSError*)error{
    if(error != nil){
        [self.client URLProtocol:self didFailWithError:error];
    }else{
        NSURLResponse *response = [[NSURLResponse alloc]initWithURL:self.request.URL MIMEType:nil expectedContentLength:data?data.length:0 textEncodingName:@"utf-8"];
        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [[self client] URLProtocol:self didLoadData:data];
        [[self client] URLProtocolDidFinishLoading:self];
    }
}

@end
