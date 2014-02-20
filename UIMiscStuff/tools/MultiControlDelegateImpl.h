//
//  MultiControlDelegateImpl.h
//
//  Created by Beau Scott on 2/19/14.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import <Foundation/Foundation.h>

//
// There's no requirement to actually type these out for support, but it does make code more readable.
//

#pragma mark - UIPickerViewDataSource Blocks
typedef NSInteger (^MCDBlock_PickerViewNumberOfRowsInComponent)(UIPickerView *pickerView, NSInteger component);
typedef NSInteger (^MCDBlock_NumberOfComponentsInPickerView)(UIPickerView *pickerView);

#pragma mark - UIPickerViewDelegate Blocks
typedef CGFloat (^MCDBlock_PickerViewRowHeightForComponent)(UIPickerView *pickerView, NSInteger component);
typedef CGFloat (^MCDBlock_PickerViewWidthForComponent)(UIPickerView *pickerView, NSInteger component);
typedef UIView *(^MCDBlock_PickerViewViewForRowForComponentReusingComponent)(UIPickerView *pickerView, NSInteger row, NSInteger component, UIView *reusingView);
typedef NSString *(^MCDBlock_PickerViewTitleForRowForComponent)(UIPickerView *pickerView, NSInteger row, NSInteger component);
typedef void (^MCDBlock_PickerViewDidSelectRowInComponent)(UIPickerView *pickerView, NSInteger row, NSInteger component);

/**
 * Ad-hoc control delegate implementation.
 * @TODO Add more delegate support
 */
@interface MultiControlDelegateImpl : NSProxy {
@private
    NSMutableDictionary *blocks;
    NSArray *protocols;
}
-(void)setBlock:(id)block forSelector:(SEL)selector;
-(id)initWithProtocols:(Protocol*)protocol,... NS_REQUIRES_NIL_TERMINATION;
-(id)initAsPickerDelegates:(UIPickerView *)pickerView;
-(id)init;
@end
