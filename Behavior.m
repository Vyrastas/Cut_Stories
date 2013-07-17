//
//  Behavior.m
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

#import "Behavior.h"
#import "Vector2D.h"
#import "Paper.h"
#import "ObjManager.h"
#import "Messenger.h"
#import "Timer.h"

@implementation Behavior

@synthesize vel, velX, velY, vRunning, vTarget, idTarget, pSelf, pTarget1, pTarget2, iFlags, timers;
@synthesize decelType, flip, flipX, bobAmp, bobOffset;
@synthesize spawnCount, spawnCountCheck;
@synthesize bSpeed, bKillOnArrive, bSeekOffset, bFlocking;
@synthesize rVelMax, rVelMin, fixedDir, sinkAngle, sinkAngleInterval;
@synthesize animFrameDur, autoReverse, rotateAngle, rotateAngleMemory, angledPath, viewCheckType, peekTime;
@synthesize weightAlignment, weightCohesion, weightSeparation, bHalfSize;

- (id)initBehavior {
    self = [super init];
    if(nil != self)
    {
        vel = [[Vector2D alloc] initWithX:0.0 Y:0.0];
        vRunning = [[Vector2D alloc] init];
        pSelf = [[Paper alloc] init];
        timers = [[NSMutableDictionary alloc] init];
        
        iFlags = 0;
        flip = 1;
        rotateAngle = 0.0;
        
        weightSeparation = 1.0;
        weightAlignment = 0.5;
        weightCohesion = 0.1;
    }
    return self;
}

- (BOOL)isOn:(BehaviorType)bt       { return ((iFlags & bt) == bt); }
- (void)turnOn:(BehaviorType)bt     { if (![self isOn:bt]) { iFlags |= bt; } }

- (void)turnOn:(BehaviorType)bt withTarget:(int)targetID; {
    
    if (![self isOn:bt]) {
    
        Paper *pTarget;
        
        if (targetID > 0) {
            ObjManager *world = [ObjManager theWorld];
            pTarget = [world getObject:targetID];
        }
        
        switch (bt) {
                
            case btSeek:
                [self SeekOn:pTarget];  break;
                
            case btFlee:
                [self FleeOn:pTarget];  break;
                
            default:
                break;
        }
        
    }
}

- (void)turnOnFlocking {
    [self turnOn:btSeparation];
    [self turnOn:btAlignment];
    [self turnOn:btCohesion];
}

- (void)turnOff:(BehaviorType)bt { if([self isOn:bt]) { iFlags ^= bt; } }
- (void)turnOffAll { iFlags = 0; }
- (BOOL)areAllBehaviorsOff { if (iFlags == 0) { return YES; } else { return NO; } }

- (void)BobOn:(CGFloat)bAmp withOffset:(CGFloat)bOffset {
    iFlags |= btBob;
    bobAmp = bAmp;
    bobOffset = bOffset;
}

- (void)SeekOn:(Paper*)pTarget {
    if (![self isOn:btSeek]) { iFlags |= btSeek; }
    [self setTarget:pTarget];
}

- (void)FleeOn:(Paper*)pTarget {
    if (![self isOn:btFlee]) { iFlags |= btFlee; }
    [self setTarget:pTarget];
}

- (void)setTarget:(Paper*)pTarget {
    pTarget1 = pTarget;
}

- (void)addTimer:(Timer *)objTimer forBehavior:(BehaviorType)bt {
    [timers setObject:objTimer forKey:[NSNumber numberWithInt:bt]];
}

- (void)delTimer:(BehaviorType)bt {
    [timers removeObjectForKey:[NSNumber numberWithInt:bt]];
}

- (void)turnTimer:(BehaviorType)bt toOn:(BOOL)isOn {
    Timer *bTimer = [timers objectForKey:[NSNumber numberWithInt:bt]];
    if (isOn)   { [bTimer turnTimerOn]; }
    else        { [bTimer turnTimerOff]; }
}

