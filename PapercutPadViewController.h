//
//  PapercutPadViewController.h
//  Papercut
//
//  Created by Jeff Bumgardner on 9/4/12.
//  Copyright (c) 2012 Jeff Bumgardner. All rights reserved.
//
//  Main view controller for the simulation.  Game loop resides here.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AudioToolbox/AudioServices.h>
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <unistd.h>

#import "Variables.h"

@class Border;
@class Paper;
@class PaperPath;
@class ObjManager;
@class Messenger;

@interface PapercutPadViewController : UIViewController <UIAccelerometerDelegate, UIGestureRecognizerDelegate, AVAudioPlayerDelegate> {

    // primary attributes
    CGFloat elapsedTime;            // amount of elasped time
    int     debugUpdate;
    int     frameUpdate;
    
    CGRect infoRect;                // for the info button
    
    // debugging attributes
    UILabel *deltaLabel;            // label for movement deltas
    UILabel *objectLabel;
    NSString *numObjects;
    
}

@property (nonatomic, strong) ObjManager *world;            // object manager for all images displayed
@property (nonatomic, strong) Messenger *messenger;
@property (nonatomic, retain) NSTimer *mainTimer;           // OLD loop timer
@property (nonatomic, retain) CADisplayLink *displayLoop;     // main game loop
@property (nonatomic, strong) Paper *touchPiece;            // temp Paper object for touch responses
@property (nonatomic, strong) Paper *eachPiece;             // temp Paper object for dictionary iteration

@property (assign) CFTimeInterval prevTimestamp;
@property (assign) CGPoint firstTouch;                      // first spot touched - from touchesBegan
@property (assign) CGPoint lastTouch;

@property (assign) CGFloat accelX;
@property (assign) CGFloat lastScale;
@property (assign) CGFloat currScale;

@property (nonatomic, retain) AVAudioPlayer *audio;         
@property (nonatomic, retain) AVAudioPlayer *audio_2;

- (id)initPapercut:(PaperProps[])prp
              anim:(PaperPropsAnim[])prpAnim
             touch:(PaperPropsTouchspot[])prpTouch
             group:(PaperGroups[])prpGroups
            random:(PaperRandom[])prpRandom
             sound:(PaperPropsSounds[])prpSounds
             timer:(PaperWorldTimers[])prpTimers;    // custom initialization based on menu selection

- (void)loadPapercut;
- (void)unloadPapercut;
- (void)chimeSwipe:(BOOL)dirLeft leftTouch:(CGFloat)xLeft rightTouch:(CGFloat)xRight;

@end
