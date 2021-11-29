//
//  LCFileDB.m
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import "LCFileDB.h"
#import "LCFileM+WCDB.h"
#import "LCFileTagM+WCDB.h"

#define KFileSaveMTab    LCFileM.tableName
#define KFileSaveMCls    LCFileM.class

#define KFileSaveTagMTab LCFileTagM.tableName
#define KFileSaveTagMCls LCFileTagM.class

static WCTDatabase *_db = nil;
@interface LCFileDB ()
@property (nonatomic, strong, class) WCTDatabase *db;
@end
@implementation LCFileDB

///MARK: - LCFileM

///MARK: save
+ (BOOL)lc_saveFile:(LCFileM *)fileM {
    if (fileM.md5.length == 0 || fileM.key.length == 0 || fileM.filePath.length == 0) {
        NSAssert(false, @"lc_saveFile fail,unnullable");
        return NO;
    }
    BOOL ret = [LCFileDB.db insertOrReplaceObject:fileM into:KFileSaveMTab];
    NSAssert(ret, @"lc_saveFile fail");
    return ret;
}

///MARK: get
+ (LCFileM *)lc_getFileWithMd5:(NSString *)md5 {
    return [LCFileDB.db getOneObjectOfClass:KFileSaveMCls fromTable:KFileSaveMTab where:LCFileM.md5 == md5];
}

+ (LCFileM *)lc_getFileWithKey:(NSString *)key {
    return [LCFileDB.db getOneObjectOfClass:KFileSaveMCls fromTable:KFileSaveMTab where:LCFileM.key == key];
}

+ (LCFileM *)lc_getFileWithfilePath:(NSString *)filePath {
    return [LCFileDB.db getOneObjectOfClass:KFileSaveMCls fromTable:KFileSaveMTab where:LCFileM.filePath == filePath];
}
///MARK: update

///MARK: delete
+ (BOOL)lc_deleteFileWithMd5:(NSString *)md5 {
    BOOL ret = [LCFileDB.db deleteObjectsFromTable:KFileSaveMTab where:LCFileM.md5 == md5];
    NSAssert(ret, @"delete failed");
    return ret;
}
+ (BOOL)lc_deleteFileWithMd5s:(NSArray *)md5s {
    BOOL ret = [LCFileDB.db deleteObjectsFromTable:KFileSaveMTab where:LCFileM.md5.in(md5s)];
    NSAssert(ret, @"delete failed");
    return ret;
}
///MARK: - LCFileTagM

///MARK: save
+ (BOOL)lc_saveTag:(LCFileTagM *)tag {
    if (tag.md5.length == 0 || tag.tag.length == 0 || tag.group == 0) {
        NSAssert(false, @"save fail,unnullable");
        return NO;
    }
    BOOL ret = [LCFileDB.db insertOrReplaceObject:tag into:KFileSaveTagMTab];
    NSAssert(ret, @"save failed");
    return ret;
}

///MARK: get

+ (LCFileTagM *)lc_getTagWithTagId:(NSString *)tagId {
    return [LCFileDB.db getOneObjectOfClass:KFileSaveTagMCls fromTable:KFileSaveTagMTab where:LCFileTagM.tagId == tagId];
}

+ (NSArray<LCFileTagM *> *)lc_getTagWithMd5:(NSString *)md5 {
    return [LCFileDB.db getObjectsOfClass:KFileSaveTagMCls fromTable:KFileSaveTagMTab where:LCFileTagM.md5 == md5];
}
+ (NSArray<LCFileTagM *> *)lc_getTagWithTag:(NSString *)tag {
    return [LCFileDB.db getObjectsOfClass:KFileSaveTagMCls fromTable:KFileSaveTagMTab where:LCFileTagM.tag == tag];
}
+ (NSArray<LCFileTagM *> *)lc_getTagWithGroup:(NSString *)group {
    return [LCFileDB.db getObjectsOfClass:KFileSaveTagMCls fromTable:KFileSaveTagMTab where:LCFileTagM.group == group];
}
 

///MARK: update

///MARK: delete

+ (BOOL)lc_deleteWithTagId:(NSString *)tagId {
    BOOL ret = [LCFileDB.db deleteObjectsFromTable:KFileSaveTagMTab where:LCFileTagM.tagId == tagId];
    NSAssert(ret, @"delete tag failed");
    return ret;
}


