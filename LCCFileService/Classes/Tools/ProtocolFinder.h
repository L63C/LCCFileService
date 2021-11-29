//
//  ProtocolFinder.h
//  L63FileSever
//
//  Created by L63 on 2020/7/21.
//  Copyright © 2020 com.lc.Demo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProtocolFinder : NSObject


/**
 获取默认的查找器

 @return finder
 */
+ (instancetype)defaultFinder;

/**
 注册obj
 此方法不会对obj造成强引用，所以不用主动移除
 @param obj 待处理的obj
 @param protocols obj所提供的功能协议
 */
- (void)registerObj:(id)obj forProtocols:(NSArray<Protocol *> *)protocols;

/**
 移除指定协议下的指定的obj

 @param obj 待移除的obj
 @param protocols 待移除的obj的指定协议列表
 */
- (void)removeObj:(id)obj forProtocols:(NSArray<Protocol *> *)protocols;

/**
 查找obj列表

 @param protocol 查找协议
 @return 实现了指定协议的obj列表
 */
- (NSArray *)findObjForProtocol:(Protocol *)protocol;

/**
 查找最新的obj

 @discussion 最新的obj即后最后注册的obj

 @param protocol 查找协议
 @return 实现了指定协议的最新obj
 */
- (id)findLastestObjForProtocol:(Protocol *)protocol;

/// 执行注册过对应方法的协议
/// @param protocol 协议名称
/// @param selector 方法名称
/// @param run 使用id 对象执行对应的方法
- (void)execute:(Protocol *)protocol selector:(SEL)selector run:(void(^)(id obj))run;

/// 执行注册过对应方法的协议
/// @param protocol 协议名称
/// @param selector 方法名称
/// @param obj 单个参数
- (void)execute:(Protocol *)protocol selector:(SEL)selector withObj:(nullable id)obj;
@end

NS_ASSUME_NONNULL_END
