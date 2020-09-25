//
//  OneViewController.m
//  MYIURLMediator
//
//  Created by MasterYi on 2020/9/23.
//

#import "OneViewController.h"

@interface OneViewController ()

@end

@implementation OneViewController

+ (void)JumpToVC:(NSString *)param{
    dispatch_async(dispatch_get_main_queue(), ^{
        OneViewController *vc = [[OneViewController alloc] init];
        [[URLMediator sharedSingleton] pushToViewController:vc];
    });
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor redColor];
    self.title = @"模块1";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
