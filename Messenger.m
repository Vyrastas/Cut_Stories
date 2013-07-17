//
//  Messenger.m
//  Papercut
//
//  Created by Jeff Bumgardner on 1/12/13.
//  Copyright (c) 2013 Jeff Bumgardner. All rights reserved.
//
//  Queues up messages and processes them at the end of the frame
//    Messages currently include:
//    - Spawn/kill object
//    - Turn behavior on/off
//    - Start/stop frame animation
//

#import "Messenger.h"
#import "ObjManager.h"
#import "Paper.h"
#import "Behavior.h"

static Messenger *mySharedMessenger = nil;

@implementation Messenger

+ (id) theMessenger {
    @synchronized([Messenger class]) {
        if (!mySharedMessenger) { mySharedMessenger = [[self alloc] init]; }
    }
    return mySharedMessenger;
}

+ (id) alloc
{
  @synchronized([Messenger class])
	{
		NSAssert(mySharedMessenger == nil, @"Attempted to allocate a second instance of the Messenger.");
        mySharedMessenger = [super alloc];
        return mySharedMessenger;
	}
    
	return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)init {
    self = [super init];
    if(nil != self)
    {
        _queue = [[NSMutableDictionary alloc] init];
        _queueID = 1;
    }
    return self;
}

- (void)queueObject:(int)spawnID
           behavior:(BehaviorType)bType
             turnOn:(BOOL)on
             target:(int)targetID {
    
    [self queueObject:spawnID message:mtBehavior behavior:bType turnOn:on target:targetID atPoint:CGPointZero wasSpawned:NO];
    return;
}

- (void)queueObject:(int)spawnID
            message:(MessageType)mType
             turnOn:(BOOL)on
             target:(int)targetID {
    
    [self queueObject:spawnID message:mType behavior:btNone turnOn:on target:targetID atPoint:CGPointZero wasSpawned:NO];
    return;
}

- (void)queueObject:(int)spawnID
            message:(MessageType)mType
             turnOn:(BOOL)on
             target:(int)targetID
         wasSpawned:(BOOL)wSpawn {
    
    [self queueObject:spawnID message:mType behavior:btNone turnOn:on target:targetID atPoint:CGPointZero wasSpawned:wSpawn];
    return;
}

- (void)queueObject:(int)spawnID
            message:(MessageType)mType
           behavior:(BehaviorType)bType
             turnOn:(BOOL)on
             target:(int)targetID
            atPoint:(CGPoint)point
         wasSpawned:(BOOL)wSpawn {
    
    // create the Message struct
    Message newMessage;
    newMessage.spawnID = spawnID;
    newMessage.mType = mType;
    newMessage.bType = bType;
    newMessage.turnOn = on;
    newMessage.targetSpawnID = targetID;
    newMessage.point = point;
    newMessage.wasSpawned = wSpawn;
    
    // wrap the Message struct in an NSValue object, then add to queue
    NSValue *structValue = [NSValue value:&newMessage withObjCType:@encode(Message)];
    [_queue setObject:structValue forKey:[NSNumber numberWithInt:_queueID]];
    _queueID++;
    
    return;
}

- (void)processQueue {
    
    ObjManager *world = [ObjManager theWorld];
    
    for (NSNumber *key in _queue) {
        
        NSValue *keyValue = [_queue objectForKey:key];
        
        // unwrap NSValue to Message
        Message theMessage;
        [keyValue getValue:&theMessage];
        
        int msSpawnID   = theMessage.spawnID;
        int msTargetID  = theMessage.targetSpawnID;
        CGPoint msPoint = theMessage.point;
        BOOL msSpawned  = theMessage.wasSpawned;
        
        // get Paper object for message
        Paper *mPaper;
        if (msSpawnID > 0) { mPaper = [world getObject:msSpawnID]; }
        
        // apply message
        
        switch (theMessage.mType) {
            
            // turning on / off behaviors
            case mtBehavior:
                if (theMessage.turnOn) {
                    [mPaper.behavior turnOn:theMessage.bType withTarget:msTargetID];
                }
                else {
                    // turn off
                    [mPaper.behavior turnOff:theMessage.bType];
                }
                break;
                
            // spawning / killing objects
            case mtSpawn:
                if (theMessage.turnOn) {
                    // spawn object
                    Paper *tPaper;
                    
                    // only spawn if max objects not reached
                    if (![world maxObjectsReached]) {
                    
                        if (mPaper != nil) {
                            tPaper = [world spawnPiece:mPaper objID:msSpawnID childID:msTargetID wasSpawned:msSpawned atPoint:msPoint];
                        }
                        else {
                            if (msSpawnID == 0) {
                                tPaper = [world spawnPiece:nil objID:msTargetID childID:0 wasSpawned:msSpawned atPoint:msPoint];
                            }
                            else {
                                tPaper = [world spawnPiece:nil objID:msSpawnID childID:0 wasSpawned:msSpawned atPoint:msPoint];
                            }
                        }
                        
                        [world addToView:tPaper];
                        
                    }
                    
                }
                else {
                    // kill object
                    mPaper.remove = YES;
                }
                break;
                
            // turning on / off animations
            case mtAnimate:
                if (theMessage.turnOn) { [mPaper startAnimating]; }
                else                   { [mPaper stopAnimating]; }
                break;
                
            default:
                break;
        }
        
    }
    
    // empty the queue when all messages are processed
    [_queue removeAllObjects];

}

@end
