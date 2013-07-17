//
//  ObjManager.m
//  Papercut
//
//  Created by Jeff Bumgardner on 9/16/12.
//  Copyright (c) 2012 Jeff Bumgardner. All rights reserved.
//
//  Class that manages objects at a high level (the "world"),
//    including sounds, world timers and world states
//    Also pauses / resumes animations when app enters background
//

#import "ObjManager.h"
#import "Paper.h"
#import "Border.h"
#import "Vector2D.h"
#import "Messenger.h"
#import "Behavior.h"
#import "Timer.h"

static ObjManager *mySharedWorld = nil;

@implementation ObjManager

@synthesize objects, objects_coll, objects_pinch, objects_shake, objects_neighbors, objects_wiggle;
@synthesize objects_sounds, objects_sounds_splash;
@synthesize queue_shake, queue_clean, queue_view, accel, accelX, osFlags, world_timers;
@synthesize spawnID, timerID, border, borderWidth, borderBound, viewWidth, viewHeight;
@synthesize fps, bounceOffset, gravityFilter, elapsedTime, cleanMin, cleanMax;
@synthesize maxNotes, numObjects;

+ (id) theWorld {
    @synchronized([ObjManager class]) {
        if (!mySharedWorld) { mySharedWorld = [[self alloc] initWithBlank]; }
    }
    return mySharedWorld;
}

+ (id) alloc
{
  @synchronized([ObjManager class])
	{
		NSAssert(mySharedWorld == nil, @"Attempted to allocate a second instance of the ObjManager.");
        mySharedWorld = [super alloc];
        return mySharedWorld;
	}

	return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (ObjManager*) initWithBlank {
    //self = [super init];
    
    if (self = [super init]) {
        objects = [[NSMutableDictionary alloc] init];
        objects_coll = [[NSMutableDictionary alloc] init];
        objects_pinch = [[NSMutableDictionary alloc] init];
        objects_shake = [[NSMutableDictionary alloc] init];
        objects_wiggle = [[NSMutableDictionary alloc] init];
        objects_sounds = [[NSMutableDictionary alloc] init];
        objects_sounds_splash = [[NSMutableDictionary alloc] init];
        queue_view = [[NSMutableDictionary alloc] init];
        queue_shake = [[NSMutableArray alloc] init];
        queue_clean = [[NSMutableArray alloc] init];
        world_timers = [[NSMutableDictionary alloc] init];
        
        spawnID = 100;  // start of counter for dynamically spawned object IDs
        timerID = 1;
        viewWidth = 0;
        viewHeight = 0;
        cleanMin = 4;
        cleanMax = 10;
        numObjects = 0;
        
        [self turnOffAllStates];

        _optInteract = YES;
        _optSound = YES;
        
        // Accelerometer
#ifdef ACCEL_ON
        accel = [UIAccelerometer sharedAccelerometer];
#endif
        accelX = 0.0;
        
        // Audio FX setup
        //   Use 3 different audio players so sounds can overlap
        
        //
        NSString *fxFilePath = [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"FX_Pop2"]
                                                        ofType: [NSString stringWithFormat:@"wav"]];
        NSURL *fxFileURL = [[NSURL alloc] initFileURLWithPath: fxFilePath];
        _fx_audio01 = [[AVAudioPlayer alloc] initWithContentsOfURL:fxFileURL error:nil];
        [_fx_audio01 setDelegate:self];
        [_fx_audio01 prepareToPlay];
        
        fxFilePath = [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"FX_Start"]
                                                               ofType: [NSString stringWithFormat:@"wav"]];
        fxFileURL = [[NSURL alloc] initFileURLWithPath: fxFilePath];
        _fx_audio02 = [[AVAudioPlayer alloc] initWithContentsOfURL:fxFileURL error:nil];
        [_fx_audio02 setDelegate:self];
        [_fx_audio02 prepareToPlay];
        
        fxFilePath = [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"FX_Pop1"]
                                                               ofType: [NSString stringWithFormat:@"wav"]];
        fxFileURL = [[NSURL alloc] initFileURLWithPath: fxFilePath];
        _fx_audio03 = [[AVAudioPlayer alloc] initWithContentsOfURL:fxFileURL error:nil];
        [_fx_audio03 setDelegate:self];
        [_fx_audio03 prepareToPlay];
        
        // Sounds for Splash menu
        [self loadSplashSounds];
        
    }
    return self;
}