+ (BOOL)lc_deleteTag:(NSString *)tag md5:(NSString *)md5 inGroup:(NSString *)group{
    WCTExpr expr = 1;
    if(tag.length > 0){
        expr = expr && LCFileTagM.tag == tag;
    }
    if(md5.length > 0){
        expr = expr && LCFileTagM.md5 == md5;
    }
    if(group.length > 0){
        expr = expr && LCFileTagM.group == group;
    }
    
    BOOL ret = [LCFileDB.db deleteObjectsFromTable:KFileSaveTagMTab where:expr];
    NSAssert(ret, @"delete tag failed");
    return ret;
}

+ (BOOL)lc_deleteTagInGroup:(NSString *)group after:(long long)time{
    BOOL ret = [LCFileDB.db deleteObjectsFromTable:KFileSaveTagMTab where:LCFileTagM.group == group && LCFileTagM.time >= time];
    NSAssert(ret, @"delete tag failed");
    return ret;
}
+ (BOOL)lc_deleteTagInGroup:(NSString *)group before:(long long)time{
    BOOL ret = [LCFileDB.db deleteObjectsFromTable:KFileSaveTagMTab where:LCFileTagM.group == group && LCFileTagM.time <= time];
    NSAssert(ret, @"delete tag failed");
    return ret;
}

///MARK: - file+tag

/// 查询没有任何tag 的文件
+ (NSArray<LCFileM *> *)lc_getNoTagFile {
    WCTResultList resultList = {
        LCFileM.AllProperties.inTable(KFileSaveMTab),
        LCFileTagM.AllProperties.inTable(KFileSaveTagMTab)
    };
    WCTExpr condition = LCFileTagM.tagId.inTable(KFileSaveTagMTab).isNull();
    
    WCDB::JoinClause joinClause = WCDB::JoinClause(KFileSaveMTab.UTF8String)
        .join(KFileSaveTagMTab.UTF8String, WCDB::JoinClause::Type::LeftOuter)
        .on(LCFileM.md5.inTable(KFileSaveMTab)  == LCFileTagM.md5.inTable(KFileSaveTagMTab));
    WCDB::StatementSelect statementSelect = WCDB::StatementSelect().select(resultList).from(joinClause).where(condition);
    WCTError *error;
    WCTStatement *statement = [LCFileDB.db prepare:statementSelect withError:&error];
    NSMutableArray *files = [NSMutableArray array];
    if (statement) {
        while ([statement step]) {
            LCFileM *file = [[LCFileM alloc] init];
            for (int i = 0; i < [statement getColumnCount]; ++i) {
                NSString *tableName = [statement getTableNameAtIndex:i];
                NSString *columnName = [statement getColumnNameAtIndex:i];
                WCTValue *value = [statement getValueAtIndex:i];
                if ([tableName isEqualToString:KFileSaveMTab]) {
                    if (value != NULL) [file setValue:value forKey:columnName];
                }
            }
            [files addObject:file];
            
        }
        error = [statement getError];
        if (error) {
            NSLog(@"Error %@", error);
        }
    } else {
        NSLog(@"Error %@", error);
    }
    return files;
}

///MARK: - DB
+ (WCTDatabase *)openDB {
    // 创建数据库
    NSString *dbDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    NSString *dbPath = [dbDir stringByAppendingPathComponent:@"lc_file.db"];
    WCTDatabase *db = [[WCTDatabase alloc] initWithPath:dbPath];
    [self setDb:db];
    NSLog(@"save file db path:%@",dbPath);
    // 创建表
    if ([db canOpen] && [db isOpened]) {
        [db createTableAndIndexesOfName:KFileSaveMTab withClass:KFileSaveMCls];
        [db createTableAndIndexesOfName:KFileSaveTagMTab withClass:KFileSaveTagMCls];
    }
    return db;
}

+ (void)closeDB {
    [LCFileDB.db close];
}

+ (void)setDb:(WCTDatabase *)db {
    _db = db;
}

+ (WCTDatabase *)db {
    if (_db == nil) {
        _db = [self openDB];
    }
    return _db;
}

@end
