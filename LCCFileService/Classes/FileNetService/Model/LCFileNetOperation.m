//
//  LCFileNetOperation.m
//  S3Demo
//
//  Created by L63 on 2021/10/28.
//

#import "LCFileNetOperation.h"
#import "LCFileNetTask.h"
#import "LCFileNetHander.h"

@interface LCFileNetOperation()

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;

@property (nonatomic, strong) LCFileNetTask *task;
@property (nonatomic, weak) id<LCFileNetHander> hander;
@end
@implementation LCFileNetOperation
@synthesize executing = _executing;
@synthesize finished = _finished;
- (void)dealloc{
    NSLog(@"taskOperation: %s,task:%@",__func__,_task);
}
-(instancetype)initWithTask:(LCFileNetTask *)task
                     hander:(nonnull id<LCFileNetHander>)hander
                   observer:(nonnull id<LCFileNetOperationObserver>)observer{
    self = [super init];
    if(self){
        NSAssert(hander, @"NO hander ,please add a hender");
        self.task = task;
        self.hander = hander;
        self.observer = observer;
    }
    return self;
}

- (void)start {
    NSLog(@"taskOperation: %s,task:%@",__func__,_task);
    //第一步就要检测是否被取消了，如果取消了，要实现相应的KVO
    if ([self isCancelled]) {
        self.finished = YES;
        return;
    }
    self.executing = YES;
    [self main];
}
- (void)cancel {
    NSLog(@"taskOperation: %s,task:%@",__func__,_task);
    if(!self.isFinished || !self.isCancelled){
        if(self.hander && [self.hander respondsToSelector:@selector(lc_fileNetHanderCancelTask:)]){
            [self.hander lc_fileNetHanderCancelTask:self.task];
        }
        [self p_notifyStatusUpadteWithNewStatus:LCFileNetTaskStatusCanceled];
       
    }
   
    [super cancel];
    [self p_finishOperatioin];
}

- (void)pause {
    NSLog(@"taskOperation: %s,task:%@",__func__,_task);
    if(!self.isFinished || !self.isCancelled){
        if(self.hander && [self.hander respondsToSelector:@selector(lc_fileNetHanderCancelTask:)]){
            [self.hander lc_fileNetHanderPauseTask:_task];
        }
        [self p_notifyStatusUpadteWithNewStatus:LCFileNetTaskStatusPause];
    }
    
    [super cancel];
    [self p_finishOperatioin];
}


