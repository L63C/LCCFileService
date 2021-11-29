//
//  LCFileSaveService.h
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import <Foundation/Foundation.h>

@class LCFileM;

NS_ASSUME_NONNULL_BEGIN


/// 文件服务
/// 让文件只在手机中保存一份
/// 主要思想是给文件增加一个tag 当一个文件的tag 数量为0 时，文件将会被删除
/// 同时给tag 增加了，group 和 time 字段可以对tag 进行批量操作
@interface LCFileSaveService : NSObject

///MARK: - save

/// 保存一个文件进入文件系统中
/// @param sourcePath 原文件的路径
/// @param key 文件的key ,方便业务可以通过这个key 知道对应的file
/// @param tag 给文件增加的key
/// @param group 对tag 进行分组
/// @param time tag 时间
/// @param deleteSource 复制进入文件系统后，是否删除原本资源
- (LCFileM *)lc_saveFileFrom:(NSString *)sourcePath
                         key:(nullable NSString *)key
                         tag:(NSString *)tag
                       group:(NSString *)group
                        time:(long long)time
                deleteSource:(BOOL)deleteSource;

///MARK: - get

- (LCFileM *)lc_getFileWithMd5:(NSString *)md5;
- (LCFileM *)lc_getFileWithKey:(NSString *)key;

- (LCFileM *)lc_getFileWithFilePath:(NSString *)filePath;

///MARK: - delete

- (BOOL)lc_deleteFileWithMd5:(NSString *)md5 tag:(NSString *)tag group:(NSString *)group;

- (BOOL)lc_deleteFileWithKey:(NSString *)key tag:(NSString *)tag group:(NSString *)group;

- (BOOL)lc_deleteFileWithFilePath:(NSString *)filePath tag:(NSString *)tag group:(NSString *)group;

- (BOOL)lc_deleteFileInGroup:(NSString *)group after:(long long)time;

- (BOOL)lc_deleteFileInGroup:(NSString *)group before:(long long)time;
@end

NS_ASSUME_NONNULL_END
