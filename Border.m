//
//  Border.m
//  Papercut
//
//  Created by Jeff Bumgardner on 9/15/12.
//  Copyright (c) 2012 Jeff Bumgardner. All rights reserved.
//
//  Used to draw a border around the main view controller
//

#import "Border.h"
#import "Paper.h"

@implementation Border

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)initProps:(PaperProps)prp {
    // initialize the border properties
    // we use a PaperProps struct so we can store the border info
    //   in the same array as all the object info, so the property
    //   names are going to be different
    borderProps.spawnX      = prp.spawnX;       // width
    borderProps.velX        = prp.velX;         // color R
    borderProps.velY        = prp.velY;         // color G
    borderProps.decel       = prp.decel;        // color B
    borderProps.decelTime   = prp.decelTime;    // color A
    return;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    /* Set UIView Border */
    // Get the contextRef
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
        
    // Set the border width
    CGContextSetLineWidth(contextRef, borderProps.spawnX);
        
    // Set the border color to BLACK
    CGContextSetRGBStrokeColor(contextRef, borderProps.velX, borderProps.velY,
                               borderProps.decel, borderProps.decelTime);
        
    // Draw the border along the view edge
    CGContextStrokeRect(contextRef, rect);

}

@end