- (void) resetObjManager {
    // since this is a singleton class at the app-level, we have
    //   to reset all objects and variables whenever the user
    //   returns to the main menu
    [objects removeAllObjects];
    [objects_coll removeAllObjects];
    [objects_pinch removeAllObjects];
    [objects_shake removeAllObjects];
    [objects_neighbors removeAllObjects];
    [objects_wiggle removeAllObjects];
    [objects_sounds removeAllObjects];
    [queue_view removeAllObjects];
    [queue_shake removeAllObjects];
    [queue_clean removeAllObjects];
    [world_timers removeAllObjects];
    spawnID = 100;  // start of counter for dynamically spawned object IDs
    timerID = 1;
    viewWidth = 0;
    viewHeight = 0;
    cleanMin = 4;
    cleanMax = 10;
    numObjects = 0;
    
    [self turnOffAllStates];
    
    if (_optSound) {
        [_bg_audio01 stop];
        [_bg_audio02 stop];
    }
    
    _bg_audio01 = nil;
    _bg_audio02 = nil;
    
    fps = 0.0;
    bounceOffset = 0.0;
    gravityFilter = 0.0;
    elapsedTime = 0.0;
    accelX = 0.0;
    
    //NSLog(@"Reset ObjM");
    
    return;
}

- (void) resetObjProperties {
    
    // this method should not be run during a
    //   scene reset
    _objProps         = nil;
    _objAnimProps     = nil;
    _objTouchProps    = nil;
    _objGroups        = nil;
    _objRandom        = nil;
    _objSounds        = nil;
    _objTimers        = nil;
    
    //NSLog(@"Reset ObjM Props");
    
}

- (void) loadSounds {
    
    NSString *soundFilePath;
    NSURL *fileURL;
    
    // get # of sounds in the array
    int i = _objSounds[0].soundID;
    
    for (int j=1; j<=i; j++) {
        soundFilePath = [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"%s", _objSounds[j].soundPath]
                                                        ofType: [NSString stringWithFormat:@"%s", _objSounds[j].fileType]];
        fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
        
        [objects_sounds setObject:fileURL forKey:[NSNumber numberWithInt:_objSounds[j].soundID]];
    }
    
}

- (void) playSound:(int)sID {
    [self playSound:sID atVolume:1.0];
}

- (void) playSound:(int)sID atVolume:(CGFloat)vol {
    
    if (_optSound) {
        
        NSURL *soundURL;
        soundURL = [objects_sounds objectForKey:[NSNumber numberWithInt:sID]];
        
        // Determine which FX Player to use based on which are already active
        if (![_fx_audio01 isPlaying]) {
            _fx_audio01 = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
            [_fx_audio01 setVolume:1.0];
            [_fx_audio01 setNumberOfLoops:0];
            
            if (vol < 1.0) {
                [_fx_audio01 setVolume:vol];
            }
            
            [_fx_audio01 prepareToPlay];
            [_fx_audio01 play];
        }
        else if (![_fx_audio02 isPlaying]) {
            _fx_audio02 = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
            [_fx_audio02 setVolume:1.0];
            [_fx_audio02 setNumberOfLoops:0];
            
            if (vol < 1.0) {
                [_fx_audio02 setVolume:vol];
            }

            [_fx_audio02 prepareToPlay];
            [_fx_audio02 play];
        }
        else {
            _fx_audio03 = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
            [_fx_audio03 setVolume:1.0];
            [_fx_audio03 setNumberOfLoops:0];
            
            if (vol < 1.0) {
                [_fx_audio03 setVolume:vol];
            }
            
            [_fx_audio03 prepareToPlay];
            [_fx_audio03 play];
        }
        
    }
    
}

- (void) loadSplashSounds {
    
    // setup the sounds needed on the splash screen
    
    NSString *soundFilePath;
    NSURL *fileURL;
    
    // STORY
    soundFilePath = [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"FX_Pop2"]
                                                    ofType: [NSString stringWithFormat:@"wav"]];
    fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
    
    [objects_sounds_splash setObject:fileURL forKey:[NSNumber numberWithInt:1]];
    
    // START
    soundFilePath = [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"FX_Start"]
                                                    ofType: [NSString stringWithFormat:@"wav"]];
    fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
    
    [objects_sounds_splash setObject:fileURL forKey:[NSNumber numberWithInt:2]];

}

- (void) playSplashSound:(int)sID {
    
    NSURL *soundURL;
    soundURL = [objects_sounds_splash objectForKey:[NSNumber numberWithInt:sID]];
    
    _fx_audio01 = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
    [_fx_audio01 setNumberOfLoops:0];
    [_fx_audio01 prepareToPlay];
    [_fx_audio01 play];
    
}

- (BOOL)isStateOn:(ObjState)os       { return ((osFlags & os) == os); }
- (void)turnOnState:(ObjState)os     { if (![self isStateOn:os]) { osFlags |= os; } }
- (void)turnOffState:(ObjState)os    { if([self isStateOn:os]) { osFlags ^= os; } }
- (void)turnOffAllStates { osFlags = 0; }

