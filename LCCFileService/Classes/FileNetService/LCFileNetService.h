//
//  LCFileNetService.h
//  S3Demo
//
//  Created by L63 on 2021/9/30.
//

#import <Foundation/Foundation.h>
#import "LCFileNetTask.h"

NS_ASSUME_NONNULL_BEGIN
@protocol LCFileNetHander;
@protocol LCFileNetProtocol;
@interface LCFileNetService : NSObject
+ (instancetype)default;

- (void)addHander:(nonnull id<LCFileNetHander>)hander;

- (void)addObserver:(nonnull id<LCFileNetProtocol>)observer;

- (void)lc_startTask:(LCFileNetTask *)task
               queue:(nullable NSOperationQueue *)queue;

- (void)lc_resumTask:(NSString *)taskId
               queue:(nullable NSOperationQueue *)queue;

- (void)lc_cancelTask:(NSString *)taskId;

- (void)lc_pauseTask:(NSString *)taskId ;

- (void)lc_pauseAllTask;

- (void)lc_updatetask:(NSString *)key
             filePath:(NSString *)filePath;

- (LCFileNetTask *)lc_getTask:(NSString *)taskId;

@end

NS_ASSUME_NONNULL_END
