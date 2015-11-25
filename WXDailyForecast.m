//
//  WXDailyForecast.m
//  weather
//
//  Created by lz-jack on 8/19/15.
//  Copyright (c) 2015 lz-jack. All rights reserved.
//

#import "WXDailyForecast.h"

@implementation WXDailyForecast

//重写父中的+JSONKeyPathsByPropertyKey方法
+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    //获取WXCondition的映射，并创建它的可变副本。
    NSMutableDictionary *paths = [[super JSONKeyPathsByPropertyKey] mutableCopy];//调用父类的函数，并转换为可变字典
    //你需要为daily forecast做的是改变max和min键映射。
    paths[@"tempHigh"] = @"temp.max";
    paths[@"tempLow"] = @"temp.min";
    //返回新的映射。
    return paths;
}

@end
