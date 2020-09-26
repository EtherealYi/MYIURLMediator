//
//  URLMediator.m
//  MYIURLMediator
//
//  Created by MasterYi on 2020/9/23.
//

#import "URLMediator.h"

NSString *loacalHost = @"com.MYIURLMediator";

@interface URLMediator()<NSURLSessionDelegate>

@end

@implementation URLMediator

+ (instancetype)sharedSingleton {
    static URLMediator *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
          // 要使用self来调用
        _sharedSingleton = [[self alloc] init];
    });
    return _sharedSingleton;
}

- (void)pushToModuleID:(NSString *)moduleID{
    [self pushToModuleID:moduleID param:@""];
}

- (void)pushToModuleID:(NSString *)moduleID param:(NSString *)param{
    [self pushToModuleID:moduleID param:param queue:[NSOperationQueue currentQueue]];
}

- (void)pushToModuleID:(NSString *)moduleID param:(NSString *)param queue:(NSOperationQueue *)queue{
    if (!queue) {
        queue = [NSOperationQueue currentQueue];
    }
    if (moduleID.length == 0) return;
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"URLScheme" ofType:@"plist"];
    if (plistPath.length == 0) return;
    
    NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    if (dictionary == nil) return;
    NSString *clsName;
    if ([dictionary.allKeys containsObject:moduleID]) {
        clsName = dictionary[moduleID];
    }
    NSString *funcPath = [NSString stringWithFormat:@"%@://%@/pushToModule/%@", loacalHost, clsName, param];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:funcPath]];
    request.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.protocolClasses = @[[NSClassFromString(@"URLSchemeProrocol") class]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:queue];
    NSURLSessionTask *task = [session dataTaskWithRequest:request];
    [task resume];
}


- (UINavigationController *)getNavigationController{
    UIWindow *window = [UIApplication sharedApplication].windows[0];
    UIViewController *vc = window.rootViewController;
    
    return (UINavigationController *)vc;
}

- (void)pushToViewController:(UIViewController *)viewController{
    if (!viewController) {
        return;
    }
    [[self getNavigationController] pushViewController:viewController animated:YES];
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    NSLog(@"接收响应");
    //必须告诉系统是否接收服务器返回的数据
    //默认是completionHandler(NSURLSessionResponseAllow)
    //可以再这边通过响应的statusCode来判断否接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
}


//2.接受到服务器返回数据的时候调用,可能被调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    NSLog(@"接收到数据");
    //一般在这边进行数据的拼接，在方法3才将完整数据回调
//    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}


//3.请求完成或者是失败的时候调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    if (error) {
        NSDictionary *dict = error.userInfo;
        NSString *className = dict[NSLocalizedDescriptionKey];
        if (className.length > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                Class cls = NSClassFromString(className);
                UIViewController *vc = [[cls alloc] init];
                [[URLMediator sharedSingleton] pushToViewController:vc];
            });
        }
    }
    NSLog(@"请求完成或者是失败");
}

//4.将要缓存响应的时候调用（必须是默认会话模式，GET请求才可以）
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler{
    //可以在这边更改是否缓存，默认的话是completionHandler(proposedResponse)
    //不想缓存的话可以设置completionHandler(nil)
    completionHandler(proposedResponse);
}

@end
