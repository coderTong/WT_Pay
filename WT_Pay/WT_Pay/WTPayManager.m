//
//  WTPayManager.m
//  WT_Pay
//
//  Created by Mac on 16/7/5.
//  Copyright © 2016年 wutong. All rights reserved.
//

#import "WTPayManager.h"
#import "payRequsestHandler.h"
#import "Order.h"
#import "DataSigner.h"

@interface WTPayManager ()<NSCopying>
@property (nonatomic, copy)WTPayResultBlock result;
@end

@implementation WTPayManager

+ (void)initialize
{
    [WTPayManager shareWTPayManager];
}


static WTPayManager * _instance;

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
        [_instance setRegisterApps];
    });
    return _instance;
}

+ (instancetype)shareWTPayManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc]init];
        [_instance setRegisterApps];
    });
    return _instance;
}


- (id)copyWithZone:(nullable NSZone *)zone
{
    return _instance;
}



// 注册appid
- (void)setRegisterApps
{    // 微信注册
    [WXApi registerApp:kWXAppID];
}

+ (void)wtPayOrderItem:(WTPayOrderItem *)orderItem payType:(WTPayType)type result:(WTPayResultBlock)result
{
    [WTPayManager shareWTPayManager].result = result;
    if (type == WTPayTypeWeixin) {
        [WTPayManager weixinPayWithOrderItem:orderItem];
    }else if (type == WTPayTypeAli){
        [WTPayManager aliPayWithOrderItem:orderItem];
    }
}
+ (void)aliPayWithOrderItem:(WTPayOrderItem *)orderItem
{
    /*
     *商户的唯一的parnter和seller。
     *签约后，支付宝会为每个商户分配一个唯一的 parnter 和 seller。
     */
    
    /*
     *生成订单信息及签名
     */
    //将商品信息赋予AlixPayOrder的成员变量
    Order *order = [[Order alloc] init];
    order.partner = kPartner;
    order.sellerID = kSeller;
    order.outTradeNO = orderItem.orderOutTradeNO;//订单ID（由商家自行制定）
    
    order.subject = orderItem.orderName;//商品标题
    order.body = orderItem.orderBody; //商品描述
    order.totalFee = orderItem.orderPrice; //商品价格
    order.notifyURL = kPayNotifyURL;
    order.service = @"mobile.securitypay.pay";
    order.paymentType = @"1";
    order.inputCharset = @"utf-8";
    order.itBPay = @"30m";
    order.showURL = kShowURL;
    
    // 应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *appScheme =kAppScheme;
    
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    NSLog(@"orderSpec = %@",orderSpec);
    
    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(kPrivateKey);
    NSString *signedString = [signer signString:orderSpec];
    
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    
//    __weak typeof(self) weakSelf = self;
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                       orderSpec, signedString, @"RSA"];
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            
            NSLog(@"resultDic=%@",resultDic);
            
            //[weakSelf handleAlipayResponse:resultDic];
        }];
        
    }else{
        //[self handleAlipayResponse:nil];
    }

}

- (void)handleAlipayResponse:(NSDictionary *)resultDic
{
    
//    resultDic;
    NSLog(@"%@", resultDic);
    
    if ([resultDic[@"resultStatus"] integerValue] != WTPayAilPayResultTypeSucess) {
        
        NSString * errorStr;
        errorStr = resultDic[@"memo"] ? resultDic[@"memo"] : @"支付失败";
        self.result(nil, errorStr);
    }else{
        NSDictionary * response = @{@"result":@"支付宝支付成功!"};
        self.result(response,nil);
    }
    
    
}




+ (void)weixinPayWithOrderItem:(WTPayOrderItem *)orderItem
{

    payRequsestHandler *payObj = [payRequsestHandler sharedInstance];
    //1. 拿到prepayId 和 sign, 其他参数写在外面都行
    NSDictionary * dict = [payObj sendPay:orderItem.orderName orderPrice:orderItem.orderPrice outTradeNo:orderItem.orderOutTradeNO];


    // 2.调起微信支付
    if(dict != nil){
        NSMutableString *retcode = [dict objectForKey:@"retcode"];
        if (retcode.intValue == 0){
            NSMutableString *stamp  = [dict objectForKey:@"timestamp"];
            
            //调起微信支付
            PayReq* req             = [[PayReq alloc] init];
            req.partnerId           = [dict objectForKey:@"partnerid"];
            req.prepayId            = [dict objectForKey:@"prepayid"];
            req.nonceStr            = [dict objectForKey:@"noncestr"];
            req.timeStamp           = stamp.intValue;
            req.package             = [dict objectForKey:@"package"];
            req.sign                = [dict objectForKey:@"sign"];
            
            BOOL success = [WXApi sendReq:req];
            if(!success){
                NSLog(@"调微信失败");
            }
            return;
        }else{
            NSLog(@"%@",[dict objectForKey:@"retmsg"]);
        }
    }else{
        NSLog(@"服务器返回错误");
    }


    
}




-(void)onResp:(BaseResp*)resp{
    if ([resp isKindOfClass:[PayResp class]]){
        PayResp*response=(PayResp*)resp;
        
        
        if (response.errCode == WXSuccess) {
            NSDictionary * response = @{@"result":@"微信支付成功!"};
            self.result(response,nil);

        }else{
            NSLog(@"支付失败，retcode=%d",resp.errCode);
            
            self.result(nil,@"支付失败");
            
        }
    }
}

@end



@implementation WTPayOrderItem
@end