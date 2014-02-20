//
//  UIFormBuilder.m
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIFormBuilder.h"
#import "NSString+Util.h"
#import "FocusUtil.h"
#import "NumberFieldDelegateImpl.h"

#pragma mark - Internal Interfaces
//---------------------------------------------
// UIFormBuilderFormItem (internal)
//---------------------------------------------
@interface UIFormBuilderFormItem (internal)
@property (nonatomic, assign) UIFormBuilderSection *section;
@property (nonatomic,readonly) UIFormBuilderFormItemCell *_renderer;
-(void)updateControlValue;
-(id)formDataValue;
-(void)clearBindings;
-(void)addBindings;
-(void)updateControlEditability;
-(BOOL)containsControl:(UIControl *)ctrl;
@end

//---------------------------------------------
// UIFormBuilderFormItemCell (internal)
//---------------------------------------------
@interface UIFormBuilderFormItemCell (internal)
@property (nonatomic, assign) UIFormBuilderFormItem *formItem;
-(void)clearActions;
-(void)addActions;
-(void)resetValidation:(BOOL)valid;
-(void)controlValueChanged;
-(void)controlDidBeginEditing;
-(UITextBorderStyle)originalBorderStyle;
@end;

//---------------------------------------------
// UIFormBuiilderSection (internal)
//---------------------------------------------
@interface UIFormBuilderSection (internal)
-(NSInteger)indexOfItem:(UIFormBuilderFormItem *)item;
@end

//---------------------------------------------
// UIFormBuilderSelectSection (internal)
//---------------------------------------------
@interface UIFormBuilderSelectSection (internal)
-(void)clearBindings;
-(void)addBindings;
-(void)rowSelected:(NSInteger)row;
@end

//---------------------------------------------
// UIFormBuilder (internal)
//---------------------------------------------
@interface UIFormBuilder (internal)
//-(NSInteger)indexOfSectionWithTitle:(NSString *)title;
//-(NSInteger)indexOfSection:(id<UIFormBuilderSection>)sect;
-(void)refreshSection:(id<UIFormBuilderSection>)section;
-(UIFormBuilderFormItem *)itemForControl:(UIControl *)ctrl;
-(void)registerTextFieldWithFocusUtil:(UITextField *)tf;
@end


#pragma mark - UIFormBuilder
//---------------------------------------------
// UIFormBuilder
//---------------------------------------------
@implementation UIFormBuilder
@synthesize table;
@synthesize data;
@synthesize editable;
-(void)setTable:(UITableView *)t {
    table.delegate = nil;
    table.dataSource = nil;
    [table release];
    table = [t retain];
    table.delegate = self;
    table.dataSource = self;
}

-(id)init {
    self = [super init];
    editable = YES;
    focusUtil = [[FocusUtil alloc] init];
    inputAccView = [[UIToolbarWithAccessory alloc] initWithTextFields:nil];
    inputAccView.delegate = self;
    items = [NSMutableArray new];
    sectionOrder = [NSMutableArray new];
    sections = [NSMutableDictionary new];
    data = nil;
    return self;
}

-(id)initWithTableView:(UITableView *)t andDataObject:(NSObject *)somedata {
    if ((self = [self init])) {
        self.data = somedata;
        self.table = t;
    }
    return self;
}

-(FocusUtil *)focusUtil {
    return focusUtil;
}

-(UIToolbar *)sharedInputAccessory {
    return inputAccView;
}

-(UIFormBuilderCustomSection *)addCustomSectionWithTitle:(NSString *)title delegate:(id<UITableViewDelegate>)delegate andDataSource:(id<UITableViewDataSource>)dataSource {
    UIFormBuilderCustomSection *s = [[[UIFormBuilderCustomSection alloc] initWithDelegate:delegate andDataSource:dataSource] autorelease];
    s.title = title;
    [self addSection:s atIndex:[sectionOrder count]];
    return s;
}

-(UIFormBuilderSection *)addSectionWithTitle:(NSString *)title {
    return [self insertSectionWithTitle:title atIndex:[sectionOrder count]];
}

-(UIFormBuilderSection *)insertSectionWithTitle:(NSString *)title atIndex:(NSInteger)index {
    if (!title) title = UIFORMBUILDER_NIL_TITLE;
    UIFormBuilderSection *s = [sections objectForKey:title];
    if (s == nil) {
        s = [[[UIFormBuilderSection alloc] initWithTitle:title andFooter:nil] autorelease];
    }
    [self addSection:s atIndex:index];
    return s;
}

-(void)addSection:(id<UIFormBuilderSection>)section atIndex:(NSInteger)index {
    if (![sectionOrder containsObject:section]) {
        [sectionOrder insertObject:section atIndex:index];
    }
    else {
        NSInteger idx = [sectionOrder indexOfObject:section];
        if (idx != index) {
            id old = [sectionOrder objectAtIndex:index];
            [sectionOrder removeObject:section];
            [sectionOrder insertObject:section atIndex:[sectionOrder indexOfObject:old]];
        }
    }
    if (section.form != nil && section.form != self) {
        [section.form removeSection:section];
    }
    NSString *t = section.title;
    if (!t) t = UIFORMBUILDER_NIL_TITLE;
    [sections setObject:section forKey:t];
    section.form = self;
    [self.table reloadData];
}

-(void)removeSection:(id<UIFormBuilderSection>)section {
    if ([sectionOrder containsObject:section]) {
        [sectionOrder removeObject:section];
        NSArray *ks = [sections allKeysForObject:section];
        for (NSString *k in ks) {
            [sections removeObjectForKey:k];
        }
        section.form = nil;
    }
}

-(NSInteger)indexOfSection:(id<UIFormBuilderSection>)item {
    if ([sectionOrder containsObject:item]) {
        return [sectionOrder indexOfObject:item];
    }
    return -1;
}

-(id<UIFormBuilderSection>)sectionForIndex:(NSUInteger)index {
    return [sectionOrder objectAtIndex:index];
}

-(NSUInteger)numberOfSections {
    return [sectionOrder count];
}

