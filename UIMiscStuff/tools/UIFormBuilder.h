//
//  UIFormBuilder.h
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2011 Beau Scott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FocusUtil.h"

@class UIFormBuilder, UIFormBuilderFormItem, UIFormBuilderEmailFormItem, UIFormBuilderSliderFormItem, UIFormBuilderSwitchFormItem, UIFormBuilderNumericFormItem, UIFormBuilderDatePickerFormItem, UIFormBuilderPickerFormItem;

#define UIFORMBUILDER_NIL_TITLE @"__FB_NIL_TITLE__"
#define UIFORMBUILDER_TEXTFIELD_PADDING 2

@protocol UIFormBuilderValidator <NSObject>
@required
-(BOOL)validate:(id)value;
+(id)new;
@end

@protocol UIFormBuilderSection <NSObject>
@property (nonatomic,retain) NSString *title;
@property (nonatomic,retain) NSString *footer;
@property (readonly) NSUInteger count;
@property (nonatomic,assign) UIFormBuilder *form;
@property (nonatomic) BOOL editable;
-(UITableViewCell *)cellForRow:(NSInteger)row;
-(BOOL)isValid;
@end

#pragma mark - UIFormBuilderSection
@interface UIFormBuilderSection : NSObject <UIFormBuilderSection> {
    NSString *title;
    NSString *footer;
    NSMutableArray *items;
    UIFormBuilder *_form;
    BOOL editable;
}
-(id)initWithTitle:(NSString *)ttl andFooter:(NSString *)ftr;
-(void)addItem:(UIFormBuilderFormItem *)item;
-(void)removeItem:(UIFormBuilderFormItem *)item;
-(void)addItem:(UIFormBuilderFormItem *)item atIndex:(NSInteger)index;
-(UIFormBuilderFormItem *)itemAtIndex:(NSInteger)index;
-(BOOL)containsItem:(UIFormBuilderFormItem *)item;
//Default utility item creation methods
-(UIFormBuilderFormItem *)createFormItemWithLabel:(NSString *)label forField:(NSString *)field;
-(UIFormBuilderEmailFormItem *)createEmailFormItemWithLabel:(NSString *)label forField:(NSString *)field;
-(UIFormBuilderNumericFormItem *)createNumericFormItemWithLabel:(NSString *)label forField:(NSString *)field withFormatter:(NSNumberFormatter*)formatter andMin:(NSDecimalNumber*)min andMax:(NSDecimalNumber*)max andDecimals:(uint)scale;
-(UIFormBuilderSwitchFormItem *)createSwitchFormItemWithLabel:(NSString *)label forField:(NSString *)field;
-(UIFormBuilderSliderFormItem *)createSliderFormItemWithLabel:(NSString *)label forField:(NSString *)field;
-(UIFormBuilderDatePickerFormItem *)createDateFormItemWithLabel:(NSString *)label forField:(NSString *)field;
-(UIFormBuilderPickerFormItem *)createPickerFormItemWithLabel:(NSString *)label options:(NSArray *)options forField:(NSString *)field;
@end

#pragma mark UIFormBuilderCustomSection
@interface UIFormBuilderCustomSection : NSObject <UIFormBuilderSection> {
    @protected
    id<UITableViewDelegate> _delegate;
    id<UITableViewDataSource> _dataSource;
    NSString *_title;
    NSString *_footer;
    NSUInteger _sectionIndex;
}
@property (nonatomic,readonly) id<UITableViewDelegate> delegate;
@property (nonatomic,readonly) id<UITableViewDataSource> dataSource;
@property (nonatomic,readonly) NSUInteger sectionIndex;
-(id)initWithDelegate:(id<UITableViewDelegate>)delegate andDataSource:(id<UITableViewDataSource>)dataSource;
-(id)initWithDelegate:(id<UITableViewDelegate>)delegate andDataSource:(id<UITableViewDataSource>)dataSource withVirtualSectionIndex:(NSUInteger)sectionIndex;
@end;

