//   MutableThreadTest.m
//   ControlUsageLib
//
//   Created by Ted on 2024/2/1
//   


#import "MutableThreadTest.h"

@interface MutableThreadTest()
@property (nonatomic,strong)NSMutableArray<NSString*> *testArray;
@end

@implementation MutableThreadTest
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self mutableThreadTest];
    }
    return self;
}

-(void)mutableThreadTest {
    
    self.testArray = @[].mutableCopy;
    for (NSInteger i = 0; i< 500; i++) {
        [self.testArray addObject:[NSString stringWithFormat:@"%ld",(long)i]];
    }
    
    NSThread *thread1 = [[NSThread alloc] initWithBlock:^{
        NSLog(@"thread1 %@ 正在遍历数组",[NSThread currentThread]);
        NSArray *copyArr = [self.testArray mutableCopy];
        for (NSString *s1 in copyArr) {
            NSLog(@"thread1,%@",s1);
        }
    }];
    [thread1 start];
    
    NSThread *thread2 = [[NSThread alloc] initWithBlock:^{
        NSLog(@"thread2 %@ 正在遍历数组",[NSThread currentThread]);
        NSArray *copyArr = [self.testArray mutableCopy];
        for (NSString *s1 in copyArr) {
            NSLog(@"thread2,%@",s1);
        }
    }];
    [thread2 start];
    
    NSThread *thread3 = [[NSThread alloc] initWithBlock:^{
        NSLog(@"thread3 %@ 正在遍历数组",[NSThread currentThread]);
        NSArray *copyArr = [self.testArray mutableCopy];
//        NSArray *copyArr = self.testArray;
        for (NSString *s1 in copyArr) {
            NSLog(@"thread3,%@",s1);
        }
    }];
    [thread3 start];
    
    NSThread *thread4 = [[NSThread alloc] initWithBlock:^{
        NSLog(@"thread4 %@ 正在修改数组",[NSThread currentThread]);
        [self.testArray addObject:@"1000"];
        [self.testArray addObject:@"1001"];
        for (NSInteger i = 0; i < self.testArray.count - 100; i++) {
            self.testArray[i] = [NSString stringWithFormat:@"%ld",(long)i+1];
        }
        for (NSInteger i = 0; i < 10; i++) {
//            [self.testArray addObject:[NSString stringWithFormat:@"%ld",(long)i+1]];
            [self.testArray removeLastObject];
        }
    }];
    [thread4 start];
}

@end
