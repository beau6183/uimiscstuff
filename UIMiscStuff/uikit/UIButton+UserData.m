//
//  UIButton+UserData.m
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright (c) 2014 Beau Scott. All rights reserved.
//

#import "UIButton+UserData.h"
#import <objc/runtime.h>

@implementation UIButton (UserData)

static char KEY;

@dynamic userData;

-(void)setUserData:(id)userData {
    objc_setAssociatedObject(self, &KEY, userData, OBJC_ASSOCIATION_RETAIN);
}
-(id)userData {
    return objc_getAssociatedObject(self, &KEY);
}
@end
