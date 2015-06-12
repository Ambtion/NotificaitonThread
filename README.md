
# Notification在多线程下的转发

## 1：Notification的发送与接收处理都是在同一个线程中

***
#### 
`@implementation ViewController`

`- (void)viewDidLoad {`
    `[super viewDidLoad];`

    `NSLog(@"current thread = %@", [NSThread currentThread]);`

    `[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:TEST_NOTIFICATION object:nil];`

    `dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{`

        `[[NSNotificationCenter defaultCenter] postNotificationName:TEST_NOTIFICATION object:nil userInfo:nil];`
    `});`
`}`

`- (void)handleNotification:(NSNotification *)notification`
`{`
    `NSLog(@"current thread = %@", [NSThread currentThread]);`
    `NSLog(@"test notification");`
`}`

`@end`

## 2: NSNotificationCenter是线程安全的，但是并不意味这可以在多线程中任意使用，不合理使用依旧可以导致Crash
### 1 : 线程A抛消息
### 2 : 线程A的Reciver接受处理消息
### 3 : 线程B释放Reciver
### 4 : Reciver 处理消息过程中访问Reciver，此时Reciver已经释放，导致Crash