#pragma mark UIFormBuilderSelectSection
@interface UIFormBuilderSelectSection : NSObject <UIFormBuilderSection> {
    NSString *title;
    NSString *footer;
    NSArray *options;
    NSString *labelField;
    NSString *fieldName;
    BOOL required;
    id currentValue;
    UIFormBuilder *_form;
    BOOL editable;
}
@property (nonatomic,retain) NSArray *options;
@property (nonatomic,retain) NSString *labelField;
@property (nonatomic,retain) NSString *fieldName;
@property (nonatomic) BOOL required;

-(id)initWithTitle:(NSString *)title options:(NSArray *)opts fieldName:(NSString *)fn labelField:(NSString *)lf;
-(void)didSelectRow:(NSInteger)row;
-(BOOL)canSelectRow:(NSInteger)row;

@end

#pragma mark - UIFormBuilderFormItemCell
//---------------------------------------------
// UIFormBuilderFormItemCell
//---------------------------------------------
@class UIFormBuilderFormItem;
@interface UIFormBuilderFormItemCell : UITableViewCell {
    UIControl *control;
@protected
    UIFormBuilderFormItem *_formItem;
    UILabel *reqLabel;
    BOOL isValid;
    BOOL actionsAdded;
    UITextBorderStyle oldStyle;
}
@property (nonatomic, retain) UIControl *control;
-(id)initWithControl:(UIControl *)ctrl forItem:(UIFormBuilderFormItem*)frmItem;
@end

#pragma mark - UIFormBuilderFormItem
//---------------------------------------------
// UIFormBuilderFormItem
//---------------------------------------------
@class UIFormBuilder;
@interface UIFormBuilderFormItem : NSObject {
    UIFormBuilderFormItemCell *renderer;
    NSString *label;
    NSString *fieldName;
    BOOL required;
    id<UIFormBuilderValidator> validator;
    BOOL editable;
@protected
    UIFormBuilderSection *section;
}
@property (nonatomic,retain) UIFormBuilderFormItemCell *renderer;
@property (nonatomic,retain) NSString *fieldName;
@property (nonatomic,retain) NSString *label;
@property (nonatomic) BOOL required;
@property (nonatomic,retain) id<UIFormBuilderValidator> validator;
@property (nonatomic) BOOL editable;
-(id)initForField:(NSString *)fn withLabel:(NSString*)lbl;
-(void)layoutCell;
-(void)markInvalid:(BOOL)valid;
-(BOOL)validateValueAndUpdateData;
@end

#pragma mark UIFormBuilderNumericFormItem
@class NumberFieldDelegateImpl;
@interface UIFormBuilderNumericFormItem : UIFormBuilderFormItem {
    uint decimalPlaces;
    NSDecimalNumber *max;
    NSDecimalNumber *min;
    NumberFieldDelegateImpl *nfd;
    NSNumberFormatter *formatter;
}
@property (nonatomic) uint decimalPlaces;
@property (retain,nonatomic) NSDecimalNumber * max;
@property (retain,nonatomic) NSDecimalNumber * min;
@property (retain,nonatomic) NumberFieldDelegateImpl *nfd;
@property (retain,nonatomic) NSNumberFormatter *formatter;
-(id)initForField:(NSString *)fn withLabel:(NSString*)lbl andFormatter:(NSNumberFormatter*)_fmt andMin:(NSDecimalNumber *)minimum andMax:(NSDecimalNumber *)maximum andDecimals:(uint)decimals;
@end


#pragma mark UIFormBuilderSliderFormItem
@interface UIFormBuilderSliderFormItem : UIFormBuilderFormItem {
    double max;
    double min;
}
@property (nonatomic) double max;
@property (nonatomic) double min;
-(id)initForField:(NSString *)fn withLabel:(NSString*)lbl withMin:(double)minimum andMax:(double)maximum;
@end

#pragma mark UIFormBuilderSwitchFormItem
@interface UIFormBuilderSwitchFormItem : UIFormBuilderFormItem {
}
@end

#pragma mark UIFormBuilderEmailFormItem
@interface UIFormBuilderEmailFormItem : UIFormBuilderFormItem {
}
@end;

