//
//  Timer.m
//  Papercut
//
//  Created by Jeff Bumgardner on 1/26/13.
//  Copyright (c) 2013 Jeff Bumgardner. All rights reserved.
//
//  Custom Timer class to manage any discrete / repeatable timers
//    during the simulation, for both Behavior and ObjManager (world)
//    timers.  A timer here can also autoreverse (i.e. Peek behavior).
//

#import "Timer.h"

@implementation Timer

@synthesize bType, timeCheck, timeInterval, timeIntervalMax, timeIntervalMin, timerOn;
@synthesize wtType, wtMessageType, wtTargetID;
@synthesize timerReverse, reversing;

- (id)initTimer:(BehaviorType)tType withInterval:(CGFloat)tInterval
                                 withIntervalMax:(CGFloat)tIntervalMax
                                 withIntervalMin:(CGFloat)tIntervalMin {
    
    self = [self initTimer:tType worldTimer:wtNone worldMessage:mtNone worldTarget:0
              withInterval:tInterval timerOn:YES reverseTimer:NO
           withIntervalMax:tIntervalMax withIntervalMin:tIntervalMin];
    return self;
    
}

- (id)initTimer:(BehaviorType)tType withInterval:(CGFloat)tInterval
                                         timerOn:(BOOL)isOn
                                    reverseTimer:(BOOL)reverses
                                 withIntervalMax:(CGFloat)tIntervalMax
                                 withIntervalMin:(CGFloat)tIntervalMin {
    
    self = [self initTimer:tType worldTimer:wtNone worldMessage:mtNone worldTarget:0
              withInterval:tInterval timerOn:isOn reverseTimer:reverses
           withIntervalMax:tIntervalMax withIntervalMin:tIntervalMin];
    return self;
}

- (id)initWorldTimer:(WorldTimer)wType worldMessage:(MessageType)wtmType
                                        worldTarget:(int)wTarget
                                       withInterval:(CGFloat)tInterval
                                    withIntervalMax:(CGFloat)tIntervalMax
                                    withIntervalMin:(CGFloat)tIntervalMin {
    
    self = [self initTimer:btNone worldTimer:wType worldMessage:wtmType worldTarget:wTarget
              withInterval:tInterval timerOn:YES reverseTimer:NO
           withIntervalMax:tIntervalMax withIntervalMin:tIntervalMin];
    return self;
    
}

- (id)initTimer:(BehaviorType)tType worldTimer:(WorldTimer)wType
                                  worldMessage:(MessageType)wmType
                                   worldTarget:(int)wTarget
                                  withInterval:(CGFloat)tInterval
                                       timerOn:(BOOL)isOn
                                  reverseTimer:(BOOL)reverses
                               withIntervalMax:(CGFloat)tIntervalMax
                               withIntervalMin:(CGFloat)tIntervalMin {
    
    self = [super init];
    if(nil != self)
    {
        bType           = tType;
        wtType          = wType;
        wtMessageType   = wmType;
        wtTargetID      = wTarget;
        timeInterval    = tInterval;
        timeIntervalMax = tIntervalMax;
        timeIntervalMin = tIntervalMin;
        timeCheck       = 0.0;
        timerOn         = isOn;
        timerReverse    = reverses;
        reversing       = NO;
    }
    return self;
    
}

- (void)randomizeInterval {
    timeInterval = RAND_NUM(timeIntervalMax, timeIntervalMin);
    return;
}

- (BOOL)timerComplete {
    
    // for reverse timers
    if (timerReverse) {
        if (((reversing) && (timeCheck < 0.0)) ||
            ((!reversing) && (timeCheck > timeInterval))) {
            return YES;
        }
        else {
            return NO;
        }
    }
    
    // for normal timers
    else {
        if (timeCheck > timeInterval) {
            return YES;
        }
        else {
            return NO;
        }
    }
}

- (void)timerReset {
    timeCheck = 0.0;
    reversing = NO;
    return;
}

- (void)timerUpdate:(CGFloat)interval {
    
    // if a reverse timer, switch directions as needed
    if (timerReverse) {
        if (((reversing) && (timeCheck < 0.0)) ||
            ((!reversing) && (timeCheck > timeInterval))) {
            reversing = !reversing;
        }
    }
    
    if (reversing) {
        timeCheck -= interval;
    }
    else {
        timeCheck += interval;
    }
    return;
}

- (BOOL)isTimerOn {
    return timerOn;
}

- (void)turnTimerOn {
    timerOn = YES;
}

- (void)turnTimerOff {
    timerOn = NO;
}

- (CGFloat)intervalFraction {
    return timeCheck / timeInterval;
}

- (BOOL)isReversing {
    return reversing;
}

- (CGFloat)interval {
    return timeInterval;
}

@end
