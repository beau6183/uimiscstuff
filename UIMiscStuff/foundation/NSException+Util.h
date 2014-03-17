//
//  NSException+Util.h
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSException (NSException_Util)
/**
 * (Static)
 * Read the appropriate message/description/reason from the given NSException/NSError.
 */
+(NSString*)getMessage:(id)thing;
@end
