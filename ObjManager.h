//
//  ObjManager.h
//  Papercut
//
//  Created by Jeff Bumgardner on 9/16/12.
//  Copyright (c) 2012 Jeff Bumgardner. All rights reserved.
//
//  Class that manages objects at a high level (the "world"),
//    including sounds, world timers and world states
//    Also pauses / resumes animations when app enters background
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVAudioPlayer.h>
#import "Variables.h"

@class Paper;
@class PaperPath;
@class Border;
@class Timer;
@class Messenger;

@interface ObjManager : NSObject < AVAudioPlayerDelegate >  {
    NSMutableDictionary *objects;       // dictionary of Paper objects
    NSMutableDictionary *objects_coll;  // dictionary of Collision objects
    NSMutableDictionary *objects_pinch; // dictionary of Pinch objects
    NSMutableDictionary *objects_shake; // dictionary of Shake objects
    NSMutableDictionary *objects_neighbors;
    NSMutableDictionary *objects_wiggle;
    NSMutableDictionary *objects_sounds;
    NSMutableDictionary *objects_sounds_splash;
    NSMutableDictionary *queue_view;
    NSMutableDictionary *world_timers;       // world-level timers
    
    NSMutableArray      *queue_shake;
    NSMutableArray      *queue_clean;
    
    UIAccelerometer     *accel;
    CGFloat             accelX;
    
    SystemSoundID       splashSounds[2];
    
    int                 osFlags;        // world-level flags
    
    int                 spawnID;        // counter for spawned object IDs
    int                 timerID;        // counter for timer objects
    Border              *border;        // view border
    int                 borderWidth;    // border width
    int                 borderBound;    // border bounds
    int                 viewWidth;
    int                 viewHeight;
    
    CGFloat             fps;
    CGFloat             bounceOffset;
    CGFloat             gravityFilter;
    CGFloat             elapsedTime;
    
    int                 cleanMin;
    int                 cleanMax;
    
    int                 maxNotes;       // max # of note fish allowed at once
    int                 numObjects;
}

@property (nonatomic, retain) NSMutableDictionary *objects;
@property (nonatomic, retain) NSMutableDictionary *objects_coll;
@property (nonatomic, retain) NSMutableDictionary *objects_pinch;
@property (nonatomic, retain) NSMutableDictionary *objects_shake;
@property (nonatomic, retain) NSMutableDictionary *objects_neighbors;
@property (nonatomic, retain) NSMutableDictionary *objects_wiggle;

@property (nonatomic, retain) NSMutableDictionary *objects_sounds;
@property (nonatomic, retain) NSMutableDictionary *objects_sounds_splash;
@property (nonatomic, retain) AVAudioPlayer *fx_audio01;
@property (nonatomic, retain) AVAudioPlayer *fx_audio02;
@property (nonatomic, retain) AVAudioPlayer *fx_audio03;
@property (nonatomic, retain) AVAudioPlayer *bg_audio01;
@property (nonatomic, retain) AVAudioPlayer *bg_audio02;

@property (nonatomic, retain) NSMutableDictionary *queue_view;
@property (nonatomic, retain) NSMutableDictionary *world_timers;
@property (nonatomic, retain) NSMutableArray      *queue_shake;
@property (nonatomic, retain) NSMutableArray      *queue_clean;

@property (nonatomic, strong) Messenger *messenger;

@property (nonatomic, retain) UIAccelerometer *accel;
@property (assign) CGFloat accelX;

@property (assign) int osFlags;

@property (assign) int spawnID;
@property (assign) int timerID;
@property (nonatomic, retain) Border *border;
@property (assign) int borderWidth;
@property (assign) int borderBound;
@property (assign) int viewWidth;
@property (assign) int viewHeight;

@property (assign) CGFloat fps;
@property (assign) CGFloat bounceOffset;
@property (assign) CGFloat gravityFilter;
@property (assign) CGFloat elapsedTime;

@property (assign) int cleanMin;
@property (assign) int cleanMax;

@property (assign) int maxNotes;
@property (assign) int numObjects;

@property (assign) PaperProps *objProps;                    // holds PaperProps from menu selection
@property (assign) PaperPropsAnim *objAnimProps;            // holds PaperPropsAnim from menu selection
@property (assign) PaperPropsTouchspot *objTouchProps;      // holds PaperPropsTouchspot from menu selection
@property (assign) PaperGroups *objGroups;                  // holds PaperGroup from menu selection
@property (assign) PaperRandom *objRandom;                  // holds PaperRandom from menu selection
@property (assign) PaperPropsSounds *objSounds;             // holds PaperPropsSounds from menu selection
@property (assign) PaperWorldTimers *objTimers;             // holds PaperWorldTimers from menu selection

