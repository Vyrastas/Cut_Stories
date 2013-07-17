//
//  Messenger.h
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

#import <Foundation/Foundation.h>
#import "Variables.h"


typedef struct {
    int             spawnID;
    MessageType     mType;
    BehaviorType    bType;
    BOOL            turnOn;
    int             targetSpawnID;
    CGPoint         point;
    BOOL            wasSpawned;
} Message;

@class ObjManager;
@class Behavior;

@interface Messenger : NSObject {

}

@property (assign) int queueID;
@property (nonatomic, retain) NSMutableDictionary *queue;

+ (id) theMessenger;

- (id)init;
- (void)queueObject:(int)spawnID behavior:(BehaviorType)bType turnOn:(BOOL)on target:(int)targetID;
- (void)queueObject:(int)spawnID message:(MessageType)mType turnOn:(BOOL)on target:(int)targetID;
- (void)queueObject:(int)spawnID message:(MessageType)mType turnOn:(BOOL)on target:(int)targetID wasSpawned:(BOOL)wSpawn;

- (void)queueObject:(int)spawnID
            message:(MessageType)mType
           behavior:(BehaviorType)bType
             turnOn:(BOOL)on
             target:(int)targetID
            atPoint:(CGPoint)point
         wasSpawned:(BOOL)wSpawn;

- (void)processQueue;

@end
