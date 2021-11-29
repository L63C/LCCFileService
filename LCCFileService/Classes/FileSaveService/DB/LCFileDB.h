//
//  LCFileDB.h
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class LCFileM;
@class LCFileTagM;

@interface LCFileDB : NSObject

///MARK: - LCFileM

///MARK: save
+ (BOOL)lc_saveFile:(LCFileM *)fileM;

///MARK: get
+ (LCFileM *)lc_getFileWithMd5:(NSString *)md5;

+ (LCFileM *)lc_getFileWithKey:(NSString *)key;

+ (LCFileM *)lc_getFileWithfilePath:(NSString *)filePath;
///MARK: update

///MARK: delete
+ (BOOL)lc_deleteFileWithMd5:(NSString *)md5;
+ (BOOL)lc_deleteFileWithMd5s:(NSArray *)md5s;
///MARK: - LCFileTagM

///MARK: save
+ (BOOL)lc_saveTag:(LCFileTagM *)tag;

///MARK: get

+ (LCFileTagM *)lc_getTagWithTagId:(NSString *)tagId;

+ (NSArray<LCFileTagM *> *)lc_getTagWithMd5:(NSString *)md5;
+ (NSArray<LCFileTagM *> *)lc_getTagWithTag:(NSString *)tag;
+ (NSArray<LCFileTagM *> *)lc_getTagWithGroup:(NSString *)group;

///MARK: update

///MARK: delete

+ (BOOL)lc_deleteWithTagId:(NSString *)tagId;

+ (BOOL)lc_deleteTag:(nullable NSString *)tag md5:(nullable NSString *)md5 inGroup:(nullable NSString *)group;

+ (BOOL)lc_deleteTagInGroup:(NSString *)group after:(long long)time;

+ (BOOL)lc_deleteTagInGroup:(NSString *)group before:(long long)time;

///MARK: - file+tag

/// 查询没有任何tag 的文件
+ (NSArray<LCFileM *> *)lc_getNoTagFile;

@end

NS_ASSUME_NONNULL_END
