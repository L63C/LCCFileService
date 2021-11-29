//
//  LCFileNetService.m
//  S3Demo
//
//  Created by L63 on 2021/9/30.
//

#import "LCFileNetService.h"
#import "LCFileNetHander.h"
#import "LCFileNetProtocol.h"
#import "ProtocolFinder.h"
#import "LCFileTaskDB.h"
#import "LCFileNetOperation.h"
#import "Md5Tools.h"

@interface LCFileNetService()<LCFileNetOperationObserver>
{
    dispatch_semaphore_t _uploadSem;
    dispatch_semaphore_t _downloadSem;
}
@property (nonatomic, weak) id<LCFileNetHander> hander;
@property (nonatomic, weak) id<LCFileNetProtocol> observer;
@property (nonatomic, strong) NSMutableDictionary *cache;

@property (nonatomic, strong) NSMutableDictionary *taskOperationDic;


@property (nonatomic, strong) NSOperationQueue *uploadQueue;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;

@property (nonatomic, strong) NSMutableDictionary *progressCallbackCache;
@property (nonatomic, strong) NSMutableDictionary *finishCallbackCache;
@property (nonatomic, strong) NSMutableDictionary *statusCallbackCache;


@end
@implementation LCFileNetService

+ (instancetype)default{
    static LCFileNetService *service = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[super allocWithZone:nil] init];
    });
    return service;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _uploadSem = dispatch_semaphore_create(0);
        _downloadSem = dispatch_semaphore_create(0);
    }
    return self;
}
- (void)addHander:(id<LCFileNetHander>)hander {
    self.hander = hander;
}
- (void)addObserver:(id<LCFileNetProtocol>)observer {
    self.observer = observer;
}
- (void)lc_startTask:(LCFileNetTask *)task
          queue:(NSOperationQueue *)queue{
    NSLog(@"file service: %s task:%@ ",__func__,task);
    [self p_saveCallback:task];
    if(![self p_checkTask:task]){
        [self p_notifyFinish:task error:[NSError errorWithDomain:@"file.service" code:9999 userInfo:@{NSLocalizedDescriptionKey:@"task error"}]];
        return;
    }
    // 检查是否在当前任务队列
    LCFileNetTask *oldTask = [self p_getTaskFromCacheByKey:task.taskId];
    if(oldTask){
        NSLog(@"file service: this task had exist task:%@ ",oldTask);
        if(oldTask.status == LCFileNetTaskStatusFinish){
            NSLog(@"file service: this task had been finish task:%@ ",oldTask);
            [self p_notifyFinish:oldTask error:nil];
        }else if (oldTask.status == LCFileNetTaskStatusPause
                  || oldTask.status == LCFileNetTaskStatusFailed
                  || oldTask.status == LCFileNetTaskStatusInterrupt){
            NSLog(@"file service: a pause task had been added. task:%@ ",oldTask);
            [self p_addTask:oldTask queue:queue];
        }
        return;
    }
    // 检查数据库
    LCFileNetTask *dbTask = [LCFileTaskDB lc_getTaskByTaskId:task.taskId];
    if(dbTask){
        NSLog(@"file service: I will add dbtask to queue task:%@ ",dbTask);
        [self p_setTask:dbTask key:dbTask.taskId];
        if(dbTask.status == LCFileNetTaskStatusFinish){
            NSLog(@"file service: this task had been finish task:%@ ",dbTask);
            [self p_notifyFinish:dbTask error:nil];
        }else if(dbTask.status == LCFileNetTaskStatusProgress
                 || dbTask.status == LCFileNetTaskStatusCreate){
            dbTask.status = LCFileNetTaskStatusInterrupt;
            [self p_addTask:dbTask queue:queue];
        }else{
            [self p_addTask:dbTask queue:queue];
        }
        
    }else {
        // 一个新任务
        NSLog(@"file service: I add a new task to queue task:%@ ",task);
        [self p_setTask:task key:task.taskId];
        [LCFileTaskDB lc_saveTask:task];
        [self p_addTask:task queue:queue];
    }
}
- (void)p_addTask:(LCFileNetTask *)task
              queue:(NSOperationQueue *)queue{
    NSLog(@"file service: %s task:%@ ",__func__,task);
    if(task.type == LCFileNetTaskTypeUpload){
        LCFileNetOperation *netOperation = [[LCFileNetOperation alloc] initWithTask:task hander:self.hander observer:self];
        [self.taskOperationDic setObject:netOperation forKey:task.taskId];
        [queue ?: self.uploadQueue addOperation:netOperation];
    }else if (task.type == LCFileNetTaskTypeDownload) {
        LCFileNetOperation *netOperation = [[LCFileNetOperation alloc] initWithTask:task hander:self.hander observer:self];
        [self.taskOperationDic setObject:netOperation forKey:task.taskId];
        [queue ?: self.downloadQueue addOperation:netOperation];
    }
}

