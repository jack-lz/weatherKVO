//
//  WXManager.h
//  weather
//
//  Created by lz-jack on 8/19/15.
//  Copyright (c) 2015 lz-jack. All rights reserved.
//

@import Foundation;
@import CoreLocation;
@import UIKit;

#import "WXCondition.h"
#import "WXURLSession.h"
#import "WXDailyForecast.h"
#import "WXLocation.h"

@interface WXManager : NSObject
<CLLocationManagerDelegate>

// 使用instancetype而不是WXManager，子类将返回适当的类型
+ (instancetype)sharedManager;

// 这些属性将存储您的数据。由于WXManager是一个单例，这些属性可以任意访问。设置公共属性为只读，因为只有管理者能更改这些值。
@property (nonatomic, strong, readonly) CLLocation *currentLocation;
@property (nonatomic, strong, readonly) WXCondition *currentCondition;
@property (nonatomic, strong, readonly) NSArray *hourlyForecast;
@property (nonatomic, strong, readonly) NSArray *dailyForecast;

// 这个方法启动或刷新整个位置和天气的查找过程。
- (void)requestLocationAuthority;
- (void)chooseCityLocation:(NSString *) selectedCity;
- (void)startUpdatingLocation;

@end