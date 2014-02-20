//
//  UIButton+BarButton.h
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright (c) 2014 Beau Scott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (BarButton)

+(UIBarButtonItem*)barButtonItemWithTitle:(NSString*)title andImage:(UIImage*)image andTarget:(id)target andSelector:(SEL)selector;

@end
