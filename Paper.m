//
//  Paper.m
//  Papercut
//
//  Created by Jeff Bumgardner on 9/4/12.
//  Copyright (c) 2012 Jeff Bumgardner. All rights reserved.
//
//  Custom UIImageView class that holds all the special properties
//    needed for the papercut objects.  All objects displayed (aside
//    from the border) are of this class.
//

#import "Paper.h"
#import "Vector2D.h"
#import "Behavior.h"
#import "PocketSVG.h"
#import "Messenger.h"
#import "Timer.h"

@implementation Paper

@synthesize objID, spawnID, posSpawn, tagged, bounded, collision, mass, transformEnabled;
@synthesize dir, orientation, imagePath, imageType, halfSize, moveType, paperType, bindType, remove, pinch, pinchMax, pinchMin;
@synthesize moveable, drag, decel, decelTime;
@synthesize bob, bobAmp, bobOffset, flip, flipX, flipTime;
@synthesize randSpawn, spawnByShake, killTime, killTimeCheck;
@synthesize childImage, childSpawn, animated, animGroup, animLayerKeys, animShape, animStartTime;
@synthesize touchSpot, tsRand, groupID, killOnTouch, frames, frameDur;
@synthesize behavior, movePath, pathTime, numPaths, manageRemove, removeOnClean, resumeFromPause, resumeFromBackground;
@synthesize wiggleAngle, wiggleTime, scaleStart, objLimit, curvePoint;

- (id)initWithImage:(UIImage *)image
{
    self = [super initWithImage:image];
    if (self) {
        // empty
        self.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    }
    return self;
}

