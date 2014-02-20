//
//  UIButton+BarButton.m
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright (c) 2014 Beau Scott. All rights reserved.
//

#import "UIButton+BarButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIButton (BarButton)

+(UIBarButtonItem*)barButtonItemWithTitle:(NSString*)title andImage:(UIImage*)image andTarget:(id)target andSelector:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12.0f];
    [button.layer setCornerRadius:4.0f];
    [button.layer setMasksToBounds:YES];
    [button.layer setBorderWidth:1.0f];
    [button.layer setBorderColor: [[UIColor grayColor] CGColor]];
    button.frame=CGRectMake(0.0, 100.0, 60.0, 30.0);
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    return [[UIBarButtonItem alloc] initWithCustomView:button];
}

@end
