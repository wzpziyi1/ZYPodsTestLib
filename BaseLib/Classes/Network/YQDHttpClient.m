//
//  YQDHttpClient.m
//  YQD_iPhone
//
//  Created by 王志盼 on 2017/7/24.
//  Copyright © 2017年 王志盼. All rights reserved.
//

#import "YQDHttpClient.h"
#import "YQDHttpClinetCore.h"
#import "YQDObjectToJsonStringUtils.h"

@interface YQDHttpClient()
@property (nonatomic, strong) YQDHttpClinetCore *manager;
@end

static id _instance = nil;

@implementation YQDHttpClient
+ (instancetype)sharedInstance
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (_instance == nil)
        {
            _instance = [[self alloc] init];
        }
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil)
        {
            _instance = [super allocWithZone:zone];
        }
    });
    return _instance;
}

#pragma mark - 处理请求

/*
 * 带缓存的使用字典请求的Get请求
 */
-(void)executeGetRequest:(NSString *)url  params:(NSDictionary *)params cache:(CacheBlock)cacheBlock success:(SuccessBlock)successBlock failed:(FailedBlock)failedBlock{
    [self executeGetRequest:url params:params cacheMark:nil cache:cacheBlock success:successBlock failed:failedBlock];
}

/*
 * 带缓存的使用字典请求的Get请求
 */
