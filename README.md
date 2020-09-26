# 基于URL Scheme的组件路由化初步尝试

[博客地址](https://yizhanxiong.com/2020/09/26/%e5%9f%ba%e4%ba%8eurlscheme%e7%9a%84%e7%bb%84%e4%bb%b6%e8%b7%af%e7%94%b1%e5%8c%96%e5%88%9d%e6%ad%a5%e5%b0%9d%e8%af%95/)

关于项目组件路由化的概念已经由来已久，网上的各种方案层出不穷，而最近自己也尝试了一套组件路由化的方案，仅作为抛砖引玉，希望大家一起讨论

方案主要基于URLScheme方案，利用NSURLSession+NSURLProtocol实现组件路由化


## 使用
在plist中创建多对key-value，key定义为一个唯一的ID，value是我们将要跳转的controller类名
```
@interface URLMediator : NSObject

+ (instancetype)sharedSingleton;

- (void)pushToModuleID:(NSString *)moduleID;

- (void)pushToModuleID:(NSString *)moduleID param:(NSString *)param;

/// 路由跳转
/// @param moduleID 路由ID
/// @param param 传递参数
/// @param queue 线程，默认子线程
- (void)pushToModuleID:(NSString *)moduleID param:(NSString *)param queue:(NSOperationQueue *)queue;

- (void)pushToViewController:(UIViewController *)viewController;

@end
```
实例代码：
```
[[URLMediator sharedSingleton] pushToModuleID:@"999" param:@"1"];
```
而在跳转过去的类实现`+ (void)pushToModule:(NSString *)param`完成自定义逻辑
```
+ (void)pushToModule:(NSString *)param{
    dispatch_async(dispatch_get_main_queue(), ^{
        OneViewController *vc = [[OneViewController alloc] init];
        [[URLMediator sharedSingleton] pushToViewController:vc];
    });
}
```

## 思路
利用URL Scheme的沙盒机制，我们再APP中自定义一个相对应的URL，使用NSURLSession发送请求，同时利用NSURLProtocol拦截请求，并自行处理跳转逻辑。

所以方案的重点在于URL Scheme和NSURLProtocol的拦截


## URL Scheme
> 由于苹果选择沙盒来保障用户的隐私和安全，App只能访问自己的沙盒，但同时也阻碍了应用间合理的信息共享。所以苹果提供了一个可以在App之间跳转的方法：URL Scheme。如果你的App需要提供一个供别的App访问的功能或者数据，那么你必须在你的App定义一个相对应的URL Scheme。当别的App使用一个URL Scheme进行访问时，系统会根据URL Scheme进行匹配，执行相应的操作。

观察URL的组成：
`schema://host[:port#]/path/.../[?query-string][#anchor]`
由此我们可以利用URL组成的以下几个关键字
- schema:指定低层使用的协议
- host:HTTP 服务器的 IP 地址或者域名
- path:访问资源的路径
通过这几个部件我们尝试去自定义一个URL Scheme
`scheme(自定义协议）：//host(类名)/path(传递参数)`


## NSURLProtocol
通过上一个步骤完成自定义URL后，我们利用NSURLProtocol拦截URL请求，那么NSURLProtocol是什么呢？
> NSURLProtocol 是 Foundation 框架中  [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system?language=objc)  的一部分。它可以让开发者可以在不修改应用内原始请求代码的情况下，去改变 URL 加载的全部细节。换句话说，NSURLProtocol 是一个被 Apple 默许的中间人攻击。

具体使用可参考[NSURLProtocal](https://juejin.im/post/6844904079458566152)


## 代码实现
### 创建可维护的表
接下来代码实现
首先我们的路由规则是已创建一个可维护的Map，key定义为一个唯一的ID，value是我们将要跳转的controller。
初步尝试我们使用plist创建一个可维护的Map，**当然plist极不安全，可能会被反编译拦截，有想法的朋友可考虑其他方案**
[image:49C75216-674C-406A-9798-C700D72A3390-20355-00002E6ABB363ECC/7358B856-D5C9-4A09-8C48-58365AA05418.png]

### 路由中间模块
创建路由中间模块URLMediator
其中核心代码：
```
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
```
思路便是上述所说的利用NSURLSession发送一个自定义的URL，注意想要下面的NSURLProtocol能拦截该请求，需要给NSURLSessionConfiguration的rotocolClasses的属性赋值
`config.protocolClasses = @[[NSClassFromString(@"URLSchemeProrocol") class]];`
而该实例URL为`com.MYIURLMediator://OneViewController/pushToModule/1`

### 子类化NSURLProtocol
因为NSURLProtocol是一个抽象类，所以我们要创建一个NSURLProtocol的子类，并且在AppDelegate中注册。
```
@interface URLSchemeProrocol : NSURLProtocol
@end
```


```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [NSURLProtocol registerClass:[URLSchemeProrocol class]];
    return YES;
}
```

```
// 在拦截到网络请求后会调用这一方法，可以再次处理拦截的逻辑
+ (BOOL)canInitWithRequest:(NSURLRequest *)request{
    NSString *scheme = request.URL.scheme;
    // 判断是否为自定义URL
    if ([scheme isEqualToString:loacalHost]) {
        // 看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:loacalHost inRequest:request]) {
            return NO;
        }
        return YES;
    }
    return NO;
}
```

开始加载request
```
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
```
其中核心代码
```
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
```
思路就是解析URL，拿到host代表的类名，其中path以`/`分割数组，数组第一个有效字符串是跳转的类需要实现的方法名，后面的数据是需要传递的参数
之后利用runtime机制让目标类调用需要实现的类从而实现路由化。


## 后续
希望大家有更好的解决方案。