@property (assign) BOOL optInteract;
@property (assign) BOOL optSound;

// Class methods
+ (id) theWorld;         // singleton

// Instance methods
- (ObjManager*) initWithBlank;                                      // setup blank array of Papers
- (void) initBorder;                                                // create border
- (void) initScene;                                                 // create all Paper objects
- (void) resetObjManager;                                           // resets ObjManager singleton on return to main menu
- (void) resetObjProperties;                                        // resets only Property arrays

- (void) loadSounds;
- (void) playSound:(int)sID;
- (void) playSound:(int)sID atVolume:(CGFloat)vol;
- (void) loadSplashSounds;
- (void) playSplashSound:(int)sID;

- (BOOL)isStateOn:(ObjState)os;
- (void)turnOnState:(ObjState)os;
- (void)turnOffState:(ObjState)os;
- (void)turnOffAllStates;

- (void) addObj:(Paper *)paperPiece forDictionary:(NSMutableDictionary *)objDict;   // add to specified dictionary
- (void) addObj:(Paper *)paperPiece wasSpawned:(BOOL)spawned;                       // add to objects dictionary for spawned objects
- (void) delObj:(Paper *)paperPiece;                                                // remove from objects dictionary

- (void) addToView:(Paper *)paperPiece;
- (void) addToCleanQueue:(int)objID;

- (void) addWorldTimer:(Timer *)objTimer forType:(WorldTimer)wt;    // adds a world timer to the ObjManager
- (void) updateWorldTimers:(CGFloat)interval;                       // updates all active world timers
- (void) turnWorldTimer:(WorldTimer)wt toOn:(BOOL)isOn;             // turn world timer on/off
- (void) processWorldTimers;                                        // executes specific code when a world timer completes
- (BOOL) isWorldTimerOn:(WorldTimer)wt;

- (Paper*) objTouched:(CGPoint)touchPos;                            // determine which object was touched
- (Paper*) getObject:(int)objID;                                    // get object based on objID

- (void) collidePiece:(Paper *)piece1 withPiece:(Paper *)piece2;    // recalcs velocity of pieces as they collide
- (void) updateDirection:(Paper *)imagePiece;                       // updates image direction
- (CGAffineTransform) imageTransform:(Paper *)imagePiece;           // determines image transform
- (CGAffineTransform) imageTransform:(Paper *)imagePiece withScale:(CGFloat)scale;  // determine image transform w/ scale

- (BOOL) leftTopHalf:(Paper *)imagePiece;                                   // is the object in the upper half or left half of the screen?
- (CGPoint) keepInBounds:(Paper *)pPiece forBounds:(ViewCheckType)vcType;   // keep the object within its ViewCheckType boundary

- (void) updateGroup:(Paper *)mstrPiece;                            // updates the center of all Sub objects in a group
- (void) updateGroup:(Paper *)mstrPiece                             // this one includes a specific transform (like scale)
           transform:(CGAffineTransform)mstrTransform;              

- (Paper*) spawnPiece:(Paper *)touchedPiece isChild:(BOOL)child;    // spawning a child object
- (Paper*) spawnPiece:(Paper *)touchedPiece objID:(int)childImage isChild:(BOOL)child;    // spawning based on Paper child/touchspot
- (Paper*) spawnPiece:(int)objID;                                   // spawning based on Object ID
- (Paper*) spawnPiece:(int)objID wasSpawned:(BOOL)spawn;            // spawning an object spawned by another piece
- (Paper*) spawnPiece:(int)objID atPoint:(CGPoint)pos;              // spawning an object at a specific point

- (Paper*) spawnPiece:(Paper *)parentPiece objID:(int)obj childID:(int)child wasSpawned:(BOOL)spawn atPoint:(CGPoint)pos;

- (void) killPiece:(Paper *)piece;      // destroy the object, remove it from all dictionarys, etc
- (BOOL) maxObjectsReached;             // have the maximum allowed # of objects been reached?

- (void) tagNeighbors:(Paper*)piece ofQueue:(NSMutableArray*)queue;         // used for flocking, who is close to the object?
- (void) changeZPosition:(NSMutableDictionary *)objDict toPos:(int)zPos;    // changes the z position for an object

- (void) pauseAnimations;                                           // pauses update & saves all animation states
- (void) resumeAnimations;                                          // resumes update & restores all animation states
- (void) enteredBackground;                                         // additional housekeeping if switching apps

@end
