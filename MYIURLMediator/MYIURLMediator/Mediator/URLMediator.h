//
//  URLMediator.h
//  MYIURLMediator
//
//  Created by MasterYi on 2020/9/23.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString *loacalHost;

@interface URLMediator : NSObject

+ (instancetype)sharedSingleton;

- (void)pushToModuleID:(NSString *)moduleID;

- (void)pushToModuleID:(NSString *)moduleID param:(NSString *)param;

/// 路由跳转 跳转的类实现`+ (void)pushToModule:(NSString *)param`
/// @param moduleID 路由ID
/// @param param 传递参数
/// @param queue 线程，默认子线程
- (void)pushToModuleID:(NSString *)moduleID param:(NSString *)param queue:(NSOperationQueue *)queue;

- (void)pushToViewController:(UIViewController *)viewController;

@end


