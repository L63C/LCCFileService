//
//  LCFileTagM+WCDB.h
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import "LCFileTagM.h"
#import <WCDB/WCDB.h>
NS_ASSUME_NONNULL_BEGIN

@interface LCFileTagM (WCDB)<WCTTableCoding>
WCDB_PROPERTY(tagId);
WCDB_PROPERTY(md5);
WCDB_PROPERTY(tag);
WCDB_PROPERTY(group);
WCDB_PROPERTY(time);
+ (NSString *)tableName;
@end

NS_ASSUME_NONNULL_END