-(UIFormBuilderSelectSection *)createSelectSectionForField:(NSString *)fieldName labelField:(NSString *)labelField title:(NSString *)title footer:(NSString *)footer options:(NSArray *)options {
    NSString *t = title;
    if (t == nil) {
        t = UIFORMBUILDER_NIL_TITLE;
    }
    id s = [sections objectForKey:t];
    UIFormBuilderSelectSection *ss = nil;
    if (s && ![s isKindOfClass:[UIFormBuilderSelectSection class]]) {
        NSString *r = [NSString stringWithFormat:@"A section titled %@ already exists of a different section type.", title];
        @throw [NSException exceptionWithName:@"Invalid section name" reason:r userInfo:nil];
    }
    else if (!s) {
        ss = [[[UIFormBuilderSelectSection alloc] initWithTitle:title options:options fieldName:fieldName labelField:labelField] autorelease];
        [self addSection:ss atIndex:[sectionOrder count]];
    }
    else {
        ss = s;
        ss.options = options;
        ss.fieldName = fieldName;
    }
    ss.footer = footer;
    
    return ss;
}


-(BOOL)validate {
    BOOL v = YES;
    for (id<UIFormBuilderSection> s in sectionOrder) {
        v = [s isValid] && v;
    }
    return v;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    id<UIFormBuilderSection> s = [self sectionForIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            [section.delegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:ip];
        }
    }
}
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderSelectSection class]]) {
        UIFormBuilderSelectSection *sect = s;
        if (editable && sect.editable && [sect canSelectRow:indexPath.row]) {
            return indexPath;
        }
    }
    else if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            ip = [section.delegate tableView:tableView willSelectRowAtIndexPath:ip];
            if (ip != nil) {
                return [NSIndexPath indexPathForRow:ip.row inSection:indexPath.section];
            }
            return nil;
        }
        return indexPath;
    }
    return nil;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<UIFormBuilderSection> s = [self sectionForIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:willDeselectRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            ip = [section.delegate tableView:tableView willDeselectRowAtIndexPath:ip];
            if (ip != nil) {
                return [NSIndexPath indexPathForRow:ip.row inSection:indexPath.section];
            }
            return nil;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //TODO add hook
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderSelectSection class]]) {
        UIFormBuilderSelectSection *sect = s;
        if (editable && sect.editable) {
            [sect rowSelected:indexPath.row];
        }
    }
    else if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            [section.delegate tableView:tableView didSelectRowAtIndexPath:ip];
                //Commented for now... gotta resolve some indexpath logic (should the index path be changed?? probably not)
//            return; //
        }
    }
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
}
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            [section.delegate tableView:tableView didDeselectRowAtIndexPath:ip];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:editingStyleForRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            return [section.delegate tableView:tableView editingStyleForRowAtIndexPath:ip];
        }
    }
    return UITableViewCellEditingStyleNone;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            return [section.delegate tableView:tableView titleForDeleteConfirmationButtonForRowAtIndexPath:ip];
        }
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            [section.delegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:ip];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            return [section.delegate tableView:tableView heightForRowAtIndexPath:ip];
        }
    }
    return tableView.rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)sect {
    id s = [sectionOrder objectAtIndex:sect];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
            return [section.delegate tableView:tableView heightForHeaderInSection:section.sectionIndex];
        }
    }

    // for some reason, even though we're setting this table to be
    // grouped, if you check the style, it says plain and sectionHeaderHeight==10
    // instead of 22 like it "should" be...
    return 22;// tableView.sectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)sect {
    id s = [sectionOrder objectAtIndex:sect];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:heightForFooterInSection:)]) {
            return [section.delegate tableView:tableView heightForFooterInSection:section.sectionIndex];
        }
    }
    // for some reason, even though we're setting this table to be
    // grouped, if you check the style, it says plain and sectionHeaderHeight==10
    // instead of 22 like it "should" be...
    return 22;//tableView.sectionFooterHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sect {
    id s = [sectionOrder objectAtIndex:sect];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
            return [section.delegate tableView:tableView viewForHeaderInSection:section.sectionIndex];
        }
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)sect {
    id s = [sectionOrder objectAtIndex:sect];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:viewForFooterInSection:)]) {
            return [section.delegate tableView:tableView viewForFooterInSection:section.sectionIndex];
        }
    }
    return nil;
}

-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:shouldIndentWhileEditingRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            return [section.delegate tableView:tableView shouldIndentWhileEditingRowAtIndexPath:ip];
        }
    }
    return NO;
}

-(void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:willBeginEditingRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            return [section.delegate tableView:tableView willBeginEditingRowAtIndexPath:ip];
        }
    }
}

-(void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.delegate respondsToSelector:@selector(tableView:didEndEditingRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            [section.delegate tableView:tableView didEndEditingRowAtIndexPath:ip];
        }
    }
}

#pragma mark UITableViewDataSource
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.dataSource respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            return [section.dataSource tableView:tableView canEditRowAtIndexPath:ip];
        }
    }
    return NO;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.dataSource respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            return [section.dataSource tableView:tableView canMoveRowAtIndexPath:ip];
        }
    }
    return NO;
}


