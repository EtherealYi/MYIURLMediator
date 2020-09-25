//
//  TwoViewController.m
//  MYIURLMediator
//
//  Created by MasterYi on 2020/9/25.
//

#import "TwoViewController.h"

@interface TwoViewController ()

@end

@implementation TwoViewController

//+ (void)JumpToVC:(NSString *)param{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        TwoViewController *vc = [[TwoViewController alloc] init];
//        [[URLMediator sharedSingleton] pushToViewController:vc];
//    });
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"模块2";
    self.view.backgroundColor = [UIColor blueColor];
}



@end
