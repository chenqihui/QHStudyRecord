//
//  CacheInThoseYearsViewController.m
//  QHStudyRecord
//
//  Created by chen on 15-1-22.
//  Copyright (c) 2015年 chen. All rights reserved.
//

#import "CacheInThoseYearsViewController.h"

//那些年我们一起追过的缓存写法(一)---http://blog.jobbole.com/83439/

/*
 1、在项目中，有不少这样写法。这样写没有错，但在并发量上来后就会有问题。继续看
 
 2、缓存雪崩是由于缓存失效(过期)，新缓存未到期间。
 
 这个中间时间内，所有请求都去查询数据库，而对数据库CPU和内存造成巨大压力，前端连接数不够、查询阻塞。
 
 3、举个简单例子：一般我们会缓存用户搜索结果。而数据库查询不到，是不会做缓存的。但如果频繁查这个关键字，就会每次都直查数据库了。
 
 4、在高并发下： 缓存重建期间，你是锁着的，1000个请求999个都在阻塞的。  用户体验不好，还浪费资源：阻塞的线程本可以处理后续请求的。
 
 5、总结
 
 补充下： 这里说的阻塞其他函数指的是，高并发下锁同一对象。
 
 实际使用中，缓存层封装往往要复杂的多。  关于更新缓存，可以单开一个线程去专门跑这些，图方便就扔线程池吧。
 
 具体使用场景，可根据实际用户量来平衡。
 
 */

@interface CacheHelper : NSObject
{
    NSMutableDictionary *_HttpRuntime_Cache;
}

- (id)Get:(NSString *)cacheKey;

- (void)Add:(NSString *)cacheKey object:(id)obj cacheMinute:(int)cacheMinute;

@end

@implementation CacheHelper

- (id)Get:(NSString *)cacheKey
{
    if (_HttpRuntime_Cache == nil)
        return nil;
    
    return [_HttpRuntime_Cache objectForKey:cacheKey];
}

- (void)Add:(NSString *)cacheKey object:(id)obj cacheMinute:(int)cacheMinute
{
    if (_HttpRuntime_Cache == nil)
        _HttpRuntime_Cache = [NSMutableDictionary new];
    
    [_HttpRuntime_Cache setObject:obj forKey:cacheKey];
}

@end

@interface CacheInThoseYearsViewController ()
{
    CacheHelper *_cacheHelper;
}

@end

@implementation CacheInThoseYearsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _cacheHelper = [CacheHelper new];
}

-(id)GetMemberSigninDays1
{
    const int cacheTime = 5;
    NSString *cacheKey = @"mushroomsir";
    
    id cacheValue = [_cacheHelper Get:cacheKey];
    if (cacheValue != nil)
        return cacheValue;
    
    cacheValue = @"395"; //这里一般是 sql查询数据。 例：395 签到天数
    [_cacheHelper Add:cacheKey object:cacheValue cacheMinute:cacheTime];
    
    return cacheValue;
}

//1：全局锁，实例锁
static NSObject *obj1;;
-(id)GetMemberSigninDays2
{
//    if (obj1 == nil)
//        obj1 = [NSObject new];
    
    const int cacheTime = 5;
    NSString *cacheKey = @"mushroomsir";
    
    id cacheValue = [_cacheHelper Get:cacheKey];
    if (cacheValue != nil)
        return cacheValue;
    
//    @synchronized(obj1)//全局锁
//    {
//        id cacheValue = [_cacheHelper Get:cacheKey];
//        if (cacheValue != nil)
//            return cacheValue;
//        
//        cacheValue = @"395"; //这里一般是 sql查询数据。 例：395 签到天数
//        [_cacheHelper Add:cacheKey object:cacheValue cacheMinute:cacheTime];
//    }
    
    @synchronized(self)
    {
        id cacheValue = [_cacheHelper Get:cacheKey];
        if (cacheValue != nil)
            return cacheValue;
        
        cacheValue = @"395"; //这里一般是 sql查询数据。 例：395 签到天数
        [_cacheHelper Add:cacheKey object:cacheValue cacheMinute:cacheTime];
    }
    
    return cacheValue;
}

//2：字符串锁

-(id)GetMemberSigninDays3
{
    const int cacheTime = 5;
    NSString *cacheKey = @"mushroomsir";
    
    id cacheValue = [_cacheHelper Get:cacheKey];
    if (cacheValue != nil)
        return cacheValue;
    
    NSString *lockKey = [NSString stringWithFormat:@"%@%@", cacheKey, @"n(*≧▽≦*)n"];
    
//    @synchronized(cacheKey)
//    {
//        id cacheValue = [_cacheHelper Get:cacheKey];
//        if (cacheValue != nil)
//            return cacheValue;
//        
//        cacheValue = @"395"; //这里一般是 sql查询数据。 例：395 签到天数
//        [_cacheHelper Add:cacheKey object:cacheValue cacheMinute:cacheTime];
//    }
    
    @synchronized(lockKey)
    {
        id cacheValue = [_cacheHelper Get:cacheKey];
        if (cacheValue != nil)
            return cacheValue;
        
        cacheValue = @"395"; //这里一般是 sql查询数据。 例：395 签到天数
        [_cacheHelper Add:cacheKey object:cacheValue cacheMinute:cacheTime];
    }
    
    return cacheValue;
}

//三：缓存穿透

-(id)GetMemberSigninDays4
{
    const int cacheTime = 5;
    NSString *cacheKey = @"mushroomsir";
    
    id cacheValue = [_cacheHelper Get:cacheKey];
    if (cacheValue != nil)
        return cacheValue;
    
    NSString *lockKey = [NSString stringWithFormat:@"%@%@", cacheKey, @"n(*≧▽≦*)n"];
    
    @synchronized(lockKey)
    {
        id cacheValue = [_cacheHelper Get:cacheKey];
        if (cacheValue != nil)
            return cacheValue;
        
        cacheValue = nil;//数据库查询不到，为空。
//        if (cacheValue2 == nil)
//        {
//            return nil;//一般为空，不做缓存
//        }
        
        if (cacheValue == nil)
        {
            cacheValue = @"";//如果发现为空，我设置个默认值，也缓存起来。
        }
        cacheValue = @"395"; //这里一般是 sql查询数据。 例：395 签到天数
        [_cacheHelper Add:cacheKey object:cacheValue cacheMinute:cacheTime];
    }
    
    return cacheValue;
}

//四：再谈缓存雪崩

-(id)GetMemberSigninDays5
{
    const int cacheTime = 5;
    NSString *cacheKey = @"mushroomsir";
    
    //缓存标记。
    NSString *cacheSign = [NSString stringWithFormat:@"%@%@", cacheKey, @"_Sign"];
    NSString *sign = [_cacheHelper Get:cacheSign];
    
    //获取缓存值
    __block id cacheValue = [_cacheHelper Get:cacheKey];
    if (cacheValue != nil)
        return cacheValue;//未过期，直接返回。
    
    @synchronized(cacheSign)
    {
        sign = [_cacheHelper Get:cacheSign];
        if (sign != nil)
            return cacheValue;
        
        [_cacheHelper Add:cacheSign object:@"1" cacheMinute:cacheTime];
        dispatch_sync(dispatch_get_main_queue(), ^
        {
            cacheValue = @"395"; //这里一般是 sql查询数据。 例：395 签到天数
            [_cacheHelper Add:cacheKey object:cacheValue cacheMinute:cacheTime]; //日期设缓存时间的2倍，用于脏读。
        });
    }
    
    return cacheValue;
}

@end
