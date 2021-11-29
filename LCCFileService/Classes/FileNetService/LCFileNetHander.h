//
//  LCFileNetHander.h
//  S3Demo
//
//  Created by L63 on 2021/10/8.
//

#import <Foundation/Foundation.h>
#import "LCFileNetTask.h"
NS_ASSUME_NONNULL_BEGIN

@protocol LCFileNetHander <NSObject>


- (void)lc_fileNetHanderDownload:(LCFileNetTask *)task
                          progress:(LCFileNetTaskProgressCallback)progressCallback
                             finish:(LCFileNetTaskFinishCallback)finishCallback;

- (void)lc_fileNetHanderUpload:(LCFileNetTask *)task
                          progress:(LCFileNetTaskProgressCallback)progressCallback
                             finish:(LCFileNetTaskFinishCallback)finishCallback;

- (void)lc_fileNetHanderResumUploadTask:(LCFileNetTask *)task
         progress:(LCFileNetTaskProgressCallback)progressCallback
            finish:(LCFileNetTaskFinishCallback)finishCallback;

- (void)lc_fileNetHanderResumDownloadTask:(LCFileNetTask *)task
         progress:(LCFileNetTaskProgressCallback)progressCallback
            finish:(LCFileNetTaskFinishCallback)finishCallback;

- (void)lc_fileNetHanderCancelTask:(LCFileNetTask *)task;

- (void)lc_fileNetHanderPauseTask:(LCFileNetTask *)task;

    
@end


NS_ASSUME_NONNULL_END