- (void)lc_resumTask:(NSString *)taskId
            queue:(NSOperationQueue *)queue{
    NSLog(@"file service: %s task:%@ ",__func__,taskId);
    LCFileNetTask *task = [self p_getTaskFromCacheByKey:taskId];
    if(!task){
        task = [LCFileTaskDB lc_getTaskByTaskId:task.taskId];
    }
    if(task){
        if(task.status != LCFileNetTaskStatusFinish){
            NSLog(@"file service: start resum task:%@ ",task);
            [self lc_startTask:task queue:queue];
        }else{
            NSLog(@"file service: resum task had finished :%@ ",task);
        }
    }else{
        NSLog(@"file service: resum this task not find task:%@ ",task);
    }
    
}


- (void)lc_cancelTask:(NSString *)taskId {
    LCFileNetTask *cacheTask = [self p_getTaskFromCacheByKey:taskId];
    if(!cacheTask){
        return;
    }
    NSLog(@"file service: %s task:%@ ",__func__,cacheTask);
    if(cacheTask.status == LCFileNetTaskStatusFinish){
        return;
    }
    /// 移除队列中的任务
    LCFileNetOperation *operaton = [self.taskOperationDic objectForKey:taskId];
    [operaton cancel];
    [self.taskOperationDic removeObjectForKey:taskId];
    
    /// 删除数据库
    [LCFileTaskDB lc_deleteTaskByTaskId:taskId];
    
    // 通知外部
    cacheTask.status = LCFileNetTaskStatusCanceled;
    [self p_notifyStatusChange:cacheTask];
    
    NSError *error = [NSError errorWithDomain:@"file.net.server" code:999 userInfo:@{NSLocalizedDescriptionKey:@"task had been canceled"}];
    [self p_notifyFinish:cacheTask error:error];
    
    [self.cache removeObjectForKey:taskId];
}

- (void)lc_pauseTask:(NSString *)taskId {
    LCFileNetTask *cacheTask = [self p_getTaskFromCacheByKey:taskId];
    if(!cacheTask){
        return;
    }
    NSLog(@"file service: %s task:%@ ",__func__,cacheTask);
    if(cacheTask.status == LCFileNetTaskStatusFinish){
        return;
    }
    /// 移除队列中的任务
    LCFileNetOperation *operaton = [self.taskOperationDic objectForKey:taskId];
    [operaton pause];
    
    // 通知外部
    cacheTask.status = LCFileNetTaskStatusPause;
    [self p_notifyStatusChange:cacheTask];
}

- (void)lc_pauseAllTask {
    NSLog(@"file service: %s ",__func__);
    for (NSString *taskId in self.taskOperationDic.allKeys) {
        [self lc_pauseTask:taskId];
    }
}

- (void)lc_updatetask:(NSString *)key
             filePath:(NSString *)filePath {
    [LCFileTaskDB lc_updateTask:key filePath:filePath];
}
- (LCFileNetTask *)lc_getTask:(NSString *)taskId{
    LCFileNetTask *task = [self p_getTaskFromCacheByKey:taskId];
    if(!task){
        task = [LCFileTaskDB lc_getTaskByTaskId:taskId];
        if(task){
            if(task.status == LCFileNetTaskStatusCreate
               || task.status == LCFileNetTaskStatusProgress){
                task.status = LCFileNetTaskStatusInterrupt;
            }
            [self p_setTask:task key:task.taskId];
        }
        
    }
    return task;
}

///MARK: - LCFileNetOperationObserver


- (void)lc_netOperationStart:(nonnull LCFileNetTask *)task {
    NSLog(@"file service: %s task:%@ ",__func__,task);
    task.status = LCFileNetTaskStatusProgress;
    [LCFileTaskDB lc_updateTask:task.taskId status:LCFileNetTaskStatusProgress];
    [self p_notifyStatusChange:task];
}

