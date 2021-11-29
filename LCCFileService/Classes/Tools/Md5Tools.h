//
//  Md5Tools.h
//  S3Demo
//
//  Created by L63 on 2021/9/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Md5Tools : NSObject
+ (NSString *)fileMD5WithData:(NSData *)data;
+ (NSString *)fileMD5WithPath:(NSString *)path;
+ (NSString *)getFileMD5WithPath:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
