# WT_Pay
微信和支付宝接入Demo

# demo使用时,请在WTPayKeys.h里面将各个参数配置好,谢谢.


# 一. 微信支付 
## 1.所需要的材料
- 微信SDK
[微信SDK](https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419319164&lang=zh_CN)
- 在微信开放平台上面申请得到的参数
> 
// 应用的APPID
kWXAppID @"wxc82cXXXXXXXX"
// AppSecret
kWXAppSecret @"7f47bfe47b84XXXXXXXXXXXx"
//商户号
kWXMchID          @"1242XXXXXX"
//商户API密钥
kWXPartnerID      @"n1LeHtXUV9ZuPp156mcmXXXXXXXXX"
//支付结果回调页面
kWXNotifyURL      @"http://XXXXXXXXX"

1.2 微信支付工程配置

// 需要的系统依赖
> SystemConfiguration.framework
libz.dylib
libsqlite3.0.dylib
libc++.dylib


## 2.调起微信客户端代码


```objc
    [WXApi registerApp:weichat_appid];
    //调起微信支付
    PayReq* req             = [[PayReq alloc] init];
    req.partnerId           = item.partnerid;
    req.prepayId            = item.prepayid;
    req.nonceStr            = item.noncestr;
    req.timeStamp           = [item.timestamp intValue];
    req.package             = item.package;
    req.sign                = item.sign;
    
    [WXApi sendReq:req];
```

> 问: 微信支付怎么支付?
答: 其实就是上面的代码.
 - 创建一个PayReq对象req, 然后[WXApi sendReq:req];  就这么简单.
难就难在,怎么得到PayReq对象所需要的那些值,一共六个值.
而这六个值其他的值好说,就两个:prepayId和sign比较麻烦.
- 获取prepayId(预支付订单)是需要发请求给微信(统一下单),然后微信返回结果给我们的.
- 而sign前面的话,各种参数柔和在一起,MD5一下,也比较烦.


3.拿到prepayId
> 怎么拿?
[官方文档---->统一下单](https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=9_1)
就是发一个请求给微信,然后微信返回prepayId给你.官方要求统一下单要放在我们的服务器做.--------这是个好事情!!!!!!!!!!!
服务器端完成的!!!!哈哈哈哈,其实放在服务器端做的话,接入微信支付就没什么好说的了. 
- 放在服务器端我们的步奏
 - 拿到商品id 和 商品名称 商品价格发给我们的服务器,然后服务器端返回给我们调用微信需要的PayReq对象req的所有参数
 - 我们调起微信(没错现实当中就是这样的简单,我们发个请求,服务端给我需要的所有参数,然后我们调起微信就ok, 烦不了~)
