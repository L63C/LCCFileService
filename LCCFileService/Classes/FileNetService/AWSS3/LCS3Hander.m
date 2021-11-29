//
//  LCS3Hander.m
//  S3Demo
//
//  Created by L63 on 2021/10/8.
//

#import "LCS3Hander.h"

#import "AWSS3.h"
#import "LCFileNetTask.h"
#import "Md5Tools.h"
#import "LCFileTaskDB.h"

static NSString *const BCAWSS3ConfigKey = @"AWSS3ConfigKey";

@interface LCS3Hander ()

/// 缓存任务
/// {key:task.key value:AWSTask}
@property (nonatomic, strong) NSMutableDictionary *taskDic;

@property (nonatomic, strong) AWSS3TransferUtility *utility;
@end

@implementation LCS3Hander
+ (instancetype)default{
    static LCS3Hander *hander = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hander = [[LCS3Hander allocWithZone:nil] init];
    });
    return hander;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self regiseterS3];
        [self awsLog:YES];
    }
    return self;
}

- (void)regiseterS3 {
    
    // way1 静态授权
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:@"AKIAQUYCPI5JQTIKAMHN" secretKey:@"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"];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionAPSoutheast1 credentialsProvider:credentialsProvider];
    
    AWSS3TransferUtilityConfiguration *transferConfig = [[AWSS3TransferUtilityConfiguration alloc] init];
    transferConfig.accelerateModeEnabled = YES;
    transferConfig.bucket = [self bucket];
    transferConfig.retryLimit = 3;
    transferConfig.timeoutIntervalForResource = 7 * 24 * 60 * 60;
    transferConfig.multiPartConcurrencyLimit = @(5);
    
    
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    [AWSS3TransferUtility registerS3TransferUtilityWithConfiguration:configuration transferUtilityConfiguration:transferConfig forKey:BCAWSS3ConfigKey completionHandler:^(NSError * _Nullable error) {
        NSLog(@"s3Hander:config finshed");
        [self loadHistoryAWSTask];
    }];
    [AWSS3PreSignedURLBuilder registerS3PreSignedURLBuilderWithConfiguration:configuration forKey:BCAWSS3ConfigKey];
    [AWSS3 registerS3WithConfiguration:configuration forKey:BCAWSS3ConfigKey];
   
    
}
- (void)awsLog:(BOOL)open{
    if(!open){
        return;
    }
    /// 日志
    [AWSDDLog sharedInstance].logLevel = AWSDDLogLevelVerbose;
    AWSDDFileLogger *fileLogger = [[AWSDDFileLogger alloc] init]; // File Logger
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [AWSDDLog addLogger:fileLogger];
    [AWSDDLog addLogger:[AWSDDTTYLogger sharedInstance]]; // TTY = Xcode console
}
///MARK: - LCFileNetHander


- (void)lc_fileNetHanderUpload:(LCFileNetTask *)task progress:(LCFileNetTaskProgressCallback)progressCallback finish:(LCFileNetTaskFinishCallback)finishCallback{
    NSLog(@"s3Hander:%s,task:%@",__func__,task);
    /// 查看是否已经上传过，然后尝试进行复制
    NSArray<LCFileNetTask *> *sameMd5Tasks = [LCFileTaskDB lc_getTaskByMd5:task.md5];
    __block LCFileNetTask *oldTask = nil;
    [sameMd5Tasks enumerateObjectsUsingBlock:^(LCFileNetTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.status == LCFileNetTaskStatusFinish){
            oldTask = obj;
            *stop = YES;
        }
    }];
    if(oldTask){
        [self p_copyTask:task from:oldTask callback:^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            if(error){
                [self p_startUpload:task progress:progressCallback finish:finishCallback];
            }else{
                if(progressCallback){
                    progressCallback(task);
                }
                if(finishCallback){
                    finishCallback(task,nil);
                }
            }
        }];
    }else{
        [self p_startUpload:task progress:progressCallback finish:finishCallback];
    }
    
}
- (void)lc_fileNetHanderDownload:(LCFileNetTask *)task progress:(LCFileNetTaskProgressCallback)progressCallback finish:(LCFileNetTaskFinishCallback)finishCallback{
    NSLog(@"s3Hander:%s,task:%@",__func__,task);
    /// 查看是否本地已经存在，然后尝试进行复制
    NSArray<LCFileNetTask *> *sameMd5Tasks = [LCFileTaskDB lc_getTaskByFileKey:task.fileKey];
    __block LCFileNetTask *oldTask = nil;
    [sameMd5Tasks enumerateObjectsUsingBlock:^(LCFileNetTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.status == LCFileNetTaskStatusFinish){
            oldTask = obj;
            *stop = YES;
        }
    }];
    if(oldTask){
        [self p_copyTask:task from:oldTask callback:^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            if(error){
                [self p_startDownload:task progress:progressCallback finish:finishCallback];
            }else{
                if(progressCallback){
                    progressCallback(task);
                }
                if(finishCallback){
                    finishCallback(task,nil);
                }
            }
        }];
    }else{
        [self p_startDownload:task progress:progressCallback finish:finishCallback];
    }
    
    
}


