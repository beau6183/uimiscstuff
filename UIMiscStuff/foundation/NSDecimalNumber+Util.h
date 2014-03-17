//
//  NSDecimalNumber+Util.h
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDecimalNumber (Util)
/**
 * Determines the greater between self and given NSDecimalNumber
 */
-(NSDecimalNumber*)max:(NSDecimalNumber*)x;
/**
 * Determines the lesser between self and given NSDecimalNumber
 */
-(NSDecimalNumber*)min:(NSDecimalNumber*)x;
@end
