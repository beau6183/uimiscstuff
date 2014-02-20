//
//  NSDecimalNumber+Util.m
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import "NSDecimalNumber+Util.h"


@implementation NSDecimalNumber (Util)
-(NSDecimalNumber*)max:(NSDecimalNumber*)x {
    return x != nil && [self compare:x] == NSOrderedAscending ? x : self;
}
-(NSDecimalNumber*)min:(NSDecimalNumber*)x {
    return [self max:x] == self ? x : self;
}
@end