- (void)lc_fileNetHanderResumUploadTask:(LCFileNetTask *)task progress:(LCFileNetTaskProgressCallback)progressCallback finish:(LCFileNetTaskFinishCallback)finishCallback{
    NSLog(@"s3Hander:%s,task:%@",__func__,task);
    id awsTask = [self.taskDic objectForKey:task.taskId];
    if(!awsTask) {
        NSLog(@"s3Hander:%s, resume upload not find task:%@",__func__,task);
        if(finishCallback){
            finishCallback(task,[NSError new]);
        }
        return;
    }
    if([awsTask isKindOfClass:AWSS3TransferUtilityUploadTask.class]) {
        AWSS3TransferUtilityUploadTask *uploadTask = awsTask;
        [uploadTask setProgressBlock:^(AWSS3TransferUtilityTask * _Nonnull t, NSProgress * _Nonnull progress) {
            task.finishedSize = MAX(progress.completedUnitCount, task.finishedSize);
            task.totalSize = progress.totalUnitCount;
            NSLog(@"s3Hander:resum upload progress,task:%@",task);
            if(progressCallback){
                progressCallback(task);
            }
        }];
        [uploadTask setCompletionHandler:^(AWSS3TransferUtilityUploadTask * _Nonnull t, NSError * _Nullable error) {
            NSLog(@"s3Hander:finish resume upload task:%@ error:%@",task,error);
            if(finishCallback){
                if(error){
                    finishCallback(task,error);
                }else{
                    [self lc_getURLByFileKey:task.fileKey callback:^(NSString *url, NSError *error) {
                        task.url = url;
                        finishCallback(task,error);
                    }];
                }
            }
        }];
        [uploadTask resume];
        NSLog(@"s3Hander:start resume upload task:%@",task);
    }else if([awsTask isKindOfClass:AWSS3TransferUtilityMultiPartUploadTask.class]){
        AWSS3TransferUtilityMultiPartUploadTask *multipartTask = awsTask;
        [multipartTask setProgressBlock:^(AWSS3TransferUtilityMultiPartUploadTask * _Nonnull t, NSProgress * _Nonnull progress) {
            task.finishedSize = MAX(progress.completedUnitCount, task.finishedSize);
            task.totalSize = progress.totalUnitCount;
            NSLog(@"s3Hander:resum multi part upload progress,task:%@",task);
            if(progressCallback){
                progressCallback(task);
            }
        }];
        [multipartTask setCompletionHandler:^(AWSS3TransferUtilityMultiPartUploadTask * _Nonnull t, NSError * _Nullable error) {
            NSLog(@"s3Hander:finish resume mutli part upload task:%@ error:%@",task,error);
            if(finishCallback){
                if(error){
                    finishCallback(task,error);
                }else{
                    [self lc_getURLByFileKey:task.fileKey callback:^(NSString *url, NSError *error) {
                        task.url = url;
                        finishCallback(task,error);
                    }];
                }
            }
        }];
        [multipartTask resume];
        NSLog(@"s3Hander:start resume multi part upload task:%@",task);
    }else {
        NSLog(@"s3Hander:%s, resume upload not analysis task:%@",__func__,task);
        NSAssert(false, @"unknow aws task");
    }
}
- (void)lc_fileNetHanderResumDownloadTask:(LCFileNetTask *)task progress:(LCFileNetTaskProgressCallback)progressCallback finish:(LCFileNetTaskFinishCallback)finishCallback{
    NSLog(@"s3Hander:%s,task:%@",__func__,task);
    id awsTask = [self.taskDic objectForKey:task.taskId];
    if(!awsTask) {
        NSLog(@"s3Hander:%s, resume download not find task:%@",__func__,task);
        if(finishCallback){
            finishCallback(task,[NSError new]);
        }
        return;
    }
    if([awsTask isKindOfClass:AWSS3TransferUtilityDownloadTask.class]){
        AWSS3TransferUtilityDownloadTask *downloadTask = awsTask;
        [downloadTask setProgressBlock:^(AWSS3TransferUtilityTask * _Nonnull t, NSProgress * _Nonnull progress) {
            task.finishedSize = MAX(progress.completedUnitCount, task.finishedSize);
            task.totalSize = progress.totalUnitCount;
            NSLog(@"s3Hander:resum download progress,task:%@",task);
            if(progressCallback){
                progressCallback(task);
            }
        }];
        [downloadTask setCompletionHandler:^(AWSS3TransferUtilityDownloadTask * _Nonnull t, NSURL * _Nullable location, NSData * _Nullable data, NSError * _Nullable error) {
            NSLog(@"s3Hander:finish resume download task:%@ error:%@",task,error);
            if(finishCallback){
                if(!error){
                    task.md5 = [Md5Tools fileMD5WithPath:task.filePath];
                }
                finishCallback(task,error);
            }
        }];
        [downloadTask resume];
        NSLog(@"s3Hander:start resume download task:%@",task);
    }else {
        NSLog(@"s3Hander:%s, resume download not analysis task:%@",__func__,task);
        NSAssert(false, @"unknow aws task");
    }
}

