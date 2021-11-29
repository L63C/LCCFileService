# LCCFileService
- 支持断点续传
- 支持断点下载
- 大文件分片上传
- 最大同时上传，下载队列可控
- 上传，下载，进度多种方式监听
- 可以自定义下下载，上传器（目前是封装的亚马逊`AWSS3`）
- 秒传，秒下载（通过MD5和FileKey，判定文件是否已经上传或者下载，如果是，直接进行copy 操作）
[![CI Status](https://img.shields.io/travis/lu63chuan@163.com/LCCFileService.svg?style=flat)](https://travis-ci.org/lu63chuan@163.com/LCCFileService)
[![Version](https://img.shields.io/cocoapods/v/LCCFileService.svg?style=flat)](https://cocoapods.org/pods/LCCFileService)
[![License](https://img.shields.io/cocoapods/l/LCCFileService.svg?style=flat)](https://cocoapods.org/pods/LCCFileService)
[![Platform](https://img.shields.io/cocoapods/p/LCCFileService.svg?style=flat)](https://cocoapods.org/pods/LCCFileService)

## Example

### 上传
```
第一步：添加下载器
 _netService = [[LCFileNetService alloc] init];
  [_netService addHander:[LCS3Hander default]];
 第二步：添加任务
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
    task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"test:finishCallback:%@ error:%@",task,error);
        XCTAssertNil(error);
        [ret fulfill];
    };
    [self.netService lc_startTask:task queue:nil];

```
### 下载
```
第一步：添加下载器
 _netService = [[LCFileNetService alloc] init];
  [_netService addHander:[LCS3Hander default]];
  
 第二步：添加任
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
    task.fileKey = _smallFileKeys.firstObject;
    task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"test:finishCallback:%@ error:%@",task,error);
        XCTAssertNil(error);
        [ret fulfill];
    };
    [self.netService lc_startTask:task queue:nil];
```
### 灵活的监听方式
#### Way1 ：使用block
```
LCFileNetTask *task = [[LCFileNetTask alloc] init];
 task.statusCallback = ^(LCFileNetTask * _Nonnull task) {
        NSLog(@"test:statusCallback:%@",task);
    };
    task.progressCallback = ^(LCFileNetTask * _Nonnull task) {
        NSLog(@"test:progressCallback:%@",task);
    };
    task.fileKey = _smallFileKeys.firstObject;
    task.finishCallback = ^(LCFileNetTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"test:finishCallback:%@ error:%@",task,error);
        XCTAssertNil(error);
        [ret fulfill];
    };
```
#### Way2: 使用代理
```
#import <LCFileNetService.h>
#import "LCFileNetProtocol.h"
@interface LCCViewController ()<LCFileNetProtocol>
@property (nonatomic, strong) LCFileNetService *fileService;
@end

@implementation LCCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
  _fileService = [LCFileNetService default];
    [_fileService addObserver:self];
}
- (void)lc_fileNetProgress:(LCFileNetTask *)task{
    NSLog(@"%s",__func__);
}
- (void)lc_fileNetStatusChange:(LCFileNetTask *)task{
    NSLog(@"%s",__func__);
}
- (void)lc_fileNetFinshed:(LCFileNetTask *)task error:(NSError *)error{
    NSLog(@"%s",__func__);
}

```

#### Way3  使用ProtocolFinder 监听
```
第一步： 注册监听
[[ProtocolFinder defaultFinder] registerObj:self forProtocols:@[@protocol(LCFileNetProtocol)]];
第二步：监听（同代理）
- (void)lc_fileNetProgress:(LCFileNetTask *)task{
    NSLog(@"%s",__func__);
}
- (void)lc_fileNetStatusChange:(LCFileNetTask *)task{
    NSLog(@"%s",__func__);
}
- (void)lc_fileNetFinshed:(LCFileNetTask *)task error:(NSError *)error{
    NSLog(@"%s",__func__);
}
```
tips:
```
way1 和way2 只能在一处获得回调结果，
way3,可以在多处同时获得回调结果，多用于需要在不同地方都要现实文件上传下载进度或状态的场景
```
### 自定义上传，下载器
目前LCFileNetService 只封装了亚马逊AWSS3 的库，如果需要添加其他的方式，只需要实现`LCFileNetHander` 协议，然后调用`- (void)addHander:(nonnull id<LCFileNetHander>)hander;`既可

### API 
```
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
```

## Requirements

## Installation

LCCFileService is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'LCCFileService'
```

## Author

lu63chuan@163.com, lu63chuan@163.com

## License

LCCFileService is available under the MIT license. See the LICENSE file for more info.