-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    id s = [sectionOrder objectAtIndex:indexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.dataSource respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:indexPath.row inSection:section.sectionIndex];
            [section.dataSource tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:ip];
        }
    }
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    id s = [sectionOrder objectAtIndex:sourceIndexPath.section];
    if ([s isKindOfClass:[UIFormBuilderCustomSection class]]) {
        UIFormBuilderCustomSection *section = (UIFormBuilderCustomSection *) s;
        if ([section.dataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:sourceIndexPath.row inSection:section.sectionIndex];
            NSIndexPath *dip = [NSIndexPath indexPathForRow:destinationIndexPath.row inSection:section.sectionIndex];
            [section.dataSource tableView:tableView moveRowAtIndexPath:ip toIndexPath:dip];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[sectionOrder objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<UIFormBuilderSection> sect = [sectionOrder objectAtIndex:indexPath.section];
    return [sect cellForRow:indexPath.row];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sectionOrder count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section; {
    id<UIFormBuilderSection> s = [sectionOrder objectAtIndex:section];
    return s.title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    id<UIFormBuilderSection> s = [sectionOrder objectAtIndex:section];
    return s.footer;
}

#pragma mark UIToolbarWithAccessoryDelegate
//-(UITextField *)shouldMoveToTextField:(UITextField *)textField {
//    return textField;
//}

-(void)willFocusOnTextField:(UITextField *)textField {
    UIFormBuilderFormItem *fi = [self itemForControl:textField];
    if (fi != nil) {
        NSIndexPath *p = nil;
        if (fi._renderer != nil) {
            p = [self.table indexPathForCell:fi._renderer];
        }
        if (p == nil) {
            NSInteger s = [sectionOrder indexOfObject:fi.section];
            NSInteger r = [fi.section indexOfItem:fi];
            p = [NSIndexPath indexPathForRow:r inSection:s];
            [self.table scrollToRowAtIndexPath:p atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        }    
    }
}

-(void)didFocusOnTextField:(UITextField *)textField {

}

-(UITextField *)nextFieldAfter:(UITextField *)textField inFields:(NSArray *)fields {
    return nil;
}

#pragma mark Memory Management
-(void) dealloc {
    [focusUtil release];
    [table release];
    [data release];
    [items release];
    [sectionOrder release];
    [sections release];
    [super dealloc];
}

@end

#pragma mark UIFormBuilder (internal)

//---------------------------------------------
// UIFormBuilderSection (internal)
//---------------------------------------------
@implementation UIFormBuilder (internal)
-(void)refreshSection:(id<UIFormBuilderSection>)section {
    if (self.table != nil && [sectionOrder containsObject:section]) {
        // This was causing a layout issue, will fix later.
//        NSUInteger idx = [sectionOrder indexOfObject:section];
//        NSIndexSet *s = [NSIndexSet indexSetWithIndex:idx];
//        [self.table reloadSections:s withRowAnimation:YES];
        [self.table reloadData];
    }
}

-(UIFormBuilderFormItem *)itemForControl:(UIControl *)ctrl {
    for (id<UIFormBuilderSection> s in sectionOrder) {
        if ([s isKindOfClass:[UIFormBuilderSection class]]) {
            UIFormBuilderSection *sect = (UIFormBuilderSection *) s;
            for (uint i = 0; i < [sect count]; i++) {
                UIFormBuilderFormItem *fi = [sect itemAtIndex:i];
                if ([fi containsControl:ctrl]) {
                    return fi;
                }
            }
        }
    }
    return nil;
}

-(NSUInteger)calcEditorRowPosition:(UIFormBuilderFormItem *)fi {
    NSInteger s = [self indexOfSection:fi.section] - 1, r = [fi.section indexOfItem:fi];
    while (s > -1) {
        int c = [[self sectionForIndex:s] count];
        if (c > 0)
            r += c;
        s--;
    }
    return r;
}

-(void)registerTextFieldWithFocusUtil:(UITextField *)tf {
    UIFormBuilderFormItem *fi = [self itemForControl:tf];
    if (fi != nil) {
        NSUInteger r1 = [self calcEditorRowPosition:fi];
        uint i = 0;
        for (i = 0; i < [self.sharedInputAccessory count]; i++) {
            UITextField *tt = [self.sharedInputAccessory textFieldAtIndex:i];
            NSUInteger r2 = [self calcEditorRowPosition:[self itemForControl:tt]];
            NSLog(@"Comparing r1:%i r2:%i", r1, r2);
            if (r2 > r1) {
                NSLog(@"Inserting control for fi: %i-%@ at index %i", r1, fi.fieldName, i);
                [self.sharedInputAccessory setTabOrder:i forTextField:tf];
                return;
            }
        }
        NSLog(@"Adding control for fi: %i-%@ at index %i", r1, fi.fieldName, i);
        [self.sharedInputAccessory addTextField:tf];
    }
}

@end


#pragma mark - UIFormBuilderSection
//---------------------------------------------
// UIFormBuilderSection
//---------------------------------------------
@implementation UIFormBuilderSection
@synthesize title, footer, editable;
-(void)setForm:(UIFormBuilder *)f {
    _form = f;
}

-(UIFormBuilder *)form {
    return _form;
}
-(id)init {
    self = [super init];
    items = [NSMutableArray new];
    _form = nil;
    title = nil;
    editable = YES;
    footer = nil;
    return self;
}
-(id)initWithTitle:(NSString *)ttl andFooter:(NSString *)ftr {
    self = [self init];
    self.title = ttl;
    self.footer = ftr;
    return self;
}

-(UIFormBuilderFormItem *)createFormItemWithLabel:(NSString *)label forField:(NSString *)field {
    UIFormBuilderFormItem *fi = [[[UIFormBuilderFormItem alloc] initForField:field withLabel:label] autorelease];
    [self addItem:fi];
    return fi;
}
-(UIFormBuilderEmailFormItem *)createEmailFormItemWithLabel:(NSString *)label forField:(NSString *)field {
    UIFormBuilderEmailFormItem *fi = [[[UIFormBuilderEmailFormItem alloc] initForField:field withLabel:label] autorelease];
    [self addItem:fi];
    return fi;
}
-(UIFormBuilderNumericFormItem *)createNumericFormItemWithLabel:(NSString *)label forField:(NSString *)field withFormatter:(NSNumberFormatter*)formatter andMin:(NSDecimalNumber*)min andMax:(NSDecimalNumber*)max andDecimals:(uint)scale {
    UIFormBuilderNumericFormItem *fi = [[[UIFormBuilderNumericFormItem alloc] initForField:field withLabel:label andFormatter:formatter andMin:min andMax:max andDecimals:scale] autorelease];
    [self addItem:fi];
    return fi;
}
-(UIFormBuilderSwitchFormItem *)createSwitchFormItemWithLabel:(NSString *)label forField:(NSString *)field {
    UIFormBuilderSwitchFormItem *fi = [[[UIFormBuilderSwitchFormItem alloc] initForField:field withLabel:label] autorelease];
    [self addItem:fi];
    return fi;
}
-(UIFormBuilderSliderFormItem *)createSliderFormItemWithLabel:(NSString *)label forField:(NSString *)field {
    UIFormBuilderSliderFormItem *fi = [[[UIFormBuilderSliderFormItem alloc] initForField:field withLabel:label] autorelease];
    [self addItem:fi];
    return fi;
}
-(UIFormBuilderDatePickerFormItem *)createDateFormItemWithLabel:(NSString *)label forField:(NSString *)field {
    UIFormBuilderDatePickerFormItem *fi = [[[UIFormBuilderDatePickerFormItem alloc] initForField:field withLabel:label] autorelease];
    [self addItem:fi];
    return fi;
}

-(UIFormBuilderPickerFormItem *)createPickerFormItemWithLabel:(NSString *)label options:(NSArray *)options forField:(NSString *)field {
    UIFormBuilderPickerFormItem *fi = [[[UIFormBuilderPickerFormItem alloc] initForField:field withLabel:label withOptions:options] autorelease];
    [self addItem:fi];
    return fi;
}

-(void)dealloc {
    [title release];
    [footer release];
    [items release];
    [super dealloc];
}
-(UITableViewCell *)cellForRow:(NSInteger)row {
    return [[items objectAtIndex:row] renderer];
}
-(NSUInteger)count {
    return [items count];
}
-(void)addItem:(UIFormBuilderFormItem *)item {
    [self addItem:item atIndex:[items count]];
}
-(void)removeItem:(UIFormBuilderFormItem *)item {
    if ([items containsObject:item]) {
        [items removeObject:item];
        if (self.form != nil) {
            [self.form refreshSection:self];
        }
    }
    item.section = nil;
}
-(void)addItem:(UIFormBuilderFormItem *)item atIndex:(NSInteger)index {
    if ([self containsItem:item]) {
        if ([items indexOfObject:item] != index) {
            if (index == 0) {
                [items insertObject:items atIndex:index];
            }
            else if (index >= [items count]) {
                [items addObject:item];
            }
            else {
                id old = [items objectAtIndex:index];
                [items removeObject:item];
                [items insertObject:items atIndex:[items indexOfObject:old]];
            }
        }
    }
    else {
        if (item.section != nil) {
            [item.section removeItem:item];
        }
        [items insertObject:item atIndex:index];
    }
    item.section = self;
    if (self.form != nil) {
        [self.form refreshSection:self];
    }
}
-(UIFormBuilderFormItem *)itemAtIndex:(NSInteger)index {
    return [items objectAtIndex:index];
}

-(BOOL)containsItem:(UIFormBuilderFormItem *)item {
    return [items containsObject:item];
}

-(NSInteger)indexOfItem:(UIFormBuilderFormItem *)item {
    if ([self containsItem:item]) {
        return [items indexOfObject:item];
    }
    return -1;
}

-(BOOL)isValid {
    BOOL v = YES;
    for (UIFormBuilderFormItem *item in items) {
        BOOL cv = [item validateValueAndUpdateData];
        if (!cv) {
            v = NO;
            [item.renderer resetValidation:NO];
        }
    }
    return v;
}

@end;


#pragma mark - UIFormBuilderCustomSection
//---------------------------------------------
// UIFormBuilderCustomSection
//---------------------------------------------
@implementation UIFormBuilderCustomSection
@synthesize form = _form;
@synthesize title = _title;
@synthesize footer = _footer;
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize sectionIndex = _sectionIndex;

-(NSString *)title {
    if (_title != nil) {
        return _title;
    }
    if ([_dataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)]) {
        return [_dataSource tableView:self.form.table titleForHeaderInSection:_sectionIndex];
    }
    return nil;
}

-(NSString *)footer {
    if (_footer != nil) {
        return _footer;
    }
    if ([_dataSource respondsToSelector:@selector(tableView:titleForFooterInSection:)]) {
        return [_dataSource tableView:self.form.table titleForFooterInSection:_sectionIndex];
    }
    return nil;
}
-(NSUInteger)count {
    return [_dataSource tableView:self.form.table numberOfRowsInSection:_sectionIndex];
}

-(void)setEditable:(BOOL)editable {
    // does nothing
}

-(BOOL)editable {
    return NO;
}

-(id)initWithDelegate:(id<UITableViewDelegate>)delegate andDataSource:(id<UITableViewDataSource>)dataSource {
    return [self initWithDelegate:delegate andDataSource:dataSource withVirtualSectionIndex:0];
}

-(id)initWithDelegate:(id<UITableViewDelegate>)delegate andDataSource:(id<UITableViewDataSource>)dataSource withVirtualSectionIndex:(NSUInteger)sectionIndex {
    if ((self = [self init])) {
        _delegate = [delegate retain];
        _dataSource = [dataSource retain];
        _sectionIndex = sectionIndex;
    }
    return self;
}

-(UITableViewCell *)cellForRow:(NSInteger)row {
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:_sectionIndex]; 
    return [_dataSource tableView:self.form.table cellForRowAtIndexPath:path];
}
-(BOOL)isValid {
    return YES;
}

-(void)dealloc {
    [_delegate release];
    [_dataSource release];
    [super dealloc];
}

@end
#pragma mark - UIFormBuilderSelectSection
//---------------------------------------------
// UIFormBuilderSelectSection
//---------------------------------------------
@implementation UIFormBuilderSelectSection
@synthesize options, labelField, fieldName, title, footer, required, editable;
-(void)setForm:(UIFormBuilder *)form {
    [self clearBindings];
    _form = form;
    [self addBindings];
}

-(UIFormBuilder *)form {
    return _form;
}
-(void)setOptions:(NSArray *)opts {
    [self clearBindings];
    if (options != nil) {
        [options release];
        options = nil;
    }
    options = [opts retain];
    [self addBindings];
}
-(void)setFieldName:(NSString *)fn {
    [self clearBindings];
    if (fieldName != nil) {
        [fieldName release];
        fieldName = nil;
    }
    fieldName = [fn retain];
    [self addBindings];
}
-(NSUInteger)count {
    return [self.options count];
}

-(id)init {
    self = [super init];
    editable = YES;
    return self;
}

-(id)initWithTitle:(NSString *)t options:(NSArray *)opts fieldName:(NSString *)fn labelField:(NSString *)lf {
    if ((self = [self init])) {
        self.title = t;
        self.options = opts;
        self.fieldName = fn;
        self.labelField = lf;
    }
    return self;
}

-(void)dealloc {
    [labelField release];
    fieldName = nil;
    [title release];
    [footer release];
    [super dealloc];
}

-(BOOL)isValid {
    if (self.fieldName != nil) {
        id v = [self.form.data valueForKeyPath:self.fieldName];
        if (self.required && v == nil) {
            return NO;
        }
    }
    return YES;
}

-(UITableViewCell *)cellForRow:(NSInteger)row {
    static NSString *CELL_ID = nil;
    if (CELL_ID == nil) {
        CELL_ID = [[NSNumber numberWithDouble:(floor(rand() * 100000))] stringValue];
    }
    UITableViewCell * cell = [self.form.table dequeueReusableCellWithIdentifier:CELL_ID];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_ID] autorelease];
    }
    id d = [self.options objectAtIndex:row];
    cell.textLabel.text = self.labelField != nil ? [d valueForKeyPath:self.labelField] : d;
    cell.accessoryType = (currentValue != nil && [currentValue isEqual:d]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}
