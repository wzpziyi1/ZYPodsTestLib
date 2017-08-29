//
//  YQDObjectToJsonStringUtils.h
//  YQD_iPhone
//
//  Created by 王志盼 on 2017/7/24.
//  Copyright © 2017年 王志盼. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YQDObjectToJsonStringUtils : NSObject
+(NSString *)idToJsonString:(id)object;

+(NSString *)dictionaryToString:(NSDictionary *)dic;
@end
