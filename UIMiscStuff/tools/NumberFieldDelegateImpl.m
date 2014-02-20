//
//  NumberFieldDelegateImpl.m
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import "NumberFieldDelegateImpl.h"
#import "NSString+Util.h"
#import <objc/runtime.h>
#import "FocusUtil.h"


#pragma mark - Private Impl

@interface NumberFieldDelegateImpl (Private) 
- (void)addDoneButton;
- (void)removeDoneButton;
- (IBAction)donePressed:(id)sender;
@end

#pragma mark - Public Impl

@implementation NumberFieldDelegateImpl

@synthesize field;
@synthesize viewDelegate;
@synthesize formatter;
@synthesize doneButton;
@synthesize doneButtonAdded;
@synthesize useDoneButton;

-(NSDecimalNumber*) value {
    if (self.formatter && self.field && self.field.text && self.field.text.length > 0) {
        NSString *cents = [self.field.text numericOnly];
        NSDecimalNumber *d = [NSDecimalNumber decimalNumberWithString:cents];
        d = [d decimalNumberByMultiplyingByPowerOf10:-[self.formatter maximumFractionDigits]];
        return d;
    }
    return nil;
}

-(id)init {
    [NSException raise:@"NumberFieldDelegateImpl:init is not supported." format:@"Use NumberFieldDelegateImpl:initWithTextField:andFormatter"];
    return nil;
}

-(id)initWithTextField:(UITextField *)aTextField andFormatter:(NSNumberFormatter*)aFormatter notUsingDoneButton:(BOOL)noDoneButton {
    self = [super init];
    if (self) {
        self.field = aTextField;
        if (self.field.delegate) {
            self.viewDelegate = self.field.delegate;
        }
        //self.field.delegate = self;
        self.formatter = aFormatter;
        if (!self.formatter) {
            NSNumberFormatter *f = [NSNumberFormatter new];
            self.formatter = f;
            [f release];
        };
        if ([[UIDevice currentDevice].model rangeOfString:@"iPad"].location == NSNotFound) {
            useDoneButton = !noDoneButton;
        }
        else {
            useDoneButton = NO;
        }
        self.field.keyboardType = (useDoneButton 
                                   ? UIKeyboardTypeNumberPad 
                                   : ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                                      ? UIKeyboardTypePhonePad
                                      : UIKeyboardTypeDecimalPad));
        doneButtonAdded = NO;
    }
    return self;
}


- (void)unregister {
    [self removeDoneButton];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIKeyboardDidShowNotification 
                                                  object:nil];
    if (self.field && self.field.delegate == self) {
        self.field.delegate = self.viewDelegate;
    }
    
    //self.viewDelegate = nil;
    self.field = nil;
    self.formatter = nil;
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
    // Only respond once, focus might have changed...
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIKeyboardDidShowNotification 
                                                  object:nil];
    
    if (useDoneButton && [self.field isFirstResponder] && !doneButtonAdded) {
        [self addDoneButton];
    }
}

- (BOOL) shouldCheckViewDelegate:(SEL)aSelector {
    return self.viewDelegate && [self.viewDelegate respondsToSelector:aSelector];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if ([self shouldCheckViewDelegate:@selector(textFieldDidBeginEditing:)]) {
        [self.viewDelegate textFieldDidBeginEditing:textField];
    }
    
    [self addDoneButton];
    
    if (!self.doneButtonAdded) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(keyboardWasShown:) 
                                                     name:UIKeyboardDidShowNotification 
                                                   object:nil];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self shouldCheckViewDelegate:@selector(textFieldShouldReturn:)]) {
        if (![self.viewDelegate textFieldShouldReturn:textField]) {
            return NO;
        }
    }
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self shouldCheckViewDelegate:@selector(textFieldDidEndEditing:)]) {
        [self.viewDelegate textFieldDidEndEditing:textField];
    }
    [self removeDoneButton];
}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    if ([self shouldCheckViewDelegate:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        if (![self.viewDelegate textField:textField shouldChangeCharactersInRange:range replacementString:string]) {
            return NO;
        }
    }
    
    //TODO Character replacements. For now, ignoring pastes and cuts
    if (range.length > 1) {
        return NO;
    }
    
    NSMutableString *cents = [NSMutableString stringWithString:[textField.text numericOnly]];
    NSString *ns = [string numericOnly];
    if ([string length]) {
        if ([ns length]) {
            [cents appendString:ns];
        }
    }
    else if ([cents length]) {
        // Backspace
        [cents deleteCharactersInRange:NSMakeRange([cents length] - 1, 1)];
    }
    NSDecimalNumber *d = [NSDecimalNumber decimalNumberWithString:cents];
    if (![d isEqual:[NSDecimalNumber notANumber]]) {
        d = [d decimalNumberByMultiplyingByPowerOf10:-[self.formatter maximumFractionDigits]];
        [textField setText:[self.formatter stringFromNumber:d]];
    }
    else {
        [textField setText:nil];        
    }

    return NO;
}

#pragma mark - Memory management
-(void)dealloc {
    //[self.viewDelegate release];
    [self unregister];
    [field release];
    [formatter release];
    [doneButton release];
    [super dealloc];
}

@end

#pragma mark - Private Impl

@implementation NumberFieldDelegateImpl (Private)

- (void)addDoneButton {
    
    if (doneButtonAdded || ![self.field isFirstResponder]) return;
    
    UIView* keyboard = [FocusUtil findKeyboard];
    if (!keyboard) return;
    
    if (self.doneButton == nil) {
        self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.doneButton.frame = CGRectMake(0, keyboard.frame.size.height - 53, 106, 53);
        self.doneButton.adjustsImageWhenHighlighted = NO;
        [self.doneButton setImage:[UIImage imageNamed:@"doneup.png"] forState:UIControlStateNormal];
        [self.doneButton setImage:[UIImage imageNamed:@"donedown.png"] forState:UIControlStateHighlighted];
        [self.doneButton addTarget:self action:@selector(donePressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [keyboard addSubview:self.doneButton];
    doneButtonAdded = YES;
}

- (void)removeDoneButton {
    if (doneButtonAdded && self.doneButton) {
        [self.doneButton removeFromSuperview];
        self.doneButton = nil;
        [doneButton release];
    }
    doneButtonAdded = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIKeyboardDidShowNotification 
                                                  object:nil];
}

-(IBAction)donePressed:(id)sender {
    [self textFieldShouldReturn:self.field];
}

@end

