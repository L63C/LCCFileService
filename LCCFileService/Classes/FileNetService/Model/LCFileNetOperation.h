//
//  LCFileNetOperation.h
//  S3Demo
//
//  Created by L63 on 2021/10/28.
//

#import <Foundation/Foundation.h>
@class LCFileNetTask;
@class LCFileNetOperation;
@protocol LCFileNetHander;
NS_ASSUME_NONNULL_BEGIN
@protocol LCFileNetOperationObserver <NSObject>
- (void)lc_netOperationStart:(LCFileNetTask *)task;
- (void)lc_netOperationProgressUpdate:(LCFileNetTask *)task;
- (void)lc_netOperationStatusUpadte:(LCFileNetTask *)task;
- (void)lc_netOperationStatusFinish:(LCFileNetTask *)task error:(NSError *)error;
@end
@interface LCFileNetOperation : NSOperation
@property (nonatomic, strong,readonly) LCFileNetTask *task;
@property (nonatomic, weak) id<LCFileNetOperationObserver> observer;

- (instancetype)initWithTask:(LCFileNetTask *)task
                      hander:(id<LCFileNetHander>)hander
                    observer:(id<LCFileNetOperationObserver>)observer;

- (void)pause;


@end

NS_ASSUME_NONNULL_END
