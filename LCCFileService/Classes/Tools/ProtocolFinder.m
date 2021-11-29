//
//  ProtocolFinder.m
//  L63FileSever
//
//  Created by L63 on 2020/7/21.
//  Copyright © 2020 com.lc.Demo. All rights reserved.
//

#import "ProtocolFinder.h"
@interface ProtocolFinder ()

/**
 protocol 注册记录表
 p:协议名
 obj:class
{
 p1:[obj1,obj2,obj3],
 p2:[obj1,obj2,obj3],
 p3:[obj1,obj2,obj3],
 ...
 ...
 pn:[obj1,obj2,obj3],
 }
 */
@property (nonatomic, strong) NSMutableDictionary *objRegistrationDic;
@end
@implementation ProtocolFinder

+ (instancetype)defaultFinder {
    static ProtocolFinder *finder = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        finder = [[ProtocolFinder alloc] init];
        finder.objRegistrationDic = [NSMutableDictionary dictionary];
    });

    return finder;
}

- (void)registerObj:(id)obj forProtocols:(NSArray<Protocol *> *)protocols {
    if (!obj || !protocols.count) {
        return;
    }
    dispatch_async(protocol_finder_queue(), ^{
        for (Protocol *p in protocols) {
            NSPointerArray *objArray = [self objArrayForProtocol:p];
            if ([[objArray allObjects] indexOfObject:obj] == NSNotFound) {
                [objArray addPointer:(__bridge void *_Nullable)(obj)];
            }
        }
    });
}

- (void)removeObj:(id)obj forProtocols:(NSArray<Protocol *> *)protocols {
    if (!obj || !protocols.count) {
        return;
    }
    dispatch_async(protocol_finder_queue(), ^{
        for (Protocol *p in protocols) {
            NSPointerArray *objArray = [self objArrayForProtocol:p];
            for (int i = 0; i < objArray.count; i++) {
                if ([objArray pointerAtIndex:i] == (__bridge void *_Nullable)(obj)) {
                    [objArray removePointerAtIndex:i];
                    break;
                }
            }
        }
    });
}

- (NSArray *)findObjForProtocol:(Protocol *)protocol {
    __block NSArray *objArray = nil;
    dispatch_sync(protocol_finder_queue(), ^{
        objArray = [[[self objArrayForProtocol:protocol] allObjects] copy];
    });
    return objArray;
}

- (id)findLastestObjForProtocol:(Protocol *)protocol {
    return [[self findObjForProtocol:protocol] lastObject];
}

- (void)execute:(Protocol *)protocol selector:(SEL)selector run:(void (^)(id obj))run {
    NSArray *objs = [self findObjForProtocol:protocol];
    for (id obj in objs) {
        if ([obj respondsToSelector:selector]) {
            run(obj);
        }
    }
}

- (void)execute:(Protocol *)protocol selector:(SEL)selector withObj:(id)param {
    [self execute:protocol selector:selector run:^(id _Nonnull obj) {
        [obj performSelector:selector withObject:param afterDelay:0.0];
    }];
}

#pragma mark - private
- (NSPointerArray *)objArrayForProtocol:(Protocol *)protocol {
    NSPointerArray *objArray = [self.objRegistrationDic objectForKey:NSStringFromProtocol(protocol)];

    [objArray addPointer:NULL];
    [objArray compact];

    if (!objArray) {
        objArray = [NSPointerArray weakObjectsPointerArray];
        [self.objRegistrationDic setObject:objArray forKey:NSStringFromProtocol(protocol)];
    }

    return objArray;
}

static dispatch_queue_t protocol_finder_queue()
{
    static dispatch_queue_t protocol_queue_t;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        protocol_queue_t = dispatch_queue_create("protocol_queue_t", DISPATCH_QUEUE_SERIAL);
    });
    return protocol_queue_t;
}

@end
