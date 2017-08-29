//
//  YQDHttpClient.h
//  YQD_iPhone
//
//  Created by 王志盼 on 2017/7/24.
//  Copyright © 2017年 王志盼. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  handler处理完后调用的Block
 */
typedef void (^CompleteBlock)();

/**
 *  handler处理成功时调用的Block
 */
typedef void (^SuccessBlock)(id obj);

/**
 *  handler处理失败时调用的Block
 */
typedef void (^FailedBlock)(id obj);

/**
 *  缓存数据block
 */
typedef void(^CacheBlock)(id obj);

@interface YQDHttpClient : NSObject

//网络访问单例
+ (instancetype)sharedInstance;


/**
 *  字典参数的get请求
 *
 */
-(void)executeGetRequest:(NSString *)url  params:(NSDictionary *)params  cache:(CacheBlock)cache success:(SuccessBlock)success failed:(FailedBlock)failed;
/**
 *  字典参数的get请求
 *
 */
-(void)executeGetRequest:(NSString *)url  params:(NSDictionary *)params  cacheMark:extarnalCacheMark
                   cache:(CacheBlock)cache success:(SuccessBlock)success failed:(FailedBlock)failed;


//不带url和参数封装的post
- (void)executePostRequestWithoutCommonParams:(NSString *)url params:(NSDictionary *)params success:(SuccessBlock)success failed:(FailedBlock)failed;

//带url和参数封装的post
- (void)executePostRequestWithURL:(NSString *)url params:(NSDictionary *)params success:(SuccessBlock)success failed:(FailedBlock)failed;

//图片上传
- (void)uploadImageWithURL:(NSString *)url parameters:(id)parameters image:(UIImage *)image name:(NSString *)name fileName:(NSString *)fileName success:(void(^)(id obj))success failure:(void(^)(id obj))failure;

@end
