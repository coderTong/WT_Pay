//
//  WTPayManager.h
//  WT_Pay
//
//  Created by Mac on 16/7/5.
//  Copyright © 2016年 wutong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AlipaySDK/AlipaySDK.h>
#import "WXApi.h"


@interface WTPayOrderItem : NSObject

/**
 商品名称
 */
@property (nonatomic, strong)NSString * orderName;

/**
商品价格
 
 支付宝的单位是元
 微信的单位是分
*/
@property (nonatomic, strong)NSString * orderPrice;

/**
订单号
*/
@property (nonatomic, strong)NSString * orderOutTradeNO;

/**
 商品描述
 */
@property (nonatomic, strong)NSString * orderBody;


@end




typedef NS_ENUM(NSInteger, WTPayType) {
    WTPayTypeAli = 0,   // 支付宝支付
   WTPayTypeWeixin  // 微信支付
};

typedef NS_ENUM(NSInteger, WTPayAilPayResultType) {
    WTPayAilPayResultTypeSucess = 9000,   // 支付成功
    WTPayAilPayResultTypeCancel = 6001// 用户取消
};

typedef void(^WTPayResultBlock)(NSDictionary * payResult, NSString * error);
@interface WTPayManager : NSObject<WXApiDelegate>


+ (instancetype)shareWTPayManager;
- (void)handleAlipayResponse:(NSDictionary *)resultDic;


+ (void)wtPayOrderItem:(WTPayOrderItem *)orderItem payType:(WTPayType)type result:(WTPayResultBlock)result;
@end




