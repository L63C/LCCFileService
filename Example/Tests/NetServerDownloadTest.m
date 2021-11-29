//
//  NetServerDownloadTest.m
//  S3DemoTests
//
//  Created by L63 on 2021/10/9.
//

#import <XCTest/XCTest.h>
#import "LCFileNetService.h"
#import "LCS3Hander.h"

//static NSString *rootPath = @"/Users/luchuan/Desktop/S3Demo";
static NSString *rootPath = @"/Users/luchuan/Desktop/S3DemoDownloadFile";
@interface NetServerDownloadTest : XCTestCase

@property (nonatomic, strong) LCFileNetService *netService;
@property (nonatomic, strong) LCS3Hander *s3Hander;
@property (nonatomic, strong) NSArray *smallFileKeys;
@property (nonatomic, strong) NSArray *largeFileKeys;

@end

@implementation NetServerDownloadTest

- (void)setUp {
    _netService = [[LCFileNetService alloc] init];
    [_netService addHander:[LCS3Hander default]];
    _smallFileKeys = @[
        @"10_29/F92A4C5B-6328-4E91-A659-7ED73927D799",
        @"10_29/08F1C0AE-0C68-422A-B9DD-F494B2088A6D",
        @"10_29/75A7377A-018F-4E0E-B92C-C9F0254A4E8E",
        @"10_29/D6D69B47-A4AF-47AA-A6A6-D1CDC17ACC61",
        @"10_29/33A72916-0E6C-403A-BBBA-5E1A44AE46B5",
        @"10_29/ED7FCFE8-72C3-48E4-AA5A-EDCF5BFE872E",
        @"10_29/E1644D48-FCC2-4389-8434-1F6A3B67BFF1",
        @"10_29/A6F41EF9-2418-42E5-963B-1677B0D9B918",
        @"10_29/7B01C9DA-2D10-4BE2-BBEA-9A2CC040A261",
    ];
    _largeFileKeys = @[
        @"10_29/1157E05B-F99B-4FBA-B8C7-174434D7B2D9",
        @"10_29/20D66009-E6AC-4010-B27E-C496275ED6CA",
        @"10_29/B1B06BC7-EAEC-4224-A139-21EA7EC4635C",
        @"10_29/19C22600-2899-41C3-8DF0-F791B6A1327A",
        @"10_29/1B95947F-35E8-4621-8BFD-576018CD9083",
        @"10_29/A484B5E3-AE94-4888-8B5E-C9CAE5C42EDA",
        @"10_29/F4A2149B-A1BD-40BF-9187-F5707E2F84ED"
    ];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

///MARK: - Upload task
- (void)testDownLoadFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    LCFileNetTask *task = [self p_getOneTask:_smallFileKeys.firstObject];
    task.fileKey = _smallFileKeys.firstObject;
    task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"test:finishCallback:%@ error:%@",task,error);
        XCTAssertNil(error);
        [ret fulfill];
    };
    [self.netService lc_startTask:task queue:nil];
    [self waitForExpectations:@[ret] timeout:100];
}
- (void)testDownLoadLargeFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    LCFileNetTask *task = [self p_getOneTask:_largeFileKeys.firstObject];
    task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"test:finishCallback:%@ error:%@",task,error);
        XCTAssertNil(error);
        [ret fulfill];
    };
    [self.netService lc_startTask:task queue:nil];
    [self waitForExpectations:@[ret] timeout:100];
}
- (void)testDownLoadSomeSmallFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    dispatch_group_t group_t = dispatch_group_create();
    NSMutableArray *keys = [NSMutableArray array];
    for (int i = 0; i<_smallFileKeys.count; i++) {
        dispatch_group_enter(group_t);
        LCFileNetTask *task = [self p_getOneTask:_smallFileKeys[i]];
        task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            NSLog(@"test:finishCallback:%@ error:%@",task,error);
            [keys addObject:task.taskId];
            NSLog(@"test:all keys %@",keys);
            XCTAssertNil(error);
            dispatch_group_leave(group_t);
        };
        [self.netService lc_startTask:task queue:nil];
    }
    dispatch_group_notify(group_t, dispatch_get_main_queue(), ^{
        
        [ret fulfill];
    });
    [self waitForExpectations:@[ret] timeout:500];
}
- (void)testDownLoadSomelargeFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    NSMutableArray *keys = [NSMutableArray array];
    dispatch_group_t group_t = dispatch_group_create();
    for (int i = 0; i<_largeFileKeys.count; i++) {
        dispatch_group_enter(group_t);
        LCFileNetTask *task = [self p_getOneTask:_largeFileKeys[i]];
        task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            NSLog(@"test:finishCallback:%@ error:%@",task,error);
            XCTAssertNil(error);
            [keys addObject:task.taskId];
            NSLog(@"test:all keys %@",keys);
            dispatch_group_leave(group_t);
        };
        [self.netService lc_startTask:task queue:nil];
    }
    dispatch_group_notify(group_t, dispatch_get_main_queue(), ^{
        [ret fulfill];
    });
    [self waitForExpectations:@[ret] timeout:500];
}
- (void)testDownLoadNilFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    LCFileNetTask *task = [self p_getOneTask:nil];
    task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"test:finishCallback:%@ error:%@",task,error);
        XCTAssertNotNil(error);
        [ret fulfill];
    };
    [self.netService lc_startTask:task queue:nil];
    [self waitForExpectations:@[ret] timeout:100];
}
- (void)testDownLoadSomeSameTaskIdFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    dispatch_group_t group_t = dispatch_group_create();
    NSString *sametaskId = [[NSUUID UUID]UUIDString];
    for (int i = 1; i<10; i++) {
        dispatch_group_enter(group_t);
        LCFileNetTask *task = [self p_getOneTask:_smallFileKeys.lastObject];
        task.taskId = sametaskId;
        task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            NSLog(@"test:finishCallback:%d,%@ error:%@",i,task,error);
            XCTAssertNil(error);
            dispatch_group_leave(group_t);
        };
        [self.netService lc_startTask:task queue:nil];
    }
    dispatch_group_notify(group_t, dispatch_get_main_queue(), ^{
        [ret fulfill];
    });
    [self waitForExpectations:@[ret] timeout:500];
}
- (void)testDownLoadSomeSameKeyFile {
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    dispatch_group_t group_t = dispatch_group_create();
    for (int i = 1; i<10; i++) {
        dispatch_group_enter(group_t);
        LCFileNetTask *task = [self p_getOneTask:_smallFileKeys.lastObject];
        task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
            NSLog(@"test:finishCallback:%d,%@ error:%@",i,task,error);
            XCTAssertNil(error);
            dispatch_group_leave(group_t);
        };
        [self.netService lc_startTask:task queue:nil];
    }
    dispatch_group_notify(group_t, dispatch_get_main_queue(), ^{
        [ret fulfill];
    });
    [self waitForExpectations:@[ret] timeout:500];
}
- (void)testDownLoadPauseAndReusmATask{
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    LCFileNetTask *task = [self p_getOneTask:_largeFileKeys.lastObject];
    task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"test:finishCallback:%@ error:%@",task,error);
        XCTAssertNil(error);
        [ret fulfill];
    };
    [_netService lc_startTask:task queue:nil];
    
    sleep(20);
    NSLog(@"test:暂停....");
    [_netService lc_pauseTask:task.taskId];
    sleep(10);
    NSLog(@"test:恢复....");
    [_netService lc_resumTask:task.taskId queue:nil];
    
    [self waitForExpectations:@[ret] timeout:500];
}
- (void)testDownLoadCancelAndReusmATask{
    XCTestExpectation *ret = [self expectationWithDescription:@"waiting for switch result"];
    
    BOOL isCanceled = NO;
    
    LCFileNetTask *task = [self p_getOneTask:_largeFileKeys.lastObject];
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
- (LCFileNetTask *)p_getOneTask:(NSString *)key {
    LCFileNetTask *task = [[LCFileNetTask alloc] init];
    task.taskId = [NSUUID UUID].UUIDString;
    task.fileKey = key;
    task.type = LCFileNetTaskTypeDownload;
    task.filePath = [[rootPath stringByAppendingPathComponent:task.taskId] stringByAppendingPathExtension:@"file"];
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