- (void) addToView:(Paper *)paperPiece  {
    // this queue adds objects to the view controller after message processing
    [queue_view setObject:paperPiece forKey:[NSNumber numberWithInt:paperPiece.spawnID]];
}

- (void) addToShakeQueue:(int)objID {
    // this queue tracks objects that can be shaken out
    [queue_shake addObject:[NSNumber numberWithInt:objID]];
}

- (void) addToCleanQueue:(int)objID {
    // this queue tracks objects that should be removed after
    //   a certain count has been reached (i.e. little fish to be eaten)
    [queue_clean addObject:[NSNumber numberWithInt:objID]];
}

- (void) addWorldTimer:(Timer *)objTimer forType:(WorldTimer)wt {
    [world_timers setObject:objTimer forKey:[NSNumber numberWithInt:wt]];
}

- (void) delWorldTimer:(WorldTimer)wt {
    [world_timers removeObjectForKey:[NSNumber numberWithInt:wt]];
}

- (void) turnWorldTimer:(WorldTimer)wt toOn:(BOOL)isOn {
    Timer *wTimer = [world_timers objectForKey:[NSNumber numberWithInt:wt]];
    if (isOn)   { [wTimer turnTimerOn]; }
    else        { [wTimer turnTimerOff]; }
}

- (BOOL) isWorldTimerOn:(WorldTimer)wt {
    Timer *wTimer = [world_timers objectForKey:[NSNumber numberWithInt:wt]];
    return [wTimer isTimerOn];
}

- (void) updateWorldTimers:(CGFloat)interval {
    
    Timer *wTimer;
    for (NSNumber *key in world_timers) {
        wTimer = [world_timers objectForKey:key];
        
        if ([wTimer isTimerOn]) {
            [wTimer timerUpdate:interval];
        }
    }
    
}

- (void) processWorldTimers {
    
    Timer *wTimer;
    Messenger *messenger = [Messenger theMessenger];
    
    for (NSNumber *key in world_timers) {
        wTimer = [world_timers objectForKey:key];
        
        if ([wTimer timerComplete]) {
            
            switch (wTimer.wtMessageType) {
                    
                case mtSpawn:
                    [messenger queueObject:0 message:wTimer.wtMessageType turnOn:YES target:wTimer.wtTargetID wasSpawned:YES];
                    break;
                    
                case mtNone:    // no message type is a simple wait timer
                    [wTimer turnTimerOff];
                    break;
                    
                default:
                    break;
                    
            }
            
            [wTimer randomizeInterval];
            [wTimer timerReset];
            
        }
        
    }
    
}

- (void) addObj:(Paper *)paperPiece forDictionary:(NSMutableDictionary *)objDict {
    // generic add Paper to any object dictionary
    NSNumber *newID;
    newID = [NSNumber numberWithInt:paperPiece.spawnID];
    [objDict setObject:paperPiece forKey:newID];
}

- (void) addObj:(Paper *)paperPiece wasSpawned:(BOOL)spawned {
    
    // add paper piece to objects
    NSNumber *newID;
    if (spawned) {
        newID = [NSNumber numberWithInt:spawnID];
        paperPiece.spawnID = spawnID;
        spawnID++;
    }
    else {
        newID = [NSNumber numberWithInt:paperPiece.objID];
        paperPiece.spawnID = paperPiece.objID;
    }
    
    [objects setObject:paperPiece forKey:newID];
    
    // add to the objLimit
    if (paperPiece.objLimit) { numObjects++; }
}

- (void) delObj:(Paper *)paperPiece {
    // delete paper piece from objects
    if (paperPiece.objLimit) {
        if (numObjects > 0) { numObjects--; }
    }
    [objects removeObjectForKey:[NSNumber numberWithInt:paperPiece.spawnID]];
}

- (void) initBorder {
    
    border = [[Border alloc] initWithFrame:CGRectMake(0, 0, 768, 1024) ];
    [border initProps:_objProps[0]];
    border.backgroundColor = [UIColor clearColor];
    
    // set manager border properties
    borderWidth = _objProps[0].spawnX;
    borderBound = _objProps[0].spawnY;
    
    return;
}

