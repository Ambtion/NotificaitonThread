//
//  ViewController.m
//  Notification
//
//  Created by quke on 15/6/12.
//  Copyright (c) 2015年 quke. All rights reserved.
//

#import "ViewController.h"


#define TEST_NOTIFICATION @"TEST"


//#define MsgInThread

#ifdef MsgInThread

@interface ViewController()<NSMachPortDelegate>

@property (nonatomic) NSMutableArray    *notifications;         // 通知队列
@property (nonatomic) NSThread          *notificationThread;    // 期望线程
@property (nonatomic) NSLock            *notificationLock;      // 用于对通知队列加锁的锁对象，避免线程冲突
@property (nonatomic) NSMachPort        *notificationPort;      // 用于向期望线程发送信号的通信端口

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"current thread = %@", [NSThread currentThread]);
    
    // 初始化
    self.notifications = [[NSMutableArray alloc] init];
    self.notificationLock = [[NSLock alloc] init];
    
    self.notificationThread = [NSThread currentThread];
    self.notificationPort = [[NSMachPort alloc] init];
    self.notificationPort.delegate = self;
    
    // 往当前线程的run loop添加端口源
    // 当Mach消息到达而接收线程的run loop没有运行时，则内核会保存这条消息，直到下一次进入run loop
    [[NSRunLoop currentRunLoop] addPort:self.notificationPort
                                forMode:(__bridge NSString *)kCFRunLoopCommonModes];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:TEST_NOTIFICATION object:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [[NSNotificationCenter defaultCenter] postNotificationName:TEST_NOTIFICATION object:nil userInfo:nil];
        
    });
}

- (void)handleMachMessage:(void *)msg {
    
    [self.notificationLock lock];
    
    while ([self.notifications count]) {
        NSNotification *notification = [self.notifications objectAtIndex:0];
        [self.notifications removeObjectAtIndex:0];
        [self.notificationLock unlock];
        [self processNotification:notification];
        [self.notificationLock lock];
    };
    
    [self.notificationLock unlock];
}

- (void)processNotification:(NSNotification *)notification {
    
    if ([NSThread currentThread] != _notificationThread) {
        // Forward the notification to the correct thread.
        [self.notificationLock lock];
        [self.notifications addObject:notification];
        [self.notificationLock unlock];
        [self.notificationPort sendBeforeDate:[NSDate date]
                                   components:nil
                                         from:nil
                                     reserved:0];
    }
    else {
        // Process the notification here;
        NSLog(@"current thread = %@", [NSThread currentThread]);
        NSLog(@"process notification");
    }
}

@end

#else

/**
 * 异步线程post消息
 */
@interface Poster : NSObject
@end

@implementation Poster

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self performSelectorInBackground:@selector(postNotification) withObject:nil];
    }
    
    return self;
}

- (void)postNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TEST_NOTIFICATION object:nil];
}

@end


/**
 * 消息接受
 */

@interface Observer : NSObject
@property(nonatomic,strong)Poster * poster;
@end

@implementation Observer

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _poster = [[Poster alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:TEST_NOTIFICATION object:nil];

    }
    
    return self;
}

- (void)handleNotification:(NSNotification *)notification
{
    
    NSLog(@"handle notification begin");
//    sleep(1);
    
    NSLog(@"handle notification end");
    NSLog(@"%@",self);
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
   __autoreleasing  Observer *observer = [[Observer alloc] init];
    
}


@end

#endif










