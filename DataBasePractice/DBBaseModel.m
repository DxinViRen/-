//
//  DBBaseModel.m
//  DataBasePractice
//
//  Created by D.xin on 2017/4/26.
//  Copyright © 2017年 D.xin. All rights reserved.
//

#import "DBBaseModel.h"
#import "DBHelper.h"
#import <FMDatabaseAdditions.h>
static NSString * dbTimeCount;
@implementation DBBaseModel

+(void)initialize{
    if(self != [DBBaseModel self]){
        [self createTable];
    }
}

-(instancetype)init{
    if(self = [super init]){
    
        NSDictionary * dic = [self.class getAllPropertys];
        _columeNames = [[NSMutableArray alloc]initWithArray:[dic objectForKey:@"name"]];
        _columeTypes = [[NSMutableArray alloc]initWithArray:[dic objectForKey:@"type"]];
    }
    return self;
}

#pragma base method

/*获取该类的所有的属性*/
+(NSDictionary *)getProperty{
    NSMutableArray * proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    NSArray * TheTransients = [[self class]transients];
    
    unsigned int outCount,i;
    objc_property_t * properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i<outCount; i++) {
        objc_property_t property= properties[i];
        //获取属性名称
        NSString * propertyName = [NSString  stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        if([TheTransients containsObject:propertyName]){
            continue;
        }
        [proNames addObject:propertyName];
        
        //获取属性类型等参数
        NSString * propertyType  = [NSString  stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        
        if ([propertyType hasPrefix:@"T@"]) {
            [proTypes addObject:SQLTEXT];
        } else if ([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"]) {
            [proTypes addObject:SQLINTEGER];
        } else {
            [proTypes addObject:SQLREAL];
        }
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",nil];
}


/*获取所有的属性 包括主键KEY*/
+(NSDictionary *)getAllPropertys{
    NSDictionary *dict = [self.class getAllPropertys];
    
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    [proNames addObject:primaryId];
    [proTypes addObject:[NSString stringWithFormat:@"%@ %@",SQLINTEGER,Primarykey]];
    [proNames addObjectsFromArray:[dict objectForKey:@"name"]];
    [proTypes addObjectsFromArray:[dict objectForKey:@"type"]];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",nil];
}


/*数据库中是否有表存在*/
+(BOOL)isExistTable{
    __block BOOL res = NO;
    DBHelper * dbhelper =[DBHelper shareDBHelper];
    //这样操作是线程安全的
   [dbhelper.queue inDatabase:^(FMDatabase *db) {
       NSString * tableName = NSStringFromClass([self class]);
       res = [db tableExists:tableName];
   }];
    return res;
}

+(NSArray *)getColumes{

    DBHelper * dbHelper = [DBHelper shareDBHelper];
    NSMutableArray * columns = [NSMutableArray array];
    [dbHelper.queue inDatabase:^(FMDatabase *db) {
        
        NSString * tableName =NSStringFromClass([self class]);
        FMResultSet * resultSet = [db getTableSchema:tableName];
        while ([resultSet next]) {
            NSString * column = [resultSet stringForColumn:@"name"];
            [columns addObject:column];
        }
    }];
    return [columns copy];
}


/*创建表，如果已经创建返回YES*/
+(BOOL)createTable{
    FMDatabase * dateBase =[FMDatabase databaseWithPath:[DBHelper dbPath]];
    if(![dateBase open]){
        NSLog(@"数据库打开失败");
        return NO;
    }
    /*这是随便起的名字*/
    NSString * tableName = NSStringFromClass([self class]);
    NSString * columnType =[[self class]getColumeAndTypeString];
    NSString * sql = [NSString stringWithFormat:@"CREAT TABLE IF NOT EXISTS %@(%@)",tableName,columnType];
    if(![dateBase executeUpdate:sql]){
        return NO;
    }
    NSMutableArray * columns = [NSMutableArray array];
    FMResultSet * resultSet = [dateBase getTableSchema:tableName];
    while ([resultSet next]) {
        NSString * colunm = [resultSet stringForColumn:@"name"];
        [columns addObject:colunm];
    }
    
    NSDictionary * dic =[[self class] getAllPropertys];
    NSArray * properties = [dic objectForKey:@"name"];
    NSPredicate * filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",columns];
    //过滤数组
    NSArray *resultArray = [properties filteredArrayUsingPredicate:filterPredicate];
    
    for (NSString *column in resultArray) {
        NSUInteger index = [properties indexOfObject:column];
        NSString *proType = [[dic objectForKey:@"type"] objectAtIndex:index];
        NSString *fieldSql = [NSString stringWithFormat:@"%@ %@",column,proType];
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ ",NSStringFromClass(self.class),fieldSql];
        if (![dateBase executeUpdate:sql]) {
            return NO;
        }
    }
    [dateBase close];
    return YES;
    
}

//数据是否存在
- (BOOL )isExsistObj{
    
    id otherPaimaryValue = [self valueForKey:_keyWord];
    
    DBHelper *dbHelper = [DBHelper shareDBHelper];
    
    __block BOOL isExist = NO;
    
    __block DBBaseModel *WeakSelf = self;
    
    [dbHelper.queue inDatabase:^(FMDatabase *db) {
        
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = '%@'",tableName,WeakSelf.keyWord,otherPaimaryValue];
        
        FMResultSet *aResult = [db executeQuery:sql];
        
        if([aResult next]){
            
            isExist = YES;
            
        }else{
            
            isExist = NO;
        }
        [aResult close];
    }];
    
    return isExist;
}

- (BOOL)saveOrUpdate
{
    
    BOOL isExsist = [self isExsistObj];
    
    if (isExsist ) {
        
        return  [self update];
        
    }else{
        
        return [self save];
        
    }
}




- (BOOL)save
{
    //保存修改时间
    NSTimeInterval time = [[NSDate date]timeIntervalSince1970];
    NSString *str = [NSString stringWithFormat:@"%.0f",time];
    
    NSString *tableName = NSStringFromClass(self.class);
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray  array];
    for (int i = 0; i < self.columeNames.count; i++) {
        NSString *proname = [self.columeNames objectAtIndex:i];
        if ([proname isEqualToString:primaryId]) {
            continue;
        }
        
        [keyString appendFormat:@"%@,", proname];
        [valueString appendString:@"?,"];
        id value;
        if ([proname isEqualToString:dbTimeCount]) {
            value = str;
        }else{
            value = [self valueForKey:proname];
        }
        if (!value) {
            value = @"";
        }
        [insertValues addObject:value];
    }
    
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
    
    DBHelper *dbHelper = [DBHelper shareDBHelper];
    __block BOOL res = NO;
    [dbHelper.queue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
        res = [db executeUpdate:sql withArgumentsInArray:insertValues];
        self.pk = res?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
        NSLog(res?@"插入成功":@"插入失败");
    }];
    return res;
}

/** 批量保存用户对象 */
+ (BOOL)saveObjects:(NSArray *)array
{
    //判断是否是JKBaseModel的子类
    for (DBBaseModel *model in array) {
        if (![model isKindOfClass:[DBBaseModel class]]) {
            return NO;
        }
    }
    
    __block BOOL res = YES;
    DBHelper *dbHelper = [DBHelper shareDBHelper];
    // 如果要支持事务
    [dbHelper.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (DBBaseModel *model in array) {
            //保存修改时间
            NSTimeInterval time = [[NSDate date]timeIntervalSince1970];
            NSString *str = [NSString stringWithFormat:@"%.0f",time];
            
            NSString *tableName = NSStringFromClass(model.class);
            NSMutableString *keyString = [NSMutableString string];
            NSMutableString *valueString = [NSMutableString string];
            NSMutableArray *insertValues = [NSMutableArray  array];
            for (int i = 0; i < model.columeNames.count; i++) {
                NSString *proname = [model.columeNames objectAtIndex:i];
                if ([proname isEqualToString:primaryId]) {
                    continue;
                }
                [keyString appendFormat:@"%@,", proname];
                [valueString appendString:@"?,"];
                id value;
                if ([proname isEqualToString:dbTimeCount]) {
                    value = str;
                }else{
                    value = [model valueForKey:proname];
                }
                if (!value) {
                    value = @"";
                }
                [insertValues addObject:value];
            }
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
            
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:insertValues];
            model.pk = flag?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
            NSLog(flag?@"插入成功":@"插入失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return res;
}



/** 更新单个对象 */
- (BOOL)update
{
    //设置更新时间
    NSTimeInterval time = [[NSDate date]timeIntervalSince1970];
    NSString *str = [NSString stringWithFormat:@"%.0f",time];
    
    DBHelper *dbHelper = [DBHelper shareDBHelper
                          ];
    __block BOOL res = NO;
    
    [dbHelper.queue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValue = [self valueForKey:self.keyWord];
        
        NSMutableString *keyString = [NSMutableString string];
        NSMutableArray *updateValues = [NSMutableArray  array];
        for (int i = 0; i < self.columeNames.count; i++) {
            NSString *proname = [self.columeNames objectAtIndex:i];
            if ([proname isEqualToString:self.keyWord]) {
                continue;
            }
            if([proname isEqualToString:primaryId]){
                
                continue;
            }
            [keyString appendFormat:@" %@=?,", proname];
            id value;
            if ([proname isEqualToString:dbTimeCount]) {
                value = str;
            }else{
                value = [self valueForKey:proname];
            }
            if (!value) {
                value = @"";
            }
            [updateValues addObject:value];
        }
        
        //删除最后那个逗号
        [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
        NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?;", tableName, keyString, self.keyWord];
        [updateValues addObject:primaryValue];
        res = [db executeUpdate:sql withArgumentsInArray:updateValues];
        NSLog(res?@"更新成功":@"更新失败");
    }];
    return res;
}


/** 批量更新用户对象*/
+ (BOOL)updateObjects:(NSArray *)array
{
    for (DBBaseModel *model in array) {
        if (![model isKindOfClass:[DBBaseModel class]]) {
            return NO;
        }
    }
    __block BOOL res = YES;
    DBHelper *dbHelper = [DBHelper shareDBHelper];
    // 如果要支持事务
    [dbHelper.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (DBBaseModel *model in array) {
            NSTimeInterval time = [[NSDate date]timeIntervalSince1970];
            NSString *str = [NSString stringWithFormat:@"%.0f",time];
            
            NSString *tableName = NSStringFromClass(model.class);
            id primaryValue = [model valueForKey:primaryId];
            if (!primaryValue || primaryValue <= 0) {
                res = NO;
                *rollback = YES;
                return;
            }
            
            NSMutableString *keyString = [NSMutableString string];
            NSMutableArray *updateValues = [NSMutableArray  array];
            for (int i = 0; i < model.columeNames.count; i++) {
                NSString *proname = [model.columeNames objectAtIndex:i];
                if ([proname isEqualToString:primaryId]) {
                    continue;
                }
                [keyString appendFormat:@" %@=?,", proname];
                id value;
                if ([proname isEqualToString:dbTimeCount]) {
                    value = str;
                }else{
                    value = [model valueForKey:proname];
                }
                if (!value) {
                    value = @"";
                }
                [updateValues addObject:value];
            }
            
            //删除最后那个逗号
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=?;", tableName, keyString, primaryId];
            [updateValues addObject:primaryValue];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:updateValues];
            NSLog(flag?@"更新成功":@"更新失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    
    return res;
}

/** 删除单个对象 */
- (BOOL)deleteObject
{
    DBHelper *dbHelper = [DBHelper shareDBHelper];
    __block BOOL res = NO;
    [dbHelper.queue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValue = [self valueForKey:primaryId];
        if (!primaryValue || primaryValue <= 0) {
            return ;
        }
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName,primaryId];
        res = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
        NSLog(res?@"删除成功":@"删除失败");
    }];
    return res;
}

/** 批量删除用户对象 */
+ (BOOL)deleteObjects:(NSArray *)array
{
    for (DBBaseModel *model in array) {
        if (![model isKindOfClass:[DBBaseModel class]]) {
            return NO;
        }
    }
    
    __block BOOL res = YES;
    DBHelper *dbHelper = [DBHelper shareDBHelper];
    // 如果要支持事务
    [dbHelper.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (DBBaseModel *model in array) {
            NSString *tableName = NSStringFromClass(model.class);
            id primaryValue = [model valueForKey:primaryId];
            if (!primaryValue || primaryValue <= 0) {
                return ;
            }
            
            NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName,primaryId];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
            NSLog(flag?@"删除成功":@"删除失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return res;
}

/** 通过条件删除数据 */
+ (BOOL)deleteObjectsByCriteria:(NSString *)criteria
{
    DBHelper *dbHelper = [DBHelper shareDBHelper];
    __block BOOL res = NO;
    [dbHelper.queue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ %@ ",tableName,criteria];
        res = [db executeUpdate:sql];
        NSLog(res?@"删除成功":@"删除失败");
    }];
    return res;
}

/** 清空表 */
+ (BOOL)clearTable
{
    DBHelper *dbHelper = [DBHelper shareDBHelper];
    __block BOOL res = NO;
    [dbHelper.queue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@",tableName];
        res = [db executeUpdate:sql];
        NSLog(res?@"清空成功":@"清空失败");
    }];
    return res;
}

/** 查询全部数据 */
+ (NSArray *)findAll
{
    NSLog(@"db---%s",__func__);
    DBHelper *dbHelper = [DBHelper shareDBHelper];
    NSMutableArray *users = [NSMutableArray array];
    [dbHelper.queue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            DBBaseModel *model = [[self.class alloc] init];
            for (int i=0; i< model.columeNames.count; i++) {
                NSString *columeName = [model.columeNames objectAtIndex:i];
                NSString *columeType = [model.columeTypes objectAtIndex:i];
                if ([columeType isEqualToString:SQLTEXT]) {
                    [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                } else {
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                }
            }
            [users addObject:model];
            FMDBRelease(model);
        }
    }];
    
    return users;
}

/** 查找某条数据 */
+ (instancetype)findFirstByCriteria:(NSString *)criteria
{
    NSArray *results = [self.class finderByCriteria:criteria];
    if (results.count < 1) {
        return nil;
    }
    
    return [results firstObject];
}

+ (instancetype)findByPK:(int)inPk
{
    NSString *condition = [NSString stringWithFormat:@"WHERE %@=%d",primaryId,inPk];
    return [self findFirstByCriteria:condition];
}








+(NSString *)getColumeAndTypeString{

    NSMutableString* pars = [NSMutableString string];
    NSDictionary *dict = [self.class getAllPropertys];
    
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    NSMutableArray *proTypes = [dict objectForKey:@"type"];
    
    for (int i=0; i< proNames.count; i++) {
        [pars appendFormat:@"%@ %@",[proNames objectAtIndex:i],[proTypes objectAtIndex:i]];
        if(i+1 != proNames.count)
        {
            [pars appendString:@","];
        }
    }
    return pars;
}


+ (instancetype)findWhereColoum:(NSString *)coloum equleToValue:(NSString *)value{
    
    return [[self class] findFirstByCriteria:[NSString stringWithFormat:@"WHERE %@='%@'",coloum,value]];
}


#pragma mark - util method
//+ (NSString *)getColumeAndTypeString
//{
//    NSMutableString* pars = [NSMutableString string];
//    NSDictionary *dict = [self.class getAllPropertys];
//    
//    NSMutableArray *proNames = [dict objectForKey:@"name"];
//    NSMutableArray *proTypes = [dict objectForKey:@"type"];
//    
//    for (int i=0; i< proNames.count; i++) {
//        [pars appendFormat:@"%@ %@",[proNames objectAtIndex:i],[proTypes objectAtIndex:i]];
//        if(i+1 != proNames.count)
//        {
//            [pars appendString:@","];
//        }
//    }
//    return pars;
//}

- (NSString *)description
{
    NSString *result = @"";
    NSDictionary *dict = [self.class getAllPropertys];
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    for (int i = 0; i < proNames.count; i++) {
        NSString *proName = [proNames objectAtIndex:i];
        id  proValue = [self valueForKey:proName];
        result = [result stringByAppendingFormat:@"%@:%@\n",proName,proValue];
    }
    return result;
}

#pragma mark - must be override method
/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
 */
+ (NSArray *)transients
{
    return @[];
}

@end
