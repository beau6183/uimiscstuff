//
//  FocusUtil.h
//
//  Created by Beau Scott on 2/19/14.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import <Foundation/Foundation.h>


#define BOTTOM_CONTROL_PADDING 20

@interface FocusUtil : NSObject {
@private
    UIView *currentControl;
    UIView *currentView;
    CGRect currentViewOriginalPosition;
}
@property CGFloat padding;

-(void)positionControl:(UIView*)control forKeyboardInView:(UIView*)view;
+(UIView*)findKeyboard;
+(CGFloat)findKBBaselineInView:(UIView *)view;
@end

@protocol UIToolbarWithAccessoryDelegate <NSObject>
@optional
-(UITextField *)nextFieldAfter:(UITextField *)textField inFields:(NSArray *)fields;
-(UITextField *)shouldMoveToTextField:(UITextField *)textField;
-(void)willFocusOnTextField:(UITextField *)textField;
-(void)didFocusOnTextField:(UITextField *)textField;

@end

@interface UIToolbarWithAccessory : UIToolbar {
    id<UIToolbarWithAccessoryDelegate> delegate;
@private
    NSMutableArray *fields;
}
@property (nonatomic,assign) id<UIToolbarWithAccessoryDelegate> delegate;
- (id)initWithTextFields:(UITextField *)textField,...;
- (void)nextPressed:(id)sender;
- (void)donePressed:(id)sender;
- (void)addTextField:(UITextField *)textField;
- (void)removeTextField:(UITextField *)textField;
- (BOOL)hasTextField:(UITextField *)textField;
- (void)setTabOrder:(NSUInteger)index forTextField:(UITextField *)textField;
- (UITextField *)textFieldAtIndex:(NSUInteger)idx;
- (NSInteger)indexOfTextField:(UITextField *)textField;
- (UITextField *)nextTextFieldAfter:(UITextField *)textField visibleOnly:(BOOL)visibleOnly allowLooping:(BOOL)allowLooping;
- (NSUInteger)count;
@end;

