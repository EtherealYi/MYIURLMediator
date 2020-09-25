//
//  URLMediator.h
//  MYIURLMediator
//
//  Created by MasterYi on 2020/9/23.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface URLMediator : NSObject

+ (instancetype)sharedSingleton;

- (void)JumpToFuncID:(NSString *)funcID param:(NSString *)param;

- (void)jumpToFuncID:(NSString *)funcID;

- (void)pushToViewController:(UIViewController *)viewController;

@end