- (id)initWithProps:(PaperProps)prp
          AnimProps:(PaperPropsAnim)prpAnim
         TouchProps:(PaperPropsTouchspot)prpTouch
             Parent:(Paper*)parentPaper {
    
    behavior        = [[Behavior alloc] initBehavior];
    animLayerKeys   = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    // create temp variables / objects
    NSString *tName;
    UIImage  *tImage;
    
    double   tRand;
    CGFloat  tRandVel;
    
    tName = [NSString stringWithUTF8String: prp.imagePath];
    
    // PAPER INITIALIZATION ________________________
    
    switch (prp.paperType) {
            
        case Paper_Image:
        {
            tImage      = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", tName]];
            self        = [self initWithImage: tImage];
            
            // set center here to avoid conflict with anchorPoint for svg images
            if (parentPaper == nil) { self.center = CGPointMake(prp.spawnX, prp.spawnY); }
            else {
                // use dir to account for flipped parent images
                self.center = CGPointMake(parentPaper.center.x + (parentPaper.dir * parentPaper.childSpawn.x),
                                          parentPaper.center.y + parentPaper.childSpawn.y);
            }
            
            break;
        }
            
        case Paper_Vector:
        {
            self            = [self init];
            break;
        }
            
        default:
            break;
            
    }
    
    // PROPERTIES _________________________________
    
    animGroup = [CAAnimationGroup animation];
    animShape = [CAShapeLayer layer];
    
    [self.layer setShouldRasterize:YES];
    [self.layer setRasterizationScale:[[UIScreen mainScreen] scale]];
    [animShape setShouldRasterize:YES];
    [animShape setRasterizationScale:[[UIScreen mainScreen] scale]];
    
    // defaults / pre-calcs
    spawnID         = 0;
    flip            = 1;
    killTimeCheck   = 0.0;
    tsRand          = 0;
    animated        = NO;
    remove          = NO;
    manageRemove    = NO;
    resumeFromPause = NO;
    resumeFromBackground = NO;
    transformEnabled= NO;
    tagged          = NO;
    halfSize        = CGPointMake(self.image.size.width/2, self.image.size.height/2);
    self.backgroundColor = [UIColor clearColor];
    
    // properties based on PaperProps
    objID               = prp.objID;
    bounded             = prp.bounded;
    collision           = prp.collision;
    mass                = prp.mass;
    const char *imgPath = prp.imagePath;
    imagePath           = [[NSString alloc] initWithUTF8String:imgPath];
    dir                 = 1;
    orientation         = prp.orientation;
    randSpawn           = prp.randSpawn;
    posSpawn            = CGPointMake(prp.spawnX, prp.spawnY);
    if (prp.zPos != 0)  { self.layer.zPosition = prp.zPos; }
    moveType            = prp.moveType;
    paperType           = prp.paperType;
    bindType            = prp.bindType;
    decel               = prp.decel;
    decelTime           = prp.decelTime;
    bob                 = prp.bob;
    flipX               = prp.flipX;
    flipTime            = prp.flipTime;
    childImage          = prp.childImage;
    childSpawn          = CGPointMake(prp.childSpawnX, prp.childSpawnY);
    groupID             = prp.groupID;
    pinch               = prp.pinch;
    pinchMax            = prp.pinchMax;
    pinchMin            = prp.pinchMin;
    scaleStart          = prp.scaleStart;
    killOnTouch         = prp.killOnTouch;
    spawnByShake        = prp.spawnByShake;
    killTime            = prp.killTime;
    movePath            = prp.movePath;
    pathTime            = prp.pathTime;
    numPaths            = prp.numPaths;
    removeOnClean       = prp.removeOnClean;
    wiggleTime          = prp.wiggleTime;
    wiggleAngle         = prp.wiggleAngle;
    objLimit            = prp.objLimit;
    
    // set touch capabilities
    if (moveType == Move_Anim) {
        self.userInteractionEnabled = NO;
        self.multipleTouchEnabled = NO;
    }
    else {
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;
    }
    
    // INFO BUTTON
    if (objID == 45) {
        [self setAlpha:0.8];
    }
    
    // randomize some properties a little so multiples of the
    //   same vertical objects don't all bob/sway in sync or have the same velocity
    
    tRand = floorf(((double)arc4random() / ARC4RANDOM_MAX) * 0.6f);
    bobAmp              = prp.bobAmp + tRand;
    
    tRand = floorf(((double)arc4random() / ARC4RANDOM_MAX) * 1.7f);
    bobOffset           = prp.bobOffset + tRand;
    
    // don't randomize velocity for shaken objects
    if (spawnByShake) {
        behavior.vel = [behavior.vel initWithX:prp.velX Y:prp.velY];
    }
    else {
        tRand = floorf(((double)arc4random() / ARC4RANDOM_MAX) * 1.5f);
        if (prp.velY > 0.0) {
            tRandVel = prp.velY + tRand;
        }
        else if (prp.velY < 0.0) {
            tRandVel = prp.velY - tRand;
        }
        else {
            tRandVel = 0.0;
        }
        behavior.vel = [behavior.vel initWithX:prp.velX Y:tRandVel];
    }
    
    
    // BEHAVIOR _______________________________
    behavior.pSelf = self;
    behavior.velX           = prp.velX;
    behavior.velY           = prp.velY;
    behavior.flipX          = prp.flipX;
    behavior.bSpeed         = prp.bSpeed;
    behavior.bKillOnArrive  = prp.bKillOnArrive;
    behavior.bSeekOffset    = CGPointMake(prp.bSeekOffsetX, prp.bSeekOffsetY);
    behavior.rVelMax        = prp.rVelMax;
    behavior.rVelMin        = prp.rVelMin;
    behavior.spawnCount     = prp.spawnCount;
    behavior.spawnCountCheck= 0.0;
    behavior.animFrameDur   = prp.frameDur;
    behavior.autoReverse    = prp.autoReverse;
    behavior.decelType      = prp.decelType;
    behavior.angledPath     = prp.angledPath;
    behavior.viewCheckType  = prp.vcType;
    behavior.peekTime       = prp.peekTime;
    behavior.bFlocking      = prp.bFlocking;
    behavior.sinkAngle      = DEGREES_TO_RADIANS(prp.sinkAngle);
    behavior.sinkAngleInterval  = 0.0;
    behavior.fixedDir       = prp.fixedDir;
    behavior.bHalfSize      = halfSize;         // used to optimize variable accessing in Behavior
    
    
    // ___ flip
    if ((prp.flipTime > 0) && (prp.frames == 0)) {
        Timer *bTimer = [[Timer alloc] initTimer:btAxisflip withInterval:prp.flipTime withIntervalMax:0.0 withIntervalMin:0.0];
        [behavior addTimer:bTimer forBehavior:btAxisflip];
        [behavior turnOn:btAxisflip];
    }
    
    // ___ bob
    if (prp.bob) { [behavior BobOn:prp.bobAmp withOffset:prp.bobOffset]; }
    
    // ___ drift
    if ((prp.moveType == Move_Auto) || (prp.moveType == Move_Touch)) { [behavior turnOn:btDrift]; }
    
    // ___ decel
    if (prp.decelType != Decel_None) { [behavior turnOn:btDecel]; }
    
    // ___ seek
    if (prp.seekDelay > 0.0) {
        // add an inert timer for later activation
        Timer *bTimer = [[Timer alloc] initTimer:btSeek withInterval:prp.seekDelay timerOn:NO reverseTimer:NO
                                 withIntervalMax:prp.rVelTimeMax withIntervalMin:prp.rVelTimeMin];
        [behavior addTimer:bTimer forBehavior:btSeek];
    }
    
    // ___ randvel
    if (prp.rVelOn) {
        CGFloat brVelTime = RAND_NUM(prp.rVelTimeMax, prp.rVelTimeMin);
        Timer *bTimer = [[Timer alloc] initTimer:btRandvel
                                    withInterval:brVelTime withIntervalMax:prp.rVelTimeMax withIntervalMin:prp.rVelTimeMin];
        [behavior addTimer:bTimer forBehavior:btRandvel];
        [behavior turnOn:btRandvel];
    }
    
    // ___ toroid
    if (prp.spawnTime > 0.0) {
        Timer *bTimer = [[Timer alloc] initTimer:btToroid withInterval:prp.spawnTime withIntervalMax:0.0 withIntervalMin:0.0];
        [behavior addTimer:bTimer forBehavior:btToroid];
        [behavior turnOn:btToroid];
    }
    
    // ___ sink
    if (prp.spawnByShake) {
        Timer *bTimer = [[Timer alloc] initTimer:btSink withInterval:prp.killTime timerOn:NO reverseTimer:NO
                                 withIntervalMax:0.0 withIntervalMin:0.0];
        [behavior addTimer:bTimer forBehavior:btSink];
    }
    
    // ___ peek
    if (prp.peekTime > 0.0) {
        Timer *bTimer = [[Timer alloc] initTimer:btPeek withInterval:prp.peekTime timerOn:YES reverseTimer:YES
                                 withIntervalMax:0.0 withIntervalMin:0.0];
        [behavior addTimer:bTimer forBehavior:btPeek];
        [behavior turnOn:btPeek];
        
        // also add a Wait timer for later
        bTimer = [[Timer alloc] initTimer:btWait withInterval:prp.peekTime timerOn:NO reverseTimer:NO
                          withIntervalMax:0.0 withIntervalMin:0.0];
        [behavior addTimer:bTimer forBehavior:btWait];
    }
    
    // ___ flocking
    if (prp.bFlocking) {
        [behavior turnOnFlocking];
    }
    
    // ___ tilt timer
    if ((prp.moveType == Move_Touch) && (prp.bounded)) {
        Timer *bTimer = [[Timer alloc] initTimer:btTilt withInterval:2.0 timerOn:NO reverseTimer:NO
                                 withIntervalMax:0.0 withIntervalMin:0.0];
        [behavior addTimer:bTimer forBehavior:btTilt];
    }

    
    // TOUCHSPOT ______________________________
    if (prp.tsID > 0) {
        touchSpot = CGRectMake(prpTouch.tsX, prpTouch.tsY, prpTouch.tsWd, prpTouch.tsHt);
        tsRand = prpTouch.objID;
    }
    
    // ANIMATION ______________________________
    
    switch (paperType) {
            
        case Paper_Image:
        {
    
            // setup custom animation properties - angle/position (i.e. weeds, big fish)
            if ((prp.animID > 0) && (prp.frames == 0)) {
                
                animated = YES;
                
                // set anchor point for rotation and movement
                self.layer.anchorPoint = CGPointMake(prpAnim.anchorX, prpAnim.anchorY);
                
                CAKeyframeAnimation *rotateAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
                CAKeyframeAnimation *pathAnim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
                
                // rotation animation
                if (prpAnim.numAngles > 0) {
                    rotateAnim.duration = prpAnim.duration;
                    rotateAnim.removedOnCompletion = killOnTouch;
                    rotateAnim.fillMode = kCAFillModeForwards;
                    
                    NSMutableArray *anglesArray = [[NSMutableArray alloc] initWithCapacity:0];
                    
                    // there should be at least one angle
                    [anglesArray addObject:[NSNumber numberWithFloat:DEGREES_TO_RADIANS(prpAnim.angle01)]];
                    
                    // add more angles if necessary - FIND A BETTER WAY TO DO THIS?
                    if (prpAnim.numAngles > 1) { [anglesArray addObject:[NSNumber numberWithFloat:DEGREES_TO_RADIANS(prpAnim.angle02)]]; }
                    if (prpAnim.numAngles > 2) { [anglesArray addObject:[NSNumber numberWithFloat:DEGREES_TO_RADIANS(prpAnim.angle03)]]; }
                    if (prpAnim.numAngles > 3) { [anglesArray addObject:[NSNumber numberWithFloat:DEGREES_TO_RADIANS(prpAnim.angle04)]]; }
                    if (prpAnim.numAngles > 4) { [anglesArray addObject:[NSNumber numberWithFloat:DEGREES_TO_RADIANS(prpAnim.angle05)]]; }
                    if (prpAnim.numAngles > 5) { [anglesArray addObject:[NSNumber numberWithFloat:DEGREES_TO_RADIANS(prpAnim.angle06)]]; }
                    if (prpAnim.numAngles > 6) { [anglesArray addObject:[NSNumber numberWithFloat:DEGREES_TO_RADIANS(prpAnim.angle07)]]; }
                    if (prpAnim.numAngles > 7) { [anglesArray addObject:[NSNumber numberWithFloat:DEGREES_TO_RADIANS(prpAnim.angle08)]]; }
                    if (prpAnim.numAngles > 8) { [anglesArray addObject:[NSNumber numberWithFloat:DEGREES_TO_RADIANS(prpAnim.angle09)]]; }
                    //[anglesArray addObject:[NSNull null]];
                    
                    rotateAnim.values = anglesArray;
                    
                }
                
                // path animation
                if (prpAnim.numPoints > 0) {
                    pathAnim.calculationMode = kCAAnimationPaced;
                    pathAnim.fillMode = kCAFillModeForwards;
                    pathAnim.removedOnCompletion = killOnTouch;
                    
                    CGMutablePathRef tPath = CGPathCreateMutable();
                    CGPathMoveToPoint(tPath, nil, prpAnim.point01x, prpAnim.point01y);
                    CGPathAddLineToPoint(tPath, nil, prpAnim.point02x, prpAnim.point02y);
                    
                    // add more points if necessary - FIND A BETTER WAY TO DO THIS?
                    if (prpAnim.numPoints > 2) { CGPathAddLineToPoint(tPath, nil, prpAnim.point03x, prpAnim.point03y); }
                    if (prpAnim.numPoints > 3) { CGPathAddLineToPoint(tPath, nil, prpAnim.point04x, prpAnim.point04y); }
                    if (prpAnim.numPoints > 4) { CGPathAddLineToPoint(tPath, nil, prpAnim.point05x, prpAnim.point05y); }
                    
                    pathAnim.path = tPath;
                    CGPathRelease(tPath);
                }
                
                animGroup.fillMode = kCAFillModeForwards;
                
                if (prpAnim.numAngles == 0) {
                    [animGroup setAnimations:[NSArray arrayWithObjects:pathAnim, nil]];
                }
                else if (prpAnim.numPoints == 0) {
                    [animGroup setAnimations:[NSArray arrayWithObjects:rotateAnim, nil]];
                }
                else {
                    [animGroup setAnimations:[NSArray arrayWithObjects:pathAnim, rotateAnim, nil]];
                }
                
                animGroup.duration = prpAnim.duration;
                animGroup.repeatCount = prpAnim.repeat;
                animGroup.delegate = self;
                animGroup.removedOnCompletion = killOnTouch;
                [animGroup setValue:self forKey:[NSString stringWithFormat:@"paper.rot.pos.%d",objID]];
                
                [self.layer addAnimation:animGroup forKey:[NSString stringWithFormat:@"rot.pos.%d",objID]];
                
                animStartTime = [self.layer convertTime:CACurrentMediaTime() fromLayer:nil];
                
            }
            
#ifdef FRAMES_ON
            
            // setup frame animation
            if (prp.frames > 0) {
                
                animated = YES;

                // turn on behavior and create timer
                if (prp.animTime > 0.0) {
                    Timer *bTimer = [[Timer alloc] initTimer:btAnimframe withInterval:prp.animTime withIntervalMax:0.0 withIntervalMin:0.0];
                    [behavior addTimer:bTimer forBehavior:btAnimframe];
                    [behavior turnOn:btAnimframe];
                }
                
                NSMutableArray *frameArray = [[NSMutableArray alloc] initWithCapacity:0];
                UIImage *tFrame, *tempFrame;
                
                // Loop through each image and add to the frameArray
                for(int i = 1; i < prp.frames + 1; i++) {
                    tFrame = [UIImage imageNamed:[NSString stringWithFormat:@"%@%d.png", tName, i]];
                    
                    // if the image frame # doesn't exist, use the most recent one
                    // remember the most recent valid image if it does exist
                    // this currently does not work for autoreversing frame animations
                    if (!tFrame) {
                        [frameArray addObject:tempFrame];
                    }
                    else {
                        [frameArray addObject:tFrame];
                        tempFrame = tFrame;
                    }
                    
                }
                
                // Just like above but instead loop back down and add the images in reverse except drop the first and last frames
                if (prp.autoReverse) {
                    for(int i = prp.frames - 1; i > 1; i--) {
                        tFrame = [UIImage imageNamed:[NSString stringWithFormat:@"%@%d.png", tName, i]];
                        [frameArray addObject:tFrame];
                    }
                }
                
                // Overwrite initial static image, set duration and start animating if initial vel > 0
                [self setAnimationImages:frameArray];
                [self setAnimationDuration:behavior.animFrameDur];
                [self setAnimationRepeatCount:prp.animID];
                
                if (((behavior.vel.lengthSquared > 0.0) && (prp.animTime == 0.0)) || (movePath)) {
                    [self startAnimating];
                    [self performSelector:@selector(frameAnimComplete) withObject:nil afterDelay:behavior.animFrameDur];
                }
                
            }
            
#endif
            
            // if image should move along a path
            if (movePath) {
                
                animated = YES;
                
                CAKeyframeAnimation *movePathAnim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
                
                PocketSVG *tSVG;
                UIBezierPath *tBezier;
                
                int randIndex;
                if (numPaths > 0) {
                    // for those with multiple paths to choose from
                    randIndex = arc4random_uniform(numPaths)+1;
                    //NSLog(@"Rand Path %d", randIndex);
                    tSVG = [[PocketSVG alloc] initFromSVGFileNamed:[NSString stringWithFormat:@"P_%@%d", tName, randIndex]];
                }
                else {
                    tSVG = [[PocketSVG alloc] initFromSVGFileNamed:[NSString stringWithFormat:@"P_%@", tName]];
                }
                
                // flip the image direction based on the path direction
                if ((objID == 37) && (randIndex == 2)) {
                    [self setTransform:CGAffineTransformMake(-1, 0, 0, 1, 0, 0)];
                }
                
                // Use PocketSVG to convert the SVG to a Bezier Path
                tBezier = tSVG.bezier;
                movePathAnim.path = tBezier.CGPath;
                movePathAnim.calculationMode = kCAAnimationCubicPaced;
                movePathAnim.fillMode = kCAFillModeForwards;
                movePathAnim.duration = pathTime;
                movePathAnim.delegate = self;
                movePathAnim.removedOnCompletion = NO;
                
                if (prp.animID == 0) {
                    movePathAnim.repeatCount = FLT_MAX;
                }
                else {
                    movePathAnim.repeatCount = prp.animID;
                }
                
                [self.layer addAnimation:movePathAnim forKey:[NSString stringWithFormat:@"pos.path.%d",objID]];
                
                animStartTime = [self.layer convertTime:CACurrentMediaTime() fromLayer:nil];
 
            }
            
            break;
        }
            
        case Paper_Vector:
            {
                
                PocketSVG *tSVG;
                UIBezierPath *tBezier;
                
                PocketSVG *tSVG2;
                UIBezierPath *tBezier2;
                CAShapeLayer *tLayer2;
                CABasicAnimation *animBezier;
                CABasicAnimation *animScale;
                
                tSVG = [[PocketSVG alloc] initFromSVGFileNamed:[NSString stringWithFormat:@"%@", tName]];
                
                // Use PocketSVG to convert the SVG to a Bezier Path
                tBezier = tSVG.bezier;
                animShape.path = tBezier.CGPath;
                animShape.lineWidth = 1;
                animShape.strokeColor = [[UIColor blackColor] CGColor];
                animShape.fillColor = [[UIColor blackColor] CGColor];
                animShape.fillRule = kCAFillRuleNonZero;
                
                // Set the frame & bounds to position the piece and set anchor point for rotation
                CGPoint newCenter;
                CGFloat imageScale = fabsf(parentPaper.transform.a);
                
                if (parentPaper == nil) {
                    newCenter = CGPointMake(prp.spawnX, prp.spawnY);
                }
                else {
                    // use dir to account for flipped parent images
                    //newCenter = CGPointMake(parentPaper.center.x + (parentPaper.dir * parentPaper.childSpawn.x),
                    //                        parentPaper.center.y + parentPaper.childSpawn.y);
                    
                    // scale the image only if the parent is scaled
                    animShape.transform = CATransform3DScale(animShape.transform, imageScale, imageScale, 0.0);
                    
                    CGFloat scaleSpawnX, scaleSpawnY;
                    scaleSpawnY = parentPaper.childSpawn.y * imageScale;
                    
                    if (parentPaper.dir == parentPaper.orientation) {
                        scaleSpawnX = ((parentPaper.dir * parentPaper.childSpawn.x) - 35) * imageScale;
                        newCenter = CGPointMake(parentPaper.center.x + scaleSpawnX,
                                                  parentPaper.center.y + scaleSpawnY);
                    }
                    else {
                        scaleSpawnX = (parentPaper.dir * parentPaper.childSpawn.x) * imageScale;
                        newCenter = CGPointMake(parentPaper.center.x + scaleSpawnX,
                                                  parentPaper.center.y + scaleSpawnY);
                    }
                    
                }
                
                animShape.bounds = CGPathGetBoundingBox(animShape.path);
                
                CGRect lBounds = CGRectMake(newCenter.x, newCenter.y, animShape.bounds.size.width, animShape.bounds.size.height);
                [animShape setFrame:lBounds];

                halfSize = CGPointMake(animShape.bounds.size.width/2, animShape.bounds.size.height/2);
                animShape.anchorPoint = CGPointMake(prp.childSpawnX, prp.childSpawnY);
                
                // Create the end path for animation
                tSVG2 = [[PocketSVG alloc] initFromSVGFileNamed:[NSString stringWithFormat:@"%@2", tName]];
                tBezier2 = tSVG2.bezier;
                tLayer2 = [CAShapeLayer layer];
                tLayer2.path = tBezier2.CGPath;
                
                // Create the animation and add it to the layer
                animBezier = [CABasicAnimation animationWithKeyPath:@"path"];
                animBezier.delegate = self;
                animBezier.duration = prp.frameDur;
                animBezier.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                animBezier.fillMode = kCAFillModeForwards;
                animBezier.removedOnCompletion = NO;
                animBezier.autoreverses = behavior.autoReverse;
                
                if (prp.animID < 0)  {
                    animBezier.repeatCount = FLT_MAX;
                }
                else {
                    animBezier.repeatCount = prp.animID;
                }
                
                animBezier.fromValue = (id)animShape.path;
                animBezier.toValue = (id)tLayer2.path;
                [animShape addAnimation:animBezier forKey:@"animatePath"];
                
                // also scale the animation if spawned from a parent
                //   i.e. small note to normal-sized fish
                if (parentPaper != nil) {
                    
                    animScale = [CABasicAnimation animationWithKeyPath:@"transform"];
                    animScale.delegate = self;
                    animScale.duration = prp.frameDur;
                    animScale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
                    animScale.fillMode = kCAFillModeForwards;
                    animScale.removedOnCompletion = NO;
                    animScale.autoreverses = NO;
                    animScale.repeatCount = 0;
                    animScale.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(imageScale, imageScale, 0.0)];
                    animScale.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 0.0)];
                    [animShape addAnimation:animScale forKey:@"animateScale"];
                }
                
                // Movement along a curved path (notefish)
                if (prp.crvXOffMin != 0.0) {
                    
                    CGFloat curveXOffset = RAND_NUM(prp.crvXOffMin, prp.crvXOffMax);
                    CGFloat curveYOffset = RAND_NUM(prp.crvYOffMin, prp.crvYOffMax);
                    CGFloat curveCOffset = RAND_NUM(prp.crvCOffMin, prp.crvCOffMax);
                    
                    //NSLog(@"Curve Offsets X:%f Y:%f C:%f",curveXOffset, curveYOffset, curveCOffset);
                    
                    CAKeyframeAnimation *movePathAnim = [CAKeyframeAnimation animationWithKeyPath:@"position"];

                    movePathAnim.calculationMode = kCAAnimationPaced;
                    movePathAnim.fillMode = kCAFillModeForwards;
                    movePathAnim.removedOnCompletion = NO;
                    movePathAnim.autoreverses = NO;
                    movePathAnim.duration = prp.frameDur;
                    movePathAnim.delegate = self;
                    movePathAnim.repeatCount = 0;
                    
                    CGMutablePathRef tPath = CGPathCreateMutable();
                    CGPathMoveToPoint(tPath, nil, newCenter.x, newCenter.y);
                    
                    CGPoint ctl01 = CGPointMake(newCenter.x-curveXOffset, newCenter.y-curveCOffset);
                    CGPoint ctl02 = CGPointMake(newCenter.x+curveXOffset, newCenter.y-(curveYOffset-curveCOffset));
                    curvePoint =    CGPointMake(newCenter.x, newCenter.y-curveYOffset);
                    
                    CGPathAddCurveToPoint(tPath, nil, ctl01.x, ctl01.y, ctl02.x, ctl02.y, curvePoint.x, curvePoint.y);
                    
                    movePathAnim.path = tPath;
                    CGPathRelease(tPath);
                    
                    [animShape addAnimation:movePathAnim forKey:[NSString stringWithFormat:@"pos.path.%d",objID]];
                    
                }
                
                [self.layer addSublayer:animShape];
                
                animStartTime = [self.animShape convertTime:CACurrentMediaTime() fromLayer:nil];
                
                break;
            }
            
        default:
            break;
        
    }
    
    return self;
    
}

