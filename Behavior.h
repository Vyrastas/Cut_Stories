//
//  Behavior.h
//  Papercut
//
//  Created by Jeff Bumgardner on 1/1/13.
//  Copyright (c) 2013 Jeff Bumgardner. All rights reserved.
//
//  This class encapsulates all movement / steering behaviors for an object, including:
//    Flocking, Waiting, Flip, Anim, Peek, Flee, Drift, RandVel, Bob, Decel, Sink, Seek, Toroid
//
//  It calculates the final force based on all behaviors turned on for an object and applies it
//    to the object's position each frame.
//
//  Portions of this class were derived from the SteeringBehaviors class
//    written by Mat Buckland (c) 2002, found in the book "Programming Game AI by Example".
//    More info at ai-junkie.com.
//

#import <Foundation/Foundation.h>
#import "Variables.h"

@class Paper;
@class Vector2D;
@class ObjManager;
@class Timer;

@interface Behavior : NSObject {
    
@private
    
    Vector2D        *vel;       // object's current velocity (drift)
    CGFloat         velY;       // original starting velocity
    CGFloat         velX;       // original starting velocity
    
    Vector2D        *vRunning;  // tracks running force for a single update loop
    Vector2D        *vTarget;
    
    int             idTarget;
    
    Paper           *pSelf;         // Paper piece that owns the instance
    Paper           *pTarget1;      // Target for seek, flee, etc
    Paper           *pTarget2;
    
    int             iFlags;         // holds flags that determine behavior

    DecelType       decelType;
    int             flip;
    BOOL            flipX;          // YES = flip about X axis, NO = Y axis, i.e. the axis it FACES / travels along
    CGFloat         bobAmp;         // bob amplitude, higher = less bob
    CGFloat         bobOffset;      // offset so objects bob out of sync
    
    int             spawnCount;     // # of times to respawn, 0 = infinite
    int             spawnCountCheck;// current # of times respawned

    CGFloat         bSpeed;         // max speed for things like flee, seek
    BOOL            bKillOnArrive;  // destroy object when seek/arrive conditions met
    CGPoint         bSeekOffset;    // offset from center for seek
    BOOL            bFlocking;
    
    CGFloat         rVelMax;        // range of random vel along current trajectory
    CGFloat         rVelMin;
    BOOL            fixedDir;      // YES = don't change directions while moving
    
    CGFloat         animFrameDur;   // duration of frame animation
    BOOL            autoReverse;
    CGFloat         rotateAngle;
    CGFloat         rotateAngleMemory;
    BOOL            angledPath;
    ViewCheckType   viewCheckType;
    CGFloat         peekTime;
    CGFloat         sinkAngle;
    CGFloat         sinkAngleInterval;
    
    NSMutableDictionary     *timers;
    
    CGFloat         weightSeparation;
    CGFloat         weightAlignment;
    CGFloat         weightCohesion;
    
    CGPoint         bHalfSize;
    
}

@property (nonatomic, retain) Vector2D *vel;
@property (assign) CGFloat velX;
@property (assign) CGFloat velY;

@property (nonatomic, retain) Vector2D *vRunning;
@property (nonatomic, retain) Vector2D *vTarget;
@property (assign) int idTarget;
@property (nonatomic, retain) Paper    *pSelf;
@property (nonatomic, retain) Paper    *pTarget1;
@property (nonatomic, retain) Paper    *pTarget2;

@property (assign) int iFlags;

@property (assign) DecelType decelType;
@property (assign) int flip;
@property (assign) BOOL flipX;
@property (assign) CGFloat bobAmp;
@property (assign) CGFloat bobOffset;

@property (assign) int spawnCount;
@property (assign) int spawnCountCheck;

@property (assign) CGFloat bSpeed;
@property (assign) BOOL bKillOnArrive;
@property (assign) CGPoint bSeekOffset;
@property (assign) BOOL bFlocking;

@property (assign) CGFloat rVelMin;
@property (assign) CGFloat rVelMax;
@property (assign) BOOL fixedDir;

@property (assign) CGFloat animFrameDur;
@property (assign) BOOL autoReverse;
@property (assign) CGFloat rotateAngle;
@property (assign) CGFloat rotateAngleMemory;
@property (assign) BOOL angledPath;
@property (assign) ViewCheckType viewCheckType;
@property (assign) CGFloat peekTime;

@property (assign) CGFloat sinkAngle;
@property (assign) CGFloat sinkAngleInterval;

@property (nonatomic, retain) NSMutableDictionary *timers;

@property (assign) CGFloat weightSeparation;
@property (assign) CGFloat weightAlignment;
@property (assign) CGFloat weightCohesion;

@property (assign) CGPoint bHalfSize;


- (id)initBehavior;

- (BOOL)isOn:(BehaviorType)bt;
- (void)turnOn:(BehaviorType)bt;
- (void)turnOn:(BehaviorType)bt withTarget:(int)targetID;
- (void)turnOnFlocking;
- (void)turnOff:(BehaviorType)bt;
- (void)turnOffAll;
- (BOOL)areAllBehaviorsOff;

- (void)BobOn:(CGFloat)bAmp withOffset:(CGFloat)bOffset;
- (void)SeekOn:(Paper*)pTarget;
- (void)FleeOn:(Paper*)pTarget;

- (void)addTimer:(Timer *)objTimer forBehavior:(BehaviorType)bt;
- (void)updateTimers:(CGFloat)interval;
- (void)turnTimer:(BehaviorType)bt toOn:(BOOL)isOn;

- (void)accumulateForce:(Vector2D*)addedForce;
- (void)calculateForce:(CGFloat)frameTime totalTime:(CGFloat)elapsedTime forPoint:(Vector2D*)pos;
- (Vector2D*)calculateSeekVelocity:(Vector2D*)centerOfMass;

- (BOOL)viewCheck:(ViewCheckType)vcType;
- (BOOL)viewCheck:(ViewCheckType)vcType atPoint:(CGPoint)point;
- (AxisType)axisHitCheck:(ViewCheckType)vcType;

@end
