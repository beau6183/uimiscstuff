//
//  FocusUtil.m
//
//  Created by Beau Scott on 2/19/14.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import "FocusUtil.h"
#import <objc/runtime.h>

static NSString *UITextEffectsWindowClassName = @"UITextEffectsWindow";
static Class UITextEffectsWindowClass = nil;
static NSString *UIPeripheralHostViewClassName = @"UIPeripheralHostView";
static Class UIPeripheralHostViewClass = nil;

@interface FocusUtil (Private)
-(void) restoreView;
-(void) adjustScrollingForControl:(CGRect)convertedKbRect;
-(void) keyboardWillHide:(NSNotification*)note;
-(void) keyboardWasShown:(NSNotification*)note;
@end


@implementation FocusUtil

@synthesize padding=_padding;

-(id) init {
    if ((self = [super init])) {
        currentControl = nil;
        currentView = nil;
        currentViewOriginalPosition = CGRectNull;
        _padding = BOTTOM_CONTROL_PADDING;
    }
    return self;
}

+(UIView*)findKeyboard {
    UIWindow* tempWindow = nil;
    
    // HACK ALERT: UITextEffectsWindow is a private class in UIKit.
    // However I needed away to find the keyboard's window when used in a non-baselayer window.
    
    if (!UITextEffectsWindowClass) {
        UITextEffectsWindowClass = objc_getClass([UITextEffectsWindowClassName cStringUsingEncoding:NSASCIIStringEncoding]);
    }
    if (!UIPeripheralHostViewClass) {
        UIPeripheralHostViewClass = objc_getClass([UIPeripheralHostViewClassName cStringUsingEncoding:NSASCIIStringEncoding]);
    }
    
    for (UIWindow* w in [[UIApplication sharedApplication] windows]) {
        if ([w isKindOfClass:UITextEffectsWindowClass]) {
            tempWindow = w;
            break;
        }
    }
    
    if (tempWindow) {
        
        UIView* keyboard;
        
        for(int i=0; i<[tempWindow.subviews count]; i++) {
            keyboard = [tempWindow.subviews objectAtIndex:i];
            if([keyboard isKindOfClass:UIPeripheralHostViewClass]) {
                return keyboard;
            }
        }
    }
    
//    NSLog(@"Keyboard Window not found yet, registering for keyboard show notification");
    return nil;
}

+(CGFloat)findKBBaselineInView:(UIView *)view {
    UIView* keyboard = [FocusUtil findKeyboard];
        //Keyboard view frame
    CGRect kbFrame = keyboard.frame;
    
    // Window metrics
    // Window chrome (application window, status bar) is not transformed landscape... transform it now.
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        appFrame = CGRectMake(appFrame.origin.y, appFrame.origin.x, appFrame.size.height, appFrame.size.width);
    }
    
    CGFloat targetBaseLine = appFrame.origin.y + appFrame.size.height - kbFrame.size.height;
    
        // Adjust for navviewcontrollers
    if ([view.window.rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *) view.window.rootViewController;
        if (!nav.navigationBarHidden) {
            targetBaseLine -= nav.navigationBar.frame.size.height;
        }
    }
    if (![UIApplication sharedApplication].isStatusBarHidden) {
        CGRect sbFrame = [UIApplication sharedApplication].statusBarFrame;
        // Use height in portrait, width in landscape;
        if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
            targetBaseLine -= sbFrame.size.width;
        }
        else {
            targetBaseLine -= sbFrame.size.height;
        }
    }
    
    return targetBaseLine;
}

-(void)positionControl:(UIView*)control forKeyboardInView:(UIView*)view {
    
    if (currentView != view) {
        [self restoreView];
        currentViewOriginalPosition = view.frame;
    }
    currentView = view;
    currentControl = control;
    
    UIView* keyboard = [FocusUtil findKeyboard];
    if (!keyboard) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(keyboardWasShown:) 
                                                     name:UIKeyboardDidShowNotification 
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(keyboardWillHide:) 
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];

        return;
    }
    [self adjustScrollingForControl:CGRectNull];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    currentView = nil;
    currentControl = nil;
    [super dealloc];
}

@end

@implementation FocusUtil (Private)

-(void) restoreView {
    if (currentView) {
        if ([currentView isKindOfClass:[UIScrollView class]]) {
            UIScrollView *sv = (UIScrollView *) currentView;

            if (([sv contentOffset].y + sv.frame.size.height) > sv.contentSize.height) {
                CGPoint offset = sv.contentOffset;
                offset.y = MAX(0, sv.contentSize.height - sv.frame.size.height);
                [sv setContentOffset:offset animated:YES];
            }
        }
        // Otherwise move the view frame
        else {
            NSTimeInterval animationDuration = 0.300000011920929;
            [UIView beginAnimations:@"RestoreFromKeyboard" context:nil];
            [UIView setAnimationDuration:animationDuration];
            currentView.frame = currentViewOriginalPosition;
            [UIView commitAnimations];
        }
    }
}

