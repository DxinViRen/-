//
//  DBBaseModel.h
//  DataBasePractice
//
//  Created by D.xin on 2017/4/26.
//  Copyright © 2017年 D.xin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#define SQLTEXT   @"TEXT"
#define SQLINTEGER @"INTEGER"
#define SQLREAL   @"REAL"
#define SQLBLOB   @"BLOB"
#define SQLNULL   @"NULL"
#define Primarykey  @"PRIMARY KEY"
#define primaryId @"pk"
@interface DBBaseModel : NSObject

#pragma mark - property
/*主键ID*/
@property(nonatomic,assign)int  pk;

/*查表的关键字字段*/
@property(nonatomic,copy)NSString * keyWord;

/*列名*/
@property(nonatomic,retain,readonly)NSMutableArray * columeNames;

/*列类型*/
@property(nonatomic,retain,readonly)NSMutableArray * columeTypes;


#pragma mark - methods
/*获取该类中的所有的属性*/
+(NSDictionary *)getProperty;

/*获取所有的属性，包括主键*/
+(NSDictionary *)getAllPropertys;

/*数据库中是否存在表*/
+(BOOL)isExistTable;

/*表中的字段*/
+(NSArray *)getColumes;

/*保存或者更新
   如果不存在主键，保存
    存在主键  ，更新
*/
-(BOOL)saveOrUpDate;

/*保存单个数据*/
-(BOOL)save;

/*批量保存数据*/
+(BOOL)saveObjects:(NSArray *)array;

/*更新单个数据*/
-(BOOL)update;

/*批量更新数据*/
+(BOOL)updateObject:(NSArray *)array;

/*删除单个数据*/
-(BOOL)deleteObject;

/*批量删除数据*/
+(BOOL)deleteObject:(NSArray *)array;

/*通过条件删除数据*/
+(BOOL)deleteObjectByCriteria:(NSString *)criteria;

/*清空表*/
+(BOOL)clearTable;

/*查询全部数据*/
+(NSArray *)findAll;

/*通过主键查询*/
+(instancetype)findByPK:(int)pk;



/*查找某一条数据*/
+(instancetype)finderFirstByCriteria:(NSString *)creiteria;

/*通过条件查找，返回数组中的第一个*/
+(instancetype)findWhereColume:(NSString *)colume  equToValue:(NSString *)value;


/*通过条件查找数据，这样可以进行分页查找 
 
  WHERE PK >5 limit 10
 
 */

+(NSArray *)finderByCriteria:(NSString *)criteria;


/*创建表，如果已经创建，返回YES*/
+(BOOL)createTable;

/*如果子类中有一些Property不需要创建数据库字段，那么这个方法必须在子类中重写*/
+(NSArray *)transients;

/*数据是否存在*/
-(BOOL)isExsistObj;








@end
