//
//  UIAlertView+TextField.h
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import <Foundation/Foundation.h>


//Exposes hidden UIAlertView API. Probably not kosher, but this isn't an App Store app....
@interface UIAlertView (TextField)
- (UITextField*)addTextFieldWithValue:(NSString*)value label:(NSString*)label;
- (UITextField*)textFieldAtIndex:(NSUInteger)index;
- (NSUInteger)textFieldCount;
- (UITextField*)textField;
@end