- (void)animationDidStart:(CAAnimation *)anim {
    // nothing
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    // remove paper if animation completes - only for temp spawned objects (objID > 99)
    if (spawnID > 99) {
        remove = YES;   // this removes the object from the world dictionary in the main timer
    }
    
    // touchspot objects should go away after one animation loop   
    switch (spawnID) {
            
        case 15:
        case 35:
        case 36:
        case 37:
            //NSLog(@"01 ObjID %d, Remove %d, ResumeFP %d, ResumeFB %d", objID, remove, resumeFromPause, resumeFromBackground);
            if ((!resumeFromPause) || (!resumeFromBackground)) { remove = YES; }
            resumeFromPause = NO;
            resumeFromBackground = NO;
            //NSLog(@"02 ObjID %d, Remove %d, ResumeFP %d, ResumeFB %d", objID, remove, resumeFromPause, resumeFromBackground);
            break;
            
        default:
            break;
            
    }

}

- (void)frameAnimComplete {
    
    // SQUID - Accelerate and spawn bubbles
    if (objID == 30) {
        behavior.vel.x = behavior.velX;
        behavior.vel.y = behavior.velY;
        CGPoint cPoint = self.center;
        
        // only spawn bubbles if squid is on screen
        if (![behavior viewCheck:vcCompletelyOffScreen]) {
            Messenger *messenger = [Messenger theMessenger];
            [messenger queueObject:9 message:mtSpawn behavior:btNone turnOn:YES
                            target:0 atPoint:CGPointMake(cPoint.x+55, cPoint.y-15) wasSpawned:YES];
            [messenger queueObject:6 message:mtSpawn behavior:btNone turnOn:YES
                            target:0 atPoint:CGPointMake(cPoint.x+25, cPoint.y+10) wasSpawned:YES];
            [messenger queueObject:39 message:mtSpawn behavior:btNone turnOn:YES
                            target:0 atPoint:CGPointMake(cPoint.x+40, cPoint.y) wasSpawned:YES];
        }
        
    }
    
    // DIVER - Accelerate and spawn bubble
    if (objID == 28) {
        behavior.vel.x = behavior.velX;
        behavior.vel.y = behavior.velY;
        CGPoint cPoint = self.center;
        
        // only spawn bubbles if diver is on screen
        if (![behavior viewCheck:vcCompletelyOffScreen]) {
            Messenger *messenger = [Messenger theMessenger];
            [messenger queueObject:46 message:mtSpawn behavior:btNone turnOn:YES
                            target:0 atPoint:CGPointMake(cPoint.x-84, cPoint.y-33) wasSpawned:YES];
        }
        
    }
    
}