// Initalize all Paper objects based on the PaperProps tables
- (void) initScene {
    
    [self turnOffState:osPaused];
    
    // create temp objects
    Paper       *tPaper;
    
    // loop through each property record, create each Paper piece and add it to the manager
    //   the first row (index = 0) is always the border row, so start at index = 1
    
    int totalPieces = _objProps[0].bobAmp;        // bobAmp in border row is # of objects in table
    
	for (unsigned int i = 1; i <= totalPieces; i++) {
        // if the piece should appear upon view initialization,
        //    then initialize and add to manager
        if (_objProps[i].init) {

            tPaper = [[Paper alloc] initWithProps:_objProps[i]
                                        AnimProps:_objAnimProps[_objProps[i].animID]
                                       TouchProps:_objTouchProps[_objProps[i].tsID]
                                           Parent:nil];
            [self addObj:tPaper wasSpawned:NO];

        }
        
        // add objID to queue_shake if necessary
        if (_objProps[i].spawnByShake) {
            [self addToShakeQueue:_objProps[i].objID];
        }
        
    }
    
    // create world timers
    int totalTimers = _objTimers[0].objTargetID;
    
    for (unsigned int i = 1; i <= totalTimers; i++) {
        WorldTimer timerType = _objTimers[i].wTimer;
        Timer *wTimer = [[Timer alloc] initWorldTimer:timerType
                                         worldMessage:_objTimers[i].mType
                                          worldTarget:_objTimers[i].objTargetID
                                         withInterval:_objTimers[i].wtInterval
                                      withIntervalMax:_objTimers[i].wtIntervalMax
                                      withIntervalMin:_objTimers[i].wtIntervalMin];
        [self addWorldTimer:wTimer forType:timerType];
        [self turnWorldTimer:timerType toOn:YES];
    }
    
    return;
}

// Check if an object was touched by the user
- (Paper*) objTouched:(CGPoint)touchPos {
    
    Paper *eachPiece;
    
    for (NSNumber *key in objects) {
        eachPiece = [objects objectForKey:key];
        
        if((CGRectContainsPoint(eachPiece.frame, touchPos))
           && (eachPiece.moveType != Move_Static) && (eachPiece.moveType != Move_Anim)) {
            // we found the piece that was touched, so exit
            return eachPiece;
        }
        else {
            // only for animated pieces that can be killed (i.e. balloon fish)
            CGRect layerFrame = [[eachPiece.layer presentationLayer] frame];
            if((CGRectContainsPoint(layerFrame, touchPos))
                  && (eachPiece.killOnTouch) && (eachPiece.moveType == Move_Anim)) {
                   return eachPiece;
            }
        }
            
    }
    
    return nil;     // no piece was touched
}

// Returns the object specified by an objID value of type int
- (Paper*) getObject:(int)objID {
    return [objects objectForKey:[NSNumber numberWithInt:objID]];
}

// Collision detection and velocity recalc
- (void) collidePiece:(Paper *)piece1 withPiece:(Paper *)piece2 {
    
    // create temp vectors
    Vector2D *tVel1, *tVel2, *iVelSum, *eVelSum;
    Vector2D *fVel1, *fVel2;
    
    // initialize starting vectors and calculate momentum
    tVel1 = [[Vector2D alloc] initWithX:piece1.behavior.vel.x Y:piece1.behavior.vel.y];
    [tVel1 mult:piece1.mass];
    
    tVel2 = [[Vector2D alloc] initWithX:piece2.behavior.vel.x Y:piece2.behavior.vel.y];
    [tVel2 mult:piece2.mass];
    
    // initialize all other temp vectors with [0 0]
    iVelSum = [[Vector2D alloc] init];
    eVelSum = [[Vector2D alloc] init];
    fVel1 = [[Vector2D alloc] init];
    fVel2 = [[Vector2D alloc] init];
    
    // calculate the final velocity vector of piece2 after collision
    iVelSum = [[tVel1 copy] add:tVel2];
    eVelSum = [[tVel1 copy] sub:tVel2];
    CGFloat coefficient = -RESTITUTION;     // coefficient of restitution for a linear collision
    [eVelSum mult:coefficient];
    [eVelSum mult:piece1.mass];
    [eVelSum sub:iVelSum];
    
    CGFloat mDiff = -piece2.mass - piece1.mass;
    fVel2 = [[eVelSum copy] div:mDiff];
    
    // calculate the final velocity vector of piece1 after collision
    fVel1 = [[iVelSum copy] sub:fVel2];
    
    // update Paper vectors
    piece1.behavior.vel.x = fVel1.x;
    piece1.behavior.vel.y = fVel1.y;
    piece2.behavior.vel.x = fVel2.x;
    piece2.behavior.vel.y = fVel2.y;
    
    return;
    
}

