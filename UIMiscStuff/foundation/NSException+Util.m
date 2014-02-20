//
//  NSException+Util.m
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import "NSException+Util.h"

@implementation NSException (NSException_Util)
+(NSString*)getMessage:(id)thing {
    NSString *msg;
    if ([thing isKindOfClass:[NSError class]]) {
        msg = ((NSError*)thing).localizedDescription;
    } else if ([thing respondsToSelector:@selector(description)] && [thing description]) {
        msg = [thing description];
    } else if ([thing isKindOfClass:[NSException class]] && ((NSException*)thing).reason) {
        msg = ((NSException*)thing).reason;
    } else if (thing == [NSNull null]) {
        msg = @"Unknown Error";
    } else {
        msg = @"Unknown Error";
    }
    
    return msg;
}
@end