- (void)lc_fileNetHanderCancelTask:(LCFileNetTask *)task{
    NSLog(@"s3Hander:%s,task:%@",__func__,task);
    id awsTask = [self.taskDic objectForKey:task.taskId];
    if(awsTask){
        AWSS3TransferUtilityTask *tempTask = awsTask;
        [tempTask cancel];
        NSLog(@"s3Hander:start cancel task:%@",task);
    }else{
        NSLog(@"s3Hander:cancel not find task:%@",task);
    }
}

- (void)lc_fileNetHanderPauseTask:(LCFileNetTask *)task{
    NSLog(@"s3Hander:%s,task:%@",__func__,task);
    id cacheTask = [self.taskDic objectForKey:task.taskId];
    if(cacheTask){
        AWSS3TransferUtilityTask *tempTask = cacheTask;
        [tempTask suspend];
        NSLog(@"s3Hander:start suspend task:%@",task);
    }else{
        NSLog(@"s3Hander:suspend not find task:%@",task);
    }
}


- (void)lc_getURLByFileKey:(NSString *)fileKey
                  callback:(void (^)(NSString *url,NSError *error))callback{
    AWSS3GetPreSignedURLRequest *getPreSignedURLRequest = [[AWSS3GetPreSignedURLRequest alloc]init];
    getPreSignedURLRequest.bucket = [self bucket];
    getPreSignedURLRequest.key = fileKey;
    getPreSignedURLRequest.HTTPMethod = AWSHTTPMethodGET;
    getPreSignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:7 * 24 * 60 * 60];
    getPreSignedURLRequest.minimumCredentialsExpirationInterval = 8 * 24 * 60 * 60;
    getPreSignedURLRequest.accelerateModeEnabled = YES;
    [[[AWSS3PreSignedURLBuilder S3PreSignedURLBuilderForKey:BCAWSS3ConfigKey] getPreSignedURL:getPreSignedURLRequest] continueWithBlock:^id _Nullable (AWSTask<NSURL *> *_Nonnull t) {
        if(callback){
            callback(t.result.absoluteString,t.error);
        }
        return nil;
    }];
}
- (void)lc_copyFile:(NSString *)targetKey from:(NSString *)sourceKey callback:(void (^)(NSError *error))callback {
    NSLog(@"s3Hander:%s,targetKey:%@,sourceKey:%@",__func__,targetKey,sourceKey);
    AWSS3ReplicateObjectRequest *  replicate = [AWSS3ReplicateObjectRequest new];
    replicate.bucket = [self bucket];
    sourceKey =  [sourceKey stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    replicate.replicateSource = [NSString stringWithFormat:@"%@/%@",[self bucket],sourceKey];
    replicate.key = targetKey;
    [[[AWSS3 S3ForKey:BCAWSS3ConfigKey] replicateObject:replicate] continueWithBlock:^id _Nullable(AWSTask<AWSS3ReplicateObjectOutput *> * _Nonnull t) {
        NSLog(@"s3Hander:copy finshed,targetKey:%@,sourceKey:%@,error:%@",targetKey,sourceKey,t.error);
        if(callback){
            callback(t.error);
        }
        return nil;
    }];
}



///MARK: - private methods
- (void)loadHistoryAWSTask {
    AWSTask<NSArray<AWSS3TransferUtilityUploadTask *> *> *uploadTask = [self.utility getUploadTasks];
    AWSTask<NSArray<AWSS3TransferUtilityMultiPartUploadTask *> *> *multiPartUploadTask = [self.utility getMultiPartUploadTasks];
    AWSTask<NSArray<AWSS3TransferUtilityDownloadTask *> *> *downloadTask = [self.utility getDownloadTasks];
    
    [uploadTask.result enumerateObjectsUsingBlock:^(AWSS3TransferUtilityUploadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj suspend];
        [self.taskDic setObject:obj forKey:obj.key];
    }];
    [multiPartUploadTask.result enumerateObjectsUsingBlock:^(AWSS3TransferUtilityMultiPartUploadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj suspend];
        [self.taskDic setObject:obj forKey:obj.key];
    }];
    [downloadTask.result enumerateObjectsUsingBlock:^(AWSS3TransferUtilityDownloadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj suspend];
        [self.taskDic setObject:obj forKey:obj.key];
    }];
    NSLog(@"s3Hander:loadHistoryAWSTask finshed");
}