- (void)applyForce:(Vector2D*)force {
    
    CGPoint paperCenter = CGPointMake(0.0, 0.0);
    paperCenter.x = force.x;
    paperCenter.y = force.y;
    
    if (self.paperType == Paper_Image) {
        [self setCenter:paperCenter];
    }
    else if (self.paperType == Paper_Vector) {
        [self.animShape setPosition:paperCenter];
    }
    
}

- (CGPoint)getCenterPoint {
    
    CGPoint pCenter;
    if (self.paperType == Paper_Image) {
        pCenter = self.center;
    }
    else if (self.paperType == Paper_Vector) {
        pCenter = self.animShape.position;
    }
    return pCenter;
    
}

- (BOOL)isTagged { return tagged; }

- (void)wiggle {
    
    CAKeyframeAnimation *animWiggle = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animWiggle.duration = wiggleTime;
    animWiggle.cumulative = YES;
    animWiggle.repeatCount = 1;
    
    // Get the current transform in case the weed is already rotated
    CATransform3D curr3DTrans = animShape.transform;
    
    [animWiggle setValues:[NSArray arrayWithObjects:
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, 0.0, 0.0, 0.0, 1.0)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, RADIANS(-wiggleAngle), 0.0, 0.0, 1.0)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, 0.0, 0.0, 0.0, 1.0)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, RADIANS(wiggleAngle), 0.0, 0.0, 1.0)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, 0.0, 0.0, 0.0, 1.0)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, RADIANS(-wiggleAngle) * 0.5, 0.0, 0.0, 1.0)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, 0.0, 0.0, 0.0, 1.0)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, RADIANS(wiggleAngle) * 0.5, 0.0, 0.0, 1.0)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, 0.0, 0.0, 0.0, 1.0)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, RADIANS(-wiggleAngle) * 0.25, 0.0, 0.0, 1.0)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, 0.0, 0.0, 0.0, 1.0)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, RADIANS(wiggleAngle) * 0.25, 0.0, 0.0, 1.0)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(curr3DTrans, 0.0, 0.0, 0.0, 1.0)],
                           nil]];
    
    animWiggle.fillMode = kCAFillModeForwards;
    animWiggle.timingFunctions = [NSArray arrayWithObjects:
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                                  nil];
    
    animWiggle.removedOnCompletion = YES;
    animWiggle.delegate = self;
    
    [animShape addAnimation:animWiggle forKey:@"Wiggle3D"];
    
}

@end
