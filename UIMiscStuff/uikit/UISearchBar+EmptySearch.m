//
//  UISearchBar+EmptySearch.m
//
//  Created by Beau Scott on 02/19/2014.
//  Copyright (c) 2014 Beau Scott. All rights reserved.
//

#import "UISearchBar+EmptySearch.h"

@implementation UISearchBar (EmptySearch)
-(void)enableEmptySearch {
    UITextField *searchBarTextField = nil;
    for (UIView *subview in self.subviews)
    {
        if ([subview isKindOfClass:[UITextField class]])
        {
            searchBarTextField = (UITextField *)subview;
            break;
        }
    }
    searchBarTextField.enablesReturnKeyAutomatically = NO;
    
}
@end
