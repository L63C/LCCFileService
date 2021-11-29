//
//  LCFileNetTask.m
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import "LCFileNetTask.h"

@implementation LCFileNetTask
- (BOOL)isEqual:(id)object {
    if([object isKindOfClass:LCFileNetTask.class]){
        LCFileNetTask *task = object;
        if(task.taskId == self.taskId){
            if(task.type == LCFileNetTaskTypeUpload && [task.md5 isEqualToString:self.md5]){
                return YES;
            }else if (task.type == LCFileNetTaskTypeDownload && [task.url isEqualToString:self.url]){
                return YES;
            }else{
                return [super isEqual:object];
            }
        }else {
            return [super isEqual:object];
        }
    }else {
        return [super isEqual:object];
    }
}
-(NSUInteger)hash{
    if(_type == LCFileNetTaskTypeUpload){
        return [NSString stringWithFormat:@"%@%@",_taskId,_md5].hash;
    }else if(_type ==LCFileNetTaskTypeDownload){
        return [NSString stringWithFormat:@"%@%@",_taskId,_url].hash;
    }else{
        return [super hash];
    }
}

+ (instancetype)lc_uploadTask:(NSString *)taskId
                      fileKey:(NSString *)fileKey
                          md5:(NSString *)md5
                     filePath:(NSString *)filePath {
    LCFileNetTask *task = [[LCFileNetTask alloc] init];
    task.taskId = taskId;
    task.fileKey = fileKey;
    task.type = LCFileNetTaskTypeUpload;
    task.filePath = filePath;
    return task;
}
+ (instancetype)lc_downlaodTask:(NSString *)taskId
                        fileKey:(NSString *)fileKey
                       filePath:(NSString *)filePath
                            url:(NSString *)url{
    LCFileNetTask *task = [[LCFileNetTask alloc] init];
    task.taskId = taskId;
    task.fileKey = fileKey;
    task.filePath = filePath;
    task.url = url;
    return task;
}
- (NSString *)description{
    NSString *type = nil;
    switch (self.type) {
        case LCFileNetTaskTypeUpload:
            type = @"LCFileNetTaskTypeUpload";
            break;
        case LCFileNetTaskTypeDownload:
            type = @"LCFileNetTaskTypeDownload";
            break;
        case LCFileNetTaskTypeUnknown:
            type = @"LCFileNetTaskTypeUnknown";
            break;
    }
    NSString *status = nil;
    switch (self.status) {
        case LCFileNetTaskStatusCreate:
            status = @"LCFileNetTaskStatusCreate";
            break;
        case LCFileNetTaskStatusProgress:
            status = @"LCFileNetTaskStatusProgress";
            break;
        case LCFileNetTaskStatusFinish:
            status = @"LCFileNetTaskStatusFinish";
            break;
        case LCFileNetTaskStatusFailed:
            status = @"LCFileNetTaskStatusFailed";
            break;
        case LCFileNetTaskStatusCanceled:
            status = @"LCFileNetTaskStatusCanceled";
            break;
        case LCFileNetTaskStatusPause:
            status = @"LCFileNetTaskStatusPause";
            break;
        case LCFileNetTaskStatusUnkown:
            status = @"LCFileNetTaskStatusUnkown";
            break;
            
    }
    return [NSString stringWithFormat:@"task taskId:%@ fileKey:%@ type:%@ status:%@ finishedSize:%lld totalSiz:%lld md5:%@ url:%@ filePath:%@ fileName:%@",
            self.taskId,
            self.fileKey,
            type,
            status,
            self.finishedSize,
            self.totalSize,
            self.md5,
            self.url,
            self.filePath,
            self.fileName];
//    return [NSString stringWithFormat:@"task key:   %@\n type:%@\n status:  %@\n finishedSize:  %lld\n totalSiz:    %lld\n md5: %@\n url:   %@\n filePath:  %@\n fileName:  %@\n",
//            self.key,
//            type,
//            status,
//            self.finishedSize,
//            self.totalSize,
//            self.md5,
//            self.url,
//            self.filePath,
//            self.fileName];
}
@end