-(void)executeGetRequest:(NSString *)url  params:(NSDictionary *)params cacheMark:(NSString*)externalCacheMark cache:(CacheBlock)cacheBlock success:(SuccessBlock)successBlock failed:(FailedBlock)failedBlock{
    
    NSString *cacheMark=externalCacheMark;
    
    NSMutableDictionary *requestParams = [self generateRequestParams:params];
    
    NSString *requestParamsStr = [YQDObjectToJsonStringUtils dictionaryToString:requestParams];
    
    //如果cacheMark为nil则使用外部当前带参数的完整url作为cacheMark
    if(externalCacheMark == nil && cacheBlock != nil){
        cacheMark = [[NSString stringWithFormat:@"%@?%@",url,requestParamsStr] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    [self executeRequestWithUrl:url method:YQDRequestTypeGet parameters:requestParams cacheMark:cacheMark cache:cacheBlock success:successBlock failed:failedBlock];
}


#pragma mark Post请求，在方法中拼接host、url、必备环境参数以及关键字段

//(相同host都用这个)
- (void)executePostRequestWithURL:(NSString *)url params:(NSDictionary *)params success:(SuccessBlock)successBlock failed:(FailedBlock)failedBlock
{
    NSMutableDictionary *requestParams = [self generateRequestParams:params];
    
    
    [self.manager requestWithPath:url method:YQDRequestTypePost parameters:requestParams prepareExecute:^{
        
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        
        [self parserResponseObject:responseObject url:url requestMethod:YQDRequestTypePost  requestParams:requestParams success:successBlock failed:failedBlock cacheMark:nil];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        if (failedBlock) {
            NSDictionary *errDic = @{@"error" : @"当前网络不通畅,请重试"};
            failedBlock(errDic);
            
            NSLog(@"返回会的数据是  is %@",[error localizedDescription]);
            
        }
    }];
    
}


//不带url和参数封装的post(用于不同host的请求）
- (void)executePostRequestWithoutCommonParams:(NSString *)url params:(NSDictionary *)params success:(SuccessBlock)successBlock failed:(FailedBlock)failedBlock
{
    
    
    [self.manager requestWithPath:url method:YQDRequestTypePost parameters:params prepareExecute:^{
        //
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        
        [self parserResponseObject:responseObject url:url requestMethod:YQDRequestTypePost  requestParams:params success:successBlock failed:failedBlock cacheMark:nil];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        //
        if (failedBlock) {
            NSDictionary *errDic = @{@"error" : @"当前网络不通畅,请重试"};
            failedBlock(errDic);
        }
    }];
}


#pragma 网络访问的公共部分，区分缓存跟不带缓存

//无缓存
-(void)executeRequestWithUrl:(NSString *)requestURL method:(NSInteger)method  parameters:(NSDictionary*)params cacheMark:(NSString *)cacheMark cache:(CacheBlock)cache success:(SuccessBlock)successBlock failed:(FailedBlock)failedBlock
{
    //先取缓存数据
    NSData *cacheData = nil;
    
    NSMutableDictionary *requestParams = [self generateRequestParams:params];
    
    
    if (cacheMark) {
        cacheData = [YQDStorageUtils readDataFromFileByUrl:[NSString stringWithFormat:@"%@",cacheMark]];
    }
    
    if(cacheData != nil)
    {
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:cacheData options:NSJSONReadingMutableContainers error:nil];
        
        [self parserResponseObject:responseObject url:requestURL requestMethod:method  requestParams:requestParams success:cache failed:failedBlock cacheMark:nil];
    }
    
    
    
    [self.manager requestWithPath:requestURL method:method parameters:requestParams prepareExecute:^{
        
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        
        [self parserResponseObject:responseObject url:requestURL requestMethod:method  requestParams:requestParams success:successBlock failed:failedBlock cacheMark:cacheMark];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        //
        if (failedBlock) {
            NSDictionary *errDic = @{@"error":@"网络异常"};
            failedBlock(errDic);
        }
    }];
}


#pragma mark - 图片上传
- (void)uploadImageWithURL:(NSString *)url parameters:(NSDictionary *)params image:(UIImage *)image name:(NSString *)name fileName:(NSString *)fileName success:(void(^)(id obj))successBlock failure:(void(^)(id obj))failedBlock{
    
    NSMutableDictionary *requestParams = [self generateRequestParams:params];
    
    [self.manager uploadWithURL:url parameters:requestParams image:image name:name fileName:fileName success:^(id responseObject) {
        
        [self parserResponseObject:responseObject url:url requestMethod:YQDRequestTypePost  requestParams:requestParams success:successBlock failed:failedBlock cacheMark:nil];
        
    } failure:^(NSError *error) {
        if (failedBlock)
        {
            failedBlock(error);
        }
    }];
}

/*
 *  解析返回数据对象
 *  cacheMark是否存在缓存标识，此标识为nil的时候不做缓存
 *
 *
 */
-(void)parserResponseObject:(id)responseObject url:(NSString*)url requestMethod:(YQDRequestType)requestMethod requestParams:(NSDictionary*)requestParams success:(SuccessBlock)successBlock failed:(FailedBlock)failedBlock cacheMark:(NSString*)cacheMark
{
    //服务端返回成功，返回数据，否则返回异常信息
    if (responseObject)
    {
        NSInteger errCode = [[responseObject objectForKey:@"errCode"] integerValue];
        NSInteger status = [[responseObject objectForKey:@"status"] integerValue];
        
        @try {
            if(cacheMark!=nil)
            {
                //做缓存,在返回正确地请求数据之后
                @try {
                    NSData *cacheData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
                    [YQDStorageUtils saveUrl:[NSString stringWithFormat:@"%@",cacheMark] withData:cacheData];
                } @catch (NSException *exception) {
                    
                } @finally {
                    
                }
            }
            
            if (errCode == 0 && status == 1)
            {
                
                if (successBlock)
                {
                    id obj = [responseObject objectForKey:@"data"];
                    
                    @try {
                        
                        NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
                        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        NSLog(@"返回会的数据是  is %@",str);
                    } @catch (NSException *exception) {
                        
                    } @finally {
                        
                    }
                    successBlock(obj);
                }
            }
            else
            {
                if (failedBlock)
                {
                    @try {
                        NSString *error = [NSString stringWithFormat:@"%@",[responseObject objectForKey:@"error"]];
                        id obj = [responseObject objectForKey:@"data"];
                        NSDictionary *errDic = @{@"errCode":[NSNumber numberWithInteger:errCode],
                                                 @"error":error,@"data":obj};
                        NSLog(@"返回会的数据是  is %@",error);
                        failedBlock(errDic);
                    } @catch (NSException *exception) {
                        id obj = [responseObject objectForKey:@"data"];
                        NSDictionary *errDic = @{@"errCode":[NSNumber numberWithInteger:errCode],
                                                 @"error": @"返回的数据格式与文档不一致",@"data":obj};
                        NSLog(@"返回会的数据是  is %@",errDic);
                        failedBlock(errDic);
                    } @finally {
                        
                    }
                    
                }
            }
            
        } @catch (NSException *exception) {
            
            NSLog(@"-----------------Error-----------------------\n-----------------Error-----------------------\n\n  Error:\n%@", exception);
            
            if (errCode == 0 && status == 1)
            {
                successBlock(nil);
            }
        } @finally {
            
        }
    }else{
//        [self sendDebugInfo:url requestMethod:requestMethod requestParams:requestParams response:responseObject];
    }
    
    
}

#pragma mark - 获取公共的参数

- (NSMutableDictionary *)commonParams
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    [dic setObject:[NSNumber numberWithInteger:AppId] forKey:@"appId"];
//    [dic setObject:AppVersion forKey:@"clientVer"];
//    [dic setObject:@"" forKey:@"imei"];
//    [dic setObject:uuid forKey:@"uuid"];
//    [dic setObject:@"" forKey:@"macAddr"];
//    [dic setObject:@"" forKey:@"operator"];
//    [dic setObject:phoneModel forKey:@"model"];
//    [dic setObject:osVer forKey:@"osVer"];
//    [dic setObject:appCode forKey:@"appCode"];
//    if (packId)
//    {
//        [dic setObject:@(packId) forKey:@"packid"];
//    }
//    
//    [dic setObject:chanId forKey:@"chanId"];
//    
//    
//    
//    [dic setObject:[NSNumber numberWithInteger:nettype] forKey:@"nettype"];
//    if([UserInfoUtils isLogined]){
//        //因为部分接口已使用userId字段，这里必备参数使用myUserId字段
//        [dic setObject:[UserInfoUtils getUserId] forKey:@"myUserId"];
//        [dic setObject:[UserInfoUtils getToken] forKey:@"token"];
//    }
    return dic;
}


//根据单个请求的参数以及必备参数生成网络请求参数
-(NSMutableDictionary *)generateRequestParams:(NSDictionary*)params{
    NSMutableDictionary *requestParams = [self commonParams];
    if(params && params.count>0)
    {
        [requestParams addEntriesFromDictionary:params];
    }
    return requestParams;
}
#pragma mark - getter && setter
- (YQDHttpClinetCore *)manager
{
    if (_manager == nil)
    {
        _manager = [YQDHttpClinetCore sharedClient];
    }
    return _manager;
}

@end