- (void)updateTimers:(CGFloat)interval {
    
    Timer *bTimer;
    for (NSNumber *key in timers) {
        bTimer = [timers objectForKey:key];
        
        if ([bTimer isTimerOn]) {
            if (bTimer.bType == btToroid) {           // only update toroid if view off screen
                if ([self viewCheck:vcCompletelyOffScreen]) { [bTimer timerUpdate:interval]; }
            }
            else if (bTimer.bType == btAxisflip) {    // only update axisflip if object moving
                if (vel.length != 0.0) { [bTimer timerUpdate:interval]; }
            }
            else { [bTimer timerUpdate:interval]; }
        }
    }
    
}

- (void)accumulateForce:(Vector2D*)force {
    
    // Builds the final force we'll apply to the object based on each behavior enabled
    
    CGFloat forceRemaining = MAX_FORCE - vRunning.length;
    
    if (forceRemaining <= 0.0) { return; }    // if we've hit max magnitude, then don't add any more

    CGFloat forceToAdd = force.length;
    
    if (forceToAdd < forceRemaining)    { [vRunning add:force]; }       // add full force if possible
    else    { [vRunning add:[[force normalize] mult:forceRemaining]]; } // otherwise scale force down to fit remaining allowed
    
    return;
}

- (void)calculateForce:(CGFloat)frameTime totalTime:(CGFloat)elapsedTime forPoint:(Vector2D*)pos {
    
    // Prioritized calculations - once it hits MAX_FORCE in accumulateForce,
    //   additional forces are ignored
    
    ObjManager *world = [ObjManager theWorld];
    Messenger *messenger = [Messenger theMessenger];
    Timer *fTimer;
    Paper *fPiece;
    
    // These are used so that we only access the pSelf object once for each variable
    //   in order to save some CPU cycles
    int fObjID              = pSelf.objID;
    int fDir                = pSelf.dir;
    int fSpawnID            = pSelf.spawnID;
    PaperType fPaperType    = pSelf.paperType;
    
    // reset running force
    [vRunning zero];
    Vector2D *newForce = [Vector2D newWithX:0.0 Y:0.0];
    Vector2D *currPos  = [Vector2D newWithX:pos.x Y:pos.y];
    rotateAngle = 0.0;
    
    // reinstate the end rotation for fleeing fish that are frozen
    if ((rotateAngleMemory != 0.0) && (self.areAllBehaviorsOff)) {
        rotateAngle = rotateAngleMemory;
    }
    
    
// WAITING
// if this is on, it freezes the object
if ([self isOn:btWait]) {
    fTimer = [timers objectForKey:[NSNumber numberWithInt:btWait]];
    if ([fTimer timerComplete]) {
        
        // reset Wait timer and turn it off
        [fTimer timerReset];
        [fTimer turnTimerOff];
        [self turnOff:btWait];
        
        // special handling
        if (fObjID == 33) {
            [pSelf setAlpha:1.0];  // unhide image
            [self turnOn:btPeek];
            fTimer = [timers objectForKey:[NSNumber numberWithInt:btPeek]];
            [fTimer turnTimerOn];
            
            if ([world leftTopHalf:pSelf]) {
                pSelf.orientation = -1;
            }
        }
        
    }
}

    
// ONLY PROCESS BEHAVIOR IF WAIT IS OFF
else {
    
    // CLEANER FISH CHECK
    if ((fObjID == 25) && (![world isStateOn:osCleaning]))  {
        if ([self viewCheck:vcCompletelyOffScreen]) {
            // kill object if off-screen
            pSelf.remove = YES;
        }
        
    }
    
    
    // NON-FORCE BEHAVIOR PROCESSING
    
    // ___ FLIP
    if ([self isOn:btAxisflip]) {
        fTimer = [timers objectForKey:[NSNumber numberWithInt:btAxisflip]];
        if ([fTimer timerComplete]) {
            [fTimer timerReset];
            
            flip = -flip;     // switch flip direction
        }
        else if (vel.length != 0.0) { fTimer.timeCheck += world.fps; }   // INCREMENT
    }
    
    // ___ ANIM
    if ([self isOn:btAnimframe]) {
        fTimer = [timers objectForKey:[NSNumber numberWithInt:btAnimframe]];
        if ([fTimer timerComplete]) {
            [fTimer timerReset];
            [pSelf startAnimating];
            [pSelf performSelector:@selector(frameAnimComplete) withObject:nil afterDelay:animFrameDur];
        }
    }
    
    // ___ PEEK
    if ([self isOn:btPeek]) {
        fTimer = [timers objectForKey:[NSNumber numberWithInt:btPeek]];
        
        if ([fTimer timerComplete]) {
            vel.x *= -1;
        }
        
        rotateAngle = atanf([fTimer intervalFraction] * 0.5) * fDir;
        if ([world leftTopHalf:pSelf]) {
            rotateAngle *= -1;
        }
        
    }
    
    
    // FORCE PROCESSING
    
    // ___ FLEE
    if (([self isOn:btFlee]) && (pTarget1 != nil)) {
        
        Vector2D *targetPos = [[Vector2D alloc] init];
        targetPos = [targetPos initWithX:pTarget1.center.x Y:pTarget1.center.y];
        newForce = [newForce initWithX:currPos.x Y:currPos.y];
        [newForce sub:targetPos];
        
        // only flee if target is closer than the panic distance
        if ([newForce length] < (BUFFER_DISTANCE + 40)) {
            [newForce normalize];
            if (bSpeed == 0.0) { [newForce mult:MAX_FORCE]; }
            else               { [newForce mult:bSpeed]; }
            [newForce sub:vel];
            
            [self accumulateForce:newForce];
            [vel add:newForce];
            
            // find the rotation angle to the target in radians
            rotateAngle = atan2f((targetPos.y - currPos.y),(targetPos.x - currPos.x));
            
            if (fDir == -1) {
                rotateAngle += M_PI;
            }
            
            // set the memory angle
            rotateAngleMemory = rotateAngle;
            
        }
        [newForce zero];
    }
    
    // [ FLOCKING ]
    if (([self isOn:btSeparation]) || ([self isOn:btAlignment]) || ([self isOn:btCohesion])) {
        
        // ___ TAG NEIGHBORS
        [world tagNeighbors:pSelf ofQueue:world.queue_clean];
    
        // now process each individual flocking behavior
    
        // ___ SEPARATION
        if ([self isOn:btSeparation]) {
            
            for (int i = 0; i < world.queue_clean.count; i++) {
                
                int fID = [[world.queue_clean objectAtIndex:i] intValue];
                fPiece = [world getObject:fID];
                
                if ((fPiece.tagged) && (fPiece.spawnID != fSpawnID)) {
                    
                    // if the piece is tagged as a neighbor and it's not the
                    //   current piece we're processing
                    
                    Vector2D *sDist = [Vector2D withX:currPos.x Y:currPos.y];
                    Vector2D *fDist = [Vector2D withX:fPiece.center.x Y:fPiece.center.y];
                    [sDist sub:fDist];
                    
                    CGFloat lDist = sDist.length;
                    [sDist normalize];
                    [sDist div:lDist];
                    
                    [newForce add:sDist];
                    
                }
                
            }
            
            [newForce mult:weightSeparation];
            [self accumulateForce:newForce];
            [newForce zero];
            
        }
        
        // ___ ALIGNMENT
        if ([self isOn:btAlignment]) {
            
            int nCount = 0;
            
            for (int i = 0; i < world.queue_clean.count; i++) {
                
                int fID = [[world.queue_clean objectAtIndex:i] intValue];
                fPiece = [world getObject:fID];
                
                if ((fPiece.tagged) && (fPiece.spawnID != fSpawnID)) {
                    
                    // if the piece is tagged as a neighbor and it's not the
                    //   current piece we're processing
                    
                    [newForce add:fPiece.behavior.vel];
                    nCount++;
                    
                }
                
            }
            
            // only process if one or more neighbors
            if (nCount > 0) {
                
                [newForce div:(float)nCount];
                [newForce sub:pSelf.behavior.vel];
                
                [newForce mult:weightAlignment];
                [self accumulateForce:newForce];
                [newForce zero];
                
            }
            
        }
        
        // ___ COHESION
        if ([self isOn:btCohesion]) {
            
            int nCount = 0;
            Vector2D *mCenter = [Vector2D withX:0.0 Y:0.0];
            
            for (int i = 0; i < world.queue_clean.count; i++) {
                
                int fID = [[world.queue_clean objectAtIndex:i] intValue];
                fPiece = [world getObject:fID];
                
                if ((fPiece.tagged) && (fPiece.spawnID != fSpawnID)) {
                    
                    // if the piece is tagged as a neighbor and it's not the
                    //   current piece we're processing
                    
                    Vector2D *fCenter = [Vector2D withX:fPiece.center.x Y:fPiece.center.y];
                    [mCenter add:fCenter];
                    nCount++;
                    
                }
                
            }
            
            // only process if one or more neighbors
            if (nCount > 0) {
                
                [mCenter div:(float)nCount];
                
                // find the seek velocity to the center of mass and
                //   normalize it to lessen the magnitude
                [newForce add:[self calculateSeekVelocity:mCenter]];
                [newForce normalize];
                
                [newForce mult:weightAlignment];
                //[self accumulateForce:newForce];
                [newForce zero];
                
            }
            
        }

        // just in case
        [newForce zero];
    
    }
    

    // ___ DRIFT & RANDVEL
    if ([self isOn:btDrift]) {
        
        fTimer = [timers objectForKey:[NSNumber numberWithInt:btRandvel]];
        
        // check for randomized velocity first
        if (([self isOn:btRandvel]) && ([fTimer timerComplete])) {
            
            // reset time check
            [fTimer timerReset];
            [vel zero];
            
            // randomly choose a velocity
            CGFloat randVel = RAND_NUM(rVelMax, rVelMin);
            if (!pSelf.isAnimating) { [pSelf startAnimating]; }
            
            // randomly choose a direction and apply to vel based on flipX
            int rDir = 1;
            if (RAND_NUM(0.0,1.0) > 0.5) { rDir = -1; }
            pSelf.dir = rDir;
            
            // determine new force
            if (flipX)   { vel.x = randVel * rDir; }
            else         { vel.y = randVel * rDir; }
            
            // randomize the interval
            [fTimer randomizeInterval];
        }
        
        // adjust for accelerometer
#ifdef ACCEL_ON
        if ((pSelf.moveType == Move_Touch) && (pSelf.bounded) && (world.optInteract)) {
            if (fabsf(world.accelX) > TILT_THRESHOLD) {     // only move if tilted far enough
                
                // Only add vel if under the tilt cap
                if (fabsf(vel.x) < TILT_FORCE_CAP) {
                    vel.x += ((world.accelX / 1.5) / pSelf.mass);
                }
                
                [pSelf startAnimating];
                
            }
        }
#endif

        // animate toroid, non-animframe timer object if moving
        //   just in case 
        if (([vel lengthSquared] > 0.0) &&
            (!pSelf.isAnimating) &&
            ([self isOn:btToroid]) &&
            (![self isOn:btAnimframe])) {
            [pSelf startAnimating];
        }
        
        // set the rotate angle if on an angled path from peek
        if ((angledPath) && (![self isOn:btPeek]) && (![self isOn:btToroid])) {
            rotateAngle = atanf(vel.y / vel.x);
        }
        
        // check for drift back removal (only Murene for now)
        if (fObjID == 44) {
            if ([self viewCheck:viewCheckType]) {
                [world turnOffState:osMurene];
                [vel zero];
            }
        }
        
        [self accumulateForce:vel];

    }
    
    // ___ BOB
    if ([self isOn:btBob]) {
        
        CGFloat bobOff = 0.0;
        bobOff = cosf(elapsedTime+bobOffset)/bobAmp;
        
        if (!flipX) { newForce.x += bobOff; }
        if ((vel.y <= MIN_FORCE) && (flipX))   { newForce.y += bobOff; }
        
        [self accumulateForce:newForce];
        [newForce zero];
        
    }
    
    // ___ DECEL
    if ([self isOn:btDecel]) {
        
        // only decelerate if moving fast enough
        if ([vRunning length] > MIN_FORCE) {
            
            CGFloat decelMod = -(0.1 / decelType);
            
            if (flipX) {    // primary movement on X-axis
                if (vRunning.x > MIN_FORCE) {
                    newForce.x += decelMod;
                }
                else if (vRunning.x < -MIN_FORCE) {
                    newForce.x -= decelMod;
                }
                else {
                    // nothing
                }
                
                if (angledPath) {   // if path angled, decel y the same
                    if (vRunning.y > MIN_FORCE) {
                        newForce.y += decelMod;
                    }
                    else if (vRunning.y < -MIN_FORCE) {
                        newForce.y -= decelMod;
                    }
                    else {
                        // nothing
                    }
                }
                else {
                    if (vRunning.y > MIN_FORCE) {
                        newForce.y += (decelMod * 2);
                    }
                    else if (vRunning.y < -MIN_FORCE) {
                        newForce.y -= (decelMod * 2);
                    }
                    else {
                        newForce.y = 0.0;
                        vel.y = 0.0;
                    }
                }
                
            }
            else {    // primary movement on Y-axis
                if (vRunning.y > MIN_FORCE) {
                    newForce.y += decelMod;
                }
                else if (vRunning.y < -MIN_FORCE) {
                    newForce.y -= decelMod;
                }
                else {
                    // nothing
                }
                
                if (angledPath) {   // if path angled, decel y the same
                    if (vRunning.x > MIN_FORCE) {
                        newForce.x += decelMod;
                    }
                    else if (vRunning.x < -MIN_FORCE) {
                        newForce.x -= decelMod;
                    }
                    else {
                        // nothing
                    }
                }
                else {
                    if (vRunning.x > MIN_FORCE) {
                        newForce.x += (decelMod * 2);
                    }
                    else if (vRunning.x < -MIN_FORCE) {
                        newForce.x -= (decelMod * 2);
                    }
                    else {
                        newForce.x = 0.0;
                        vel.x = 0.0;
                    }
                }
                
            }
            
            // add to cumulative force and adjust velocity, or stop
            //   if needed
            [self accumulateForce:newForce];
            [vel add:newForce];
            [newForce zero];
            
        }
        
        else if (decelType == Decel_Stop) {
            vel.x = 0.0;
            [pSelf stopAnimating];
        }
    }
    
    // ___ SINK
    if ([self isOn:btSink]) {
        fTimer = [timers objectForKey:[NSNumber numberWithInt:btSink]];
        sinkAngleInterval = sinkAngle / ([fTimer interval] / world.fps);
        
        // if the timer is off, it's still floating down
        if (![fTimer isTimerOn]) {
            
            if (rotateAngleMemory <= sinkAngle) {
                rotateAngleMemory += sinkAngleInterval;
            }
            
            rotateAngle = rotateAngleMemory;
            
            if (![self viewCheck:vcOnScreenWithinHalfBorder]) {
                // if it starts to go below the border, stop it,
                //   disable touch and start timer
                [self.vel zero];
                [self turnOff:btBob];
                [fTimer turnTimerOn];

            }
        }
        
        // if timer is on, rotate object as necessary
        if (([fTimer isTimerOn]) && (![fTimer timerComplete])) {
            
            rotateAngle = rotateAngleMemory;
            
        }
        
        // if the timer is on and complete, start to sink it slowly
        if ([fTimer timerComplete]) {
            vel.y = 0.1;
        }
        
        // once the view is off screen, kill it
        if ([self viewCheck:vcCompletelyOffScreen]) {
            pSelf.remove = YES;
            [world.objects_shake removeAllObjects];
        }
    }

    // ___ SEEK
    if (([self isOn:btSeek]) && (pTarget1 != nil)) {
        newForce = [newForce initWithX:pTarget1.center.x Y:pTarget1.center.y];
        fTimer = [timers objectForKey:[NSNumber numberWithInt:btSeek]];
        
        Vector2D *targetPos = [[Vector2D alloc] initWithVector:newForce];
        
        [newForce sub:currPos];
        
        // only seek if the delay timer is off
        if (![fTimer isTimerOn]) {

            // catch instances where the target is almost at the buffer distance
            if (([newForce length] > BUFFER_DISTANCE) && ([newForce length] < BUFFER_DISTANCE * 2.5)) {
                
                // CLEANER FISH / MURENE eating animation - freeze target and fire animation early
                if ((fObjID == 25) || (fObjID == 44)) {
                    [pTarget1.behavior turnOffAll];
                    [pTarget1.behavior.vel zero];
                    [pSelf startAnimating];
                }
            }
            
            // for Murene, if it gets close to the midpoint of the screen,
            //   kill the seek/flee and retreat
            else if ((fObjID == 44) && (currPos.x > 350)) {
                
                [self turnOff:btSeek];                                                          // turn off seek
                [messenger queueObject:pTarget1.spawnID behavior:btFlee turnOn:NO target:0];    // turn off flee for target
                
                // set new velocity
                vel.x *= -0.5;
                vel.y = 0.0;
                
            }
            
            // seek as normal if still far away
            else if ([newForce length] > BUFFER_DISTANCE) {
                
                // only seek if target is farther away than buffer distance
                [newForce normalize];
                if (bSpeed == 0.0) { [newForce mult:MAX_FORCE]; }
                else               { [newForce mult:bSpeed]; }
                [newForce sub:vel];
                
                [self accumulateForce:newForce];
                [vel add:newForce];
                
                // find the rotation angle to the target in radians
                rotateAngle = atan2f((targetPos.y - currPos.y),(targetPos.x - currPos.x));
                
                if (fDir == -1) {
                    rotateAngle += M_PI;
                }
                
            }
            
            // otherwise we have reached the target
            else {
                
                // CLEANER FISH
                if (fObjID == 25) {
                    [messenger queueObject:pTarget1.spawnID message:mtSpawn turnOn:NO target:0];    // kill current target
                    [world.queue_clean removeObject:[NSNumber numberWithInt:pTarget1.spawnID]];     // remove from queue_clean
                    [self turnOff:btSeek];                                                          // turn off seek

                    int newTargetID = [[world.queue_clean objectAtIndex:0] intValue];
                    [self SeekOn:[world getObject:newTargetID]];
                    [fTimer turnTimerOn];                                                           // turn on seek delay timer
                    
                    Paper* tPaper = [world getObject:newTargetID];      // get the object that should flee
                    [tPaper.behavior FleeOn:pSelf];                     // set the flee target
                }
                
                // MURENE
                if (fObjID == 44) {
                    [messenger queueObject:pTarget1.spawnID message:mtSpawn turnOn:NO target:0];    // kill current target
                    [world.queue_clean removeObject:[NSNumber numberWithInt:pTarget1.spawnID]];     // remove from queue_clean
                    [self turnOff:btSeek];                                                          // turn off seek
                    
                    // set new velocity
                    vel.x *= -0.5;
                    vel.y = 0.0;
                }
                
            }
            [newForce zero];
            
        }
        
        // if the seek delay timer is complete, handle
        else if ([fTimer timerComplete]) {
            
            if ([world.queue_clean count] <= [world cleanMin]) {
                // cleaner fish should exit screen
                [self turnOff:btSeek];
                [world turnOffState:osCleaning];
            }
            [fTimer timerReset];
            [fTimer randomizeInterval];
            [fTimer turnTimerOff];
            
        }
        
        else {
            // nothing
        }
        
    }
    
    // ___ TOROID (RESPAWNING)
    if ([self isOn:btToroid]) {
        
        fTimer = [timers objectForKey:[NSNumber numberWithInt:btToroid]];
        
        if ([fTimer timerComplete]) {
            
            // reset timer
            [fTimer timerReset];
            
            // change the appropriate center point based on the flip axis,
            //    border and image halfsize are used to ensure the image
            //    always remains in view
            int xSpawnOffset = world.borderWidth + pSelf.halfSize.x;
            int ySpawnOffset = world.borderWidth + pSelf.halfSize.y;
            
            // since toroid resets the position, clear out any previous running force
            //   as it won't apply during this update step
            [vRunning zero];
            
            // calculate new center point
            if (flipX) {
                if (pSelf.posSpawn.x < 0)
                { vRunning.x = -xSpawnOffset; }
                else
                { vRunning.x = xSpawnOffset + world.viewWidth; }
                
                if (fObjID == 28) {  // DIVER should stay near the top
                    vRunning.y = (arc4random() % (150-ySpawnOffset)) + ySpawnOffset;
                }
                else {
                    vRunning.y = (arc4random() % (world.viewHeight-(ySpawnOffset*2))) + ySpawnOffset;
                }
            }
            else {
                if (pSelf.posSpawn.y < 0) {
                    vRunning.y = -ySpawnOffset;
                    if (fPaperType == Paper_Vector) { vRunning.y -= 20.0; }
                }
                else
                { vRunning.y = ySpawnOffset + world.viewHeight; }
                vRunning.x = (arc4random() % (world.viewWidth-(xSpawnOffset*2))) + xSpawnOffset;
            }
            
            // if path is angled, create new velocity and rotate angle
            if (angledPath) {
                int bAngle = 1;
                if (RAND_NUM(0.0,1.0) > 0.5) { bAngle = -1; }
                
                if (flipX) {
                    vel.y = RAND_NUM(bSeekOffset.x, bSeekOffset.y);
                    pSelf.behavior.velY = vel.y * bAngle;
                }
                else {
                    vel.x = RAND_NUM(bSeekOffset.x, bSeekOffset.y);
                    pSelf.behavior.velX = vel.x * bAngle;
                }
            }
            
            if (fPaperType == Paper_Vector) {
                // if toroid on a vector, hide it so we don't see it move
                //  across the screen to the new position
                //NSLog(@"Opacity Off");
                [pSelf.animShape setOpacity:0.0];
            }
            
            // set the difference between new point and old point to the force
            [vRunning sub:pos];
            
            // increment spawn count or kill object if respawn limit is reached
            if (spawnCount != 0) {
                if (spawnCountCheck < spawnCount) {
                    spawnCountCheck++;
                }
                else {
                    [messenger queueObject:fSpawnID message:mtSpawn turnOn:NO target:0];
                }
            }
        
        }
        
        // set the rotate angle if on an angled path
        if (angledPath) {
            
            if (flipX) {    // horizontal
                rotateAngle = atanf(velY / velX);
                if (fDir == -1) {
                    rotateAngle += M_PI;
                }
            }
            else {          // vertical
                rotateAngle = -atanf(velX / velY);
            }
            
        }
        
    }
    
    // OFF-SCREEN CHECK
    //  for things that need to happen after behavior updates
    if ([self viewCheck:vcCompletelyOffScreen]) {
        
        // PEEK RESET
        //  set a new position, orientation and turn on peek timer
        if ((fObjID == 33) && (![self isOn:btPeek]) && (peekTime > 0.0)) {
            
            // overwrite running force since we're changing the position
            [vRunning zero];
            
            // set new position based on which side of the screen it's on
            if ([world leftTopHalf:pSelf]) {    // left side
                vRunning.x = -pSelf.childSpawn.x;
                vel.x = -velX;
                pSelf.orientation = 1;
            }
            else {  // right side
                vRunning.x = world.viewWidth + pSelf.childSpawn.x;
                vel.x = velX;
                pSelf.orientation = -1;
            }
            
            int ySpawnOffset = world.borderWidth + (2 * pSelf.halfSize.y);
            vRunning.y = (arc4random() % (world.viewHeight-(ySpawnOffset*2))) + ySpawnOffset;
            [vRunning sub:pos];
            
            // reset velocity
            vel.y = velY;
            
            // turn on Wait behavior and timer
            [self turnOn:btWait];
            [self turnTimer:btWait toOn:YES];
            [pSelf setAlpha:0.0];   // hide image

        }
    }
    
    [vRunning mult:frameTime*60];
    
}   // end Wait

    return;
}

