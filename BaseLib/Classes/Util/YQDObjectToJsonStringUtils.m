//
//  YQDObjectToJsonStringUtils.m
//  YQD_iPhone
//
//  Created by 王志盼 on 2017/7/24.
//  Copyright © 2017年 王志盼. All rights reserved.
//

#import "YQDObjectToJsonStringUtils.h"

@implementation YQDObjectToJsonStringUtils
+(NSString *)idToJsonString:(id)object
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return jsonString;
}

+(NSString *)dictionaryToString:(NSDictionary *)dic
{
    if(dic == nil || dic.count == 0)
    {
        return @"";
    }
    
    NSArray *allKeys = [dic allKeys];
    NSMutableString *muStr = [NSMutableString string];
    for(NSString *key in allKeys)
    {
        [muStr appendFormat:@"%@=%@&",key,[dic objectForKey:key]];
    }
    return [muStr substringToIndex:muStr.length-1];
}

@end
