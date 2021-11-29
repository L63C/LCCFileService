//
//  LCFileM+WCDB.h
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import "LCFileM.h"
#import <WCDB/WCDB.h>
NS_ASSUME_NONNULL_BEGIN

@interface LCFileM (WCDB)<WCTTableCoding>
WCDB_PROPERTY(md5);
WCDB_PROPERTY(key);
WCDB_PROPERTY(filePath);


+ (NSString *)tableName;
@end

NS_ASSUME_NONNULL_END