// used for Flocking, to calc the Seek velocity whether it's seeking or not
- (Vector2D*)calculateSeekVelocity:(Vector2D*)centerOfMass {
    
    Vector2D *newVel = [[Vector2D alloc] initWithVector:centerOfMass];
    Vector2D *sPos = [Vector2D withX:pSelf.center.x Y:pSelf.center.y];
    [newVel sub:sPos];

    [newVel normalize];
    if (bSpeed == 0.0) { [newVel mult:MAX_FORCE]; }
    else               { [newVel mult:bSpeed]; }
    [newVel sub:vel];
    
    return newVel;

}

- (BOOL)viewCheck:(ViewCheckType)vcType {
    return [self viewCheck:vcType atPoint:CGPointZero];
}

- (BOOL)viewCheck:(ViewCheckType)vcType atPoint:(CGPoint)point {

    BOOL checkResult = NO;
    ObjManager *world = [ObjManager theWorld];
    CGRect screenRect;
    
    // assign these to variables once to save CPU cycles
    //   since accessing the world object can be cycle-intensive
    CGFloat worldWidth = world.viewWidth;
    CGFloat worldHeight = world.viewHeight;
    CGFloat worldBorder = world.borderWidth;
    
    CGPoint pCenter;
    if (CGPointEqualToPoint(point, CGPointZero)) {
        pCenter = [pSelf getCenterPoint];
    }
    else {
        pCenter = point;
    }
    
    switch (vcType) {
        
        case vcCompletelyOnScreen:
            screenRect = CGRectMake(bHalfSize.x, bHalfSize.y,
                                    worldWidth - (2 * bHalfSize.x),
                                    worldHeight - (2 * bHalfSize.y));
            if (CGRectContainsPoint(screenRect, pCenter)) { checkResult = YES; }
            break;
            
        case vcCenterOnScreen:
            screenRect = CGRectMake(0, 0, worldWidth, worldHeight);
            if (CGRectContainsPoint(screenRect, pCenter)) { checkResult = YES; }
            break;
            
        case vcOnScreenWithinBorder:
            screenRect = CGRectMake(worldBorder, worldBorder,
                                    worldWidth - (2 * worldBorder),
                                    worldHeight - (2 * worldBorder));
            if (CGRectContainsPoint(screenRect, pCenter)) { checkResult = YES; }
            break;
            
        case vcOnScreenWithinHalfBorder:
            screenRect = CGRectMake(worldBorder - 10, worldBorder - 10,
                                    worldWidth - (2 * (worldBorder + 3)),
                                    worldHeight - (2 * (worldBorder + 2)));
            if (CGRectContainsPoint(screenRect, pCenter)) { checkResult = YES; }
            break;
            
        case vcCompletelyOffScreen:
            screenRect = CGRectMake(-bHalfSize.x, -bHalfSize.y,
                                    worldWidth + (2 * bHalfSize.x),
                                    worldHeight + (2 * bHalfSize.y));
            if (!CGRectContainsPoint(screenRect, pCenter)) { checkResult = YES; }
            break;
            
        case vcWithinBoundedBox:  // note that this Rect doesn't extend below the ground
            screenRect = CGRectMake(-2 * bHalfSize.x, -2 * bHalfSize.y,
                                    worldWidth + (4 * bHalfSize.x),
                                    worldHeight + bHalfSize.y);
            if (CGRectContainsPoint(screenRect, pCenter)) { checkResult = YES; }
            break;
            
        case vcKeepOnGround:
            screenRect = CGRectMake(0, worldHeight * 0.5,
                                    worldWidth, worldHeight);
            if (CGRectContainsPoint(screenRect, pCenter)) { checkResult = YES; }
            break;
            
        case vcNone:
        default:
            break;
            
    }
    
    return checkResult;
    
}

