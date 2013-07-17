//
//  PapercutPadViewController.m
//  Papercut
//
//  Created by Jeff Bumgardner on 9/4/12.
//  Copyright (c) 2012 Jeff Bumgardner. All rights reserved.
//
//  Main view controller for the simulation.  Game loop resides here.
//

#import "PapercutPadViewController.h"
#import "Border.h"
#import "Paper.h"
#import "ObjManager.h"
#import "Messenger.h"
#import "Behavior.h"
#import "Vector2D.h"
#import "Timer.h"
#import "UIViewController+MJPopupViewController.h"
#import "StoryViewController.h"
#import "MenuViewController.h"
#import "Math.h"

@interface PapercutPadViewController ()

@end

@implementation PapercutPadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        //self.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    }
    return self;
}

- (id)initPapercut:(PaperProps[])prp
              anim:(PaperPropsAnim[])prpAnim
             touch:(PaperPropsTouchspot[])prpTouch
             group:(PaperGroups[])prpGroups
            random:(PaperRandom[])prpRandom
             sound:(PaperPropsSounds[])prpSounds
             timer:(PaperWorldTimers[])prpTimers
{
    
    self = [self initWithNibName:nil bundle:nil];
    
    // set _world to singleton ObjManager
    //   and initialize it with menu selection
    _world = [ObjManager theWorld];
    
    _world.objProps         = prp;
    _world.objAnimProps     = prpAnim;
    _world.objTouchProps    = prpTouch;
    _world.objGroups        = prpGroups;
    _world.objRandom        = prpRandom;
    _world.objSounds        = prpSounds;
    _world.objTimers        = prpTimers;
    
    [_world turnOffState:osPaused];
    
    // initialize the messenger
    _messenger = [Messenger theMessenger];
    
    // Set up the game loop timer
    _displayLoop = [CADisplayLink displayLinkWithTarget:self
                                               selector:@selector(mainSimulationLoop:)];
    
    //NSLog(@"Screen Scale %f", [[UIScreen mainScreen] scale]);
    if ([[UIScreen mainScreen] scale] > 1.0) {  // Retina display, in case I need to do something different
        _displayLoop.frameInterval = FRAME_INTERVAL; // 60 fps
    }
    else {
        _displayLoop.frameInterval = FRAME_INTERVAL; // 60 fps
    }
    
    [_displayLoop addToRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSDefaultRunLoopMode];
    
    
    // Create listeners for when app moves to background / foreground
    //   so the app can properly pause / save object states
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pauseTheWorld)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:NULL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resumeTheWorld)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:NULL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterTheBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:NULL];
    
    return self;
}

- (void)loadPapercut {
    
    // Setup background noise loops
  NSString *soundFilePath = [[NSBundle mainBundle] pathForResource: @"BG_Water" ofType: @"mp3"];
	NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: fileURL error: nil];
    _world.bg_audio01 = newPlayer;
	[_world.bg_audio01 prepareToPlay];
	[_world.bg_audio01 setNumberOfLoops:-1];
	[_world.bg_audio01 setDelegate: self];
    [_world.bg_audio01 setVolume:0.4];
    
	soundFilePath = [[NSBundle mainBundle] pathForResource: @"BG_Ambient" ofType: @"mp3"];
	fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: fileURL error: nil];
    _world.bg_audio02 = newPlayer;
	[_world.bg_audio02 prepareToPlay];
	[_world.bg_audio02 setNumberOfLoops:-1];
	[_world.bg_audio02 setDelegate: self];
    [_world.bg_audio02 setVolume:0.1];
    
    if (_world.optSound) {
        [_world.bg_audio01 play];
        [_world.bg_audio02 play];
    }
    
    _world.fps = 0.0167;
    _world.elapsedTime = 0.0;
    
    // Set accelerometer update to frame rate
#ifdef ACCEL_ON
    _world.accel.delegate = self;
	_world.accel.updateInterval = _world.fps;