-(void)adjustScrollingForControl:(CGRect)unconvertedKbRect {
    CGRect kbRect;
    if (CGRectIsNull(unconvertedKbRect)) {
        UIView *keyboard = [FocusUtil findKeyboard];
    
        if (!keyboard || !currentControl || !currentView)
            return;
        
        kbRect = keyboard.frame;
    } else {
        kbRect = unconvertedKbRect;
    }
    
    UIScrollView *sv;
    UIView *selfview;
        
    if ([currentView isKindOfClass:[UIScrollView class]]) {
        sv = (UIScrollView*)currentView;
        selfview = currentView.superview;
    } else {
        sv = nil;
        selfview = currentView;
    }
                 
    NSLog(@"kbRect: %@", NSStringFromCGRect(kbRect));
    if (!CGRectIsNull(unconvertedKbRect)) {
        kbRect = [selfview convertRect:unconvertedKbRect fromView:nil];
        NSLog(@"kbRect c: %@", NSStringFromCGRect(kbRect));
    }

    if (sv) {
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbRect.size.height, 0.0);
        sv.contentInset = contentInsets;
        sv.scrollIndicatorInsets = contentInsets;
        NSLog(@"contentInsets: %@", NSStringFromUIEdgeInsets(contentInsets));
    }
    
    CGRect aRect = selfview.frame;
    NSLog(@"aRect: %@", NSStringFromCGRect(aRect));
    aRect.size.height -= kbRect.size.height;
    NSLog(@"aRect -kb: %@", NSStringFromCGRect(aRect));
    aRect.size.height -= _padding;
    NSLog(@"aRect -padding: %@", NSStringFromCGRect(aRect));
    UIApplication *app = [UIApplication sharedApplication];
    if (!app.statusBarHidden) {
        CGRect sbRect = app.statusBarFrame;
        NSLog(@"sb frame: %@", NSStringFromCGRect(sbRect));
        sbRect = [selfview convertRect:sbRect fromView:nil];
        NSLog(@"sb frame c: %@", NSStringFromCGRect(sbRect));
        aRect.size.height -= sbRect.size.height;
        NSLog(@"aRect -sb: %@", NSStringFromCGRect(aRect));
    }
    
    if ([selfview.window.rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *) selfview.window.rootViewController;
        if (!nav.navigationBarHidden) {
            CGRect nbRect = nav.navigationBar.frame;
            NSLog(@"nb frame: %@", NSStringFromCGRect(nbRect));
            aRect.size.height -= nav.navigationBar.frame.size.height;
            NSLog(@"aRect -nb: %@", NSStringFromCGRect(aRect));
        }
    }
    
    CGRect afRect = [selfview convertRect:currentControl.frame fromView:currentControl.superview];
    NSLog(@"currentControl: %@", currentControl);
    NSLog(@"fieldFrame: %@", NSStringFromCGRect(currentControl.frame));
    NSLog(@"afRect: %@", NSStringFromCGRect(afRect));
    
    if (!CGRectContainsRect(aRect, afRect)) {
        NSLog(@"ADJUSTING!");
        
        int y_offset;
        
        if (sv) {
            NSLog(@"af.y:%f af.h:%f sv.h:%f kb.h%f", afRect.origin.y, afRect.size.height, sv.frame.size.height, kbRect.size.height);
            y_offset = 
                (afRect.origin.y + afRect.size.height) // bottom of the control
                - (sv.frame.size.height - sv.contentOffset.y) // take the sv size and position into account
                +  kbRect.size.height // adjust for the kb height
                + _padding;
            
            NSLog(@"y_offset: %d", y_offset);

            [sv setContentOffset:CGPointMake(0, MAX(0,y_offset)) animated:false];
        } else {
            y_offset = (afRect.origin.y + afRect.size.height)
            - (aRect.size.height)
            + _padding;

            NSLog(@"y_offset: %d", y_offset);
            
            CGFloat verticalOffset = MAX(0, y_offset);//MIN(currentViewOriginalPosition.origin.y, y_offset);
            CGRect adjustedPosition = CGRectMake(currentViewOriginalPosition.origin.x, 
                                                 currentViewOriginalPosition.origin.y - verticalOffset, 
                                                 currentViewOriginalPosition.size.width, 
                                                 currentViewOriginalPosition.size.height);
            NSTimeInterval animationDuration = 0.300000011920929;
            [UIView beginAnimations:@"RepositionForKeyboard" context:nil];
            [UIView setAnimationDuration:animationDuration];
            currentView.frame = adjustedPosition;
            [UIView commitAnimations];
        }
    }
}

