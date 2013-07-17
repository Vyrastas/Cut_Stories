//
//  Paper.h
//  Papercut
//
//  Created by Jeff Bumgardner on 9/4/12.
//  Copyright (c) 2012 Jeff Bumgardner. All rights reserved.
//
//  Custom UIImageView class that holds all the special properties
//    needed for the papercut objects.  All objects displayed (aside
//    from the border) are of this class.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Variables.h"

@class Vector2D;
@class Behavior;
@class PocketSVG;

@interface Paper : UIImageView {
@public
    
    int         objID;          // unique identifier for object
    int         spawnID;        // unique key in dictionary
    
    BOOL        tagged;         // tag for flocking behavior
    CGRect      bound;          // for collision detection
    CGPoint     posSpawn;       // spawning position
    CGPoint     posCurr;        // current position
    BOOL        bounded;        // YES = object should not leave screen
    BOOL        collision;      // YES = collision enabled for object
    CGFloat     mass;           // used for collisions
    BOOL        transformEnabled;   // flag to track when a transform should trigger
    
    CGPoint         halfSize;       // x = half width, y = half height
    BOOL            moveable;       // can the user move the image?
    CGFloat         drag;           // drag coefficient
    NSString        *imagePath;     // filename of image
    NSString        *imageType;     // filetype of image
    int             dir;            // image direction
    int             orientation;
    MovementType    moveType;       // movement type
    PaperType       paperType;      // Paper type
    BindType        bindType;
    BOOL            remove;         // YES = remove image from object dictionary
    BOOL            removeOnClean;  // YES = image should be removed during Manage: Clean
    BOOL            manageRemove;   // YES = image is being removed during Manage: Clean,
                                    //   needed to remove objects that transform into another
                                    //   after death (i.e. Note -> Notefish)
    
    BOOL            resumeFromPause;
    BOOL            resumeFromBackground;
    
    BOOL            pinch;          // YES = can be resized by pinch/zoom
    CGFloat         pinchMax;       // pinch scale limits
    CGFloat         pinchMin;
    CGFloat         scaleStart;     // initial starting scale upon app launch
    
    CGFloat     decel;          // deceleration coefficient
    CGFloat     decelTime;      // time to slow down deceleration
    
    BOOL        bob;            // should the image bob?
    CGFloat     bobAmp;         // bob amplitude, higher = less bob
    CGFloat     bobOffset;      // offset so the objects bob out of sync
    
    int         flip;           // indicates current flip direction
    BOOL        flipX;          // YES = flip about X axis, NO = Y axis, i.e. the axis it FACES / travels along
    CGFloat     flipTime;       // time between image flips; 0 = no flip
    
    BOOL        randSpawn;      // YES = spawns randomly on X axis if flipX = NO, Y axis otherwise
    BOOL        spawnByShake;   // YES = can spawn by shaking device
    CGFloat     killTime;
    CGFloat     killTimeCheck;
    
    int         childImage;     // array row of child image, 0 = no child
    CGPoint     childSpawn;     // spawn offset of child/group (compared to center of touched object)
    
    BOOL                    animated;       // indicates layer-tree animated
    CAAnimationGroup        *animGroup;     // for state saving
    NSMutableDictionary     *animLayerKeys; // for state saving - all animations / keys
    CAShapeLayer            *animShape;
    CFTimeInterval          animStartTime; // machine time when the animation started
    
    CGRect                  touchSpot;      // image-specific touchspot for spawning objects
    int                     tsRand;         // touchspot spawns random image from this row in PaperRandom
    int                     groupID;        // reference to group of images that moves with this Master
    BOOL                    killOnTouch;
    
    Behavior    *behavior;
    
    BOOL        movePath;
    CGFloat     pathTime;
    int         numPaths;
    
    CGFloat     wiggleTime;
    CGFloat     wiggleAngle;
    
    BOOL        objLimit;            // counts towards max object limit
    
    CGPoint     curvePoint;         // final position of animated path curve

}

@property (nonatomic, retain) NSString *imagePath;
@property (nonatomic, retain) NSString *imageType;
@property (nonatomic, retain) Behavior *behavior;

@property (assign) CGPoint posSpawn;

@property (assign) int objID;
@property (assign) int spawnID;

@property (assign) BOOL tagged;
@property (assign) BOOL bounded;
@property (assign) BOOL collision;
@property (assign) CGFloat mass;
@property (assign) BOOL transformEnabled;
@property (assign) int dir;
@property (assign) int orientation;
@property (assign) MovementType moveType;
@property (assign) PaperType paperType;
@property (assign) BindType bindType;
@property (assign) CGPoint halfSize;
@property (assign) BOOL moveable;
@property (assign) CGFloat drag;
@property (assign) BOOL remove;
@property (assign) BOOL removeOnClean;
@property (assign) BOOL manageRemove;
@property (assign) BOOL resumeFromPause;
@property (assign) BOOL resumeFromBackground;
@property (assign) BOOL pinch;
@property (assign) CGFloat pinchMax;
@property (assign) CGFloat pinchMin;
@property (assign) CGFloat scaleStart;

@property (assign) CGFloat decel;
@property (assign) CGFloat decelTime;

@property (assign) BOOL bob;
@property (assign) CGFloat bobAmp;
@property (assign) CGFloat bobOffset;

@property (assign) int flip;
@property (assign) BOOL flipX;
@property (assign) CGFloat flipTime;

@property (assign) BOOL randSpawn;
@property (assign) BOOL spawnByShake;
@property (assign) CGFloat killTime;
@property (assign) CGFloat killTimeCheck;

@property (assign) int childImage;
@property (assign) CGPoint childSpawn;

@property (assign) BOOL animated;
@property (nonatomic, retain) CAAnimationGroup *animGroup;
@property (nonatomic, retain) NSMutableDictionary *animLayerKeys;
@property (nonatomic, retain) CAShapeLayer *animShape;
@property (assign) CFTimeInterval animStartTime;

@property (assign) CGRect touchSpot;
@property (assign) int tsRand;
@property (assign) int groupID;
@property (assign) BOOL killOnTouch;

@property (assign) int frames;
@property (assign) CGFloat frameDur;

@property (assign) BOOL movePath;
@property (assign) CGFloat pathTime;
@property (assign) int numPaths;

@property (assign) CGFloat wiggleTime;
@property (assign) CGFloat wiggleAngle;

@property (assign) BOOL objLimit;

@property (assign) CGPoint curvePoint;

// Instance methods
- (id)initWithProps:(PaperProps)prp
          AnimProps:(PaperPropsAnim)prpAnim
         TouchProps:(PaperPropsTouchspot)prpTouch
             Parent:(Paper*)parentPaper;

- (void)applyForce:(Vector2D*)force;
- (CGPoint)getCenterPoint;
- (BOOL)isTagged;
- (void)wiggle;

@end
