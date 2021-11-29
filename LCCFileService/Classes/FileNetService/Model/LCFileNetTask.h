//
//  LCFileNetTask.h
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import <Foundation/Foundation.h>
@class LCFileNetTask;
NS_ASSUME_NONNULL_BEGIN
typedef enum : NSUInteger {
    LCFileNetTaskStatusCreate,//创建
    LCFileNetTaskStatusProgress,// 进行中
    LCFileNetTaskStatusFinish,//完成
    LCFileNetTaskStatusFailed,// 失败
    LCFileNetTaskStatusCanceled,//取消
    LCFileNetTaskStatusPause,//暂停
    LCFileNetTaskStatusInterrupt,// 异常中断
    LCFileNetTaskStatusUnkown,
} LCFileNetTaskStatus;
typedef enum : NSUInteger {
    LCFileNetTaskTypeUnknown,
    LCFileNetTaskTypeUpload,
    LCFileNetTaskTypeDownload,
} LCFileNetTaskType;

typedef void(^LCFileNetTaskProgressCallback)(LCFileNetTask *task);
typedef void(^LCFileNetTaskStatusCallback)(LCFileNetTask *task);
typedef void(^LCFileNetTaskFinishCallback)(LCFileNetTask *task,NSError * __nullable error);


@interface LCFileNetTask : NSObject
@property (nonatomic, strong) NSString *taskId;
@property (nonatomic, strong) NSString *fileKey;
@property (nonatomic, strong) NSString *md5;
@property (nonatomic, assign) LCFileNetTaskType type;
@property (nonatomic, assign) LCFileNetTaskStatus status;
@property (nonatomic, strong, nullable) NSString *way;
@property (nonatomic, assign) int64_t totalSize;
@property (nonatomic, assign) int64_t finishedSize;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *url;

@property (nonatomic, copy) LCFileNetTaskProgressCallback progressCallback;
@property (nonatomic, copy) LCFileNetTaskFinishCallback finishCallback;
@property (nonatomic, copy) LCFileNetTaskStatusCallback statusCallback;


+ (instancetype)lc_uploadTask:(NSString *)taskId
                      fileKey:(NSString *)fileKey
                          md5:(NSString *)md5
                     filePath:(NSString *)filePath;

+ (instancetype)lc_downlaodTask:(NSString *)taskId
                        fileKey:(NSString *)fileKey
                       filePath:(NSString *)filePath
                            url:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
