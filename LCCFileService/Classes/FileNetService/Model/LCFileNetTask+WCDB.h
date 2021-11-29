//
//  LCFileNetTask+WCDB.h
//  S3Demo
//
//  Created by L63 on 2021/10/9.
//

#import "LCFileNetTask.h"
#import <WCDB/WCDB.h>
NS_ASSUME_NONNULL_BEGIN

@interface LCFileNetTask (WCDB)<WCTTableCoding>

WCDB_PROPERTY(taskId);
WCDB_PROPERTY(fileKey);
WCDB_PROPERTY(md5);
WCDB_PROPERTY(type);
WCDB_PROPERTY(status);
WCDB_PROPERTY(way);
WCDB_PROPERTY(totalSize);
WCDB_PROPERTY(finishedSize);
WCDB_PROPERTY(fileName);
WCDB_PROPERTY(filePath);
WCDB_PROPERTY(url);


+ (NSString *)tableName;
@end

NS_ASSUME_NONNULL_END
