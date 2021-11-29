//
//  LCFileM+WCDB.m
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import "LCFileM+WCDB.h"

@implementation LCFileM (WCDB)

WCDB_IMPLEMENTATION(LCFileM);

WCDB_SYNTHESIZE(LCFileM, key);
WCDB_SYNTHESIZE(LCFileM, md5);
WCDB_SYNTHESIZE(LCFileM, filePath);

WCDB_PRIMARY(LCFileM,key);
WCDB_UNIQUE(LCFileM, key);

WCDB_NOT_NULL(LCFileM, key);
WCDB_NOT_NULL(LCFileM, md5);
WCDB_NOT_NULL(LCFileM, filePath);

+ (NSString *)tableName {
    return @"LCFileM";
}

@end