[统一下单API、支付结果通知API和查询订单API等都涉及签名过程，调用都必须在商户服务器端完成。](https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=8_3)
> 其实不用服务端,我们也可以完成. 就是我们自己发请求然后拿到prepayId,我只是说我们自己可以做,但是现实中我们应当放在服务端,官方文档就是这么要求,这样我们省了好多事的好不,接入微信就很简单了.</br>
但是为了演示效果,而又没有现成的服务器接口给我们.所以[Demo](https://github.com/coderTong/WT_Pay)中,我是将说有过程写在我们本地.

> 放在我们本地的做法
1.我们想这个接口:@"https://api.mch.weixin.qq.com/pay/unifiedorder"  发一个post请求

> 2.参数
aped //开放平台appid
mch_id //商户号
nonce_str//随机串
trade_type //支付类型，固定为APP
body //订单描述，展示给用户, 就是商品名
notify_url //支付结果异步通知, 就是kWXNotifyURL
out_trade_no //商户订单号 我们自己设定的订单号
spbill_create_ip // //发器支付的机器ip
total_fee //订单金额，单位为分

> sign // 签名, 就是上面那些参数按照字母顺序拼接成一个字符串,然后再拼接一个kWXPartnerID .  有关sign(签名)的生成可以参考[官方文档](https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=4_3),或者看下面关于sign的"通俗说法",或者直接看[Demo](https://github.com/coderTong/WT_Pay)


4.partnerId  商家向财付通申请的商家id
> // 商家向财付通申请的商家id 这个不用说, 自己去微信开放平台上拿


5.nonceStr 随机串
```
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

```

6.timeStamp  时间戳
```
time_t now;
time(&now);
time_stamp  = [NSString stringWithFormat:@"%ld", now];
```

7.package 商家根据财付通文档填写的数据和签名

> 这个是个死值 Sign=WXPay
[官方文档说:](https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=9_12&index=2)暂填写固定值Sign=WXPay


8.sign

> [官方文档](https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=4_3)这么说的</br>
签名算法
签名生成的通用步骤如下：
第一步，设所有发送或者接收到的数据为集合M，将集合M内非空参数值的参数按照参数名ASCII码从小到大排序（字典序），使用URL键值对的格式（即key1=value1&key2=value2…）拼接成字符串stringA。
特别注意以下重要规则：
◆ 参数名ASCII码从小到大排序（字典序）；
◆ 如果参数的值为空不参与签名；
◆ 参数名区分大小写；
◆ 验证调用返回或微信主动通知签名时，传送的sign参数不参与签名，将生成的签名与该sign值作校验。
◆ 微信接口可能增加字段，验证签名时必须支持增加的扩展字段
第二步，在stringA最后拼接上key得到stringSignTemp字符串，并对stringSignTemp进行MD5运算，再将得到的字符串所有字符转换为大写，得到sign值signValue。


----------------
> 通俗的说:
1.就是拿到PayReq对象的其他5个值,参数名ASCII码从小到大排序（字典序）,然后
a字母顺序第一个appid,就是第一,然后后面的同样按照字母先后顺序一个&一个那么拼接成一个字符串.
```
str1 = @"appid=wxd930ea5d5a258f4f&package=Sign=WXPay......";
```

> 2.得到上面的字符串以后了再在后的字符串后面拼接上key
// kWXPartnerID      @"n1LeHtXUV9ZuPp156mcmXXXXXXXXX"
str2 = [str1 appendFormat:@"key=%@", kWXPartnerID];

>然后对str2 MD5加密一下,就得到了sign了.


## 如果是按照官方文档"统一下单API、支付结果通知API和查询订单API等都涉及签名过程，调用都必须在商户服务器端完成。"这样,上面的这些所有参数你都不用管,你要做的只是,拿到你们APP里面商品的价格,商品名什么的发给后台,然后后台就会把你需要的这些所有参数给你,然后你拿着这些参数调起微信就ok!

</br></br>
# 二.支付宝支付
### 1.需要的材料
[支付宝SDK](http://aopsdkdownload.cn-hangzhou.alipay-pub.aliyun-inc.com/demo/WS_MOBILE_PAY_SDK_BASE.zip?spm=a219a.7629140.0.0.YtjpFj&file=WS_MOBILE_PAY_SDK_BASE.zip)
下载下来解压文件如图

![Snip20160709_15.png](http://upload-images.jianshu.io/upload_images/571446-1d211d518b7828cb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

// 解压iOS那个zip
![Snip20160709_17.png](http://upload-images.jianshu.io/upload_images/571446-cf6b8f0e433e4a8e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

// 得到如图

![Snip20160709_18.png](http://upload-images.jianshu.io/upload_images/571446-d35470c52e627070.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

// 我们需要的文件有如图

![Snip20160709_19.png](http://upload-images.jianshu.io/upload_images/571446-f4a092da21297611.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

// 在我们工程里面新建一个文件夹Alipay将上面我们需要的文件放在文件Alipay下

![Snip20160709_20.png](http://upload-images.jianshu.io/upload_images/571446-1f10e6562ccb226a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



// 支付宝需要的系统库

"1"CFNetwork.framework
"2"CoreMotion.framework
"3"“SystemConfiguration.framework”，
"4"“CoreGraphics.Framework”、
"5"“CoreTelephony.framework”
"6"“libz.dylib”
"7"libc++.dylib
"8"QuartzCore.framework
"9"CoreText.framework


// 在支付宝上申请得到的参数

```

#ifndef __OPTIMIZE__
#define kPayNotifyURL @"http://WWW.XXXX.XXXXXXXXX"
#else
#define kPayNotifyURL @"https://WWW.FFFF.XXXXXXX"
#endif
#define kPrivateKey @"SDGSFHGDFHGSVF$%#$RFFDSFASFASFASFSDFASDFASDCVCVZXVZXCVZXCVZXCVXCVZXCVGQWY%##$T@!RXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"// 
#define kSeller @"20XXXXXXXXXXXXXX"
#define kPartner @"20XXXXXXXXXXXXX"
```
kPayNotifyURL
kPrivateKey
kSeller
kPartner
##2.支付实现
我是用WTPayManager统一管理微信和支付宝支付的
在WTPayManager里包含
#import <AlipaySDK/AlipaySDK.h>

调用支付宝代码
```
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
    order.service = @"mobile.securitypay.pay";//接口名称，固定为mobile.securitypay.pay。
    order.paymentType = @"1";
    order.inputCharset = @"utf-8";
    order.itBPay = @"30m";
    order.showURL = @"m.alipay.com";
    
    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *appScheme = @"XXXXXXXXXX";
    
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
```


// 支付宝支付相对微信来说简单些
> 拿到
kPayNotifyURL
kPrivateKey
kSeller
kPartner
这几个参数
加上我们的商品价格,名称,商品订单,本地加个密,往支付宝一推,就ok了.

集成支付宝openssl可能会出现
导入SDK或者调用支付宝失败的情况
1.0 openssl/asn1.h file not found
[点击这里答案,感谢-----荏苒少年](http://www.jianshu.com/p/7722520289af)


三.统一配置

info.plist // 文件下加入这个

```
<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>sinaweibohd</string>
		<string>sinaweibo</string>
		<string>sinaweibosso</string>
		<string>weibosdk</string>
		<string>weibosdk2.5</string>
		<string>mqqapi</string>
		<string>mqq</string>
		<string>mqqOpensdkSSoLogin</string>
		<string>mqqconnect</string>
		<string>mqqopensdkdataline</string>
		<string>mqqopensdkgrouptribeshare</string>
		<string>mqqopensdkfriend</string>
		<string>mqqopensdkapi</string>
		<string>mqqopensdkapiV2</string>
		<string>mqqopensdkapiV3</string>
		<string>mqzoneopensdk</string>
		<string>wtloginmqq</string>
		<string>wtloginmqq2</string>
		<string>mqqwpa</string>
		<string>mqzone</string>
		<string>mqzonev2</string>
		<string>mqzoneshare</string>
		<string>wtloginqzone</string>
		<string>mqzonewx</string>
		<string>mqzoneopensdkapiV2</string>
		<string>mqzoneopensdkapi19</string>
		<string>mqzoneopensdkapi</string>
		<string>mqzoneopensdk</string>
		<string>alipay</string>
		<string>alipayshare</string>
	</array>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
```

![Snip20160709_21.png](http://upload-images.jianshu.io/upload_images/571446-906d013e02270b0c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



// PCH

![Snip20160709_22.png](http://upload-images.jianshu.io/upload_images/571446-bf6769218b42834e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


// -ObjC


![Snip20160709_23.png](http://upload-images.jianshu.io/upload_images/571446-349163c1c4de0f97.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


// URL Schemes

![Snip20160709_24.png](http://upload-images.jianshu.io/upload_images/571446-9f8670e517bd5f64.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



