//
//  LCFileNetTask+WCDB.m
//  S3Demo
//
//  Created by L63 on 2021/10/9.
//

#import "LCFileNetTask+WCDB.h"
@implementation LCFileNetTask (WCDB)

WCDB_IMPLEMENTATION(LCFileNetTask);

WCDB_SYNTHESIZE(LCFileNetTask, taskId);
WCDB_SYNTHESIZE(LCFileNetTask, fileKey);
WCDB_SYNTHESIZE(LCFileNetTask, md5);
WCDB_SYNTHESIZE(LCFileNetTask, type);
WCDB_SYNTHESIZE(LCFileNetTask, status);
WCDB_SYNTHESIZE(LCFileNetTask, way);
WCDB_SYNTHESIZE(LCFileNetTask, totalSize);
WCDB_SYNTHESIZE(LCFileNetTask, finishedSize);
WCDB_SYNTHESIZE(LCFileNetTask, fileName);
WCDB_SYNTHESIZE(LCFileNetTask, filePath);
WCDB_SYNTHESIZE(LCFileNetTask, url);

WCDB_PRIMARY(LCFileNetTask, taskId);
WCDB_UNIQUE(LCFileNetTask, taskId);
WCDB_NOT_NULL(LCFileNetTask, taskId);

+ (NSString *)tableName {
    return @"LCFileNetTask";
}
@end
