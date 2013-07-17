//
//  Timer.h
//  Papercut
//
//  Created by Jeff Bumgardner on 1/26/13.
//  Copyright (c) 2013 Jeff Bumgardner. All rights reserved.
//
//  Custom Timer class to manage any discrete / repeatable timers
//    during the simulation, for both Behavior and ObjManager (world)
//    timers.  A timer here can also autoreverse (i.e. Peek behavior).
//

#import <Foundation/Foundation.h>
#import "Variables.h"

@interface Timer : NSObject {
    BehaviorType    bType;              // type of Behavior Timer
    WorldTimer      wtType;             // World Timer = type
    MessageType     wtMessageType;      // World Timer = action to take
    int             wtTargetID;            // World Timer = target object
    CGFloat         timeInterval;       // amount of time to wait before triggering timer
    CGFloat         timeCheck;          // current aggregate time check once timer turned on
    CGFloat         timeIntervalMax;
    CGFloat         timeIntervalMin;
    BOOL            timerOn;
    BOOL            timerReverse;
    BOOL            reversing;
}

@property (assign)  BehaviorType    bType;      // type of Timer
@property (assign)  WorldTimer      wtType;
@property (assign)  MessageType     wtMessageType;
@property (assign)  int             wtTargetID;
@property (assign)  CGFloat         timeInterval;   // amount of time to wait before triggering timer
@property (assign)  CGFloat         timeCheck;
@property (assign)  CGFloat         timeIntervalMax;
@property (assign)  CGFloat         timeIntervalMin;
@property (assign)  BOOL            timerOn;
@property (assign)  BOOL            timerReverse;
@property (assign)  BOOL            reversing;

- (id)initTimer:(BehaviorType)tType withInterval:(CGFloat)tInterval
                                 withIntervalMax:(CGFloat)tIntervalMax
                                 withIntervalMin:(CGFloat)tIntervalMin;

- (id)initTimer:(BehaviorType)tType withInterval:(CGFloat)tInterval
                                         timerOn:(BOOL)isOn
                                    reverseTimer:(BOOL)reverses
                                 withIntervalMax:(CGFloat)tIntervalMax
                                 withIntervalMin:(CGFloat)tIntervalMin;

- (id)initWorldTimer:(WorldTimer)wType worldMessage:(MessageType)wtmType
         worldTarget:(int)wTarget
        withInterval:(CGFloat)tInterval
     withIntervalMax:(CGFloat)tIntervalMax
     withIntervalMin:(CGFloat)tIntervalMin;

- (id)initTimer:(BehaviorType)tType worldTimer:(WorldTimer)wType
   worldMessage:(MessageType)wmType
    worldTarget:(int)wTarget
   withInterval:(CGFloat)tInterval
        timerOn:(BOOL)isOn
   reverseTimer:(BOOL)reverses
withIntervalMax:(CGFloat)tIntervalMax
withIntervalMin:(CGFloat)tIntervalMin;

- (void)randomizeInterval;
- (BOOL)timerComplete;
- (void)timerReset;
- (void)timerUpdate:(CGFloat)interval;
- (BOOL)isTimerOn;
- (void)turnTimerOn;
- (void)turnTimerOff;
- (CGFloat)intervalFraction;
- (BOOL)isReversing;
- (CGFloat)interval;

@end