- (void)updateDirection:(Paper *)imagePiece {
    if (((imagePiece.behavior.flipX) && (imagePiece.behavior.vel.x < 0.0)) ||
        ((!(imagePiece.behavior.flipX)) && (imagePiece.behavior.vel.y < 0.0))) {
        imagePiece.dir = -1 * imagePiece.orientation;
    }
    else if (((imagePiece.behavior.flipX) && (imagePiece.behavior.vel.x > 0.0)) ||
             ((!(imagePiece.behavior.flipX)) && (imagePiece.behavior.vel.y > 0.0))) {
        imagePiece.dir = 1 * imagePiece.orientation;
    }
    else {
        // do nothing, keep the current direction if stopped
    }

}

- (BOOL)leftTopHalf:(Paper *)imagePiece {

    // YES if piece is on the left or top half of screen
    //   used to adjust the direction of the image
    CGPoint cPoint = [imagePiece getCenterPoint];
    
    if (imagePiece.behavior.flipX) {
        // left vs right
        if (cPoint.x < (viewWidth * 0.5)) { return YES; }
        else { return NO; }
    }
    else {
        // top vs bottom
        if (cPoint.y < (viewHeight * 0.5)) { return YES; }
        else { return NO; }
    }
}

- (CGPoint)keepInBounds:(Paper *)pPiece forBounds:(ViewCheckType)vcType {

    CGPoint cPoint = [pPiece getCenterPoint];
    
    // reverse the velocity elements if the image hits the border
    //   and bounce it away from the border so it doesn't get stuck
    
    if (![pPiece.behavior viewCheck:vcType]) {
        
        pPiece.transformEnabled = NO;
        if ([pPiece.behavior axisHitCheck:vcType] == yAxis) {

            if (pPiece.collision) {
                [pPiece.behavior.vel setX:(-pPiece.behavior.vel.x)];
                if (cPoint.x >= (viewWidth*0.5)) {
                    cPoint.x -= bounceOffset;
                }
                else {
                    cPoint.x += bounceOffset;
                }
            }
            else {
                // only bounce if not being tilted (to prevent stutter)
                if ((pPiece.bindType == Bind_Always) && (fabsf(accelX) < TILT_THRESHOLD)) {
                    [pPiece.behavior.vel setX:(-pPiece.behavior.vel.x)*0.6];
                    if (cPoint.x >= (viewWidth*0.5)) {
                        cPoint.x -= bounceOffset;
                    }
                    else {
                        cPoint.x += bounceOffset;
                    }
                }
                else {
                    [pPiece.behavior.vel setX:0.0];
                }
            }
            
        }
        else {
            
            if (vcType == vcKeepOnGround) {
                [pPiece.behavior.vel setY:0.0];
            }
            else {
                [pPiece.behavior.vel setY:(-pPiece.behavior.vel.y)];
                if (cPoint.y >= (viewHeight*0.5)) {
                    cPoint.y -= bounceOffset-2;
                }
                else {
                    cPoint.y += bounceOffset-2;
                }
            }
            
        }
        
    }
    
    return cPoint;

}

- (CGAffineTransform)imageTransform:(Paper *)imagePiece {
    CGAffineTransform transformPiece = [self imageTransform:imagePiece withScale:1.0];
    return transformPiece;
}

- (CGAffineTransform)imageTransform:(Paper *)imagePiece withScale:(CGFloat)scale {
    
    CGAffineTransform transformPiece;
    CGFloat currTransSX, currTransSY;
    int imageDir = imagePiece.dir;
    
    // don't transform based on direction if Peek is on
    if (([imagePiece.behavior isOn:btPeek]) || (imagePiece.behavior.fixedDir)) {
        if ([self leftTopHalf:imagePiece]) {
            imageDir = imagePiece.orientation;
        }
        else {
            imageDir = -imagePiece.orientation;
        }
    }
    
    // create an initial transform based on the rotation angle if necessary
    if (imagePiece.behavior.rotateAngle != 0.0) {
        transformPiece = CGAffineTransformMakeRotation(imagePiece.behavior.rotateAngle);
    }
    else {
        transformPiece = CGAffineTransformIdentity;
    }
    
    if (scale == 1.0) {

        // handle any peekers explicitly because they don't
        //   play nice with others
        if (imagePiece.behavior.peekTime > 0.0) {
            currTransSX = scale;
            currTransSY = scale;
        }
        else if (imagePiece.pinch) {
            // needed to keep pinched objects the proper size
            //   while they aren't being pinched
            currTransSX = imagePiece.transform.a;
            currTransSY = imagePiece.transform.d;
        }
        else {
            currTransSX = 1.0;
            currTransSY = 1.0;
        }

    }
    else {
        currTransSX = scale;
        currTransSY = scale;
    }
    
    if ([imagePiece.behavior isOn:btAxisflip]) {
        
        // now flip the piece based on the axis
        if (imagePiece.behavior.flipX) {
            transformPiece = CGAffineTransformScale(transformPiece,
                                                    (imageDir * fabsf(currTransSX)),
                                                    (imagePiece.behavior.flip * fabsf(currTransSY)));
        }
        else {
            transformPiece = CGAffineTransformScale(transformPiece,
                                                    (imagePiece.behavior.flip * fabsf(currTransSX)),
                                                    (imageDir * fabsf(currTransSY)));
        }
        
    }
    else {
        // if piece doesn't flip, just switch the direction as necessary
        if (imagePiece.behavior.flipX) {
            transformPiece = CGAffineTransformScale(transformPiece,
                                                    (imageDir * fabsf(currTransSX)),
                                                    currTransSY);
        }
        else {
            transformPiece = CGAffineTransformScale(transformPiece,
                                                    currTransSX,
                                                    (imageDir * fabsf(currTransSY)));
        }
    }
    
    return transformPiece;
}

