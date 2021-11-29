//
//  LCFileTagM+WCDB.m
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import "LCFileTagM+WCDB.h"

@implementation LCFileTagM (WCDB)
WCDB_IMPLEMENTATION(LCFileTagM);

WCDB_SYNTHESIZE(LCFileTagM, tagId);
WCDB_SYNTHESIZE(LCFileTagM, md5);
WCDB_SYNTHESIZE(LCFileTagM, tag);
WCDB_SYNTHESIZE(LCFileTagM, group);
WCDB_SYNTHESIZE(LCFileTagM, time);
 
WCDB_PRIMARY(LCFileTagM, tagId);
WCDB_UNIQUE(LCFileTagM, tagId);
WCDB_NOT_NULL(LCFileTagM, md5);
WCDB_NOT_NULL(LCFileTagM, tag);
WCDB_NOT_NULL(LCFileTagM, group);

+ (NSString *)tableName {
    return @"LCFileTagM";
}
@end