- (void)lc_netOperationStatusFinish:(nonnull LCFileNetTask *)task error:(nonnull NSError *)error {
    NSLog(@"file service: %s task:%@ ",__func__,task);
    if(error){
        task.status = LCFileNetTaskStatusFailed;
    }
    [LCFileTaskDB lc_saveTask:task];
    [self p_notifyFinish:task error:error];
}
- (void)lc_netOperationProgressUpdate:(nonnull LCFileNetTask *)task {
    NSLog(@"file service: %s task:%@ ",__func__,task);
    [LCFileTaskDB lc_updateTask:task.taskId finishedSize:task.finishedSize totalSize:task.totalSize];
    [self p_notifyProgress:task];
}
- (void)lc_netOperationStatusUpadte:(nonnull LCFileNetTask *)task {
    NSLog(@"file service: %s task:%@ ",__func__,task);
    [LCFileTaskDB lc_updateTask:task.taskId status:task.status];
    [self p_notifyStatusChange:task];
}


///MARK: - private methods

- (BOOL)p_checkTask:(LCFileNetTask *)task{
    if(task.type == LCFileNetTaskTypeUnknown || !task.taskId){
        NSAssert(false, @"unknown task");
        return NO;
    }
    if(task.type == LCFileNetTaskTypeUpload){
        if(!task.filePath || ![[NSFileManager defaultManager] fileExistsAtPath:task.filePath]){
            NSLog(@"file service: file not exist task:%@ ",task);
            return NO;
        }
        if(!task.md5){
            task.md5 = [Md5Tools fileMD5WithPath:task.filePath];
        }
    }
    return YES;
}
/// MARK:  通知外部
- (void)notifyInMainThread:(void (^)(void))callback {
    if(NSThread.isMainThread){
        callback();
    }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
            callback();
        });
    }
}
- (void)p_notifyProgress:(LCFileNetTask *)task {
    NSLog(@"file service: %s task:%@ ",__func__,task);
    [self notifyInMainThread:^{
        if(task.status != LCFileNetTaskStatusProgress || task.totalSize == 0 || task.finishedSize == 0){
            return;
        }
        if(self.observer && [self.observer respondsToSelector:@selector(lc_fileNetProgress:)]){
            [self.observer lc_fileNetProgress:task];
        }
        [[ProtocolFinder defaultFinder] execute:@protocol(LCFileNetProtocol) selector:@selector(lc_fileNetProgress:) run:^(id  _Nonnull obj) {
            [obj lc_fileNetProgress:task];
        }];
        [self p_executeProgressCallbackTask:task];
    }];
    
}

- (void)p_notifyStatusChange:(LCFileNetTask *)task {
    NSLog(@"file service: %s task:%@ ",__func__,task);
    [self notifyInMainThread:^{
        if(self.observer && [self.observer respondsToSelector:@selector(lc_fileNetStatusChange:)]){
            [self.observer lc_fileNetStatusChange:task];
        }
        [[ProtocolFinder defaultFinder] execute:@protocol(LCFileNetProtocol) selector:@selector(lc_fileNetStatusChange:) run:^(id  _Nonnull obj) {
            [obj lc_fileNetStatusChange:task];
        }];
        [self p_executeStatusTaskCallback:task];
    }];
   
}
- (void)p_notifyFinish:(LCFileNetTask *)task error:(NSError *)error {
    NSLog(@"file service: %s task:%@ error:%@",__func__,task,error);
    [self notifyInMainThread:^{
        if(self.observer && [self.observer respondsToSelector:@selector(lc_fileNetFinshed:error:)]){
            [self.observer lc_fileNetFinshed:task error:error];
        }
        [[ProtocolFinder defaultFinder] execute:@protocol(LCFileNetProtocol) selector:@selector(lc_fileNetFinshed:error:) run:^(id  _Nonnull obj) {
            [obj lc_fileNetFinshed:task error:error];
        }];
        [self p_executeFinishTaskCallback:task error:error];
    }];
   
}