- (void)updateGroup:(Paper *)mstrPiece {
    [self updateGroup:mstrPiece transform:CGAffineTransformIdentity];
}

- (void)updateGroup:(Paper *)mstrPiece
          transform:(CGAffineTransform)mstrTransform {
    
    // setup variables
    Paper *gPaper;
    CGPoint gPaperCenter;
    PaperGroups gGrp = _objGroups[mstrPiece.groupID];
    int i = gGrp.numSubs;
    CGFloat mstrTransSX, mstrTransSY;

    for (int j = 1; j<=i; j++) {
        
        if (j == 1) { gPaper = [self getObject:gGrp.objIDSub01]; }
        if (j == 2) { gPaper = [self getObject:gGrp.objIDSub02]; }
        
        gPaperCenter = mstrPiece.center;
        
        // use scale values of the transform in case parent object is
        //   scaled via pinch/zoom, etc, so we can adjust the
        //   position offsets accordingly
        mstrTransSX = fabsf(mstrTransform.a) * gPaper.childSpawn.x;
        mstrTransSY = fabsf(mstrTransform.d) * gPaper.childSpawn.y;
        
        if (mstrPiece.behavior.flipX) {
            gPaperCenter.x += mstrTransSX * mstrPiece.dir;
            gPaperCenter.y += mstrTransSY;
        }
        else {
            gPaperCenter.x += mstrTransSX;
            gPaperCenter.y += mstrTransSY * mstrPiece.dir;
        }
        
        gPaper.transform = mstrTransform;
        CGFloat mstrVel = mstrPiece.behavior.vel.lengthSquared;
        if ((!gPaper.isAnimating) && (mstrVel > 0.0)) {
            [gPaper startAnimating];
        }
        else if ((gPaper.isAnimating) && (mstrVel == 0.0)) {
            [gPaper stopAnimating];
            //gPaper.layer.speed = 0.0;
        }
        else {
            // do nothing
        }
        [gPaper setCenter:gPaperCenter];
        
    }
}

// Spawning new Paper objects due to user input
- (Paper*)spawnPiece:(Paper *)touchedPiece isChild:(BOOL)child {
    Paper *sPaper;
    sPaper = [self spawnPiece:touchedPiece objID:touchedPiece.childImage isChild:child];
    return sPaper;
}

// Spawning new Paper objects due to user input
- (Paper*)spawnPiece:(Paper *)touchedPiece objID:(int)childImg isChild:(BOOL)child {
    
    Paper *sPaper;
    
    // initialize the spawn object
    
    if (child) {
        sPaper = [[Paper alloc] initWithProps:_objProps[childImg]
                                    AnimProps:_objAnimProps[_objProps[childImg].animID]
                                   TouchProps:_objTouchProps[_objProps[childImg].tsID]
                                       Parent:touchedPiece];
    }
    else {
        sPaper = [[Paper alloc] initWithProps:_objProps[childImg]
                                    AnimProps:_objAnimProps[_objProps[childImg].animID]
                                   TouchProps:_objTouchProps[_objProps[childImg].tsID]
                                       Parent:nil];
    }
    
    // add spawned Paper to object manager and return it to the viewcontroller
    [self addObj:sPaper wasSpawned:YES];
    
    return sPaper;
    
}

