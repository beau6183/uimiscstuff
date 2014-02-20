//
//  UIView+Border.m
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright (c) 2014 Beau Scott. All rights reserved.
//

#import "UIView+Border.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (Border)

-(void)addBorder:(CGFloat)width withColor:(UIColor *)color {
    self.layer.borderColor = [UIColor blackColor].CGColor;
    self.layer.borderWidth = 1;
}
@end
