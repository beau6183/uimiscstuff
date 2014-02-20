//
//  NumberFieldDelegateImpl.h
//
//  Created by Beau Scott on 2/19/14.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A utility for creating and monitoring a "DONE" button on a standard
 * UIKeyboardTypeDecimal or UIKeyboardTypeNumberPad keyboard for a given
 * UITextField. NumberFieldDelegateImpl is itself a UITextFieldDelegate,
 * but works by assigning itself as the field's delegate, and then
 * proxies the original delegate's selectors.
 *
 * Usage: 
 *    UITextField *tf = [UITextField new];
 *    tf.delegate = self; // self being a UIViewController <UITextFieldDelegate>
 *
 *    NSNumberFormatter *nf = [NSNumberFormatter new];
 *    [nf setNumberStyle:NSNumberFormatterCurrencyStyle];
 *    [nf setMaximumFractionDigits:2];
 *    [nf setMinimumFractionDigits:2];
 *    nfdel = [NumberFieldDelegateImple alloc]initWithTextField:tf andFormatter:nf]
 */
@interface NumberFieldDelegateImpl : NSObject <UITextFieldDelegate> {
    UITextField *field;
    NSNumberFormatter *formatter;
@private
    id<UITextFieldDelegate> viewDelegate;
    UIButton *doneButton;
    BOOL doneButtonAdded;
    BOOL useDoneButton;
}
@property (readonly) NSDecimalNumber *value;
// TODO these should probably be read-only
@property (nonatomic,retain) UITextField *field;
@property (nonatomic,retain) NSNumberFormatter *formatter;
//--

@property (nonatomic,assign) id<UITextFieldDelegate> viewDelegate;
@property (nonatomic,retain) UIButton *doneButton;
@property BOOL doneButtonAdded;
@property BOOL useDoneButton;

/**
 * Default constructor. All params are required and not nillable
 */
-(id) initWithTextField:(UITextField*)aTextField andFormatter:(NSNumberFormatter*)aFormatter notUsingDoneButton:(BOOL)noDoneButton;

- (id)init __attribute__((unavailable));

- (void)unregister;
@end