// MASTER SPAWN METHOD
- (Paper*)spawnPiece:(Paper *)parentPiece objID:(int)obj childID:(int)child wasSpawned:(BOOL)spawn atPoint:(CGPoint)pos {
    
    Paper *sPaper;
    int objectID;
    
    if (child > 0)  { objectID = child; }
    else            { objectID = obj; }
    
    // initialize the spawn object
    if (child > 0) {
        sPaper = [[Paper alloc] initWithProps:_objProps[objectID]
                                    AnimProps:_objAnimProps[_objProps[objectID].animID]
                                   TouchProps:_objTouchProps[_objProps[objectID].tsID]
                                       Parent:parentPiece];
    }
    else {
        sPaper = [[Paper alloc] initWithProps:_objProps[objectID]
                                    AnimProps:_objAnimProps[_objProps[objectID].animID]
                                   TouchProps:_objTouchProps[_objProps[objectID].tsID]
                                       Parent:nil];
    }
    
    if (!CGPointEqualToPoint(pos, CGPointZero)) {
        [sPaper setCenter:pos];
    }
    
    // add spawned Paper to object manager and return it to the viewcontroller
    [self addObj:sPaper wasSpawned:spawn];
    
    return sPaper;
    
}

// Spawning an object explicitly
- (Paper*) spawnPiece:(int)objID {
    
    Paper *sPaper;
    sPaper = [self spawnPiece:objID wasSpawned:YES];
    
    return sPaper;
    
}

// Spawning an object explicitly
- (Paper*) spawnPiece:(int)objID wasSpawned:(BOOL)spawn {
    
    Paper *sPaper;
    
    // initialize the spawn object
    sPaper = [[Paper alloc] initWithProps:_objProps[objID]
                                AnimProps:_objAnimProps[_objProps[objID].animID]
                               TouchProps:_objTouchProps[_objProps[objID].tsID]
                                   Parent:nil];
    
    // add spawned Paper to object manager and return it to the viewcontroller
    [self addObj:sPaper wasSpawned:spawn];
    
    return sPaper;
    
}

// Spawning an object explicitly at a point
- (Paper*) spawnPiece:(int)objID atPoint:(CGPoint)pos {
    
    Paper *sPaper;

    // initialize the spawn object
    sPaper = [[Paper alloc] initWithProps:_objProps[objID]
                                AnimProps:_objAnimProps[_objProps[objID].animID]
                               TouchProps:_objTouchProps[_objProps[objID].tsID]
                                   Parent:nil];
    [sPaper setCenter:pos];
    
    // add spawned Paper to object manager and return it to the viewcontroller
    [self addObj:sPaper wasSpawned:YES];
    
    return sPaper;
    
}

- (void) killPiece:(Paper *)piece {
    
    switch (piece.objID) {
            
        case 6:
        case 7:
        case 9:
        case 10:
        case 12:
        case 14:
        case 35:
        case 39:
        case 46: // bubbles / balloon fish
        {
            
            //NSLog(@"Bubble Pop: %d", piece.objID);
            // select a sound
            int randPop = arc4random_uniform(4)+15;
            [self playSound:randPop];

            [UIView animateWithDuration:0.2
                                  delay:0.0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 piece.alpha = 0.0;
                             }
                             completion:^(BOOL finished){
                                piece.remove = YES;
                             }];
        }
            
        default:
            break;
            
    }
    
}

// for separation / alignment / cohesion behaviors
//   determines which objects are closest to a specific object
- (void) tagNeighbors:(Paper*)piece ofQueue:(NSMutableArray*)queue {
    
    Vector2D *sCenter = [Vector2D withX:piece.center.x Y:piece.center.y];
    
    for (int i = 0; i < queue.count; i++) {
        
        int sID = [[queue objectAtIndex:i] intValue];
        Paper *nPiece = [self getObject:sID];
        nPiece.tagged = NO;
        
        if (piece.spawnID != nPiece.spawnID) {  // shouldn't tag itself
        
            Vector2D *dist = [Vector2D withX:nPiece.center.x Y:nPiece.center.y];
            [dist sub:sCenter];
        
            if ([dist lengthSquared] < 900) {
                nPiece.tagged = YES;
            }
            
        }
        
    }
    
}


- (void) changeZPosition:(NSMutableDictionary *)objDict toPos:(int)zPos {
    
    // changes the Z Position of an object to prevent
    //   it from overlapping a menu view controller
    Paper *zPiece;
    for (NSNumber *key in objDict) {
        
        zPiece = [objDict objectForKey:key];
        zPiece.layer.zPosition = zPos;
        
    }
    
}



