//
//  LCFileSaveService.m
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import "LCFileSaveService.h"
#import "Md5Tools.h"
#import "LCFileDB.h"
#import "LCFileM.h"
#import "LCFileTagM.h"
@interface LCFileSaveService ()
@end
@implementation LCFileSaveService

///MARK: - save

- (LCFileM *)lc_saveFileFrom:(NSString *)sourcePath
                         key:(nullable NSString *)key
                         tag:(NSString *)tag
                       group:(NSString *)group
                        time:(long long)time
                deleteSource:(BOOL)deleteSource {
    if (!(sourcePath && [[NSFileManager defaultManager] fileExistsAtPath:sourcePath])) {
        NSAssert(nil, @"sourcePath = nil");
        return nil;
    }
    if (tag.length == 0) {
        NSAssert(nil, @"tag = nil");
        return nil;
    }
    NSString *md5 = [Md5Tools fileMD5WithPath:sourcePath];
    if (!key) {
        key = md5;
    }
    LCFileM *fileM = [[LCFileM alloc] init];
    fileM.key = key;
    fileM.md5 = md5;
    fileM.filePath = [self p_copyFile:sourcePath withMd5:md5 deleteSource:deleteSource];

    LCFileTagM *tagM = [[LCFileTagM alloc] init];
    tagM.md5 = md5;
    tagM.time = time ? : [NSDate date].timeIntervalSince1970;
    [LCFileDB lc_saveFile:fileM];
    [LCFileDB lc_saveTag:tagM];
    return fileM;
}

///MARK: - get

- (LCFileM *)lc_getFileWithMd5:(NSString *)md5 {
    LCFileM *fileM = [LCFileDB lc_getFileWithMd5:md5];
    if (![self p_fileExist:fileM]) {
        return nil;
    }
    return fileM;
}

- (LCFileM *)lc_getFileWithKey:(NSString *)key {
    LCFileM *fileM = [LCFileDB lc_getFileWithKey:key];
    if (![self p_fileExist:fileM]) {
        return nil;
    }
    return fileM;
}

- (LCFileM *)lc_getFileWithFilePath:(NSString *)filePath {
    LCFileM *fileM = [LCFileDB lc_getFileWithfilePath:filePath];
    if (![self p_fileExist:fileM]) {
        return nil;
    }
    return fileM;
}

///MARK: - delete

- (BOOL)lc_deleteFileWithMd5:(NSString *)md5 tag:(NSString *)tag group:(NSString *)group {
    [LCFileDB lc_deleteTag:tag md5:md5 inGroup:group];
    [self p_deleteNoTagFile];

    return YES;
}

- (BOOL)lc_deleteFileWithKey:(NSString *)key tag:(NSString *)tag group:(NSString *)group {
    LCFileM *fileM = [LCFileDB lc_getFileWithKey:key];
    return [self lc_deleteFileWithMd5:fileM.md5 tag:tag group:group];
}

- (BOOL)lc_deleteFileWithFilePath:(NSString *)filePath tag:(NSString *)tag group:(NSString *)group {
    LCFileM *fileM = [LCFileDB lc_getFileWithfilePath:filePath];
    return [self lc_deleteFileWithMd5:fileM.md5 tag:tag group:group];
}

- (BOOL)lc_deleteFileInGroup:(NSString *)group after:(long long)time {
    [LCFileDB lc_deleteTagInGroup:group after:time];
    [self p_deleteNoTagFile];
    return YES;
}

- (BOOL)lc_deleteFileInGroup:(NSString *)group before:(long long)time {
    [LCFileDB lc_deleteTagInGroup:group before:time];
    [self p_deleteNoTagFile];
    return YES;
}

///MARK: - private methods
/// 删除没有tag 的文件
- (void)p_deleteNoTagFile {
    NSArray<LCFileM *> *files = [LCFileDB lc_getNoTagFile];
    /// delete files
    NSMutableArray *md5s = [NSMutableArray array];
    [files enumerateObjectsUsingBlock:^(LCFileM *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [md5s addObject:obj.md5];
        if (obj.filePath && [[NSFileManager defaultManager] fileExistsAtPath:obj.filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:obj.filePath error:nil];
        }
    }];
    [LCFileDB lc_deleteFileWithMd5s:md5s];
}

/// 按照日期进行文件分组
- (NSString *)p_getSaveDir {
    NSString *rootDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    NSString *timeStr = [dateFormatter stringFromDate:[NSDate date]];
    NSString *saveDir = [rootDir stringByAppendingPathComponent:timeStr];
    return saveDir;
}

- (BOOL)p_fileExist:(LCFileM *)fileM {
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileM.filePath]) {
        [LCFileDB lc_deleteFileWithMd5:fileM.md5];
        [LCFileDB lc_deleteTag:nil md5:fileM.md5 inGroup:nil];
        return NO;
    }
    if ([LCFileDB lc_getTagWithMd5:fileM.md5].count == 0) {
        [LCFileDB lc_deleteFileWithMd5:fileM.md5];
        [[NSFileManager defaultManager] removeItemAtPath:fileM.filePath error:nil];
        return NO;
    }
    return YES;
}

- (NSString *)p_copyFile:(NSString *)sourcePath
                 withMd5:(NSString *)md5
            deleteSource:(BOOL)deleteSource {
    LCFileM *oldFile = [LCFileDB lc_getFileWithMd5:md5];
    if (oldFile && [[NSFileManager defaultManager] fileExistsAtPath:oldFile.filePath]) {
        return oldFile.filePath;
    }
    NSString *filePath = [[[self p_getSaveDir] stringByAppendingPathComponent:md5] stringByAppendingPathExtension:sourcePath.pathExtension];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        if (deleteSource) {
            // 移动文件
            if (![[NSFileManager defaultManager] moveItemAtPath:sourcePath toPath:filePath error:nil]) {
                return nil;
            }
        } else {
            // 拷贝文件
            if (![[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:filePath error:nil]) {
                return nil;
            }
        }
    }
    return filePath;
}

@end
