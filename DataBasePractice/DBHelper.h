//
//  DBHelper.h
//  DataBasePractice
//
//  Created by D.xin on 2017/4/27.
//  Copyright © 2017年 D.xin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDatabaseQueue.h>
@interface DBHelper : NSObject

@property(nonatomic,retain)FMDatabaseQueue * queue;

+(instancetype)shareDBHelper;
/*获取数据库的沙盒地址*/
+(NSString *)dbPath;
@end
