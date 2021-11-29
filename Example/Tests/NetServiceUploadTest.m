//
//  NetServiceUploadTest.m
//  S3DemoTests
//
//  Created by L63 on 2021/10/9.
//

#import <XCTest/XCTest.h>
#import "LCFileNetService.h"
#import "LCS3Hander.h"
#import "Md5Tools.h"
static NSString *rootPath = @"/Users/luchuan/Documents/Project/Pod/LCCFileService/Example/Tests/TestResource";
//static NSString *rootPath = @"/Users/luchuan/Documents/Project/Mine/s3-demo/S3DemoTests/TestResource";

@interface NetServiceUploadTest : XCTestCase

@property (nonatomic, strong) LCFileNetService *netService;
@property (nonatomic, strong) LCS3Hander *s3Hander;

@end

@implementation NetServiceUploadTest
- (void)setUp {
    _netService = [[LCFileNetService alloc] init];
    [_netService addHander:[LCS3Hander default]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}
///MARK: - Upload task
- (void)testUpLoadFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    NSString *filePath = [rootPath stringByAppendingPathComponent:@"small/s1.file"];
    LCFileNetTask *task = [self p_getOneTask:nil md5:nil filePath:filePath];
    task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"test:finishCallback:%@ error:%@",task,error);
        XCTAssertNil(error);
        [ret fulfill];
    };
    [self.netService lc_startTask:task queue:nil];
    [self waitForExpectations:@[ret] timeout:100];
}
- (void)testUpLoadLargeFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    NSString *filePath = [rootPath stringByAppendingPathComponent:@"large/l7.file"];
    LCFileNetTask *task = [self p_getOneTask:nil md5:nil filePath:filePath];
    task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"test:finishCallback:%@ error:%@",task,error);
        XCTAssertNil(error);
        [ret fulfill];
    };
    [self.netService lc_startTask:task queue:nil];
    [self waitForExpectations:@[ret] timeout:60 * 10];
}
- (void)testUpLoadSomeSmallFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    dispatch_group_t group_t = dispatch_group_create();
    NSMutableArray *keys = [NSMutableArray array];
    for (int i = 1; i<10; i++) {
        dispatch_group_enter(group_t);
        NSString *filePath =  [rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"small/s%@.file",@(i).stringValue]];
        LCFileNetTask *task = [self p_getOneTask:nil md5:nil filePath:filePath];
        task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            NSLog(@"test:finishCallback:%@ error:%@",task,error);
            [keys addObject:task.taskId];
            NSLog(@"test:all keys %@",keys);
            XCTAssertNil(error);
            dispatch_group_leave(group_t);
        };
        if([[NSFileManager defaultManager] fileExistsAtPath:task.filePath]){
            [self.netService lc_startTask:task queue:nil];
        }
    }
    dispatch_group_notify(group_t, dispatch_get_main_queue(), ^{
        
        [ret fulfill];
    });
    [self waitForExpectations:@[ret] timeout:60*5];
}
- (void)testUpLoadSomelargeFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    NSMutableArray *keys = [NSMutableArray array];
    dispatch_group_t group_t = dispatch_group_create();
    for (int i = 1; i<=7; i++) {
        dispatch_group_enter(group_t);
        NSString *filePath = [rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"large/l%@.file",@(i).stringValue]];
        LCFileNetTask *task = [self p_getOneTask:nil md5:nil filePath:filePath];
        task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            NSLog(@"test:finishCallback:%@ error:%@",task,error);
            XCTAssertNil(error);
            [keys addObject:task.taskId];
            NSLog(@"test:all keys %@",keys);
            dispatch_group_leave(group_t);
        };
        if([[NSFileManager defaultManager] fileExistsAtPath:task.filePath]){
            [self.netService lc_startTask:task queue:nil];
        }
    }
    dispatch_group_notify(group_t, dispatch_get_main_queue(), ^{
        [ret fulfill];
    });
    [self waitForExpectations:@[ret] timeout:60*20];
}
- (void)testUploadNilFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    LCFileNetTask *task = [self p_getOneTask:nil md5:nil filePath:nil];
    task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"test:finishCallback:%@ error:%@",task,error);
        XCTAssertNotNil(error);
        [ret fulfill];
    };
    [self.netService lc_startTask:task queue:nil];
    [self waitForExpectations:@[ret] timeout:100];
}
- (void)testUpLoadSomeSameTaskIdFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    dispatch_group_t group_t = dispatch_group_create();
    NSString *taskId = [NSUUID UUID].UUIDString;
    for (int i = 1; i<10; i++) {
        dispatch_group_enter(group_t);
        NSString *filePath = [rootPath stringByAppendingPathComponent:@"small/s1.file"];
        LCFileNetTask *task = [self p_getOneTask:nil md5:nil filePath:filePath];
        task.taskId = taskId;
        task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            NSLog(@"test:finishCallback:%d,%@ error:%@",i,task,error);
            XCTAssertNil(error);
            dispatch_group_leave(group_t);
        };
        if([[NSFileManager defaultManager] fileExistsAtPath:task.filePath]){
            [self.netService lc_startTask:task queue:nil];
        }
    }
    dispatch_group_notify(group_t, dispatch_get_main_queue(), ^{
        [ret fulfill];
    });
    [self waitForExpectations:@[ret] timeout:100];
}
- (void)testUpLoadSomeSameMd5File {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    dispatch_group_t group_t = dispatch_group_create();
    for (int i = 1; i<10; i++) {
        dispatch_group_enter(group_t);
        NSString *filePath = [rootPath stringByAppendingPathComponent:@"small/s1.file"];
        LCFileNetTask *task = [self p_getOneTask:nil md5:nil filePath:filePath];
        task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            NSLog(@"test:finishCallback:%d,%@ error:%@",i,task,error);
            XCTAssertNil(error);
            dispatch_group_leave(group_t);
        };
        if([[NSFileManager defaultManager] fileExistsAtPath:task.filePath]){
            [self.netService lc_startTask:task queue:nil];
        }
    }
    dispatch_group_notify(group_t, dispatch_get_main_queue(), ^{
        [ret fulfill];
    });
    [self waitForExpectations:@[ret] timeout:100];
}
- (void)testUploadPauseAndReusmATask{
 XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
 LCFileNetTask *task = [self p_getOneTask:nil md5:nil filePath:[rootPath stringByAppendingPathComponent:@"large/l7.file"]];
 task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
 NSLog(@"test:finishCallback:%@ error:%@",task,error);
 XCTAssertNil(error);
 [ret fulfill];
 };
 [_netService lc_startTask:task queue:nil];
 
 sleep(5);
 NSLog(@"test:暂停....");
 [_netService lc_pauseTask:task.taskId];
 sleep(10);
 NSLog(@"test:恢复....");
 [_netService lc_resumTask:task.taskId queue:nil];
 
 [self waitForExpectations:@[ret] timeout:500];
 }
 - (void)testUploadCancelAndReusmATask{
 XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
 
 BOOL isCanceled = NO;
 
 LCFileNetTask *task = [self p_getOneTask:nil md5:nil filePath:[rootPath stringByAppendingPathComponent:@"large/l7.file"]];
 task.progressCallback = ^(LCFileNetTask * _Nonnull task) {
 NSLog(@"test:progressCallback:%@",task);
 XCTAssertFalse(isCanceled);
 };
 task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
 NSLog(@"test:finishCallback:%@ error:%@",task,error);
 XCTAssertNil(error);
 XCTAssertFalse(isCanceled);
 [ret fulfill];
 };
 [_netService lc_startTask:task queue:nil];
 
 sleep(5);
 NSLog(@"test:取消....");
 [_netService lc_cancelTask:task.taskId];
 isCanceled = YES;
 sleep(10);
 NSLog(@"test:恢复....");
 [_netService lc_resumTask:task.taskId queue:nil];
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
 [ret fulfill];
 });
 
 [self waitForExpectations:@[ret] timeout:500];
 }

- (LCFileNetTask *)p_getOneTask:(NSString *)key md5:(NSString *)md5 filePath:(NSString *)filePath{
    LCFileNetTask *task = [[LCFileNetTask alloc] init];
    task.taskId = [NSUUID UUID].UUIDString;
    task.fileKey = key?:[@"10_29/" stringByAppendingString:[NSUUID UUID].UUIDString];
    task.type = LCFileNetTaskTypeUpload;
    task.filePath = filePath;
    task.fileName = @"task_fileName";
    task.statusCallback = ^(LCFileNetTask * _Nonnull task) {
        NSLog(@"test:statusCallback:%@",task);
    };
    task.progressCallback = ^(LCFileNetTask * _Nonnull task) {
        NSLog(@"test:progressCallback:%@",task);
    };
    return task;
}

@end

