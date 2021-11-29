//
//  LCFileNetProtocol.h
//  S3Demo
//
//  Created by L63 on 2021/9/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class LCFileNetTask;
@protocol LCFileNetProtocol <NSObject>
- (void)lc_fileNetProgress:(LCFileNetTask *)task;
- (void)lc_fileNetStatusChange:(LCFileNetTask *)task;
- (void)lc_fileNetFinshed:(LCFileNetTask *)task error:(NSError *)error;
@end
NS_ASSUME_NONNULL_END
