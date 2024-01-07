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
        NSArray *array = @[@"1",nilStr];
        NSLog(@"%@",array);
    }
    return self;
}

@end
