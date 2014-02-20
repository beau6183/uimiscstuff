//
//  NSString+Util.h
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (NSString_Util)
+(NSString*)makeString:(id)object withKeys:(NSArray*)keys andSeparator:(NSString*)separator;
-(NSString*)withCharactersRemovedInSet:(NSCharacterSet*)characterSet;
-(NSString*)numericOnly;
-(NSString*)stringByStrippingLeadingOccurancesOf:(NSString*)string;
-(BOOL)isEmptyOrWhitespace;
-(NSString*)alphaNumericString;
-(NSString*)emailCharactersString;
-(BOOL)existsInArrayByValue:(NSArray *)a;
@end