#endif
    
    // setup the FX sounds
    [_world loadSounds];
    
    // Initialize variabless
    elapsedTime = 0.0;
    debugUpdate = 0;
    frameUpdate = 0;
    _accelX = 0.0;
    _lastScale = 1.0;
    _currScale = 1.0;
    _prevTimestamp = 0.0;
    
    // Mermaids-specific variables
    _world.bounceOffset = BOUNCE_OFFSET;
    _world.gravityFilter = GRAVITY_FILTER;
    _world.maxNotes = MAX_NOTES;
    
    // Get screen bounds for initial orientation and resolution
    CGRect sBounds = self.getScreenBoundsForCurrentOrientation;
    _world.viewWidth = sBounds.size.width;
    _world.viewHeight = sBounds.size.height;
    
    // Initialize the scene and border
    [_world initScene];
    [_world initBorder];
    
    // Populate additional Paper object managers and add all subviews
    for (NSNumber *key in _world.objects) {
        
        _eachPiece = [_world.objects objectForKey:key];
        
        // Populate other object managers
        if (_eachPiece.collision) {
            [_world addObj:_eachPiece forDictionary:_world.objects_coll];
        }
        
        if (_eachPiece.pinch) {
            [_world addObj:_eachPiece forDictionary:_world.objects_pinch];
        }
        
        if (_eachPiece.wiggleTime > 0.0) {
            [_world addObj:_eachPiece forDictionary:_world.objects_wiggle];
        }
        
        // Add each object as a subview
        //   But... don't add Info button if menus are off
        if (_eachPiece.objID == 45) {
#ifdef MENUS_ON
            [self.view addSubview:_eachPiece];
            infoRect = _eachPiece.frame;
#endif
        }
        else {
            [self.view addSubview:_eachPiece];
        }
        
        // Adjust the starting scale if necessary
        if (_eachPiece.scaleStart > 0.0) {
            _eachPiece.transform = [_world imageTransform:_eachPiece withScale:_eachPiece.scaleStart];
        }
        
    }
    
    // Add the border last so it's on top of all the other views
    [self.view addSubview:_world.border];
    
    // Create main timer OLD
    //self.mainTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_PERIOD
    //                                                  target:self selector:@selector(mainTimerCallback:) userInfo:nil repeats:YES];
    
    // Make sure the display loop is not paused
    [_displayLoop setPaused:NO];
    
    // Create gesture recognizer for pinch/zoom objects
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchPaper:)];
    pinchGesture.delegate = self;
    [self.view addGestureRecognizer:pinchGesture];
    
// Create text labels for debugging
    
#ifdef DEBUG_ON
    
    objectLabel = [[UILabel alloc] initWithFrame:CGRectMake(_world.borderWidth, _world.borderWidth-20, 500, 20)];
    [objectLabel setTextColor:[UIColor whiteColor]];
    [objectLabel setBackgroundColor:[UIColor clearColor]];
    [objectLabel setFont:[UIFont fontWithName: @"Arial" size: 14.0f]];
    [objectLabel setText:[NSString stringWithFormat:@"# of Objects: "]];
    [self.view addSubview:objectLabel];
    
    deltaLabel = [[UILabel alloc] initWithFrame:CGRectMake(_world.borderWidth, _world.borderWidth, 500, 40)];
    [deltaLabel setTextColor:[UIColor whiteColor]];
    [deltaLabel setBackgroundColor:[UIColor clearColor]];
    [deltaLabel setFont:[UIFont fontWithName: @"Arial" size: 14.0f]];
    [deltaLabel setNumberOfLines:0];
    [self.view addSubview:deltaLabel];
    