- (void)p_copyTask:(LCFileNetTask *)targetTask from:(LCFileNetTask *)sourceTask callback:(LCFileNetTaskFinishCallback)finishCallback{
    NSLog(@"s3Hander:%s,targetTask:%@ sourceTask:%@",__func__,targetTask,sourceTask);
    void(^perfromCallback)(LCFileNetTask *task,NSError *error) = ^(LCFileNetTask *task,NSError *error) {
        NSLog(@"s3Hander:%s,copy task finshed :%@ error:%@",__func__,targetTask,error);
        if(finishCallback){
            finishCallback(task,error);
        }
    };
    if(targetTask.type == LCFileNetTaskTypeUpload){
        ///  调用s3的文件复制
        [self lc_copyFile:targetTask.fileKey from:sourceTask.fileKey callback:^(NSError *error) {
            if(error){
                perfromCallback(targetTask,error);
            }else{
                [self lc_getURLByFileKey:targetTask.fileKey callback:^(NSString *url, NSError *error) {
                    targetTask.url = url;
                    targetTask.finishedSize = sourceTask.finishedSize;
                    targetTask.totalSize = sourceTask.totalSize;
                    perfromCallback(targetTask,error);
                }];
            }
        }];
    }else if(targetTask.type == LCFileNetTaskTypeDownload){
        /// 进行文件拷贝
        if(sourceTask.filePath && [[NSFileManager defaultManager] fileExistsAtPath:sourceTask.filePath]){
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError *error = nil;
                BOOL ret = [[NSFileManager defaultManager] copyItemAtPath:sourceTask.filePath toPath:targetTask.filePath error:&error];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(ret){
                        targetTask.md5 = [Md5Tools fileMD5WithPath:targetTask.filePath];
                    }
                    targetTask.finishedSize = sourceTask.finishedSize;
                    targetTask.totalSize = sourceTask.totalSize;
                    perfromCallback(targetTask,error);
                });
            });
        }else{
            perfromCallback(targetTask,[NSError errorWithDomain:@"s3.hander" code:999 userInfo:@{NSLocalizedDescriptionKey:@"file is not exist"}]);
        }
       
    }else{
        perfromCallback(targetTask,[NSError errorWithDomain:@"s3.header" code:999 userInfo:@{NSLocalizedDescriptionKey:@"unknown task type"}]);
    }
}
- (void)p_startUpload:(LCFileNetTask *)task
             progress:(LCFileNetTaskProgressCallback)progressCallback
               finish:(LCFileNetTaskFinishCallback)finishCallback{
    NSLog(@"s3Hander:%s,task:%@",__func__,task);
    if(task.fileKey == nil || task.filePath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:task.filePath]){
        if(finishCallback){
            finishCallback(task,[NSError errorWithDomain:@"s3.hander" code:999 userInfo:@{NSLocalizedDescriptionKey:@"fileKey or filePath is nil.or file is not exist"}]);
        }
        return;
    }
    
    NSURL *fileUrl = [NSURL fileURLWithPath:task.filePath];
    if(task.totalSize > 10 * 1000 * 1000) { /// 大于10M使用分片上传，否则使用普通上传
        AWSS3TransferUtilityMultiPartUploadExpression *express = [[AWSS3TransferUtilityMultiPartUploadExpression alloc] init];
        express.progressBlock = ^(AWSS3TransferUtilityMultiPartUploadTask * _Nonnull t, NSProgress * _Nonnull progress) {
            NSLog(@"s3Hander: multi part upload progress,task:%@",task);
            task.finishedSize = MAX(progress.completedUnitCount, task.finishedSize);
            task.totalSize = progress.totalUnitCount;
            if(progressCallback){
                progressCallback(task);
            }
        };
        
        AWSTask<AWSS3TransferUtilityMultiPartUploadTask *> *s3task = [self.utility uploadFileUsingMultiPart:fileUrl key:task.fileKey contentType:@"text/plain" expression:express completionHandler:^(AWSS3TransferUtilityMultiPartUploadTask * _Nonnull t, NSError * _Nullable error) {
            NSLog(@"s3Hander:finish multi part upload task:%@ error:%@",task,error);
            if(finishCallback){
                if(error){
                    finishCallback(task,error);
                }else {
                    [self lc_getURLByFileKey:task.fileKey callback:^(NSString *url, NSError *error) {
                        task.url = url;
                        finishCallback(task,error);
                    }];
                }
            }
            [self.taskDic removeObjectForKey:task.taskId];
        }];
        [s3task continueWithBlock:^id _Nullable(AWSTask<AWSS3TransferUtilityMultiPartUploadTask *> * _Nonnull t) {
            NSLog(@"s3Hander:start multi part upload task:%@ error:%@",task,t.error);
            if(t.error){
                if(finishCallback){
                    finishCallback(task,t.error);
                }
            }else {
                [self.taskDic setObject:t.result forKey:task.taskId];
            }
            NSAssert(t.error == nil, t.error.description);
            return t;
        }];
        
    }else {
        AWSS3TransferUtilityUploadExpression *express = [AWSS3TransferUtilityUploadExpression new];
        express.progressBlock = ^(AWSS3TransferUtilityTask * _Nonnull t, NSProgress * _Nonnull progress) {
            NSLog(@"s3Hander:upload progress,task:%@",task);
            task.finishedSize = MAX(progress.completedUnitCount, task.finishedSize);
            task.totalSize = progress.totalUnitCount;
            if(progressCallback){
                progressCallback(task);
            }
        };
        AWSTask<AWSS3TransferUtilityUploadTask *> *s3task = [self.utility uploadFile:fileUrl key:task.fileKey contentType:@"text/plain" expression:express completionHandler:^(AWSS3TransferUtilityUploadTask * _Nonnull t, NSError * _Nullable error) {
            NSLog(@"s3Hander:finish upload task:%@ error:%@",task,error);
            if(finishCallback){
                if(error){
                    finishCallback(task,error);
                }else {
                    [self lc_getURLByFileKey:task.fileKey callback:^(NSString *url, NSError *error) {
                        task.url = url;
                        finishCallback(task,error);
                    }];
                }
            }
            [self.taskDic removeObjectForKey:task.taskId];
        }];
        [s3task continueWithBlock:^id _Nullable(AWSTask<AWSS3TransferUtilityUploadTask *> * _Nonnull t) {
            NSLog(@"s3Hander:start upload task:%@ error:%@",task,t.error);
            if(t.error){
                if(finishCallback){
                    finishCallback(task,t.error);
                }
            }else {
                [self.taskDic setObject:t.result forKey:task.taskId];
            }
            NSAssert(t.error == nil, t.error.description);
            return nil;
        }];
    }
}

