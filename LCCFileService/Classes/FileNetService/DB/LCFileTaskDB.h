//
//  LCFileTaskDB.h
//  S3Demo
//
//  Created by L63 on 2021/10/9.
//

#import <Foundation/Foundation.h>
#import "LCFileNetTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface LCFileTaskDB : NSObject
///MARK: - save

+ (BOOL)lc_saveTask:(LCFileNetTask *)task;

///MARK: - get

+ (LCFileNetTask *)lc_getTaskByTaskId:(NSString *)taskId;

+ (NSArray<LCFileNetTask *> *)lc_getTaskByMd5:(NSString *)md5;

+ (NSArray<LCFileNetTask *> *)lc_getTaskByFileKey:(NSString *)fileKey;

///MARK: - delete

+ (BOOL)lc_deleteTaskByTaskId:(NSString *)taskId;

///MARK: - update

+ (BOOL)lc_updateTask:(NSString *)taskId
               status:(LCFileNetTaskStatus)status;

+ (BOOL)lc_updateTask:(NSString *)taskId
         finishedSize:(int64_t)finishedSize
            totalSize:(int64_t)totalSize;

+ (BOOL)lc_updateTask:(NSString *)taskId
             filePath:(NSString *)filePath;
@end

NS_ASSUME_NONNULL_END
