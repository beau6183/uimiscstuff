//
//  NSString+Util.h
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (NSString_Util)
/**
 * (Static)
 * Creates a new NSString object consisting of values in an object, specified by keys and joined
 * with the given separator
 */
+(NSString*)makeString:(id)object withKeys:(NSArray*)keys andSeparator:(NSString*)separator;
/**
 * Creates and returns a new NSString derived from the current value of self, removing characters
 * specified in the character set
 */
-(NSString*)withCharactersRemovedInSet:(NSCharacterSet*)characterSet;
/**
 * Creates and returns a new NSString derived from the current value of self, removing all
 * non-numeric characters.
 */
-(NSString*)numericOnly;
/**
 * Creates and returns a new NSString derived from the current value of self, removing all leading
 * occurances of the specified string
 */
-(NSString*)stringByStrippingLeadingOccurancesOf:(NSString*)string;
/**
 * Returns true if the current value of self is zero length or consists entirely of whitespace
 * characters (space, tab, return, linefeed)
 */
-(BOOL)isEmptyOrWhitespace;
/**
 * Creates and returns a new NSString derived from the current value of self, removing all
 * non-alphanumeric characters (everything but A-Za-z0-9).
 */
-(NSString*)alphaNumericString;
/**
 * Creates and returns a new NSString derived from the current value of self, removing all non-email
 * address safe characters.
 */
-(NSString*)emailCharactersString;
/**
 * Returns true if the current value of the string exits in the given array (compares value, 
 * not instance)
 */
-(BOOL)existsInArrayByValue:(NSArray *)a;
@end