#endif
    
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // now display and starting running everything
    [self loadPapercut];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{

    // get the position where the user is touching and figure out if
    //   an object is being touched
    CGPoint currentPos = [[touches anyObject] locationInView:self.view];
    _touchPiece = [_world objTouched:currentPos];
    
    _firstTouch = currentPos;   // used for possible swiping
    Paper *sPaper;
    
#ifdef MENUS_ON
    
    // For the Info popup, the Z position of pinch objects needs
    //   to be dropped below 0 or they will appear above the
    //   popup.  The original Z position is reinstated when
    //   popup is dismissed.
    
    // Info menu
    if (CGRectContainsPoint(infoRect, currentPos)) {
        [_world changeZPosition:_world.objects_pinch toPos:-1];
        MenuViewController *popupVC = [[MenuViewController alloc] initWithVC:self nibName:@"MenuViewController" bundle:nil];
        [self presentPopupViewController:popupVC animationType:MJPopupViewAnimationFadeBottomLeft];
    }
    
#endif
    
    if (_world.optInteract) {
        
        // don't process touchspots if max objects reached
        if (![_world maxObjectsReached]) {
        
            // spawn an object if a world touchspot is entered
            int numTS = _world.objTouchProps[0].objID;
            
            for (int i = 1; i <= numTS; i++) {   // this skips the first record in the array intentionally
                
                if (_world.objTouchProps[i].objID > 0) {
                    
                    CGRect testTS = CGRectMake(_world.objTouchProps[i].tsX,
                                               _world.objTouchProps[i].tsY,
                                               _world.objTouchProps[i].tsWd,
                                               _world.objTouchProps[i].tsHt);
                    
                    if (CGRectContainsPoint(testTS, currentPos)) {
                        
                        //NSLog(@"PROPS %d, POS: %f, %f", numTS, currentPos.x, currentPos.y);
                        
                        int childObj;
                        NSUInteger randIndex = arc4random_uniform(5)+1;
                        // row 2 in objRandom is the random object row for TS
                        if (randIndex == 1) { childObj = _world.objRandom[2].rObjID01; }
                        if (randIndex == 2) { childObj = _world.objRandom[2].rObjID02; }
                        if (randIndex == 3) { childObj = _world.objRandom[2].rObjID03; }
                        if (randIndex == 4) { childObj = _world.objRandom[2].rObjID04; }
                        if (randIndex == 5) { childObj = _world.objRandom[2].rObjID05; }
                        //NSLog(@"TS Rand Obj %d", childObj);
                        
                        // spawn if an actual number is selected
                        if (childObj != 0) {
                            if (![_world.objects objectForKey:[NSNumber numberWithInt:childObj]]) {
                                sPaper = [_world spawnPiece:childObj wasSpawned:NO];
                                
                                // Add to collision manager if needed
                                if (sPaper.collision) {
                                    [_world addObj:sPaper forDictionary:_world.objects_coll];
                                }
                                
                                [self.view addSubview:sPaper];
                                
#ifdef TEST_FLIGHT_ON
                                //[TestFlight passCheckpoint:@"Touchspot"];
#endif
                                
                            }
                        }
                        
                    }
                }
            }
            
        }
        
        // if a touch object is returned, do something
        if (![_touchPiece isEqual:nil]) {
            
            //NSLog(@"TS Object Returned, Obj ID: %d, Child Image %d", _touchPiece.objID, _touchPiece.childImage);
            
            // if it should be destroyed on touch
            if (_touchPiece.killOnTouch) {
                [_world killPiece:_touchPiece];
            }
            
            // if it's a peeking object
            if ([_touchPiece.behavior isOn:btPeek]) {
                
                // turn off peek and timer
                [_touchPiece.behavior turnOff:btPeek];
                Timer *fTimer = [_touchPiece.behavior.timers objectForKey:[NSNumber numberWithInt:btPeek]];
                [fTimer turnTimerOff];
                [fTimer timerReset];
                
                // find a new random velocity
                int bAngle = 1;
                if (RAND_NUM(0.0,1.0) > 0.5) { bAngle = -1; }
                _touchPiece.behavior.vel.y = RAND_NUM(_touchPiece.behavior.bSeekOffset.x,
                                                      _touchPiece.behavior.bSeekOffset.y);
                _touchPiece.behavior.vel.y *= bAngle;
                
                int xDir = 1;
                if ([_world leftTopHalf:_touchPiece]) { xDir = -1; }
                _touchPiece.behavior.vel.x = -1.3 * xDir;
                
#ifdef TEST_FLIGHT_ON
                //[TestFlight passCheckpoint:@"Peek"];
#endif
                
            }
            
            // if moveable: zero velocity, reset decel and update transform
            if (_touchPiece.moveType == Move_Touch) {
                [_touchPiece.behavior.vel zero];
                [_touchPiece stopAnimating];
                CGAffineTransform transformPiece = [_world imageTransform:_touchPiece];
                _touchPiece.transform = transformPiece;
            }
            
            // don't spawn children if max objects reached
            if (![_world maxObjectsReached]) {
            
                // if touch location should spawn a child object, then do so
                if (_touchPiece.childImage != 0) {
                    
                    // check to see if Paper has a Touchspot - if so, only spawn
                    //   the image if the user touched within the Touchspot
                    if (((_touchPiece.touchSpot.size.height > 0) && (_touchPiece.touchSpot.size.width > 0))) {
                        
                        // if there's a touchSpot, create a new Rect based on current Paper center
                        //   and the touchSpot origin offset / size and the piece direction
                        
                        // find the start based on direction image is facing
                        //   and get the current object scale, in case it's been pinched,
                        //   that way we can scale the position of the touchspot as well
                        CGFloat tsOriginX;
                        CGFloat imageScale = fabsf(_touchPiece.transform.a);
                        
                        if (_touchPiece.dir == 1) {
                            tsOriginX = _touchPiece.center.x + (_touchPiece.touchSpot.origin.x * imageScale);
                        }
                        else {
                            tsOriginX = _touchPiece.center.x + (-(_touchPiece.touchSpot.origin.x * imageScale) -
                                                                (_touchPiece.touchSpot.size.width * imageScale));
                        }
                        
                        CGRect sTouch = CGRectMake(tsOriginX,
                                                   _touchPiece.center.y + (_touchPiece.touchSpot.origin.y * imageScale),
                                                   _touchPiece.touchSpot.size.width * imageScale,
                                                   _touchPiece.touchSpot.size.height * imageScale);
                        
                        // if our touch is inside the new Rect, spawn it
                        if (CGRectContainsPoint(sTouch, currentPos)) {
                            
                            int childObj;
                            if (_touchPiece.tsRand == 0) {
                                childObj = _touchPiece.childImage;
                            }
                            else {
                                // if random spawn, then figure out which object
                                NSUInteger randIndex = arc4random_uniform(5)+1;
                                //NSLog(@"randIndex %u", randIndex);
                                if (randIndex == 1) { childObj = _world.objRandom[_touchPiece.tsRand].rObjID01; }
                                if (randIndex == 2) { childObj = _world.objRandom[_touchPiece.tsRand].rObjID02; }
                                if (randIndex == 3) { childObj = _world.objRandom[_touchPiece.tsRand].rObjID03; }
                                if (randIndex == 4) { childObj = _world.objRandom[_touchPiece.tsRand].rObjID04; }
                                if (randIndex == 5) { childObj = _world.objRandom[_touchPiece.tsRand].rObjID05; }
                            }
                            
                            int randSax = arc4random_uniform(4)+1;
                            int randHrn = arc4random_uniform(2)+5;
                            
                            // set the volume for the mermaid horns based on the scale factor
                            //   0.9 = desired volume range (0.1 to 1.0)
                            //   0.1 = volume min from range
                            CGFloat volFinal = (0.9 / (_touchPiece.pinchMax - _touchPiece.pinchMin)) *
                                               (fabsf(_touchPiece.transform.a) + (0.1 - _touchPiece.pinchMin));
                            
                            //NSLog(@"Volume Ratio %f", volFinal);
                            
                            if (_touchPiece.objID == 5) {
                                [_world playSound:randSax atVolume:volFinal];
                            }
                            else if (_touchPiece.objID == 8) {
                                [_world playSound:randHrn atVolume:volFinal];
                            }
                            
                            if (_world.queue_clean.count <= _world.maxNotes) {
                                sPaper = [_world spawnPiece:_touchPiece objID:childObj isChild:YES];
                                
                                //NSLog(@"TS Spawn Paper");
                                // Add to collision manager if needed
                                if (sPaper.collision) {
                                    [_world addObj:sPaper forDictionary:_world.objects_coll];
                                }
                                
                                [self.view addSubview:sPaper];
                                //NSLog(@"sPaper: %d %@", sPaper.spawnID, sPaper.imagePath);
                            }
                            
                        }
                        
                    }
                    
                    // if no Touchspot, then spawn as normal
                    else {
                        
                        sPaper = [_world spawnPiece:_touchPiece isChild:YES];
                        
                        // Add to collision manager if needed
                        if (sPaper.collision) {
                            [_world addObj:sPaper forDictionary:_world.objects_coll];
                        }
                        
                        [self.view addSubview:sPaper];
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

    if (_world.optInteract) {
        
        // get touch info
        CGPoint beginPos = [[touches anyObject] previousLocationInView:self.view];
        CGPoint currentPos = [[touches anyObject] locationInView:self.view];
        _touchPiece = [_world objTouched:currentPos];
        
        // as long as view can be seen, allow user to touch it
        if ([_touchPiece.behavior viewCheck:vcCompletelyOffScreen]) {
            // do nothing
        }
        else if (![_touchPiece isEqual:nil] && (_touchPiece.moveType == Move_Touch))
        {
            CGPoint paperCenter;
            paperCenter = _touchPiece.center;
            
            // update the velocity
            _touchPiece.behavior.vel.x = currentPos.x - beginPos.x;
            if ((_touchPiece.behavior.vel.y == 0.0) &&
                (_touchPiece.bindType == Bind_OnEnter) &&
                (currentPos.y > beginPos.y)) {
                // do nothing to avoid accidentally moving object into border
            }
            else {
                _touchPiece.behavior.vel.y = currentPos.y - beginPos.y;
            }
            
            paperCenter.x += _touchPiece.behavior.vel.x;
            paperCenter.y += _touchPiece.behavior.vel.y;
            
            [_touchPiece setCenter:paperCenter];
            [_touchPiece startAnimating];
            
            // if the touched object is the Master of a Group,
            //   move all the other pieces in the group as well
            if (_touchPiece.groupID > 0) {
                [_world updateDirection:_touchPiece];
                CGAffineTransform transformPiece = [_world imageTransform:_touchPiece];
                _touchPiece.transform = transformPiece;
                [_world updateGroup:_touchPiece transform:transformPiece];
            }
            
        }
        else {
            // do nothing
        }
        
    }

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    _lastTouch = [[touches anyObject] locationInView:self.view];
    
    //NSLog(@"Start [%f %f] End [%f %f]", _firstTouch.x, _firstTouch.y, _lastTouch.x, _lastTouch.y);
    
    if (_world.optInteract) {
        
        BOOL dirLeft = NO;
    
        // check for chime swipe only if complete swipe is across bottom of screen
        if ((_firstTouch.y >= 800) && (_lastTouch.y >= 800)) {
            
            CGFloat swipeDeltaX = _firstTouch.x - _lastTouch.x;
            
            // only fire chime if greater than minimum swipe length
            if (fabsf(swipeDeltaX) > MIN_CHIME_DIST) {
                
                // determine direction of swipe
                CGFloat leftX, rightX;
                if (swipeDeltaX > 0) {
                    dirLeft = YES;
                    leftX = _lastTouch.x;
                    rightX = _firstTouch.x;
                }
                else {
                    leftX = _firstTouch.x;
                    rightX = _lastTouch.x;
                }
               
                [self chimeSwipe:dirLeft leftTouch:leftX rightTouch:rightX];
                
            }
            
        }
        
    }

}

-(void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.type == UIEventSubtypeMotionShake )
    {
        
        if (_world.optInteract) {
            
            Paper *sPaper;
            
            if (_world.objects_shake.count == 0) {
                
                // randomly choose an object in the array
                NSUInteger randIndex = arc4random_uniform([_world.queue_shake count]);
                //NSLog(@"Shake Random: %u", randIndex);
                int objID = [[_world.queue_shake objectAtIndex:randIndex] intValue];
                
                sPaper = [_world spawnPiece:objID];
                [_world addObj:sPaper forDictionary:_world.objects_shake];
                
                [self.view addSubview:sPaper];
                
            }
            
        }
        
    }
}

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.type == UIEventSubtypeMotionShake )
    {
        //NSLog(@"Shake Stop");
    }
}

-(void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.type == UIEventSubtypeMotionShake )
    {
        //NSLog(@"Shake Cancelled");
    }
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
#ifdef ACCEL_ON
    if (_world.optInteract) {
        _world.accelX = (acceleration.x * GRAVITY_FILTER) + (_world.accelX * (1.0 - GRAVITY_FILTER));
    }
#endif
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // for recognizing multiple gestures at once
    return YES;
    //return NO;
}

- (void)viewDidUnload
{
    
    [super viewDidUnload];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	//return UIInterfaceOrientationIsLandscape(interfaceOrientation);
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Resize the border if the orientation changes
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    { _world.border.frame = CGRectMake(0, 0, 1024, 768); }
    else
    { _world.border.frame = CGRectMake(0, 0, 768, 1024); }
    
    // Get screen bounds for current orientation and resolution
    CGRect sBounds = self.getScreenBoundsForCurrentOrientation;
    _world.viewWidth = sBounds.size.width;
    _world.viewHeight = sBounds.size.height;
    
}

- (void)mainSimulationLoop:(id)sender {
    
// MAIN UPDATE LOOP
    
// skip update if app is paused or in background
if (![_world isStateOn:osPaused]) {
    
    Paper       *eachPiece;             // used for enumeration of _world.objects
    Paper       *removePiece;           // Paper to remove from _world.objects
    BOOL        transformEnabled = YES; // triggers transform function
    
    debugUpdate++;
    frameUpdate++;
    
    NSDate *start = [NSDate date];
    
    CGFloat frameTime = 0.0;
    CGFloat trueFrameTime = 0.0;
    if (_prevTimestamp != 0.0) {
        
        frameTime = _displayLoop.timestamp - _prevTimestamp;
        trueFrameTime = frameTime;
        
        // because the timestamp always reflects the current time of the
        //   device, overwrite any huge frameTime value that might occur
        //   due to the app being put in an inactive state, otherwise when
        //   resuming, some animations will jump forward in time and
        //   disappear because they think they've been completed
        if (frameTime > (_world.fps * 2.5)) {
            frameTime = _world.fps;
        }
        
    }
    _prevTimestamp = _displayLoop.timestamp;
    
    // track total elapsed time
    _world.elapsedTime += frameTime;

    // loop through each piece and update
    for (NSNumber *key in _world.objects) {
        
        eachPiece = [_world.objects objectForKey:key];
        eachPiece.transformEnabled = YES;
        
        // ___ MOVE UPDATE ______________________________
        //  Only update moveable pieces
        if ((eachPiece.moveType == Move_Touch) || (eachPiece.moveType == Move_Auto)) {

            // create center point
            CGPoint paperCenter = [eachPiece getCenterPoint];
            //if (eachPiece.objID == 29) { NSLog(@"Eel Center [%f %f]", paperCenter.x, paperCenter.y); }
            
            // Update timers
            [eachPiece.behavior updateTimers:_world.fps];
        
            // Handle bounded properties
            if ((eachPiece.bindType == Bind_Always) || (eachPiece.bindType == Bind_OnEnter)) {
                
                // change bound property if Bind_OnEnter has entered the view
                if ((eachPiece.bindType == Bind_OnEnter) && (!eachPiece.bounded)) {

                    // turn on Sink behavior if a shake image enters the screen
                    if ([eachPiece.behavior viewCheck:vcOnScreenWithinBorder]) {
                        eachPiece.bounded = YES;
                        if (eachPiece.spawnByShake) { [eachPiece.behavior turnOn:btSink]; }
                    }

                }
                
                if ((eachPiece.bounded) && (!eachPiece.spawnByShake)) {
                    paperCenter = [_world keepInBounds:eachPiece forBounds:eachPiece.behavior.viewCheckType];
                }

            }
            
            if (COLLISION) {
                
                // collision detection - alter velocity vectors accordingly
                if ((eachPiece.collision) && (_world.optInteract)) {
                    
                    // only check against objects with collision enabled
                    Paper *colPiece;
                    for (NSNumber *key in _world.objects_coll) {
                        
                        colPiece = [_world.objects_coll objectForKey:key];
                        if ((colPiece.collision) && (colPiece.objID != eachPiece.objID)) {  // exclude collision against itself
                            if (CGRectIntersectsRect(eachPiece.frame, colPiece.frame)) {    // pieces have collided
                                
                                // move the main object slightly away based on the intersection's
                                //   height or width to prevent the two from sticking to each other
                                CGRect iRect = CGRectIntersection(eachPiece.frame, colPiece.frame);
                                if (iRect.size.height < iRect.size.width) {         // collision vertically
                                    if (eachPiece.center.y < colPiece.center.y) {   // main piece above secondary piece
                                        paperCenter.y -= iRect.size.height;
                                    }
                                    else {                                          // main piece below secondary piece
                                        paperCenter.y += iRect.size.height;
                                    }
                                }
                                else {                                              // collision horizontally
                                    if (eachPiece.center.x < colPiece.center.x) {   // main piece left of secondary piece
                                        paperCenter.x -= iRect.size.width;
                                    }
                                    else {                                          // main piece right of secondary piece
                                        paperCenter.x += iRect.size.width;
                                    }
                                }
                                
                                // turn off transform so the objects don't stutter
                                eachPiece.transformEnabled = NO;
                                
                                // update the velocity vectors now
                                [_world collidePiece:eachPiece withPiece:colPiece];
                            }
                        }
                    }
                    
                }
                
            }
    
            // determine image direction and transformation matrix
            //   based on flip info, velocity and rotation angle,
            //   only transform if piece is within borders to prevent stuttering
            //   do not transform if Peek is on
                
            [_world updateDirection:eachPiece];
            CGAffineTransform transformPiece = [_world imageTransform:eachPiece];
            
            if (eachPiece.paperType == Paper_Image) {
                if (eachPiece.transformEnabled) {
                    eachPiece.transform = transformPiece;
                }
            }
            
            Vector2D *paperDest;
            paperDest = [[Vector2D alloc] init];
            paperDest = [paperDest pointToVector:paperCenter];
            
            // finally move the stupid thing!
            [eachPiece.behavior calculateForce:frameTime totalTime:_world.elapsedTime forPoint:paperDest];
            [eachPiece applyForce:[paperDest add:eachPiece.behavior.vRunning]];
            
            // if the object is a Master of a group,
            //   move all the group Subs based on their offsets
            if ((eachPiece.groupID > 0) && (transformEnabled)) {
                [_world updateGroup:eachPiece transform:transformPiece];
            }
            
            // __ POSITION SPAWN ____________
            // if the position of the object should spawn something,
            //   do so if it randomly decides to (10% spawn rate)

            // MURENE Note fish check
            if (![_world isWorldTimerOn:wtMurene]) {
            
                for (int i = 0; i < _world.queue_clean.count; i++) {
                    
                    int sID = [[_world.queue_clean objectAtIndex:i] intValue];
                    
                    // If the current piece is in the clean queue, and it's not currently
                    //   not fleeing, then check further to see if it's in range of Murene
                    if ((sID == eachPiece.spawnID) && (![eachPiece.behavior isOn:btFlee])) {
                        
                        CGRect spawnRect = CGRectMake(110, 40, 40, 120);
                        int randSpawn = arc4random_uniform(1000)+1;
                        if ((CGRectContainsPoint(spawnRect, paperCenter)) && (randSpawn <= 30) && (![_world isStateOn:osMurene])) {
                            
                            // turn on World State and Timer
                            [_world turnOnState:osMurene];
                            [_world turnWorldTimer:wtMurene toOn:YES];
                            
                            // Add Seek/Flee to Murene and Target Fish
                            [_messenger queueObject:44 behavior:btSeek turnOn:YES target:sID];
                            [_messenger queueObject:sID behavior:btFlee turnOn:YES target:44];
                            
                        }
                        
                    }
                    
                }
                
            }

        }
        
        // ___ ANIM UPDATE ______________________________
        //  Handle any updates for animated pieces here
        if (eachPiece.moveType == Move_Anim) {
            
            // svg anchored pieces (weeds)
            if ((eachPiece.paperType == Paper_Vector) && (_world.optInteract)) {
                // rotate via accelerometer
#ifdef ACCEL_ON
                CATransform3D rotatePiece3D = CATransform3DMakeRotation(-(_world.accelX/(2*eachPiece.mass)), 0.0, 0.0, 1.0);
                eachPiece.animShape.transform = rotatePiece3D;
#endif
            }
            
        }
        
        // if the piece should be removed from the world, tag it;
        //   this will only grab the last piece found in the update;
        //   but the loop is called fast enough that multiple removes will
        //     appear to occur simultaneously
        if (eachPiece.remove) { removePiece = eachPiece; }
        
    }
// end MOVE UPDATE
    
    
    // ___ WORLD TIMERS _______________________
    // update any world timers and handle completed ones
    [_world updateWorldTimers:_world.fps];
    [_world processWorldTimers];
    
    // ___ WORLD CLEANING ________________________
    // initiate fish cleaning if necessary
    if ((_world.queue_clean.count >= _world.cleanMax) && (![_world isStateOn:osCleaning])) {
        
#ifdef TEST_FLIGHT_ON
        //[TestFlight passCheckpoint:@"Cleaning"];
#endif
        
        [_world turnOnState:osCleaning];
        Paper *sPaper = [_world spawnPiece:25];
        
        // Add to collision manager if needed
        if (sPaper.collision) {
            [_world addObj:sPaper forDictionary:_world.objects_coll];
        }
        
        [self.view addSubview:sPaper];
        
        // Add seek/flee messages
        int spawnID = [[_world.queue_clean objectAtIndex:0] intValue];
        [_messenger queueObject:sPaper.spawnID behavior:btSeek turnOn:YES target:spawnID];
        [_messenger queueObject:spawnID behavior:btFlee turnOn:YES target:sPaper.spawnID];
        
    }

    // ___ MESSAGE PROCESSING _________________________
    [_messenger processQueue];
    for (NSNumber *key in _world.queue_view) {
        // add spawned views to the view controller
        eachPiece = [_world.queue_view objectForKey:key];
        [self.view addSubview:eachPiece];
    }
    [_world.queue_view removeAllObjects];
    
    // ___ REMOVE UPDATE ______________________________
    // so now that we aren't enumerating, remove the last flagged piece
    //   from the world and view/layer
    if (removePiece != nil) {
        //NSLog(@"Remove Piece: %d|%d %@", removePiece.objID, removePiece.spawnID, removePiece.imagePath);
        
        // play a sound if needed on remove
        if (removePiece.objID == 37) {  // BLOWFISH EXPLODE
            
            //int randPlop = arc4random_uniform(5)+10;
            int randPlop = 7;
            [_world playSound:randPlop];
        }
        
        [_world delObj:removePiece];
        Paper *sPaper;
        
        // only do this if not part of an image swap (i.e. note -> notefish)
        if ((removePiece.childImage > 0) && (!removePiece.manageRemove)) {
            
            if (removePiece.paperType == Paper_Vector) {
                //CGPoint spawnPoint = CGPointMake(removePiece.animShape.position.x + (removePiece.animShape.frame.size.width/2),
                //                                 removePiece.animShape.position.y + (removePiece.animShape.frame.size.height/2));
                CGPoint spawnPoint = removePiece.curvePoint;

                sPaper = [_world spawnPiece:removePiece.childImage atPoint:spawnPoint];
                
                if (![sPaper.behavior viewCheck:vcCenterOnScreen atPoint:spawnPoint]) {
                    // immediately remove if fish is off screen
                    sPaper.remove = YES;
                }
                else {
                    // add to the clean queue for later removal
                    [_world addToCleanQueue:sPaper.spawnID];
                }
                
            }
            else {
                sPaper = [_world spawnPiece:removePiece isChild:YES];
            }
            
            // Add to collision manager if needed
            if (sPaper.collision) {
                [_world addObj:sPaper forDictionary:_world.objects_coll];
            }
            
            [self.view addSubview:sPaper];
            
        }
        
        [removePiece removeFromSuperview];
        removePiece = nil;
    }
    
    NSTimeInterval timeInterval;
    
    // for calculating / displaying the FPS
    if (debugUpdate > (1/_world.fps)) {
        
        timeInterval = -1 / [start timeIntervalSinceNow];
        
#ifdef DEBUG_ON
        [self updateTextLabel:deltaLabel gameTime:(1/trueFrameTime) loopTime:trueFrameTime];
#endif
        
        // Reset debug update counter
        debugUpdate = 0;
    }
    
    // log framerate every 10 seconds
    if (frameUpdate > ((1/_world.fps)*10)) {
        timeInterval = -1 / [start timeIntervalSinceNow];
        //NSLog(@"FPS: %f  Frametime (sec): %f", 1/trueFrameTime, trueFrameTime);
        //NSLog(@"# of Objects: %u  MaxObjCount: %u", [_world.objects count], _world.numObjects);
        frameUpdate = 0;
    }
    
#ifdef DEBUG_ON
    numObjects = [NSString stringWithFormat:@"[# of Objects: %u]",
                           [_world.objects count]];
    objectLabel.text = numObjects;
#endif
    
}
    
}

- (void)updateTextLabel:(UILabel *)theLabel gameTime:(CGFloat)fTime loopTime:(CGFloat)lTime {
    NSString *label01 = [NSString stringWithFormat:@"Coded FPS: %f  Frametime (sec): %f\nActual FPS: %f  Frametime (sec): %f",
                         fTime, 1/fTime, lTime, 1/lTime];
    theLabel.text = label01;
}

- (CGRect)getScreenBoundsForCurrentOrientation {
    return [self getScreenBoundsForOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (CGRect)getScreenBoundsForOrientation:(UIInterfaceOrientation)orientation {
    
    UIScreen *screen = [UIScreen mainScreen];
    CGRect fullScreenRect = screen.bounds; //implicitly in Portrait orientation.
    
    if(orientation == UIInterfaceOrientationLandscapeRight || orientation ==  UIInterfaceOrientationLandscapeLeft){
        CGRect temp = CGRectZero;
        temp.size.width = fullScreenRect.size.height;
        temp.size.height = fullScreenRect.size.width;
        fullScreenRect = temp;
    }
    
    return fullScreenRect;
}

// GESTURE RECOGNIZERS

- (void)pinchPaper:(UIPinchGestureRecognizer *)recognizer {
    //NSLog(@"Pinch scale: %f", recognizer.scale);
    
    CALayer *pinchLayer;
    Paper *pinchPiece;
    id layerDelegate;
    
    CGPoint touchPoint = [recognizer locationInView:self.view];
    pinchLayer = [self.view.layer.presentationLayer hitTest: touchPoint];
    // The layer delegate of a view is usually the view it's associated with.
    layerDelegate = [pinchLayer delegate];
    
    for (NSNumber *key in _world.objects_pinch) {
        
        pinchPiece = [_world.objects_pinch objectForKey:key];
        
        // If the delegate matches one of our pinch objects, then scale it
        if (layerDelegate == pinchPiece) {
            
            if (recognizer.state == UIGestureRecognizerStateEnded
                || recognizer.state == UIGestureRecognizerStateChanged) {
                //NSLog(@"gesture.scale = %f", recognizer.scale);
                
                // stop the piece so it doesn't move when we pinch it
                [pinchPiece.behavior.vel zero];
                
                CGFloat currentScale = pinchPiece.frame.size.width / pinchPiece.bounds.size.width;
                CGFloat newScale = currentScale * recognizer.scale;
                
                if (newScale < pinchPiece.pinchMin) {
                    newScale = pinchPiece.pinchMin;
                }
                if (newScale > pinchPiece.pinchMax) {
                    newScale = pinchPiece.pinchMax;
                }
                
                //NSLog(@"newScale = %f", newScale);
                pinchPiece.transform = [_world imageTransform:pinchPiece withScale:newScale];
                recognizer.scale = 1;
            }
            
            break;
        }
        
    }
}

- (void)chimeSwipe:(BOOL)dirLeft leftTouch:(CGFloat)xLeft rightTouch:(CGFloat)xRight {

    Paper *wPiece;
    
    for (NSNumber *key in _world.objects_wiggle) {
        
        // wiggle each piece only if it's within the swipe
        wPiece = [_world.objects_wiggle objectForKey:key];
        CGFloat xPoint = wPiece.posSpawn.x + wPiece.halfSize.x;
        if ((xPoint >= xLeft) && (xPoint <= xRight)) {
            [wPiece wiggle];
        }
        
    }
    
    // determine sound based on swipe direction
    int randSound;
    if (dirLeft) {
        randSound = arc4random_uniform(2)+20;
    }
    else {
        randSound = arc4random_uniform(2)+22;
    }
    
    [_world playSound:randSound];
    
#ifdef TEST_FLIGHT_ON
    //[TestFlight passCheckpoint:@"Chime"];
#endif
    
}

// for converting nanoseconds to seconds
double MachTimeToSecs(uint64_t time)
{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer / (double)timebase.denom / 1e9;
}


- (void) pauseTheWorld {
    
    //NSLog(@"pauseTheWorld");
    
    // skips the update loop
    [_world turnOnState:osPaused];
    _displayLoop.paused = YES;
    
    if (_world.optSound) {
        [_world.bg_audio01 pause];             // pause background noise
        [_world.bg_audio02 pause];
    }
    
    [_world pauseAnimations];   // saves animation states
    return;
}

- (void) resumeTheWorld {
    
    //NSLog(@"resumeTheWorld");
    
    // enables the update loop
    [_world turnOffState:osPaused];
    _displayLoop.paused = NO;
    
    if (_world.optSound) {
        [_world.bg_audio01 play];              // play background noise
        [_world.bg_audio02 play];
    }
    
    [_world resumeAnimations];  // restores animation states
    return;
}

- (void) enterTheBackground {
    
    [_world enteredBackground];
    return;
    
}

// Functions for switching the first responder to this view controller
//   Normally the first responder is SplashViewController
-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:NO];
    [self becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:NO];
}

-(void)viewDidDisappear:(BOOL)animated {
    [self resignFirstResponder];
    [super viewDidDisappear:NO];
    
    // reset the view and object manager
    [self unloadPapercut];
    
    // this sets the property arrays to nil
    //   only should be run when exiting the Papercut completely
    //   do not run during a simple scene reset
    [_world resetObjProperties];
    
    // Fade out the view controller to make the transition smoother    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        // remove the view controller
        [self.view removeFromSuperview];
    }];
    
}

- (void)unloadPapercut {
    
    // Release any retained subviews of the main view
    for (NSNumber *key in _world.objects) {
        
        _eachPiece = [_world.objects objectForKey:key];
        [_eachPiece removeFromSuperview];
    }
    
    [_world.border removeFromSuperview];
    
#ifdef DEBUG_ON
    [objectLabel removeFromSuperview];
    [deltaLabel removeFromSuperview];
#endif
    
    
    // reset _world since its a singleton
    //NSLog(@"View Unload");
    [_world resetObjManager];
    
    // kill the timer, otherwise it will compound each
    //   time the view loads - OLD CODE
    //[self.mainTimer invalidate];
    
    // pause the display loop
    [_displayLoop setPaused:YES];
    
}

@end
