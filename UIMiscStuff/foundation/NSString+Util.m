//
//  NSString+Util.m
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import "NSString+Util.h"

static NSCharacterSet *_emailCharacterSet;

@implementation NSString (NSString_Util)
+(NSString*)makeString:(id)object withKeys:(NSArray*)keys andSeparator:(NSString*)separator{
    NSMutableString *rv = [NSMutableString string];
    for (NSString *k in keys) {
        id v = [object valueForKey:k];
        if (v) {
            if (separator && [rv length] > 0) {
                [rv appendString:separator];
            }
            [rv appendString:[v description]];
        }
    }
    return rv;
}

-(NSString*)withCharactersRemovedInSet:(NSCharacterSet*)characterSet {
    if ([self length]) {
        NSMutableString *rv = [NSMutableString stringWithString:self];
        NSRange r = [rv rangeOfCharacterFromSet:characterSet];
        while (r.location != NSNotFound) {
            [rv deleteCharactersInRange:r];
            r = [rv rangeOfCharacterFromSet:characterSet];
        }
        return [NSString stringWithString:rv];
    }
    return self;
}

-(NSString*)numericOnly {
    return [self withCharactersRemovedInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
}

-(NSString*)stringByStrippingLeadingOccurancesOf:(NSString*)string {
    NSMutableString *rv = [NSMutableString stringWithString:self];
    NSRange r = [rv rangeOfString:string];
    while (r.location == 0) {
        [rv deleteCharactersInRange:r];
        r = [rv rangeOfString:string];
    }
    return [NSString stringWithString:rv];
}

-(BOOL)isEmptyOrWhitespace {
    NSString *t = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return [t length] == 0;
}

-(NSString *)emailCharactersString {
    if (_emailCharacterSet == nil) {
        NSMutableCharacterSet *mcs = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [mcs addCharactersInString:@"-_.@"];
        _emailCharacterSet = [mcs copy];
        [mcs release];
    }
    
    return [self stringByTrimmingCharactersInSet:[_emailCharacterSet invertedSet]];
}


-(NSString*)alphaNumericString {
    return [self stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
}

-(BOOL)existsInArrayByValue:(NSArray *)a {
    for (id v in a) {
        if ([v isKindOfClass:[NSString class]] && [v isEqualToString:self]) {
            return true;
        }
    }
    return false;
}

@end
