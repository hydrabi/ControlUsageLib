//
//  AvoidcrashTest.m
//  ControlUsageLib
//
//  Created by 毕志锋 on 2024/1/6.
//

#import "AvoidcrashTest.h"

@implementation AvoidcrashTest

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *nilStr = nil;
//        NSArray *array = @[@"1",nilStr];
//        NSLog(@"%@",array);
//        abort();
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
//            assert(nilStr != nil);
//        });
    }
    return self;
}

@end
