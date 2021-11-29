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
/// 添加操作器
- (void)addHander:(nonnull id<LCFileNetHander>)hander;

/// 添加观察器
- (void)addObserver:(nonnull id<LCFileNetProtocol>)observer;

/// 开始一个任务
- (void)lc_startTask:(LCFileNetTask *)task
               queue:(nullable NSOperationQueue *)queue;

/// 恢复任务
- (void)lc_resumTask:(NSString *)taskId
               queue:(nullable NSOperationQueue *)queue;

/// 取消任务
- (void)lc_cancelTask:(NSString *)taskId;

/// 暂停任务
- (void)lc_pauseTask:(NSString *)taskId ;

/// 暂停所有任务
- (void)lc_pauseAllTask;

/// 更新本地数据库的文件保存路径
- (void)lc_updatetask:(NSString *)key
             filePath:(NSString *)filePath;

///获取一个任务的信息，
- (LCFileNetTask *)lc_getTask:(NSString *)taskId;

@end

NS_ASSUME_NONNULL_END