-(BOOL)canSelectRow:(NSInteger)row {
    return YES;
}

-(void)didSelectRow:(NSInteger)row {
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:[@"data." stringByAppendingString:self.fieldName]]) {
        id v = [self.form valueForKeyPath:keyPath];
        if (![v isEqual:currentValue]) {
            currentValue = v;
            [self.form refreshSection:self];
        }
    }
}

@end

#pragma mark UIFormBuilderSelectSection (internal)
@implementation UIFormBuilderSelectSection (internal)

-(void)rowSelected:(NSInteger)row {
    id d = [self.options objectAtIndex:row];
    if (self.fieldName && ![d isEqual:currentValue]) {
        NSString *f = [@"data." stringByAppendingString:self.fieldName];
        [self.form setValue:d forKeyPath:f];
        [self didSelectRow:row];
    }
}
-(void)clearBindings {
    if (self.form && self.fieldName) {
        [self.form removeObserver:self forKeyPath:[@"data." stringByAppendingString:self.fieldName]];
    }
}
-(void)addBindings {
    if (self.form && self.fieldName) {
        [self.form addObserver:self forKeyPath:[@"data." stringByAppendingString:self.fieldName] options:NSKeyValueObservingOptionNew context:nil];
    }    
}
@end

#pragma mark - UIFormBuilderFormItemCell

