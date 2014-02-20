//
//  UIActionSheet+MenuHandler.h
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^MenuHandlerClosure)();

@interface UIActionSheet(MenuHandler)
-(id)initUsingMenuHanderWithTitle:(NSString *)title;
-(NSInteger)addButtonWithTitle:(NSString *)title andHandler:(MenuHandlerClosure)handler;
-(NSInteger)addButtonWithTitle:(NSString *)title withTarget:(id)target usingSelector:(SEL)selector;
-(NSInteger)addButtonWithTitle:(NSString *)title withTarget:(id)target usingSelector:(SEL)selector withObject:(id)object;
@end