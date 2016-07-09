//
//  ViewController.m
//  WT_Pay
//
//  Created by Mac on 16/7/5.
//  Copyright © 2016年 wutong. All rights reserved.
//

#import "ViewController.h"
#import "WTPayManager.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)alipayClick:(UIButton *)sender {
    
    WTPayOrderItem * item = [[WTPayOrderItem alloc]init];
    item.orderName = @"哇哈哈八宝粥一瓶";
    item.orderPrice = @"0.01";//一分钱
    item.orderOutTradeNO = @"452AFAD3423432";
    item.orderBody = @"喝了以后爽歪歪";
    [WTPayManager wtPayOrderItem:item payType:WTPayTypeAli result:^(NSDictionary *payResult, NSString *error) {
        
        if (payResult) {
            NSLog(@"%@", payResult[@"result"]);
        }else{
            NSLog(@"%@", error);
        }
    }];
    
}
- (IBAction)weixinPayClick:(id)sender {
    WTPayOrderItem * item = [[WTPayOrderItem alloc]init];
    item.orderName = @"哇哈哈八宝粥一瓶";
    item.orderPrice = @"1";//一分钱
    item.orderOutTradeNO = @"452AFAD3423432";
    item.orderBody = @"喝了以后爽歪歪";
    [WTPayManager wtPayOrderItem:item payType:WTPayTypeWeixin result:^(NSDictionary *payResult, NSString *error) {
        
        if (payResult) {
            NSLog(@"%@", payResult[@"result"]);
        }else{
            NSLog(@"%@", error);
        }
    }];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