///MARK: callback 相关操作
- (void)p_saveCallback:(LCFileNetTask *)task{
    {// 保存progressCallback
        NSMutableArray *cache = [self.progressCallbackCache objectForKey:task.taskId];
        if(!cache) {
            cache = [NSMutableArray array];
        }
        if(task.progressCallback && ![cache containsObject:task.progressCallback]){
            [cache addObject:task.progressCallback];
        }
        [self.progressCallbackCache setObject:cache forKey:task.taskId];
    }
    { /// 保存statusCallback
        NSMutableArray *cache = [self.statusCallbackCache objectForKey:task.taskId];
        if(!cache) {
            cache = [NSMutableArray array];
        }
        if(task.statusCallback  && ![cache containsObject:task.statusCallback]) {
            [cache addObject:task.statusCallback];
        }
        [self.statusCallbackCache setObject:cache forKey:task.taskId];
    }
    {/// 保存finishCallback
        NSMutableArray *cache = [self.finishCallbackCache objectForKey:task.taskId];
        if(!cache) {
            cache = [NSMutableArray array];
        }
        if(task.finishCallback && ![cache containsObject:task.finishCallback]){
            [cache addObject:task.finishCallback];
        }
        [self.finishCallbackCache setObject:cache forKey:task.taskId];
    }
    
    
    
}
- (void)p_executeProgressCallbackTask:(LCFileNetTask *)task{
    NSArray<LCFileNetTaskProgressCallback> *progressCallback = [self.progressCallbackCache objectForKey:task.taskId];
    [progressCallback enumerateObjectsUsingBlock:^(LCFileNetTaskProgressCallback  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj(task);
    }];
}

- (void)p_executeStatusTaskCallback:(LCFileNetTask *)task{
    NSArray<LCFileNetTaskProgressCallback> *statusCallback = [self.statusCallbackCache objectForKey:task.taskId];
    [statusCallback enumerateObjectsUsingBlock:^(LCFileNetTaskProgressCallback  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj(task);
    }];
}

 
- (void)p_executeFinishTaskCallback:(LCFileNetTask *)task error:(NSError *)error{
    NSArray<LCFileNetTaskFinishCallback> *finishCallback = [self.finishCallbackCache objectForKey:task.taskId];
    [finishCallback enumerateObjectsUsingBlock:^(LCFileNetTaskFinishCallback  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj(task,error);
    }];
    /// 移除cache progress and finish callback
    [self.progressCallbackCache removeObjectForKey:task.taskId];
    [self.statusCallbackCache removeObjectForKey:task.taskId];
    [self.finishCallbackCache removeObjectForKey:task.taskId];
    
}
///MARK: - setter and get
- (NSOperationQueue *)uploadQueue{
    if(!_uploadQueue){
        _uploadQueue = [[NSOperationQueue alloc] init];
        _uploadQueue.maxConcurrentOperationCount = 1;
    }
    return _uploadQueue;
}

- (NSOperationQueue *)downloadQueue {
    if(!_downloadQueue){
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.maxConcurrentOperationCount = 1;
    }
    return _downloadQueue;
}
- (NSMutableDictionary *)taskOperationDic{
    if(!_taskOperationDic){
        _taskOperationDic = [NSMutableDictionary dictionary];
    }
    return _taskOperationDic;
}

- (NSMutableDictionary *)progressCallbackCache{
    if(!_progressCallbackCache){
        _progressCallbackCache = [NSMutableDictionary dictionary];
    }
    return _progressCallbackCache;
}

- (NSMutableDictionary *)finishCallbackCache {
    if(!_finishCallbackCache){
        _finishCallbackCache = [NSMutableDictionary dictionary];
    }
    return _finishCallbackCache;
}
- (NSMutableDictionary *)statusCallbackCache{
    if(!_statusCallbackCache){
        _statusCallbackCache = [NSMutableDictionary dictionary];
    }
    return _statusCallbackCache;
}

#pragma mark - Cache
static dispatch_queue_t task_cache_queue()
{
    static dispatch_queue_t task_cache_queue_t;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        task_cache_queue_t = dispatch_queue_create("taskCache", DISPATCH_QUEUE_CONCURRENT);
    });
    return task_cache_queue_t;
}

- (NSMutableDictionary *)cache{
    if(!_cache){
        _cache = [NSMutableDictionary dictionary];
    }
    return _cache;
}
- (LCFileNetTask *)p_getTaskFromCacheByKey:(NSString *)key {
    __block LCFileNetTask *task = nil;
    dispatch_sync(task_cache_queue(), ^{
        task = [self.cache objectForKey:key];
    });
    return task;
}

- (void)p_setTask:(LCFileNetTask *)task key:(NSString *)key {
    dispatch_barrier_sync(task_cache_queue(), ^{
        if (key) {
            [self.cache setValue:task forKey:key];
        }
    });
}

@end
