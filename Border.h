//
//  Border.h
//  Papercut
//
//  Created by Jeff Bumgardner on 9/15/12.
//  Copyright (c) 2012 Jeff Bumgardner. All rights reserved.
//
//  Used to draw a border around the main view controller
//

#import <UIKit/UIKit.h>
#import "Variables.h"

@class Paper;

@interface Border : UIView {
    PaperProps borderProps;
}

- (void)initProps:(PaperProps)prp;

@end
