
#import <Foundation/Foundation.h>
#import "payRequsestHandler.h"
#import "WXApi.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

/*
 服务器请求操作处理
 */
@implementation payRequsestHandler

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static payRequsestHandler *instance;
    dispatch_once(&onceToken, ^{
        instance = [[payRequsestHandler alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if(self){
        //初始构造函数
        payUrl     = @"https://api.mch.weixin.qq.com/pay/unifiedorder";
        appid = kWXAppID;
        mchid = kWXMchID;
        spkey = kWXPartnerID;
    }
    return self;
}


//获取最后服务返回错误代码
-(long) getLasterrCode
{
    return last_errcode;
}
//创建package签名
-(NSString*) createMd5Sign:(NSMutableDictionary*)dict
{
    NSMutableString *contentString  =[NSMutableString string];
    NSArray *keys = [dict allKeys];
    //按字母顺序排序
    NSArray *sortedArray = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    //拼接字符串
    for (NSString *categoryId in sortedArray) {
        if (   ![[dict objectForKey:categoryId] isEqualToString:@""]
            && ![categoryId isEqualToString:@"sign"]
            && ![categoryId isEqualToString:@"key"]
            )
        {
            [contentString appendFormat:@"%@=%@&", categoryId, [dict objectForKey:categoryId]];
        }
        
    }
    //添加key字段
    [contentString appendFormat:@"key=%@", spkey];
    //得到MD5 sign签名
    NSString *md5Sign =[WXUtil md5:contentString];
    return md5Sign;
}

//获取package带参数的签名包
-(NSString *)genPackage:(NSMutableDictionary*)packageParams
{
    NSString *sign;
    NSMutableString *reqPars=[NSMutableString string];
    //生成签名
    sign        = [self createMd5Sign:packageParams];
    //生成xml的package
    NSArray *keys = [packageParams allKeys];
    [reqPars appendString:@"<xml>\n"];
    for (NSString *categoryId in keys) {
        [reqPars appendFormat:@"<%@>%@</%@>\n", categoryId, [packageParams objectForKey:categoryId],categoryId];
    }
    [reqPars appendFormat:@"<sign>%@</sign>\n</xml>", sign];
    
    return [NSString stringWithString:reqPars];
}
//提交预支付
-(NSString *)sendPrepay:(NSMutableDictionary *)prePayParams
{
    NSString *prepayid = nil;
    
    //获取提交支付
    NSString *send      = [self genPackage:prePayParams];
    
    //发送请求post xml数据
    NSData *res = [WXUtil httpSend:payUrl method:@"POST" data:send];
    
    //输出Debug Info
    XMLHelper *xml  = [XMLHelper alloc];
    
    //开始解析
    [xml startParse:res];
    
    NSMutableDictionary *resParams = [xml getDict];

    //判断返回
    NSString *return_code   = [resParams objectForKey:@"return_code"];
    NSString *result_code   = [resParams objectForKey:@"result_code"];
    if ( [return_code isEqualToString:@"SUCCESS"] )
    {
        //生成返回数据的签名
        NSString *sign      = [self createMd5Sign:resParams ];
        NSString *send_sign =[resParams objectForKey:@"sign"] ;
        
        //验证签名正确性
        if( [sign isEqualToString:send_sign]){
            if( [result_code isEqualToString:@"SUCCESS"]) {
                //验证业务处理状态
                prepayid    = [resParams objectForKey:@"prepay_id"];
                return_code = 0;
            }
        }else{
            last_errcode = 1;
//            DLog(@"gen_sign=%@\n   _sign=%@\n",sign,send_sign);
//            DLog(@"服务器返回签名验证错误！！！");
        }
    }else{
        last_errcode = 2;
//        DLog(@"%@,接口返回错误！！！\n",resParams);
    }
    return prepayid;
}


// Get IP Address
- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

/**
 *  生成随机字符串
 *
 *  @param kNumber 订单号的长度
 */
- (NSString *)generateRomNumWithNumber: (NSInteger)kNumber
{
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand((unsigned int)time(0));
    for (NSInteger i = 0; i < kNumber; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}

- (NSString *)generateOrderNum
{
    NSString *rStr = [[self generateRomNumWithNumber:16] lowercaseString];
    NSString *time = [NSString stringWithFormat:@"%f",ceilf([[NSDate date] timeIntervalSince1970])];
    NSRange range = [time rangeOfString:@"."];
    if(range.length > 0 && range.location < [time length]){
        time = [time substringToIndex:range.location];
    }
    rStr = [NSString stringWithFormat:@"%@%@",time,rStr];
    if([rStr length] > 30){
        rStr = [rStr substringToIndex:30];
    }
    return rStr;
}

//============================================================
// V3V4支付流程模拟实现，只作帐号验证和演示
// 注意:此demo只适合开发调试，参数配置和参数加密需要放到服务器端处理
// 服务器端Demo请查看包的文件
// 更新时间：2015年3月3日
// 负责人：李启波（marcyli）
//============================================================
//支付 订单标题，展示给用户  订单金额,单位（元）
- ( NSDictionary *)sendPay:(NSString *)orderName orderPrice:(NSString *)orderPrice outTradeNo:(NSString *)outTradeNo
{
//    debugInfo   = [NSMutableString string];
    /**
     应该服务器做,这一步主要是是拿到sign和prePayid, 其中prePayid是需要向微信发请求拿到的
     我们iOS这边本地可以做,但是一般情况下我们移动端不用管这些加密获字段,一般这些字段是后台做的,因为这种加密安卓那边也是一样的所以放在移动端的话等于我们iOS和安卓写了两份相同的代码.
     
     一般情况我们只要把商品名称和价格,发给后台让他去和微信沟通然后把我要的字段给我们就行了,然后我们调起微信支付就行了.
     */
    if([orderName length] == 0){
        orderName = @"languageBuy";
    }
    if([orderPrice length] == 0){
        orderPrice = @"0";
    }
    orderPrice = [NSString stringWithFormat:@"%@",@([orderPrice floatValue])];
    
    
    //================================
    //预付单参数订单设置
    //================================
    NSString *noncestr  = [self generateRomNumWithNumber:20];
//    NSString *orderno   = [self generateOrderNum];
    NSString *ipAddress = [self getIPAddress];
    if([ipAddress length] == 0 || [ipAddress isEqualToString:@"error"]){
        ipAddress = @"196.168.1.168";
    }
    NSLog(@"non=%@, ip=%@",noncestr, ipAddress);
    NSMutableDictionary *packageParams = [NSMutableDictionary dictionary];
    
    [packageParams setObject: appid             forKey:@"appid"];       //开放平台appid
    [packageParams setObject: mchid             forKey:@"mch_id"];      //商户号
    [packageParams setObject: noncestr          forKey:@"nonce_str"];   //随机串
    [packageParams setObject: @"APP"            forKey:@"trade_type"];  //支付类型，固定为APP
    [packageParams setObject: orderName        forKey:@"body"];        //订单描述，展示给用户
    [packageParams setObject: kWXNotifyURL        forKey:@"notify_url"];  //支付结果异步通知
    [packageParams setObject: outTradeNo           forKey:@"out_trade_no"];//商户订单号
    [packageParams setObject: ipAddress    forKey:@"spbill_create_ip"];//发器支付的机器ip
    [packageParams setObject: orderPrice       forKey:@"total_fee"];       //订单金额，单位为分
    
    
    //获取prepayId（预支付交易会话标识）
    NSString *prePayid;
    prePayid            = [self sendPrepay:packageParams];
    NSLog(@"prePayid=%@",prePayid);
    if ( prePayid != nil) {
        //获取到prepayid后进行第二次签名
        
        NSString    *package, *time_stamp, *nonce_str;
        //设置支付参数
        time_t now;
        time(&now);
        time_stamp  = [NSString stringWithFormat:@"%ld", now];
        nonce_str	= [WXUtil md5:time_stamp];
        //重新按提交格式组包，微信客户端暂只支持package=Sign=WXPay格式，须考虑升级后支持携带package具体参数的情况
        package         = @"Sign=WXPay";
        //第二次签名参数列表
        NSMutableDictionary *signParams = [NSMutableDictionary dictionary];
        [signParams setObject: appid        forKey:@"appid"];
        [signParams setObject: nonce_str    forKey:@"noncestr"];
        [signParams setObject: package      forKey:@"package"];
        [signParams setObject: mchid        forKey:@"partnerid"];
        [signParams setObject: time_stamp   forKey:@"timestamp"];
        [signParams setObject: prePayid     forKey:@"prepayid"];
        
        //生成签名
        NSString *sign  = [self createMd5Sign:signParams];
        //添加签名
        [signParams setObject: sign         forKey:@"sign"];
        
        //返回参数列表
        return signParams;
        
    }else{
        
    }
    return nil;

}


@end