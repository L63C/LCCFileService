//
//  LCFileM.h
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCFileM : NSObject
/// 文件的唯一标识
@property (nonatomic, strong) NSString *key;
/// 文件的md5
@property (nonatomic, strong) NSString *md5;
/// 文件的保存路径
@property (nonatomic, strong) NSString *filePath;
@end


NS_ASSUME_NONNULL_END
