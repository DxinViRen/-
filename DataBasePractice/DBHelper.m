//
//  DBHelper.m
//  DataBasePractice
//
//  Created by D.xin on 2017/4/27.
//  Copyright © 2017年 D.xin. All rights reserved.
//

#import "DBHelper.h"

@implementation DBHelper
+(instancetype)shareDBHelper{
    static DBHelper * _shareDBhelper = nil;
    
    static dispatch_once_t onceToken;
    if(!_shareDBhelper){
    dispatch_once(&onceToken, ^{
        _shareDBhelper = [[super allocWithZone:nil]init];
    });
  }
    return _shareDBhelper;
}

#pragma mark - 保证单例不会被创建成新的对象
+(instancetype)allocWithZone:(struct _NSZone *)zone{
    return [DBHelper shareDBHelper];
}


+(NSString *)dbPath{

    NSString * docsDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)  lastObject];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    docsDir  =[docsDir stringByAppendingPathComponent:@"AppDataBase"];
    BOOL isDir;
    BOOL exit = [fileManager fileExistsAtPath:docsDir isDirectory:&isDir];
    if(!exit||!isDir){
        [fileManager createDirectoryAtPath:docsDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString * dbPath  = [docsDir stringByAppendingPathComponent:@"TierTime.sqlite"];
    return dbPath;
}


#pragma mark - getter
-(FMDatabaseQueue *)queue{
    if(!_queue){
        _queue = [FMDatabaseQueue databaseQueueWithPath:[[self class] dbPath]];
    }
    return _queue;
}
@end