#pragma mark UIFormBuilderPickerFormItem
@interface UIFormBuilderPickerFormItem : UIFormBuilderFormItem <UIPickerViewDataSource, UIPickerViewDelegate> {
    NSArray *pickerOptions;
    UIPickerView *picker;
}
@property (nonatomic,retain) NSArray *pickerOptions;
@property (nonatomic,retain) UIPickerView *picker;
-(id)initForField:(NSString *)fn withLabel:(NSString*)lbl withOptions:(NSArray *)options;
@end;

#pragma mark UIFormBuilderDatePickerFormItem
@interface UIFormBuilderDatePickerFormItem : UIFormBuilderFormItem {
    NSDateFormatter *formatter;
    UIDatePicker *dp;
}
@property (nonatomic, assign) NSDate *minimumDate;
@property (nonatomic, assign) NSDate *maximumDate;
@property (nonatomic) UIDatePickerMode mode;
@property (nonatomic, retain) NSDateFormatter *formatter;
@property (nonatomic, retain) UIDatePicker *dp;
-(id)initForField:(NSString *)fn withLabel:(NSString*)lbl withMinDate:(NSDate *)min andMaxDate:(NSDate*)max;
@end;

#pragma mark - UIFormBuilder
//---------------------------------------------
// UIFormBuilder
//---------------------------------------------
@interface UIFormBuilder : NSObject <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, UIToolbarWithAccessoryDelegate> {
    NSObject            *data;
    UITableView         *table;
@protected
    NSMutableArray      *items;
    NSMutableArray      *sectionOrder;
    NSMutableDictionary *sections;
    FocusUtil           *focusUtil;
    UIToolbarWithAccessory              *inputAccView;
    BOOL                editable;
}
@property (nonatomic,retain)   UITableView *table;
@property (nonatomic,retain)   NSObject *data;
@property (readonly) UIToolbarWithAccessory *sharedInputAccessory;
@property (readonly) FocusUtil *focusUtil;
@property (nonatomic) BOOL editable;

-(id)initWithTableView:(UITableView *)table andDataObject:(NSObject *)data;

-(UIFormBuilderSection *)addSectionWithTitle:(NSString *)title;
-(UIFormBuilderSection *)insertSectionWithTitle:(NSString *)title atIndex:(NSInteger)index;
-(void)addSection:(id<UIFormBuilderSection>)section atIndex:(NSInteger)index;
-(NSInteger)indexOfSection:(id<UIFormBuilderSection>)item;
-(id<UIFormBuilderSection>)sectionForIndex:(NSUInteger)index;
-(NSUInteger)numberOfSections;
-(void)removeSection:(id<UIFormBuilderSection>)section;

-(UIFormBuilderSelectSection *)createSelectSectionForField:(NSString *)fieldName labelField:(NSString *)labelField title:(NSString *)title footer:(NSString *)footer options:(NSArray *)options;

-(UIFormBuilderCustomSection *)addCustomSectionWithTitle:(NSString *)title delegate:(id<UITableViewDelegate>)delegate andDataSource:(id<UITableViewDataSource>)dataSource;

-(BOOL)validate;
@end

#pragma mark - Validators


@interface FBStringValidator : NSProxy <UIFormBuilderValidator> {
    NSInteger minLength;
    NSInteger maxLength;
}
@property (nonatomic) NSInteger minLength;
@property (nonatomic) NSInteger maxLength;
-(id)init;
-(id)initWithMinLength:(NSInteger)min maxLength:(NSInteger)max;
@end;

@interface FBEmailValidator : FBStringValidator <UIFormBuilderValidator> {
    NSArray *validDomains;
    NSArray *invalidDomains;
}
@property (nonatomic, retain) NSArray *validDomains;
@property (nonatomic, retain) NSArray *invalidDomains;
-(id)init;
-(id)initWithInvalidDomains:(NSArray*)idoms validDomains:(NSArray*)vdoms;
@end

@interface FBNumericValidator : NSProxy <UIFormBuilderValidator> {
    double minimum;
    double maximum;
}
@property (nonatomic) double minimum;
@property (nonatomic) double maximum;
-(id)init;
-(id)initWithMinValue:(double)min maxValue:(double)max;
@end;