// Saves active animations when app is pushed to background
- (void) pauseAnimations {

    Paper *eachPiece;
    
    for (NSNumber *key in objects) {
        eachPiece = [objects objectForKey:key];
        
        if ((eachPiece.paperType == Paper_Image) && (eachPiece.animated)) {
            
            // Loop through each animation key and store current state in a dictionary in each Paper
            for (NSArray *eachKey in eachPiece.layer.animationKeys) {
                //NSLog(@"Key Pause Paper: %d: %@",eachPiece.spawnID, eachKey);
                NSString *animKey = [NSString stringWithFormat:@"%@",eachKey];
                CAAnimation *animLayer = [[eachPiece.layer animationForKey:animKey] copy];
                [eachPiece.animLayerKeys setObject:animLayer forKey:[NSString stringWithFormat:@"%@",animKey]];
            }
            
            // Save when the animation stopped
            CFTimeInterval pausedTime = [eachPiece.layer convertTime:CACurrentMediaTime() fromLayer:nil];
            eachPiece.layer.speed = 0.0;
            eachPiece.layer.timeOffset = pausedTime;
        }
        
        if (eachPiece.paperType == Paper_Vector) {
            
            // Loop through each animation key and store current state in a dictionary in each Paper
            for (NSArray *eachKey in eachPiece.animShape.animationKeys) {
                //NSLog(@"Key Pause Path: %d: %@",eachPiece.spawnID, eachKey);
                NSString *animKey = [NSString stringWithFormat:@"%@",eachKey];
                CAAnimation *animLayer = [[eachPiece.animShape animationForKey:animKey] copy];
                [eachPiece.animLayerKeys setObject:animLayer forKey:[NSString stringWithFormat:@"%@",animKey]];
            }
            
            // Save when the animation stopped
            CFTimeInterval pausedTime = [eachPiece.animShape convertTime:CACurrentMediaTime() fromLayer:nil];
            eachPiece.animShape.speed = 0.0;
            eachPiece.animShape.timeOffset = pausedTime;
        }
        
    }
    
    return;
}

// Restores animation states when app returns to foreground
- (void) resumeAnimations {

    Paper *eachPiece;
    CAAnimation *animLayer;
    
    for (NSNumber *key in objects) {
        eachPiece = [objects objectForKey:key];
        
        // since some animations will set remove=YES when they complete,
        //   this prevents them from disappearing when the app moves
        //   to the background by switching it back to NO before it's
        //   processed by the main loop
        eachPiece.remove = NO;
        
        if ((eachPiece.paperType == Paper_Image) && (eachPiece.animated)) {
            
            // Loop through Paper dictionary and re-add each animation key
            for (NSString *animKey in eachPiece.animLayerKeys) {
                //NSLog(@"Key Add Paper: %d: %@",eachPiece.spawnID, animKey);
                animLayer = [eachPiece.animLayerKeys objectForKey:animKey];
                [eachPiece.layer addAnimation:animLayer forKey:animKey];
            }
            
            // Remove saved keys from each object
            [eachPiece.animLayerKeys removeAllObjects];
            
            // Resume animation at point it left off
            CFTimeInterval pausedTime = [eachPiece.layer timeOffset];
            eachPiece.layer.speed = 1.0;
            eachPiece.layer.timeOffset = 0.0;
            eachPiece.layer.beginTime = 0.0;
            CFTimeInterval timeSincePause = [eachPiece.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
            eachPiece.layer.beginTime = timeSincePause;
            
        }
        
        if (eachPiece.paperType == Paper_Vector) {
            // Loop through Paper dictionary and re-add each animation key
            for (NSString *animKey in eachPiece.animLayerKeys) {
                //NSLog(@"Key Add Path: %d: %@",eachPiece.spawnID, animKey);
                animLayer = [eachPiece.animLayerKeys objectForKey:animKey];
                [eachPiece.animShape addAnimation:animLayer forKey:animKey];
            }
            
            // Remove saved keys from each object
            [eachPiece.animLayerKeys removeAllObjects];
            
            // Resume animation at point it left off
            CFTimeInterval pausedTime = [eachPiece.animShape timeOffset];
            eachPiece.animShape.speed = 1.0;
            eachPiece.animShape.timeOffset = 0.0;
            eachPiece.animShape.beginTime = 0.0;
            CFTimeInterval timeSincePause = [eachPiece.animShape convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
            eachPiece.animShape.beginTime = timeSincePause;
        }
        
        eachPiece.resumeFromPause = YES;

    }
    
    return;
}

- (void) enteredBackground {
    
    Paper *eachPiece;
    
    for (NSNumber *key in objects) {
        eachPiece = [objects objectForKey:key];
        
        // since some animations will set remove=YES when they complete,
        //   this prevents them from disappearing when the app moves
        //   to the background by switching it back to NO before it's
        //   processed by the main loop
        eachPiece.remove = NO;
        eachPiece.resumeFromBackground = YES;
    
    }
    
}

// check to see if the max objects allowed has been reached
- (BOOL) maxObjectsReached {
    if (numObjects >= MAX_OBJECTS) { return YES; }
    else                           { return NO;  }
}

@end