- (void)p_startDownload:(LCFileNetTask *)task
               progress:(LCFileNetTaskProgressCallback)progressCallback
                 finish:(LCFileNetTaskFinishCallback)finishCallback{
    NSLog(@"s3Hander:%s,task:%@",__func__,task);
    if(task.fileKey == nil || task.filePath == nil ){
        if(finishCallback){
            finishCallback(task,[NSError errorWithDomain:@"s3.hander" code:999 userInfo:@{NSLocalizedDescriptionKey:@"fileKey or filePath is nil."}]);
        }
        return;
    }
    [self p_creatDirectoryByFilePath:task.filePath];
    NSURL *fileUrl = [NSURL fileURLWithPath:task.filePath];
    AWSS3TransferUtilityDownloadExpression * express = [AWSS3TransferUtilityDownloadExpression new];
    express.progressBlock = ^(AWSS3TransferUtilityTask * _Nonnull t, NSProgress * _Nonnull progress) {
        task.finishedSize = MAX(progress.completedUnitCount, task.finishedSize);
        task.totalSize = progress.totalUnitCount;
        NSLog(@"s3Hander:download progress,task:%@",task);
        if(progressCallback){
            progressCallback(task);
        }
    };
    AWSTask<AWSS3TransferUtilityDownloadTask *> *s3task = [self.utility downloadToURL:fileUrl key:task.fileKey expression:express completionHandler:^(AWSS3TransferUtilityDownloadTask * _Nonnull t, NSURL * _Nullable location, NSData * _Nullable data, NSError * _Nullable error) {
        NSLog(@"s3Hander:finish download task:%@ error:%@",task,error);
        if(finishCallback){
            if(!error){
                task.md5 = [Md5Tools fileMD5WithPath:task.filePath];
            }
            finishCallback(task,error);
        }
        [self.taskDic removeObjectForKey:task.taskId];
        
    }];
    [s3task continueWithBlock:^id _Nullable(AWSTask * _Nonnull t) {
        NSLog(@"s3Hander:start download task:%@ error:%@",task,t.error);
        if(t.error){
            if(finishCallback){
                finishCallback(task,t.error);
            }
        }else {
            [self.taskDic setObject:t.result forKey:task.taskId];
        }
        
        NSAssert(t.error == nil, t.error.description);
        return t;
    }];
    
}

- (void)p_creatDirectoryByFilePath:(NSString *)filePath {
    NSArray *filePathArr = [filePath componentsSeparatedByString:@"/"];
    NSMutableString *path = [NSMutableString string];
    for (int i = 0; i < filePathArr.count - 1; i++) {
        [path appendString:filePathArr[i]];
        [path appendString:@"/"];
    }
    bool isdirectory = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isdirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}


///MARK: - getter and setter
- (NSMutableDictionary *)taskDic{
    if(!_taskDic){
        _taskDic = [NSMutableDictionary dictionary];
    }
    return _taskDic;
}
- (AWSS3TransferUtility *)utility {
    if(!_utility) {
        _utility = [AWSS3TransferUtility S3TransferUtilityForKey:BCAWSS3ConfigKey];
    }
    return _utility;
}
- (NSString *)bucket {
    return @"lc-test-dev";
}

@end