//---------------------------------------------
// UIFormBuilderFormItemCell
//---------------------------------------------
@implementation UIFormBuilderFormItemCell

-(void)setControl:(UIControl *)ctrl {
    [self clearActions];
    if (control) {
        [control release];
        control = nil;
    }
    control = [ctrl retain];
    [self addActions];
}
-(UIControl*)control {
    return control;
}

-(id)initWithControl:(UIControl *)ctrl forItem:(UIFormBuilderFormItem*)frmItem {
    if ((self = [self initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil])) {
        self.control = ctrl;
        isValid = YES;
        [self addSubview:ctrl];
        [self.contentView addSubview:ctrl];
        self.formItem = frmItem;
        reqLabel = [UILabel new];
        [self.contentView addSubview:reqLabel];
    }
    return self;
}
-(void)layoutSubviews {
    self.textLabel.text = self.formItem.label;
    [super layoutSubviews];
    if (self.formItem.required) {
        reqLabel.hidden = false;
        reqLabel.text = @"*";
        reqLabel.font = self.textLabel.font;
        reqLabel.textColor = [UIColor redColor];
        CGRect f = self.textLabel.frame;
        CGRect n = CGRectMake(f.origin.x, f.origin.y, f.size.width, f.size.height);
        n.size.width = f.origin.x;
        n.origin.x = f.origin.x + f.size.width;
        reqLabel.frame = n;
    }
    else {
        reqLabel.hidden = true;
    }
    [self.formItem layoutCell];
    [self.formItem markInvalid:isValid];
}

-(void)controlValueChanged {
    BOOL wasValid = isValid;
    isValid = [self.formItem validateValueAndUpdateData];
    if (wasValid != isValid) {
        [self setNeedsLayout];
    }
    if ([self.control isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField * )self.control;
        if (tf.borderStyle != oldStyle) {
            tf.borderStyle = oldStyle;
            [self setNeedsLayout];
        }
    }
}

-(void)dealloc {
    self.control = nil;
    self.formItem = nil;
    [super dealloc];
}

//---------------------------------------------
// UIFormBuilderFormItemCell (internal)
//---------------------------------------------
#pragma mark UIFormBuilderFormItemCell (internal)

-(void)resetValidation:(BOOL)valid {
    if (isValid != valid) {
        isValid = valid;
        [self setNeedsLayout];
    }
}

-(UIFormBuilderFormItem*)formItem {
    return _formItem;
}
-(void)setFormItem:(UIFormBuilderFormItem *)frmItem {
    _formItem = frmItem;
}

