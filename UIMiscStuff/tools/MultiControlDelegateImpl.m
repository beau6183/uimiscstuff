//
//  MultiControlDelegateImpl.m
//
//  Created by Beau Scott on 2/19/14.
//  Copyright 2014 Beau Scott. All rights reserved.
//

#import "MultiControlDelegateImpl.h"
#import <objc/runtime.h>

typedef id(^MCDBlock_0)();
typedef id(^MCDBlock_1)(id);
typedef id(^MCDBlock_2)(id, id);
typedef id(^MCDBlock_3)(id, id, id);
typedef id(^MCDBlock_4)(id, id, id, id);
typedef id(^MCDBlock_5)(id, id, id, id, id);
typedef id(^MCDBlock_6)(id, id, id, id, id, id);
typedef id(^MCDBlock_7)(id, id, id, id, id, id, id);
typedef id(^MCDBlock_8)(id, id, id, id, id, id, id, id);

@implementation MultiControlDelegateImpl 

#pragma mark - Class methods
-(id)init {
    blocks = [NSMutableDictionary new];
    protocols = [NSMutableArray new];
    return self;
}

-(BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [protocols containsObject:NSStringFromProtocol(aProtocol)] || [super conformsToProtocol:aProtocol];
}

-(id)initWithProtocols:(Protocol*)protocol,... {
    va_list argumentList;
    id eachProt;
    if ((self = [self init])) {
        if (protocol) {
            NSMutableArray *ps = (NSMutableArray *)protocols;
            [ps addObject:NSStringFromProtocol(protocol)];
            va_start(argumentList, protocol);
            while ((eachProt = va_arg(argumentList, id))) {
                [ps addObject:NSStringFromProtocol(eachProt)];
            }
        }
    }
    return self;
    
}

-(void)dealloc {
    [protocols release];
    [blocks release];
    [super dealloc];
}

-(void)setBlock:(id)block forSelector:(SEL)selector {
    NSString *selectorName = NSStringFromSelector(selector);
    if (block != nil) {
        [blocks setObject:[[block copy] autorelease] forKey:selectorName];
    }
    else {
        [blocks removeObjectForKey:selectorName];
    }
}
                    
#pragma mark NSProxy
-(BOOL)respondsToSelector:(SEL)aSelector {
    return [blocks objectForKey:NSStringFromSelector(aSelector)] != nil;
}

-(NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
    if ([self respondsToSelector:sel]) {
        NSString *selName = NSStringFromSelector(sel);
        NSArray *seg = [selName componentsSeparatedByString:@":"];
        NSMutableArray *sig = [NSMutableArray array];
        [sig addObject:[NSString stringWithFormat:@"%s%s%s", @encode(id), @encode(id), @encode(SEL)]];
        for (int i = 0; i < [seg count]; i++) {
            [sig addObject:[NSString stringWithFormat:@"%s", @encode(id)]];
        }
        NSLog(@"%@, %@", selName, [sig componentsJoinedByString:@""]);
        const char * types = [[sig componentsJoinedByString:@""] UTF8String];
        
        return [NSMethodSignature signatureWithObjCTypes:types];
    }
    return [super methodSignatureForSelector:sel];
}

-(void)forwardInvocation:(NSInvocation *)invocation {

    NSString *sel = NSStringFromSelector([invocation selector]);
    if ([blocks objectForKey:sel] != nil) {
        NSMethodSignature *ms = [invocation methodSignature];
        NSLog(@"%@ %i", sel, [ms numberOfArguments]);
        
        // I'm sure there's a better way to do this, but I couldn't find an easy way to runtime create methods
        // and assign an implementation with variable numbers of arguments. For now, just handle up to 8 args.
        // I have yet to see a method with more than 8 args.
        id arg0 = nil, arg1 = nil, arg2 = nil, arg3 = nil, arg4 = nil, arg5 = nil, arg6 = nil, arg7 = nil, rv = nil;
        
        // Method signature first 2 args are self and selector, skip them.
        if ([ms numberOfArguments] <= 2) {
            MCDBlock_0 b = [blocks objectForKey:sel];
            rv = b();
        }
        else {
            [invocation getArgument:&arg0 atIndex:2];
            if ([ms numberOfArguments] == 3) {
                MCDBlock_1 b = [blocks objectForKey:sel];
                rv = b(arg0);
            }
            else {
                [invocation getArgument:&arg1 atIndex:3];
                if ([ms numberOfArguments] == 4) {
                    MCDBlock_2 b = [blocks objectForKey:sel];
                    rv = b(arg0, arg1);
                }
                else {
                    [invocation getArgument:&arg2 atIndex:4];
                    if ([ms numberOfArguments] == 5) {
                        MCDBlock_3 b = [blocks objectForKey:sel];
                        rv = b(arg0, arg1, arg2);
                    }
                    else {
                        [invocation getArgument:&arg3 atIndex:5];
                        if ([ms numberOfArguments] == 6) {
                            MCDBlock_4 b = [blocks objectForKey:sel];
                            rv = b(arg0, arg1, arg2, arg3);
                        }
                        else {
                            [invocation getArgument:&arg4 atIndex:6];
                            if ([ms numberOfArguments] == 7) {
                                MCDBlock_5 b = [blocks objectForKey:sel];
                                rv = b(arg0, arg1, arg2, arg3, arg4);
                            }
                            else {
                                [invocation getArgument:&arg5 atIndex:7];
                                if ([ms numberOfArguments] == 8) {
                                    MCDBlock_6 b = [blocks objectForKey:sel];
                                    rv = b(arg0, arg1, arg2, arg3, arg4, arg5);
                                }
                                else {
                                    [invocation getArgument:&arg6 atIndex:8];
                                    if ([ms numberOfArguments] == 9) {
                                        MCDBlock_7 b = [blocks objectForKey:sel];
                                        rv = b(arg0, arg1, arg2, arg3, arg4, arg5, arg6);
                                    }
                                    else {
                                        [invocation getArgument:&arg7 atIndex:9];
                                        if ([ms numberOfArguments] == 10) {
                                            MCDBlock_8 b = [blocks objectForKey:sel];
                                            rv = b(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7);
                                        }
                                        else {
                                            @throw [NSException exceptionWithName:@"Too many arguments for MultiControlDelegate" reason:@"" userInfo:nil];
                                        }    
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if ( rv != nil ) {
            [invocation setReturnValue:&rv];
        }

    }
    else [super forwardInvocation:invocation];
}

#pragma mark - Utility initializers
-(id)initAsPickerDelegates:(UIPickerView *)pickerView {
    return [self initWithProtocols:@protocol(UIPickerViewDelegate), @protocol(UIPickerViewDataSource), nil];
}

@end
