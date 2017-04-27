//
//  ViewController.m
//  DataBasePractice
//
//  Created by D.xin on 2017/4/24.
//  Copyright © 2017年 D.xin. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <FMDatabase.h>
#import <FMDatabaseQueue.h>
@interface ViewController ()
@property(nonatomic,retain)FMDatabase *fmDataBase;
@end

@implementation ViewController

#pragma mark - life style
- (void)viewDidLoad {
    [super viewDidLoad];
    NSString * doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString * fileName = [doc stringByAppendingString:@"students.squlit"];
    FMDatabase * db = [FMDatabase databaseWithPath:fileName];
    if([db open]){
    
        //创建一张表
        BOOL isResult = [db executeUpdate:@"CREAT TABLE IF NOT EXISTS t_student(id integer PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL ,age integer NOT NULL)"];
        if(isResult){
  
            NSLog(@"成功创建表");
        }else{
            NSLog(@"创建表失败");
        }
        
        
    }else{
    
    }
    
    FMDatabaseQueue * queue = [FMDatabaseQueue databaseQueueWithPath:fileName];
    [queue inDatabase:^(FMDatabase *db) {
        if([db executeUpdate:@"CFREAT TABLE IF NOT EXISTS t_student(id integer PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,age integer NOT NULL)"]){
            NSLog(@"创建成功");
        }else{
            NSLog(@"创建失败");
        }
    }];
    
 
    
}


#pragma mark - getter
-(FMDatabase *)fmDataBase{
    if(!_fmDataBase){
        _fmDataBase = [FMDatabase databaseWithPath:@""];
    }
    return _fmDataBase;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
