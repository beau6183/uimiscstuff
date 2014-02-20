//
//  UIActionSheet+MenuHandler.m
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import "UIActionSheet+MenuHandler.h"

@interface MenuHandlerItem:NSObject {
    NSInteger buttonIndex;
    SEL selector;
    id target;
    id object;
@private
    MenuHandlerClosure _handler;
}
@property (nonatomic,copy) MenuHandlerClosure handler;
@property (nonatomic,assign) NSInteger buttonIndex;
@property (nonatomic,assign) id target;
@property (nonatomic,assign) SEL selector;
@property (nonatomic,retain) id object;
-(id)initWithHandler:(MenuHandlerClosure)closure forButtonAtIndex:(NSInteger)index;
-(id)initWithSelector:(SEL)selector onTarget:(id)_target forButtonAtIndex:(NSInteger)index;
-(id)initWithSelector:(SEL)selector onTarget:(id)_target forButtonAtIndex:(NSInteger)index withObject:(id)object;
-(void)execute;
@end;


@interface MenuHandler : NSObject <UIActionSheetDelegate> {
    NSMutableDictionary *handlers;
}
-(id)initWithActionSheet:(UIActionSheet*)actionSheet;
-(void)addHandler:(MenuHandlerItem*)item forMenuItem:(NSInteger)item;
@end

@implementation MenuHandler
-(id)init {
    self = [super init];
    handlers = [NSMutableDictionary new];
    return self;
}
-(id)initWithActionSheet:(UIActionSheet*)actionSheet {
    if (self = [self init]) {
        actionSheet.delegate = self;
        [self retain];
    }
    return self;
}

-(void)dealloc {
    [handlers release];
    [super dealloc];
}

-(void)addHandler:(MenuHandlerItem*)handler forMenuItem:(NSInteger)item {
    [handlers setObject:handler forKey:[NSNumber numberWithInt:item]];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    MenuHandlerItem* handler = [handlers objectForKey:[NSNumber numberWithInt:buttonIndex]];
    if (handler != nil) {
        [handler execute];
    }
    [self release];
}
@end

@implementation UIActionSheet(MenuHandler)

-(id)initUsingMenuHanderWithTitle:(NSString *)title {
    if (self = [self initWithTitle:title delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil]) {
        MenuHandler *handler = [[MenuHandler alloc] initWithActionSheet:self];
        self.delegate = handler;
        [handler release];
    }
    return self;
}

- (NSInteger)addButtonWithTitle:(NSString *)title andHandler:(MenuHandlerClosure)handler {
    NSInteger rv = [self addButtonWithTitle:title];
    MenuHandlerItem *hi = [[MenuHandlerItem alloc] initWithHandler:handler forButtonAtIndex:rv];
    [(MenuHandler*)self.delegate addHandler:hi forMenuItem:rv];
    [hi release];
    return rv;
}

-(NSInteger)addButtonWithTitle:(NSString *)title withTarget:(id)target usingSelector:(SEL)selector {
    return [self addButtonWithTitle:title withTarget:target usingSelector:selector withObject:nil];
}

-(NSInteger)addButtonWithTitle:(NSString *)title withTarget:(id)target usingSelector:(SEL)selector withObject:(id)object {
    NSInteger rv = [self addButtonWithTitle:title];
    MenuHandlerItem *hi = [[MenuHandlerItem alloc] initWithSelector:selector onTarget:target forButtonAtIndex:rv withObject:object];
    [(MenuHandler*)self.delegate addHandler:hi forMenuItem:rv];
    [hi release];
    return rv;
}

@end

@implementation MenuHandlerItem
@synthesize buttonIndex, selector, target, object;
-(MenuHandlerClosure)handler {
    return _handler;    
}
-(void)setHandler:(MenuHandlerClosure)handler {
    if (_handler != nil) {
        Block_release(_handler);
    }
    _handler = nil;
    if (handler != nil) {
        _handler = Block_copy(handler);
    }
}
-(id)init {
    if ((self = [super init])) {
        _handler = nil;
    }
    return self;
}
-(id)initWithHandler:(MenuHandlerClosure)closure forButtonAtIndex:(NSInteger)index {
    if ((self = [self init])) {
        self.handler = closure;
        self.buttonIndex = index;
    }
    return self;
}
-(id)initWithSelector:(SEL)_selector onTarget:(id)_target forButtonAtIndex:(NSInteger)index{
    if ((self = [self init])) {
        self.target = _target;
        self.selector = _selector;
        self.buttonIndex = index;
    }
    return self;
}
-(id)initWithSelector:(SEL)_selector onTarget:(id)_target forButtonAtIndex:(NSInteger)index withObject:(id)_object {
    if ((self = [self initWithSelector:_selector onTarget:_target forButtonAtIndex:index])) {
        self.object = _object;
    }
    return self;
}
-(void)execute {
    if (self.handler != nil) {
        self.handler();
    }
    else if (self.target != nil && selector != nil) {
        [self.target performSelector:self.selector withObject:self.object];
    }
}
-(void)dealloc {
    if (_handler != nil) {
        Block_release(_handler);
    }
    [object release];
    [super dealloc];
}

@end