-(void) keyboardWillHide:(NSNotification*)note {
    [self restoreView];
}

-(void) keyboardWasShown:(NSNotification*)note {
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%s:%@", __PRETTY_FUNCTION__, note);
    CGRect kbRect = [[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self adjustScrollingForControl:kbRect];
}
@end


@implementation UIToolbarWithAccessory
@synthesize delegate;
- (id)init {
    if ((self = [super init])) {
        fields = [[NSMutableArray array] retain];
        
        NSMutableArray *buttons = [[NSMutableArray array] retain];
        
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
        [buttons addObject:button];
        [button release];
        
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [buttons addObject:button];
        [button release];
        
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(nextPressed:)];
        [buttons addObject:button];
        [button release];
        
        [self setItems:buttons];
        [buttons release];
        
        [self sizeToFit];
    }
    return self;
}
- (id)initWithTextFields:(UITextField *)textField,... {
    if ((self = [self init])) {
        va_list argumentList;
        id eachField;
        
        if (textField) {
            [self addTextField:textField];
            va_start(argumentList, textField);
            while ((eachField = va_arg(argumentList, id))) {
                [self addTextField:eachField];
            }
        }
    }
    return self;
}
- (void)nextPressed:(id)sender {
    
    UITextField *nextField = nil;
    
    for (int i = 0; i < [fields count]; i++) {
        UITextField *field = [fields objectAtIndex:i];
        if ([field isFirstResponder]) {
            field = [self nextTextFieldAfter:field visibleOnly:NO allowLooping:YES];
            if ([self.delegate conformsToProtocol:@protocol(UIToolbarWithAccessoryDelegate)] && [self.delegate respondsToSelector:@selector(shouldMoveToTextField:)]) {
                field = [self.delegate shouldMoveToTextField:field];
            }
            if (field != nil) {
                nextField = field;
            }
            break;
        }
    }
    
    if (nextField) {
        if ([self.delegate conformsToProtocol:@protocol(UIToolbarWithAccessoryDelegate)] && [self.delegate respondsToSelector:@selector(willFocusOnTextField:)]) {
            [self.delegate willFocusOnTextField:nextField];
        }
        [nextField becomeFirstResponder];
        if ([self.delegate conformsToProtocol:@protocol(UIToolbarWithAccessoryDelegate)] && [self.delegate respondsToSelector:@selector(didFocusOnTextField:)]) {
            [self.delegate didFocusOnTextField:nextField];
        }
    }
    else {
        [self donePressed:sender];
    }
    
}
- (void)donePressed:(id)sender {
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

- (void)addTextField:(UITextField *)textField {
    if (![fields containsObject:textField]) {
        textField.inputAccessoryView = self;
        [fields addObject:textField];
    }
}

- (void)removeTextField:(UITextField *)textField {
    if ([fields containsObject:textField]) {
        [fields removeObject:textField];
        if (textField.inputAccessoryView == self)
            textField.inputAccessoryView = nil;
    }
}
- (void)setTabOrder:(NSUInteger)index forTextField:(UITextField *)textField {
    if ([fields containsObject:textField] && index != [fields indexOfObject:textField]) {
        id foo = [fields objectAtIndex:index];
        if (foo != nil) {
            [fields removeObject:textField];
            int idx = [fields indexOfObject:foo];
            [fields insertObject:textField atIndex:idx];
        }
        else {
            [fields removeObject:textField];
        }
    }
    
    if (![fields containsObject:textField]) {
        [fields insertObject:textField atIndex:MIN(index, [fields count])];
    }
}

- (BOOL)hasTextField:(UITextField *)textField {
    return [fields containsObject:textField];
}

- (UITextField *)textFieldAtIndex:(NSUInteger)idx {
    return [fields objectAtIndex:idx];
}

- (NSUInteger)count {
    return [fields count];
}


- (NSInteger)indexOfTextField:(UITextField *)textField {
    return [self hasTextField:textField] ? [fields indexOfObject:textField] : -1;
}

- (UITextField *)nextTextFieldAfter:(UITextField *)textField visibleOnly:(BOOL)visibleOnly allowLooping:(BOOL)allowLooping {
    NSInteger idx = [self indexOfTextField:textField];
    UITextField *field = textField;
    int j = idx + 1;
    BOOL looped = NO;
    while (j != idx) {
        if (j >= [fields count]) {
            if (!allowLooping || looped) break;
            j = 0;
            looped = YES;
        }
        field = [fields objectAtIndex:j];
        BOOL visible = visibleOnly ? field.superview != nil && field.window != nil : true;
        if (visible && [field canBecomeFirstResponder]) {
            return field;
        }
        j++;
    }
    return nil;
}

- (void)dealloc {
    [fields release];
    [super dealloc];
}
@end;