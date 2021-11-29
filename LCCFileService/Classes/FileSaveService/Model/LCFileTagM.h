//
//  LCFileTagM.h
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCFileTagM : NSObject

@property (nonatomic, strong) NSString *tagId;
@property (nonatomic, strong) NSString *md5;
@property (nonatomic, strong) NSString *tag;
@property (nonatomic, strong) NSString *group;
@property (nonatomic, assign) long long time;
@end

NS_ASSUME_NONNULL_END
