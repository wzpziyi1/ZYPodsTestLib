//
//  YQDHttpClinetCore.m
//  YQD_iPhone
//
//  Created by 王志盼 on 2017/7/24.
//  Copyright © 2017年 王志盼. All rights reserved.
//

#import "YQDHttpClinetCore.h"
#import "RTJSONResponseSerializerWithData.h"

@interface YQDHttpClinetCore()
@property (nonatomic, strong) AFHTTPSessionManager *manager;

@property (nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;
@end

static id _instance = nil;

@implementation YQDHttpClinetCore

#pragma mark - 单利相关方法

+ (instancetype)sharedClient
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

#pragma mark - 初始化

- (instancetype)init
{
    if (self = [super init])
    {
        self.manager = [AFHTTPSessionManager manager];
        //请求参数序列化类型
        self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        //响应结果序列化类型
        self.manager.responseSerializer = [RTJSONResponseSerializerWithData serializer];
        //接受内容类型
        self.manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"text/plain",@"text/json",@"application/json", nil];
        
        //超时时间
        [self.manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        self.manager.requestSerializer.timeoutInterval = 10.f;
        [self.manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
        
        //添加http的header
//        [self.manager.requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
//        [self.manager.requestSerializer setValue:pKey forHTTPHeaderField:@"pKey"];
        
        //设备相关信息
        NSString *userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleNameKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
        
        [self.manager.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        
        //https相关
//        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
//        securityPolicy.allowInvalidCertificates = YES;
//        securityPolicy.validatesDomainName = NO;
//        self.manager.securityPolicy = securityPolicy;

    }
    return self;
}




#pragma mark - 调用AFN方法

- (void)startMonitoringNetwork;
{
    self.reachabilityManager = [AFNetworkReachabilityManager manager];
    [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable: {
                NSLog(@"无网络");
                kIsAvailableNetwork = NO;
                break;
            }
                
            default:
                NSLog(@"有网络");
                kIsAvailableNetwork = YES;
                break;
        }
    }];
    [self.reachabilityManager startMonitoring];
}

- (void)requestWithPath:(NSString *)url
                 method:(NSInteger)method
             parameters:(id)parameters prepareExecute:(PrepareExecuteBlock)prepareExecute
                success:(void (^)(NSURLSessionDataTask *, id))success
                failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    
    NSString *host = [YQDDeviceProperties getServceHost];
    NSString *requestUrl = [[NSString stringWithFormat:@"%@%@",host, url] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //判断网络状况（有链接：执行请求；无链接：弹出提示）
    if (kIsAvailableNetwork) {
        //预处理（显示加载信息啥的）
        if (prepareExecute) {
            prepareExecute();
        }
        
        switch (method) {
            case YQDRequestTypeGet:
            {
                
                [self.manager GET:requestUrl parameters:parameters progress:nil success:success failure:failure];
            }
                break;
            case YQDRequestTypePost:
            {
                
                [self.manager POST:requestUrl parameters:parameters progress:nil success:success failure:failure];
            }
                break;
            case YQDRequestTypeDelete:
            {
                [self.manager DELETE:requestUrl parameters:parameters success:success failure:failure];
            }
                break;
            case YQDRequestTypePut:
            {
                [self.manager PUT:requestUrl parameters:parameters success:success failure:false];
            }
                break;
            default:
                break;
        }
    }else{
        
        //发出网络异常通知广播
        [[NSNotificationCenter defaultCenter] postNotificationName:@"k_NOTI_NETWORK_ERROR" object:nil];
        
    }
}

- (void)requestWithPathInHEAD:(NSString *)url
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSURLSessionDataTask *task))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    if (kIsAvailableNetwork) {
        [self.manager HEAD:url parameters:parameters success:success failure:failure];
    }else{
//        [self showExceptionDialog];
    }
}



#pragma mark - 上传图片方法
- (void)uploadWithURL:(NSString *)URL
           parameters:(NSDictionary *)parameters
                image:(UIImage *)image
                 name:(NSString *)name
             fileName:(NSString *)fileName
              success:(void(^)(id responseObject))success
              failure:(void(^)(NSError *error))failure{
    
    NSString *requestURL = [[NSString stringWithFormat:@"%@%@",[YQDDeviceProperties getServceHost], URL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //AFN的上传data
    [self.manager POST:requestURL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        //图片压缩
        NSData *imageData = UIImageJPEGRepresentation(image, 0.3);
        NSString *mimeType = @"image/jpg";
        
        /**
         拼接data到 HTTP body
         mimeType JPG:image/jpg, PNG:image/png, JSON:application/json
         */
        [formData appendPartWithFileData:imageData name:name fileName:fileName mimeType:mimeType];
        
        //表单拼接参数data
        [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id  obj, BOOL *stop) {
            
            NSString *objStr = [NSString stringWithFormat:@"%@", obj];
            NSData *objData = [objStr dataUsingEncoding:NSUTF8StringEncoding];
            [formData appendPartWithFormData:objData name:key];
        }];
        
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        success(responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        failure(error);
        
    }];
    
    
}
@end
