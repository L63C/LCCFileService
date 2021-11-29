//
//  LCFileTaskDB.m
//  S3Demo
//
//  Created by L63 on 2021/10/9.
//

#import "LCFileTaskDB.h"
#import "LCFileNetTask+WCDB.h"

#define KFileNetTaskTab LCFileNetTask.tableName
#define KFileNetTaskCls LCFileNetTask.class

static WCTDatabase *_db = nil;
@interface LCFileTaskDB ()
@property (nonatomic, strong, class) WCTDatabase *db;
@end
@implementation LCFileTaskDB
///MARK: - save
+ (BOOL)lc_saveTask:(LCFileNetTask *)task{
    BOOL ret = [LCFileTaskDB.db insertOrReplaceObject:task into:KFileNetTaskTab];
    NSAssert(ret, @"insert failed");
    return ret;
}
///MARK: - get

+ (LCFileNetTask *)lc_getTaskByTaskId:(NSString *)taskId{
    LCFileNetTask * task = [LCFileTaskDB.db getOneObjectOfClass:KFileNetTaskCls fromTable:KFileNetTaskTab where:LCFileNetTask.taskId == taskId];
    return task;
}
+ (NSArray<LCFileNetTask *> *)lc_getTaskByMd5:(NSString *)md5 {
    NSArray *arr = [LCFileTaskDB.db getObjectsOfClass:KFileNetTaskCls fromTable:KFileNetTaskTab where:LCFileNetTask.md5 == md5];
    return arr;
}
+ (NSArray<LCFileNetTask *> *)lc_getTaskByFileKey:(NSString *)fileKey {
    NSArray *arr = [LCFileTaskDB.db getObjectsOfClass:KFileNetTaskCls fromTable:KFileNetTaskTab where:LCFileNetTask.fileKey == fileKey];
    return arr;
}
///MARK: - delete
+ (BOOL)lc_deleteTaskByTaskId:(NSString *)taskId {
    BOOL ret = [LCFileTaskDB.db deleteObjectsFromTable:KFileNetTaskTab where:LCFileNetTask.taskId == taskId];
    return ret;
}
///MARK: - update
+ (BOOL)lc_updateTask:(NSString *)taskId status:(LCFileNetTaskStatus)status {
    BOOL ret = [LCFileTaskDB.db updateRowsInTable:KFileNetTaskTab onProperty:LCFileNetTask.status withValue:@(status) where:LCFileNetTask.taskId == taskId];
    return ret;
}
+ (BOOL)lc_updateTask:(NSString *)taskId
         finishedSize:(int64_t)finishedSize
            totalSize:(int64_t)totalSize{
    BOOL ret = [LCFileTaskDB.db updateRowsInTable:KFileNetTaskTab onProperties:{
        LCFileNetTask.finishedSize,
        LCFileNetTask.totalSize,
    } withRow:@[
        @(finishedSize),
        @(totalSize),
    ] where:LCFileNetTask.taskId == taskId];
    return ret;
}
+ (BOOL)lc_updateTask:(NSString *)taskId filePath:(NSString *)filePath {
    BOOL ret = [LCFileTaskDB.db updateRowsInTable:KFileNetTaskTab onProperty:LCFileNetTask.filePath withValue:filePath where:LCFileNetTask.taskId == taskId];
    return ret;
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
        [db createTableAndIndexesOfName:KFileNetTaskTab withClass:KFileNetTaskCls];
    }
    return db;
}

+ (void)closeDB {
    [LCFileTaskDB.db close];
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