-(void)clearActions {
    if (control && actionsAdded) {
        [control removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
        [control removeTarget:self action:NULL forControlEvents:UIControlEventEditingDidEnd];
        [control removeTarget:self action:NULL forControlEvents:UIControlEventEditingDidEndOnExit];
        actionsAdded = NO;
    }
}

-(void)controlDidBeginEditing {
    [self.formItem.section.form.focusUtil positionControl:self.control forKeyboardInView:self.formItem.section.form.table];
    if ([self.control isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField * )self.control;
        if (tf.borderStyle != UITextBorderStyleRoundedRect) {
            oldStyle = tf.borderStyle;
            tf.borderStyle = UITextBorderStyleRoundedRect;
            [self setNeedsLayout];
        }
    }
}

-(void)addActions {
    if (control && !actionsAdded) {
        if ([control isKindOfClass:[UITextField class]]) {
            [(UITextField*)control addTarget:self action:@selector(controlValueChanged) forControlEvents:UIControlEventEditingDidEndOnExit];
            [(UITextField*)control addTarget:self action:@selector(controlValueChanged) forControlEvents:UIControlEventEditingDidEnd];
            [(UITextField*)control addTarget:self action:@selector(controlDidBeginEditing) forControlEvents:UIControlEventEditingDidBegin];
        }
        else {
            [control addTarget:self action:@selector(controlValueChanged) forControlEvents:UIControlEventValueChanged];
        }
        actionsAdded = YES;
    }
}

@end



#pragma mark - UIFormBuilderFormItem
//---------------------------------------------
// UIFormBuilderFormItem
//---------------------------------------------
@implementation UIFormBuilderFormItem
@synthesize renderer;
@synthesize required;
@synthesize validator;
@synthesize editable;
@synthesize label;

-(NSString *)fieldName {
    return fieldName;
}

-(UIFormBuilderFormItemCell *)_renderer {
    return renderer;
}
         
-(void)setFieldName:(NSString *)fn {
    [self clearBindings];
    [fieldName release];
    fieldName = [fn retain];
    [self addBindings];
}

-(id)init {
    self = [super init];
    self.required = NO;
    self.editable = YES;
    return self;
}

-(id)initForField:(NSString *)fn withLabel:(NSString*)lbl{
    if ((self = [self init])) {
        self.fieldName = fn;
        self.label = lbl;
    }
    return self;
}

-(UIFormBuilderFormItemCell *)renderer {
    if (renderer == nil) {
        UITextField *tf = [UITextField new];
        tf.keyboardType = UIKeyboardTypeDefault;
        tf.autocorrectionType = UITextAutocorrectionTypeYes;
        tf.inputAccessoryView = self.section.form.sharedInputAccessory;
        tf.clearButtonMode = UITextFieldViewModeWhileEditing;
        renderer = [[UIFormBuilderFormItemCell alloc] initWithControl:tf forItem:self];
        [self.section.form registerTextFieldWithFocusUtil:tf];
        [tf release];
        [self updateControlValue];
        [self updateControlEditability];
    }
    return renderer;
}

-(BOOL)validateValueAndUpdateData {
    UITextField * control = (UITextField *)self.renderer.control;
    BOOL isValid = self.validator == nil || [self.validator validate:control.text];
    if (!self.validator && self.required && [control.text length] == 0) {
        isValid = NO;
    }
    if (isValid) {
        if (![control.text isEqual:[self.section.form.data valueForKeyPath:self.fieldName]]) {
            [self.section.form.data setValue:control.text forKeyPath:self.fieldName];
        }
    }
    return isValid;
}


-(void)layoutCell{
    UIControl *control = (UIControl *)self.renderer.control;
    CGRect f = self.renderer.contentView.frame;
    CGRect t = self.renderer.textLabel.frame;
    f.origin.x = t.size.width + t.origin.x + t.origin.x;
    control.contentMode = UIViewContentModeScaleToFill;
    BOOL x = YES;
    if ([control isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField *)control;
        
        [tf setTextColor:[self.renderer.detailTextLabel textColor]];
        [tf setTextAlignment:UITextAlignmentRight];
        [tf setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        
        if (tf.borderStyle != UITextBorderStyleNone) {
            f.size.height = self.renderer.contentView.frame.size.height - (2 * UIFORMBUILDER_TEXTFIELD_PADDING);
            f.origin.y = UIFORMBUILDER_TEXTFIELD_PADDING;
            f.size.width = f.size.width - f.origin.x - UIFORMBUILDER_TEXTFIELD_PADDING;
            x = NO;
        }
    }
    
    if (x) {
        f.origin.y = t.origin.y;
        f.size.height = t.size.height;
        f.size.width = f.size.width - f.origin.x - t.origin.x; //match left/right inset
    }
    
    control.frame = f;
}

-(void)markInvalid:(BOOL)valid {
    if (!valid) {
        self.renderer.textLabel.textColor = [UIColor redColor];
    }
    else {
        self.renderer.textLabel.textColor = [UIColor darkTextColor];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSString *kp = [keyPath stringByStrippingLeadingOccurancesOf:@"form.data."];
    if ([keyPath isEqual:@"form.data"] || [kp isEqual:self.fieldName]) {
        if (renderer) {
            [renderer resetValidation:YES];
        }
        [self updateControlValue];
    }
    else if ([keyPath isEqualToString:@"editable"] || [keyPath isEqualToString:@"form.editable"]) {
        [self updateControlEditability];
    }
}

-(void)dealloc {
    self.section = nil;
    [renderer release];
    [fieldName release];
    [validator release];
    [super dealloc];
}

#pragma mark UIFormBuilderFormItem (internal)
//---------------------------------------------
// UIFormBuilderFormItem (internal)
//---------------------------------------------
-(void)updateControlEditability {
    if (renderer) {
        self.renderer.control.userInteractionEnabled = editable && section.editable && section.form.editable;
    }
}

-(void)clearBindings {
    if (self.section) {
        [self.section removeObserver:self forKeyPath:@"editable"];
        [self.section removeObserver:self forKeyPath:@"form.editable"];
        if (self.fieldName != nil) {
            [self.section removeObserver:self forKeyPath:[NSString stringWithFormat:@"form.data.%@", self.fieldName]];
        }
    }
    
}
-(void)addBindings {
    if (self.section) {
        [self.section addObserver:self forKeyPath:@"editable" options:NSKeyValueObservingOptionNew context:nil];
        [self.section addObserver:self forKeyPath:@"form.editable" options:NSKeyValueObservingOptionNew context:nil];
        if (self.fieldName) {
            NSString *chain = [NSString stringWithFormat:@"form.data.%@", self.fieldName];
            [self.section addObserver:self forKeyPath:chain options:NSKeyValueObservingOptionNew context:nil];
        }
    }
}
-(UIFormBuilderSection *)section {
    return section;
}
-(void)setSection:(UIFormBuilderSection *)sect {
    [self clearBindings];
    section = sect;
    [self addBindings];
}
-(id)formDataValue {
    return [self.section.form.data valueForKeyPath:self.fieldName];
}
-(void)updateControlValue {
    if (renderer != nil) {
        id v = [self formDataValue];
        if (![v isKindOfClass:[NSString class]]) {
            v = [v stringValue];
        }
        [((UITextField*)self.renderer.control) setValue:v forKeyPath:@"text"];
    }
}

-(BOOL)containsControl:(UIControl *)ctrl {
    if (renderer && [ctrl isDescendantOfView:renderer]) {
        return YES;
    }
    return NO;
}

@end


#pragma mark - UIFormBuilderDatePickerFormItem
@interface UIFormBuilderDatePickerFormItem (internal)
-(void)dpChanged;
@end;
//---------------------------------------------
// UIFormBuilderDatePickerFormItem
//---------------------------------------------
@implementation UIFormBuilderDatePickerFormItem
@synthesize formatter, dp;
-(NSDate *)maximumDate {
    return dp.maximumDate;
}
-(void)setMaximumDate:(NSDate *)max {
    dp.maximumDate = max;
}

-(NSDate *)minimumDate {
    return dp.minimumDate;
}
-(void)setMinimumDate:(NSDate *)min {
    dp.minimumDate = min;
}

-(void)setMode:(UIDatePickerMode)mode {
    dp.datePickerMode = mode;
}

-(UIDatePickerMode)mode {
    return dp.datePickerMode;
}

-(UIFormBuilderFormItemCell *)renderer {
    if (renderer == nil) {
        renderer = [super renderer];
        [renderer clearActions];
        [(UITextField*)renderer.control setInputView:dp];
    }
    return renderer;
}


-(id)init {
    self = [super init];
    dp = [[UIDatePicker alloc] init];
    dp.date = [NSDate date];
    self.mode = UIDatePickerModeDate;
    [dp addTarget:self action:@selector(dpChanged) forControlEvents:UIControlEventValueChanged];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterMediumStyle];
    self.formatter = df;
    [df release];
    return self;
}
-(id)initForField:(NSString *)fn withLabel:(NSString*)lbl withMinDate:(NSDate *)min andMaxDate:(NSDate*)max {
    if ((self = [self initForField:fn withLabel:lbl])) {
        self.minimumDate = min;
        self.maximumDate = max;
    }
    return self;
}

-(void)updateDisplayText {
    
}

-(void)dpChanged {
    [self validateValueAndUpdateData];
}

-(void)updateControlValue {
    if (renderer != nil) {
        NSDate *v = [self formDataValue];
        [dp removeTarget:self action:@selector(dpChanged) forControlEvents:UIControlEventValueChanged];
        if (v != nil) {
            dp.date = v;
            [(UITextField *)self.renderer.control setText:[self.formatter stringFromDate:v]];
        }
        else {
            [(UITextField *)self.renderer.control setText:nil];
        }
        [dp addTarget:self action:@selector(dpChanged) forControlEvents:UIControlEventValueChanged];
    }
}

-(BOOL)validateValueAndUpdateData {
    NSDate *date = dp.date;
    BOOL isValid = self.validator == nil || [self.validator validate:date];
    if (!self.validator && self.required && date == nil) {
        isValid = NO;
    }
    if (isValid) {
        if (![date isEqual:[self.section.form.data valueForKeyPath:self.fieldName]]) {
            [self.section.form.data setValue:date forKeyPath:self.fieldName];
        }
    }
    return isValid;
}

-(void)dealloc {
    [dp removeTarget:self action:@selector(dpChanged) forControlEvents:UIControlEventValueChanged];
    [dp release];
    [formatter release];
    [super dealloc];
}
@end

#pragma mark - UIFormBuilderPickerFormItem
//---------------------------------------------
// UIFormBuilderPickerFormItem
// TODO: Advanced segments. Currently, single segments, simple strings, fixed fixed width, heights.
//---------------------------------------------
@implementation UIFormBuilderPickerFormItem
@synthesize pickerOptions, picker;

-(void)setPickerOptions:(NSArray *)opts {
    [pickerOptions release];
    pickerOptions = [opts retain];
    [self.picker reloadAllComponents];
}

-(id)initForField:(NSString *)fn withLabel:(NSString*)lbl withOptions:(NSArray *)opts {
    if ((self = [self initForField:fn withLabel:lbl])) {
        self.pickerOptions = opts;
        UIPickerView *p = [[UIPickerView alloc] init];
        p.showsSelectionIndicator = YES;
        self.picker = p;
        [p release];
        self.picker.dataSource = self;
        self.picker.delegate = self;
    }
    return self;
}
     
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return self.pickerOptions == nil ? 0 : 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.pickerOptions count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.pickerOptions objectAtIndex:row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [self validateValueAndUpdateData];
}

-(void)updateControlValue {
    if (renderer != nil) {
        NSString *v = [self formDataValue];
        for (NSString *opt in self.pickerOptions) {
            if ([opt isEqualToString:v]) {
                [self.picker selectRow:[self.pickerOptions indexOfObject:opt] inComponent:0 animated:NO];
                [(UITextField *)self.renderer.control setText:v];
                return;
            }
        }
        [(UITextField *)self.renderer.control setText:nil];
        [self.picker selectRow:0 inComponent:0 animated:NO];
    }
}

-(BOOL)validateValueAndUpdateData {
    NSString *v = [self.pickerOptions objectAtIndex:[self.picker selectedRowInComponent:0]];
    if (![v isEqual:[self.section.form.data valueForKeyPath:self.fieldName]]) {
        [self.section.form.data setValue:v forKeyPath:self.fieldName];

    }
    return YES;
}

-(UIFormBuilderFormItemCell *)renderer {
    if (renderer == nil) {
        renderer = [super renderer];
        [(UITextField *)renderer.control setInputView:self.picker];
    }
    return renderer;
}

-(void)dealloc {
    [picker release];
    [pickerOptions release];
    [super dealloc];
}

@end



#pragma mark - UIFormBuilderEmailFormItem
//---------------------------------------------
// UIFormBuilderEmailFormItem
//---------------------------------------------
@implementation UIFormBuilderEmailFormItem
-(id)initForField:(NSString *)fn withLabel:(NSString*)lbl {
    if ((self = [super initForField:fn withLabel:lbl])) {
        FBEmailValidator *v = [FBEmailValidator new];
        self.validator = v;
        [v release];
    }
    return self;
}
-(UIFormBuilderFormItemCell*)renderer {
    if (renderer == nil) {
        renderer = [super renderer];
        ((UITextField*)renderer.control).keyboardType = UIKeyboardTypeEmailAddress;
        ((UITextField*)renderer.control).autocorrectionType = UITextAutocorrectionTypeNo;
        
        ((UITextField*)renderer.control).autocapitalizationType = UITextAutocapitalizationTypeNone;
    }
    return renderer;
}
@end

#pragma mark - UIFormBuilderNumericFormItem
//---------------------------------------------
// UIFormBuilderNumericFormItem
//---------------------------------------------
@implementation UIFormBuilderNumericFormItem
@synthesize max;
@synthesize min;
@synthesize decimalPlaces;
@synthesize nfd;
@synthesize formatter;

-(id)initForField:(NSString *)fn withLabel:(NSString*)lbl andFormatter:(NSNumberFormatter*)_fmt andMin:(NSDecimalNumber *)minimum andMax:(NSDecimalNumber *)maximum andDecimals:(uint)decimals {
    if ((self = [super initForField:fn withLabel:lbl])) {
        self.min = minimum;
        self.max = maximum;
        self.decimalPlaces = decimals;
        
        if (_fmt == nil) {
            _fmt = [[NSNumberFormatter new] autorelease];
            [_fmt setNumberStyle:NSNumberFormatterNoStyle];
        } else if (_fmt.minimumFractionDigits != decimalPlaces || _fmt.maximumFractionDigits != decimalPlaces) {
            _fmt = [[_fmt copy] autorelease];
            [_fmt setMinimumFractionDigits:decimalPlaces];
            [_fmt setMaximumFractionDigits:decimalPlaces];
        }

        self.formatter = _fmt;
    }
    return self;
}

-(UIFormBuilderFormItemCell*)renderer {
    if (!renderer) {
        renderer = [super renderer];
    }
    if (!self.nfd) {
        NumberFieldDelegateImpl *x = [[NumberFieldDelegateImpl alloc] initWithTextField:(UITextField*)renderer.control
                                                                           andFormatter:formatter
                                                                     notUsingDoneButton:false];
        self.nfd = x;
        [x release];
        ((UITextField*)renderer.control).delegate = self.nfd;
    }
    return renderer;
}

-(void)updateControlValue {
    if (self.renderer != nil) {
        id v = [self.nfd.formatter stringFromNumber:[self formDataValue]];
        [((UITextField*)self.renderer.control) setValue:v forKeyPath:@"text"];
    }
}

-(BOOL)validateValueAndUpdateData {
    if ((self.min && [self.nfd.value compare:self.min] < NSOrderedSame)
        || (self.max && [self.nfd.value compare:self.max] > NSOrderedSame)) {
        return NO;
    }
    id orig = [self formDataValue];
    id updated = self.nfd.value;
    if (![orig isEqual:updated]) {
        [self.section.form.data setValue:self.nfd.value forKeyPath:self.fieldName];
    }
    return YES;
}

-(void)dealloc {
    self.nfd = nil;
    [super dealloc];
}

@end


#pragma mark - UIFormBuilderSliderFormItem
//---------------------------------------------
// UIFormBuilderSliderFormItem
//---------------------------------------------
@implementation UIFormBuilderSliderFormItem
@synthesize min;
@synthesize max;
-(id)initForField:(NSString *)fn withLabel:(NSString*)lbl withMin:(double)minimum andMax:(double)maximum {
    self = [self initForField:fn withLabel:lbl];
    self.min = minimum;
    self.max = maximum;
    return self;
}

-(UIFormBuilderFormItemCell *)renderer {
    if (renderer == nil) {
        UISlider *s = [UISlider new];
        s.value = min;
        s.minimumValue = min;
        s.maximumValue = max;
        renderer = [[UIFormBuilderFormItemCell alloc] initWithControl:s forItem:self];
        [s release];
        [self updateControlValue];
        [self updateControlEditability];
    }
    return renderer;
}
-(void)updateControlValue {
    if (renderer != nil) {
        float foo = [[self formDataValue] floatValue];
        UISlider *c = (UISlider *)self.renderer.control;
        if (c.value != foo) {
            [c setValue:foo];
        }
    }
}
-(void)setMax:(double)m {
    self.max = m;
    if (renderer != nil) {
        [(UISlider *)renderer.control setMaximumValue:m];
    }
}
-(void)setMin:(double)m {
    self.min = m;
    if (renderer != nil) {
        [(UISlider *)renderer.control setMinimumValue:m];
    }
}

-(BOOL)validateValueAndUpdateData {
    UISlider *control = (UISlider *)self.renderer.control;
    NSNumber *v = [NSNumber numberWithFloat:control.value];
    BOOL isValid = self.validator == nil || [self.validator validate:v];
    if (isValid) {
        if (control.value  != [[self formDataValue] floatValue]) {
            [self.section.form.data setValue:v forKeyPath:self.fieldName];
        }
    }
    return isValid;
}

@end

#pragma mark - UIFormBuilderSwitchFormItem
//---------------------------------------------
// UIFormBuilderSwitchFormItem
//---------------------------------------------
@implementation UIFormBuilderSwitchFormItem

-(UIFormBuilderFormItemCell *)renderer {
    if (renderer == nil) {
        UISwitch *s = [UISwitch new];
        renderer = [[UIFormBuilderFormItemCell alloc] initWithControl:s  forItem:self];
        [s release];
        [self updateControlValue];
        [self updateControlEditability];
    }
    return renderer;
}

-(void)layoutCell {
    CGRect f = self.renderer.contentView.frame;
    UISwitch *control = (UISwitch *)self.renderer.control;
    CGRect c = CGRectMake(0, 0, control.frame.size.width, control.frame.size.height);
    c.origin.x = f.size.width - c.size.width - f.origin.x;
    c.origin.y = (f.size.height - c.size.height) / 2;
    control.frame = c;
}

-(BOOL)validateValueAndUpdateData {
    UISwitch *control = (UISwitch *)self.renderer.control;
//    NSLog(@"========Saving value '%i' from %@ to %@", control.on, control, self.fieldName);
    [self.section.form.data setValue:[NSNumber numberWithBool:control.on] forKeyPath:self.fieldName];
    return YES;
}

-(void)updateControlValue {
    if (renderer != nil) {
        [(UISwitch*)self.renderer.control setOn:[[self formDataValue] boolValue]];
    }
}
@end


#pragma mark - Validators

//---------------------------------------------
// FBStringValidator
//---------------------------------------------
@implementation FBStringValidator

@synthesize maxLength, minLength;
+(id)new {
    return [[FBStringValidator alloc] init];
}
-(id)init {
    self.maxLength = -1;
    self.minLength = -1;
    return self;
}
-(id)initWithMinLength:(NSInteger)min maxLength:(NSInteger)max{
    self.minLength = min;
    self.maxLength = max;
    return self;
}
-(BOOL)validate:(id)v {
    if (minLength >= 0 && [v length] < minLength) {
        return NO;
    }
    if (maxLength >= 0 && [v length] > maxLength) {
        return NO;
    }
    return YES;
}
@end


//---------------------------------------------
// FBEmailValidator
//---------------------------------------------
@implementation FBEmailValidator
@synthesize validDomains, invalidDomains;

+(id)new {
    return [[FBEmailValidator alloc] init];
}
-(id)init {
    if ((self = [super initWithMinLength:3 maxLength:-1])) {
        self.invalidDomains = nil;
        self.validDomains = nil;
    }
    return self;
}
-(id)initWithInvalidDomains:(NSArray *)idoms validDomains:(NSArray *)vdoms {
    if ((self = [self init])) {
        self.invalidDomains = idoms;
        self.validDomains = vdoms;
    }
    return self;
}
-(BOOL)validate:(id)value {
    if ([super validate:value]) {
        NSMutableCharacterSet *mcs = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [mcs addCharactersInString:@"-_.@"];
        NSString *v = [value stringByTrimmingCharactersInSet:[mcs invertedSet]];
        [mcs release];
        NSArray *parts = [v componentsSeparatedByString:@"@"];
        if ([parts count] == 2) {
            NSString *user = [parts objectAtIndex:0];
            NSString *domain = [parts objectAtIndex:1];
            if ([user length] > 0 &&
                [domain length] > 0) {
                for (NSString *d in self.invalidDomains) {
                    if ([[domain lowercaseString] isEqualToString:[d lowercaseString]]) {
                        return NO;
                    }
                }
                for (NSString *d in self.validDomains) {
                    if ([[domain lowercaseString] isEqualToString:[d lowercaseString]]) {
                        return YES;
                    }
                }
                if ((self.invalidDomains == nil || [self.invalidDomains count] == 0) &&
                    (self.validDomains == nil || [self.validDomains count] == 0)) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

-(void)dealloc {
    [validDomains release];
    [invalidDomains release];
    [super dealloc];
}

@end


//---------------------------------------------
// FBNumericValidator
//---------------------------------------------
@implementation FBNumericValidator
@synthesize maximum, minimum;
+(id)new {
    return [[FBNumericValidator alloc] init];
}

-(id)init {
    self.maximum = [[NSDecimalNumber maximumDecimalNumber] doubleValue];
    self.minimum = [[NSDecimalNumber minimumDecimalNumber] doubleValue];
    return self;
}
-(id)initWithMinValue:(double)min maxValue:(double)max{
    self.maximum = max;
    self.minimum = min;
    return self;
}
-(BOOL)validate:(id)value {
    double v = [value doubleValue];
    return v >= self.minimum && v <= self.maximum;
}
@end

