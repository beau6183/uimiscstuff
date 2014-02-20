//
//  UIAlertView+Closure.m
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import "UIAlertView+Closure.h"

@interface UIAlertViewClosureDelegateImpl:NSObject <UIAlertViewDelegate> {
    AlertViewClosure _callback;
@private

}
@property (copy,nonatomic) AlertViewClosure callback;
-(id)initWithCallback:(AlertViewClosure)callBack;
@end

@interface UIAlertView (ClosurePrivate)

@end

@implementation UIAlertView (Closure)
+(id)showAlertWithTitle:(NSString *)title message:(NSString *)message buttonLabel:(NSString *)btnLabel {
    UIAlertView *a = [[[UIAlertView alloc] initWithTitle:title message:message callBack:nil cancelButtonTitle:btnLabel otherButtonTitles:nil] autorelease];
    [a show];
    return a;
}

-(id)initWithTitle:(NSString *)title message:(NSString *)message 
                       callBack:(AlertViewClosure)callback 
              cancelButtonTitle:(NSString *)cancelTitle 
              otherButtonTitles:(NSString *)otherButtonTitles, ... {
    
    if ((self = [self initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelTitle otherButtonTitles:nil])) {
        va_list argumentList;
        id eachField;
        if (otherButtonTitles) {
            [self addButtonWithTitle:otherButtonTitles];
            va_start(argumentList, otherButtonTitles);
            while ((eachField = va_arg(argumentList, id))) {
                [self addButtonWithTitle:eachField];
            }
        }
        
        UIAlertViewClosureDelegateImpl *delegate = [[UIAlertViewClosureDelegateImpl alloc] initWithCallback:callback];
        self.delegate = delegate;
        [delegate release];
    }
    
    return self;
}

-(void)setCallBack:(AlertViewClosure)callBack {
    if ([self.delegate isKindOfClass:[UIAlertViewClosureDelegateImpl class]]) {
        ((UIAlertViewClosureDelegateImpl*)self.delegate).callback = callBack;
    }
}

-(AlertViewClosure)callBack {
    if ([self.delegate isKindOfClass:[UIAlertViewClosureDelegateImpl class]]) {
        return ((UIAlertViewClosureDelegateImpl*)self.delegate).callback;
    }
    return nil;
}

@end

@implementation UIAlertViewClosureDelegateImpl
-(id)init {
    if ((self = [super init])) {
        _callback = nil;
    }
    return self;
}
-(id)initWithCallback:(AlertViewClosure)callBack {
    if ((self = [self init])) {
        self.callback = callBack;
        [self retain]; //hack, alertview delegates are assign
    }
    return self;
}

-(AlertViewClosure)callback {
    return _callback;
}
-(void)setCallback:(AlertViewClosure)callback {
    if (_callback != nil) {
        Block_release(_callback);
    }
    if (callback != nil) {
        _callback = Block_copy(callback);
    }
    else {
        _callback = nil;
    }
}

-(void)dealloc {
    if (_callback != nil) {
        Block_release(_callback);
    }
    [super dealloc];
}

#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    BOOL isCancel = buttonIndex == alertView.cancelButtonIndex;
    if (_callback != nil) {
        _callback(alertView, buttonIndex, isCancel);
        [self release]; //hack, alertview delegates are assign
    }
}

@end
