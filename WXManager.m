//
//  WXManager.m
//  weather
//
//  Created by lz-jack on 8/19/15.
//  Copyright (c) 2015 lz-jack. All rights reserved.
//

#import "WXManager.h"
#import <TSMessages/TSMessage.h>


@interface WXManager ()

// 声明你在公共接口中添加的相同的属性，但是这一次把他们定义为可读写，因此您可以在后台更改他们。
@property (nonatomic, strong, readwrite) CLLocation  *currentLocation;
@property (nonatomic, strong, readwrite) WXCondition *currentCondition;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;
@property (nonatomic, strong, readwrite) CLLocation *selectCity;
@property (nonatomic, strong, readwrite) WXLocation *locationManager;

@end



@implementation WXManager

//通用的单例构造器
+ (instancetype)sharedManager
{
    static id _sharedManager ;
    static dispatch_once_t onceToken;
    __weak typeof (self) wself = self;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[wself alloc] init];
    });
    return _sharedManager;
}


- (id)init
{
    if (self = [super init])
    {
        // 创建一个位置管理器，并设置它的delegate为self。
        self.locationManager = [[WXLocation alloc] init];
        self.locationManager.delegate = self;
        [self addObserver:self forKeyPath:@"currentLocation" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}


- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"currentLocation" context:nil];
}


#pragma KVOFunction
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentLocation"])
    {
        [self performSelectorOnMainThread:@selector(obtainCurrentConditions) withObject: nil waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(obtainDailyForecast) withObject: nil waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(obtainHourlyForecast) withObject: nil waitUntilDone:NO];
    }
    else
    {
        //若当前类无法捕捉到这个KVO，那很有可能是在他的superClass，或者super-superClass...中
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma LocationFunction
- (void)requestLocationAuthority
{
    [self.locationManager requestLocationAuthority];
}


- (void)startUpdatingLocation
{
    [self.locationManager  startUpdatingLocation];
}


- (void)chooseCityLocation:(NSString *) selectedCity
{
    if (selectedCity != nil)
    {
        /***************也可以先转化为拼音再搜索************/
        CFMutableStringRef string = CFStringCreateMutableCopy(NULL, 0, (__bridge CFStringRef)selectedCity);//转换字符串
        CFStringTransform(string, NULL, kCFStringTransformMandarinLatin, NO);//转换为拼音
        CFStringTransform(string, NULL, kCFStringTransformStripDiacritics, NO);//去掉音标
        NSString *oreillyAddress = [(__bridge NSString *)(string) stringByReplacingOccurrencesOfString:@" " withString:@""];//去掉空格
        //反向地理编码
        CLGeocoder *myGeocoder = [[CLGeocoder alloc] init];
        [myGeocoder geocodeAddressString:oreillyAddress completionHandler:^(NSArray *placeMarks, NSError *error)
         {
             if ([placeMarks count] > 0 && error == nil)
             {
                 CLPlacemark *firstPlaceMark = [placeMarks objectAtIndex:0];
                 self.selectCity=[[CLLocation alloc] initWithLatitude:firstPlaceMark.location.coordinate.latitude longitude:firstPlaceMark.location.coordinate.longitude];
                 self.currentLocation = self.selectCity;
             }
         }];
  
    }
    else
    {
        [self  startUpdatingLocation];
    }
}



#pragma mark - WXLocationDelegate

- (void)updateLocation:(CLLocation *)location
{
    self.currentLocation = location;
}


#pragma mark -fetchDataSelector

- (void)obtainCurrentConditions
{
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&appid=2de143494c0b295cca9337e1e96b00e0",self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    __weak typeof (self) wself = self;
    [[WXURLSession sharedSession] getJSONWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        if (! error)
        {   //序列化
            id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            id adapterModelData = [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:json error:nil];
            wself.currentCondition = adapterModelData;
        }
        else
        {
            [self performSelectorOnMainThread:@selector(alertTitle)withObject: nil waitUntilDone:NO];
        }
    }];
}


- (void)obtainHourlyForecast
{
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast?lat=%f&lon=%f&appid=2de143494c0b295cca9337e1e96b00e0",self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    __weak typeof (self) wself = self;
    [[WXURLSession sharedSession]  getJSONWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        if (! error)
        {  //序列化
            id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            NSArray *list = [json objectForKey:@"list"];
            NSMutableArray *adapterModelData = [NSMutableArray array];//创建空数组
            for (id obj in list)
            {
                id adapterModelDatapart = [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:obj error:nil];
                [adapterModelData addObject:adapterModelDatapart];
            }
            wself.hourlyForecast = adapterModelData;
        }
        else
        {
            [self performSelectorOnMainThread:@selector(alertTitle)withObject: nil waitUntilDone:NO];
        }
    }];
}


- (void)obtainDailyForecast
{
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast/daily?lat=%f&lon=%f&appid=2de143494c0b295cca9337e1e96b00e0",self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    __weak typeof (self) wself = self;
    [[WXURLSession sharedSession]  getJSONWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        if (! error)
        {  //序列化
            id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            NSArray *list = [json objectForKey:@"list"];
            NSMutableArray *adapterModelData = [NSMutableArray array];//创建空数组
            for (id obj in list)
            {
                id adapterModelDatapart = [MTLJSONAdapter modelOfClass:[WXDailyForecast class] fromJSONDictionary:obj error:nil];
                [adapterModelData addObject:adapterModelDatapart];
            }
            wself.dailyForecast = adapterModelData;
        }
        else
        {
            [self performSelectorOnMainThread:@selector(alertTitle)withObject: nil waitUntilDone:NO];
        }
    }];
}


#pragma Error
//错误警告
-(void)alertTitle
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"连接错误"  message:@"请检查网络设置或稍后再试。" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil];
    [alert addButtonWithTitle:@"确认"];
    [alert show];
}

@end