- (AxisType)axisHitCheck:(ViewCheckType)vcType {
    
    AxisType axisResult = yAxis;
    ObjManager *world = [ObjManager theWorld];
    CGPoint pCenter = [pSelf getCenterPoint];
    
    // assign these to variables once to save CPU cycles
    //   since accessing the world object can be cycle-intensive
    CGFloat worldHeight = world.viewHeight;
    CGFloat worldBorder = world.borderWidth;
    
    switch (vcType) {
            
        case vcCompletelyOnScreen:
            if ((pCenter.y < bHalfSize.y) ||
                (pCenter.y > (worldHeight - bHalfSize.y))) {
                axisResult = xAxis;
            }
            break;
            
        case vcCenterOnScreen:
            if ((pCenter.y < 0) ||
                (pCenter.y > worldHeight)) {
                axisResult = xAxis;
            }
            break;
            
        case vcOnScreenWithinBorder:
            if ((pCenter.y < worldBorder) ||
                (pCenter.y > (worldHeight - worldBorder))) {
                axisResult = xAxis;
            }
            break;
            
        case vcCompletelyOffScreen:
            if ((pCenter.y < -bHalfSize.y) ||
                (pCenter.y > (worldHeight + bHalfSize.y))) {
                axisResult = xAxis;
            }
            break;
            
        case vcWithinBoundedBox:
            if ((pCenter.y < -bHalfSize.y) ||
                (pCenter.y > (worldHeight - bHalfSize.y))) {
                axisResult = xAxis;
            }
            break;
            
        case vcKeepOnGround:
            if ((pCenter.y < (worldHeight * 0.5)) ||
                (pCenter.y > worldHeight)) {
                axisResult = xAxis;
            }
            break;
            
        case vcNone:
        default:
            break;
        
    }
    
    return axisResult;
    
}

@end