- (void)main {
    NSLog(@"taskOperation: %s,task:%@",__func__,_task);
    /// 开始执行自己的任务
    if(self.task.type == LCFileNetTaskTypeUpload) {
        if(self.task.status == LCFileNetTaskStatusPause
           || self.task.status == LCFileNetTaskStatusFailed
           || self.task.status == LCFileNetTaskStatusInterrupt){
            /// 恢复上传
            [self p_resumUpload];
        }else {
            /// 重新上传
            [self p_startUpload];
        }
    }else if(self.task.type == LCFileNetTaskTypeDownload) {
        if(self.task.status == LCFileNetTaskStatusPause
           || self.task.status == LCFileNetTaskStatusFailed
           || self.task.status == LCFileNetTaskStatusInterrupt){
            /// 恢复下载
            [self p_resumDownLoad];
        }else {
            /// 重新下载
            [self p_startDownload];
        }
        
    }
    [self p_notifyStart];
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isAsynchronous{
    return YES;
}

///MARK: - private methods
- (void)p_finishOperatioin{
    self.executing = NO;
    self.finished = YES;
}
- (void)p_startUpload{
    NSLog(@"taskOperation:%s,task:%@",__func__,_task);
    if(self.hander && [self.hander respondsToSelector:@selector(lc_fileNetHanderUpload:progress:finish:)]){
        [self.hander lc_fileNetHanderUpload:self.task progress:^(LCFileNetTask * _Nonnull task) {
            [self p_notifyProgressUpdateWithFinishedSize:task.finishedSize totalSize:task.finishedSize];
            if(self.isCancelled){
                [self p_finishOperatioin];
            }
        } finish:^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            [self p_notifyStatusUpadteWithNewStatus:error ? LCFileNetTaskStatusFailed : LCFileNetTaskStatusFinish];
            [self p_notifyFinishWithError:error];
            [self p_finishOperatioin];
        }];
    }else{
        [self p_finishOperatioin];
    }
}
- (void)p_startDownload {
    NSLog(@"taskOperation:%s,task:%@",__func__,_task);
    if(self.hander && [self.hander respondsToSelector:@selector(lc_fileNetHanderDownload:progress:finish:)]){
        [self.hander lc_fileNetHanderDownload:self.task progress:^(LCFileNetTask * _Nonnull task) {
            [self p_notifyProgressUpdateWithFinishedSize:task.finishedSize totalSize:task.finishedSize];
            if(self.isCancelled){
                [self p_finishOperatioin];
            }
        } finish:^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            [self p_notifyStatusUpadteWithNewStatus:error ? LCFileNetTaskStatusFailed : LCFileNetTaskStatusFinish];
            [self p_notifyFinishWithError:error];
            [self p_finishOperatioin];
        }];
    }else{
        [self p_finishOperatioin];
    }
}
- (void)p_resumUpload {
    NSLog(@"taskOperation:%s,task:%@",__func__,_task);
    if(self.hander && [self.hander respondsToSelector:@selector(lc_fileNetHanderResumUploadTask:progress:finish:)]){
        [self.hander lc_fileNetHanderResumUploadTask:self.task progress:^(LCFileNetTask * _Nonnull task) {
            [self p_notifyProgressUpdateWithFinishedSize:task.finishedSize totalSize:task.finishedSize];
            if(self.isCancelled){
                [self p_finishOperatioin];
            }
        } finish:^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            if(error){
                /// 恢复失败就重新上传
                [self p_startUpload];
            }else{
                [self p_notifyStatusUpadteWithNewStatus:LCFileNetTaskStatusFinish];
                [self p_notifyFinishWithError:error];
                [self p_finishOperatioin];
            }
        }];
    }
}
- (void)p_resumDownLoad {
    NSLog(@"taskOperation:%s,task:%@",__func__,_task);
    if(self.hander && [self.hander respondsToSelector:@selector(lc_fileNetHanderResumDownloadTask:progress:finish:)]){
        [self.hander lc_fileNetHanderResumDownloadTask:self.task progress:^(LCFileNetTask * _Nonnull task) {
            [self p_notifyProgressUpdateWithFinishedSize:task.finishedSize totalSize:task.finishedSize];
            if(self.isCancelled){
                [self p_finishOperatioin];
            }
        } finish:^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            if(error){
                /// 恢复失败就重新下载
                [self p_startDownload];
            }else{
                [self p_notifyStatusUpadteWithNewStatus:LCFileNetTaskStatusFinish];
                [self p_notifyFinishWithError:error];
                [self p_finishOperatioin];
            }
        }];
    }
}

///MARK: notify
- (void)p_notifyStart{
    NSLog(@"taskOperation: %s,task:%@",__func__,_task);
    if(self.observer && [self.observer respondsToSelector:@selector(lc_netOperationStart:)]){
        [self.observer lc_netOperationStart:self.task];
    }
}
- (void)p_notifyProgressUpdateWithFinishedSize:(int64_t)finishedSize totalSize:(int64_t)totalSize {
    NSLog(@"taskOperation: %s,task:%@",__func__,_task);
    if(self.observer && [self.observer respondsToSelector:@selector(lc_netOperationProgressUpdate:)]){
        [self.observer lc_netOperationProgressUpdate:self.task];
    }
}
- (void)p_notifyStatusUpadteWithNewStatus:(LCFileNetTaskStatus)status{
    self.task.status = status;
    NSLog(@"taskOperation: %s,task:%@",__func__,_task);
    if(self.observer && [self.observer respondsToSelector:@selector(lc_netOperationStatusUpadte:)]){
        [self.observer lc_netOperationStatusUpadte:self.task];
    }
}
- (void)p_notifyFinishWithError:(NSError *)error{
    NSLog(@"taskOperation: %s,task:%@",__func__,_task);
    if(self.observer && [self.observer respondsToSelector:@selector(lc_netOperationStatusFinish:error:)]){
        [self.observer lc_netOperationStatusFinish:self.task error:error];
    }
}
@end
