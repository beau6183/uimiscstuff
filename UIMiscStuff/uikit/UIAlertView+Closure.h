//
//  UIAlertView+Closure.h
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^AlertViewClosure)(UIAlertView* alertView, NSInteger buttonIndex, BOOL isCancel);

@interface UIAlertView (Closure)
+(id)showAlertWithTitle:(NSString *)title message:(NSString *)message buttonLabel:(NSString *)btnLabel;
/*
 [UIAlertView initWithTitle:nil 
 message:nil 
 callBack:^(UIAlertView* alertView, NSInteger buttonIndex, BOOL isCancel){} 
 cancelButtonTitle:nil 
 otherButtonTitles:nil];
 */
-(id)initWithTitle:(NSString *)title message:(NSString *)message 
                       callBack:(AlertViewClosure)callback 
              cancelButtonTitle:(NSString *)cancelTitle 
              otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;
@property (nonatomic,copy) AlertViewClosure callBack;
@end
