//
//  Variables.h
//  Papercut
//
//  Created by Jeff Bumgardner on 1/13/13.
//  Copyright (c) 2013 Jeff Bumgardner. All rights reserved.
//
//  This class merely features any macros, variables, structs or enums that may
//    be used throughout the app.  Also includes property tables for each papercut.
//

//#define DEBUG_ON        // toggle debug code & labels
#define MENUS_ON        // toggle menu links
#define COLLISION   0   // master collision
#define ACCEL_ON

//#define TEST_FLIGHT_ON
//#define NSLog TFLog   // uncomment to turn on TestFlight logging

// MACROS / FORMULAS
#define ARC4RANDOM_MAX      0x100000000
#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)
#define RADIANS(degrees) ((degrees * M_PI) / 180.0)

#define RAND_NUM(smallNumber, bigNumber) ((((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * (bigNumber - smallNumber)) + smallNumber)
#define RAND_NUM_INT(smallNumber, bigNumber) ((((int) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * (bigNumber - smallNumber)) + smallNumber)

// WORLD
#define FRAME_INTERVAL  1
//#define UPDATE_PERIOD   0.0334      // main update period [60FPS=0.0167, 50FPS=0.02, 40FPS=0.025 30FPS=0.033 25FPS=0.04]
#define GRAVITY_FILTER  0.1         // to filter out gravity from accelerometer readings
#define BOUNCE_OFFSET   3.0         // pixels to bounce an object off the boundary so it doesn't get stuck
#define MAX_NOTES       12          // max note fish allowed to be on-screen at the same time
#define MAX_OBJECTS     60          // max objects allowed to be active at once - things like bubbles, notefish, etc
#define MIN_CHIME_DIST  300         // swipe must be this length or greater in pixels for chime/shudder to fire
#define RESTITUTION     1.0         // for elastic collisions

// OBJECTS / BEHAVIOR
#define MIN_FORCE         0.5       // min force/velocity allowed
#define MAX_FORCE         3.5       // max force/velocity allowed
#define BUFFER_DISTANCE  20.0       // distance to stop/start seek/flee behaviors
#define TILT_THRESHOLD    0.3       // drift applied once accelerometer passes this value
#define TILT_FORCE_CAP    2.5       // max force/velocity allowed when tilting
#define FRAMES_ON                   // set to FRAMES_OFF to disable frame animation


// ________________ BEHAVIOR

typedef enum {
    btNone        = 0x00000,
    btBob         = 0x00002,
    btDrift       = 0x00004,
    btGravity     = 0x00008,
    btToroid      = 0x00010,
    btSeek        = 0x00020,
    btAxisflip    = 0x00040,
    btAnimframe   = 0x00080,
    btSink        = 0x00100,
    btPeek        = 0x00200,
    btDecel       = 0x00400,
    btFlee        = 0x00800,
    btRandvel     = 0x01000,
    btWait        = 0x02000,
    btSeparation  = 0x04000,
    btAlignment   = 0x08000,
    btCohesion    = 0x10000,
    btTilt        = 0x20000
} BehaviorType;

// Deceleration is calculated as -(0.1 / DecelType)
typedef enum {
    Decel_Slow      = 25,
    Decel_Med       = 10,
    Decel_Fast      = 3,
    Decel_Faster    = 2,
    Decel_Stop      = 1,
    Decel_None      = 0
} DecelType;

// Type of view check validation (is view on/off screen?)
typedef enum {
    vcNone,
    vcCompletelyOffScreen,      // view is completely off screen
    vcCenterOnScreen,           // view on screen as long as center point is
    vcOnScreenWithinBorder,     // view is on screen, within the set borders
    vcOnScreenWithinHalfBorder,
    vcCompletelyOnScreen,       // view is completely on screen
    vcWithinBoundedBox,         // view is within movement bounded box
    vcKeepOnGround              // view stays between ground and top of image
} ViewCheckType;

typedef enum {
    xAxis,
    yAxis
} AxisType;


// ________________ MESSENGER

typedef enum {
    mtBehavior,
    mtSpawn,
    mtAnimate,
    mtNone
} MessageType;


// ________________ PAPER

// enumerator for move types
typedef enum {
    Move_Static = 0,    // does not move
    Move_Touch,         // can be moved by touch
    Move_Auto,          // moves automatically, cannot be touched
    Move_Anim,          // moves by animation only
    Move_Group          // part of a group, moves w/ master object
} MovementType;

typedef enum {
    Paper_Image = 0,    // png image
    Paper_Vector        // svg image
} PaperType;

// determines boundary behavior
typedef enum {
    Bind_Always = 0,    // always follows boundary rules
    Bind_Never,         // not bound to view
    Bind_OnEnter        // bound once enters view
} BindType;

// for initializing paper pieces
typedef struct {
    int             objID;              // core object ID
    const char*     imagePath;          // image name
    BOOL            bounded;            // object restricted to the screen
    BOOL            randSpawn;          // spawns randomly
    int             spawnX;             // spawn point
    int             spawnY;
    int             zPos;               // z position
    MovementType    moveType;
    CGFloat         velX;               // default velocity
    CGFloat         velY;
    CGFloat         decel;             // DEPRECATED
    CGFloat         decelTime;         // DEPRECATED
    BOOL            bob;                // YES = object bobs against it's core axis (flipX)
    CGFloat         bobAmp;             // bob amplitude
    CGFloat         bobOffset;          // bob offset
    BOOL            flipX;              // core axis, travels and flips around, YES = X axis
    CGFloat         flipTime;           // if object flips, time between each flip
    CGFloat         spawnTime;          // if object respawns, time between respawn
    BOOL            init;               // YES = object spawns when scene loads
    int             childImage;         // if the object spwans a child image
    CGFloat         childSpawnX;        // image center x-axis offset, both child & group | anchorX for svg
    CGFloat         childSpawnY;        // image center y-axis offset, both child & group | anchorY for svg
    int             animID;             // has a related animation, or used as repeat count
    BOOL            collision;          // YES = collision enabled
    CGFloat         mass;               // used for accelerometer speed calc, higher mass = slower speed
    int             tsID;               // object has a touchspot
    int             groupID;            // object part of a Group
    int             frames;             // # of frames in the animation
    CGFloat         frameDur;           // animation length
    int             orientation;        // direction the image faces based on flipX (axis), 0 = N/A
    BOOL            pinch;              // object can be resized by pinch/zoom
    const char*     imageType;          // image filetype
    CGFloat         imageSizeWidth;     
    CGFloat         imageSizeHeight;
    PaperType       paperType;
    BOOL            killOnTouch;        // kill object upon touch
    CGFloat         pinchMax;           // max pinch size
    CGFloat         pinchMin;           // min pinch size
    BOOL            rVelOn;             // YES = random velocity changes
    CGFloat         rVelTimeMax;        // min/max time that the velocity changes, randomized
    CGFloat         rVelTimeMin;
    CGFloat         rVelMax;            // min/max velocity to change to, randomized
    CGFloat         rVelMin;
    BindType        bindType;           // boundary behavior
    BOOL            spawnByShake;       // object spawns by shaking device
    CGFloat         killTime;           
    CGFloat         bSpeed;             // behavior speed limit, 0 = MAX_FORCE
    BOOL            bKillOnArrive;     // DEPRECATED
    CGFloat         bSeekOffsetX;       // used for velocity of respawned angled path objects
    CGFloat         bSeekOffsetY;
    CGFloat         animTime;           // animation length
    DecelType       decelType;          // controls deceleration
    int             spawnCount;         // # of times the object respawns before dying
    BOOL            autoReverse;        // YES = animation reverses
    CGFloat         seekDelay;          // delay in seconds before a peek object reappears
    BOOL            angledPath;         // YES = Move_Auto objects along an angle
    ViewCheckType   vcType;             // view validation
    BOOL            movePath;           // YES = objects moves along an svg path
    CGFloat         pathTime;           // time object takes to move along path
    CGFloat         peekTime;           // cycle time for peeking objects
    int             numPaths;           // # of paths 
    BOOL            bFlocking;          // YES = object follows flocking rules (notefish)
    CGFloat         sinkAngle;          // angle a shakeBySpawn object turns when floating down
    BOOL            removeOnClean;      // YES = object is killed when Clean is chosen
    CGFloat         wiggleTime;         // how long the object wiggles
    CGFloat         wiggleAngle;        // angle the object wiggles to
    CGFloat         scaleStart;         // scale the object load as
    BOOL            fixedDir;           // object's direction cannot change (murene)
    BOOL            objLimit;           // YES = object counts toward the MAX_OBJECTS limit
    CGFloat         crvXOffMin;         // for note fish, the min/max of the curve elements added
    CGFloat         crvXOffMax;         //   to position path, C = control points
    CGFloat         crvYOffMin;         //   these are all randomized between min/max for each
    CGFloat         crvYOffMax;
    CGFloat         crvCOffMin;
    CGFloat         crvCOffMax;
} PaperProps;

// for initializing paper animations
typedef struct {
    int         animID;
    CGFloat     anchorX;
    CGFloat     anchorY;
    CGFloat     duration;
    CGFloat     repeat;
    int         numAngles;
    CGFloat     angle01;
    CGFloat     angle02;
    CGFloat     angle03;
    CGFloat     angle04;
    CGFloat     angle05;
    CGFloat     angle06;
    CGFloat     angle07;
    CGFloat     angle08;
    CGFloat     angle09;
    int         numPoints;
    CGFloat     point01x;
    CGFloat     point01y;
    CGFloat     point02x;
    CGFloat     point02y;
    CGFloat     point03x;
    CGFloat     point03y;
    CGFloat     point04x;
    CGFloat     point04y;
    CGFloat     point05x;
    CGFloat     point05y;
} PaperPropsAnim;

// for object groups
typedef struct {
    int     groupID;
    int     objIDMaster;  // Master object
    int     numSubs;      // number of sub objects in group
    int     objIDSub01;
    int     objIDSub02;
    int     objIDSub03;
    int     objIDSub04;
    int     objIDSub05;
    int     objIDSub06;
    int     objIDSub07;
    int     objIDSub08;
    int     objIDSub09;
    int     objIDSub10;
} PaperGroups;

// for initializing custom touch spots
typedef struct {
    int     tsID;
    CGFloat tsX;    // X offset from paper center
    CGFloat tsY;    // Y offset from paper center
    CGFloat tsWd;
    CGFloat tsHt;
    int     objID;  // for spawning objects from non-linked touchspots
    //   also represents ID from PaperPropsRandom for random = YES
    BOOL    random;
} PaperPropsTouchspot;

// for initializing sound files
typedef struct {
    int         soundID;
    const char* soundPath;
    const char* fileType;
} PaperPropsSounds;

// ________________ OBJMANAGER

// world-level flags / states
typedef enum {
    osNone          = 0x00000,
    osPaused        = 0x00002,
    osCleaning      = 0x00004,
    osMurene        = 0x00008
} ObjState;

// type of object
typedef enum {
    Obj_Paper = 0,
    Obj_PaperPath
} ObjType;

// for initializing custom touch spots
typedef struct {
    int     orID;
    CGFloat orX;    // X offset from paper center
    CGFloat orY;    // Y offset from paper center
    CGFloat orWd;
    CGFloat orHt;
} WorldRects;

// world-level timers
typedef enum {
    wtNone      = 0x00000,
    wtSpawn10   = 0x00002,
    wtSpawn12   = 0x00004,
    wtMurene    = 0x00008
} WorldTimer;

// for spawning a random object from a list of IDs, referenced by row
typedef struct {
    int     rObjID01;
    int     rObjID02;
    int     rObjID03;
    int     rObjID04;
    int     rObjID05;
} PaperRandom;

// for initializing world-level timers for spawning
typedef struct {
    MessageType mType;          // type of world timer
    WorldTimer  wTimer;         // timer identifier
    int         objTargetID;    // target of timer
    CGFloat     wtInterval;     // base interval of timer
    CGFloat     wtIntervalMax;
    CGFloat     wtIntervalMin;
} PaperWorldTimers;


// ________________ PROPERTY TABLES 

// ** NOTE - FOR ALL PROPERTY TABLES, YOU MUST UPDATE THE bobAmp PROPERTY FOR RECORD INDEX = 0
//    TO REFLECT THE CORRECT NUMBER OF OBJECTS, OR YOU WILL BE MISSING OBJECTS.  THIS IS DONE
//    BECAUSE WE CAN'T DETERMINE THE SIZE OF AN ARRAY AFTER PASSING IT TO A FUNCTION (initScene).

// MERMAIDS Properties
static PaperProps __unused paperMermaidsTable[] = {
    
//  FIRST ROW = BORDER & HIGH-LEVEL PROPERTIES ROW
    {0, "Border",   NO,  NO,
        40,     // Width
        20,     // Bounds
        0,      // PosZ
        Move_Static,
        0.0,    // R (Border Color)
        0.0,    // G
        0.0,    // B
        1.0,    // A
        NO,
        58.0,   // # of Pieces
        0.0, NO, 0.0, 0.0, NO, 0, 0, 0, 0, NO, 0.0, 0, 0, 0, 0.0, 0, NO, "png", 0, 0, Paper_Image, NO, 0.0, 0.0, NO,
        0.0, 0.0, 0.0, 0.0, Bind_Never, NO, 0.0, 0.0, NO, 0.0, 0.0, 0.0, Decel_None, 0, NO, 0.0, NO, vcNone, NO, 0.0,
        0.0, 0, NO, 0.0, NO, 0.0, 0.0, 0.0, NO, NO },
    
//  ALL OTHER ROWS = OBJECTS
//  SECOND ROW = BACKGROUND

//  [ Z-position ]  -100 (background), -10 (bubbles), -7 (shake objects), -5 (auto/group moving, weeds),
//                  -4/-3/-2 (touch objects), 0 (border), 1 (pinch objects)
    
//                        SPAWN POS (CTR)
//  ID ImageName   Bnd  Rndm PosX  PosY  PosZ MoveType     VelX  VelY  Decel  DTm  Bob  BAmp BOff FlipX FlpTm Spwn Init Cld  CldX CldY Anm Coll Mass
//     TS Grp  Frm FDur Ornt Pnch File   Hgt   Wd  PaperType    KOnT  PMx  PMn RVOn RVTMx RVTMn  RVMx  RVMn  BindType     Shke KlTm bSpd bKll
//     bSkOX  bSkOY anmTm DecelType   SpwC Auto SkDly Angle ViewCheckType       MvPth PhTm PkTm MxP Flk  SnkA ClRmv WgTm  WgAn ScSt FxDr ObjR
//    cvXMn  cvXMx  cvYMn  cvYMx  cvCMn  cvCMx
    {1, "Water"   , NO,  NO,  384,  512, -100, Move_Static, 0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0, YES,  0,   0,    0,  0, NO,  0.0,
        0,  0,  0,  0.0,  0,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {2, "Seahorse", YES, NO,  200,  700,    1, Move_Touch,  0.0,  0.0, -0.005, 0.8, YES, 5.0, 0.0, YES,  0.0,  0.0, YES,  0,   0,    0,  0, YES, 2.0,
        0,  1,  0,  0.0,  1, YES, "png",   0,   0, Paper_Image,   NO, 1.3, 0.6,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Always , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_Slow,   0,  NO,   0.0,  NO, vcWithinBoundedBox  , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.6,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {3, "Fish01",   YES, NO,  154,  452,   -2, Move_Touch,  0.0,  0.0, -0.005, 1.4, YES, 3.0, 1.8, YES,  2.0,  0.0, YES,  0,   0,    0,  0, YES, 0.7,
        0,  0,  8,  2.1,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0, YES,  8.0,  2.0,  2.0,  0.3, Bind_Always , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_Slow,   0, YES,   0.0,  NO, vcWithinBoundedBox  , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {4, "Fish02",   NO,  YES, 500, -120,   -5, Move_Auto,   0.0,  0.8,  0.0,   0.0, YES, 8.0, 0.2, NO,   1.8, 10.1, YES,  0,   0,    0,  0, NO,  0.0,
        0,  0,  8,  2.2,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0, YES,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {5, "Mermaid01",YES, NO,  600,  500,    1, Move_Touch,  0.0,  0.0,  0.0,   0.0, YES, 6.5, 0.5, YES,  0.0,  0.0, YES, 23, -70, -100,  0, NO,  4.8,
        1,  0,  0,  0.0, -1, YES, "png",   0,   0, Paper_Image,   NO, 1.2, 0.6,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Always , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_Med,    0,  NO,   0.0,  NO, vcCenterOnScreen    , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    
//  ID ImageName   Bnd  Rndm PosX  PosY  PosZ MoveType     VelX  VelY  Decel  DTm  Bob  BAmp BOff FlipX FlpTm Spwn Init Cld  CldX CldY Anm Coll Mass
//     TS Grp  Frm FDur Ornt Pnch File   Hgt   Wd  PaperType    KOnT  PMx  PMn RVOn RVTMx RVTMn  RVMx  RVMn  BindType     Shke KlTm bSpd bKll
//     bSkOX  bSkOY anmTm DecelType   SpwC Auto SkDly Angle ViewCheckType       MvPth PhTm PkTm MxP Flk  SnkA ClRmv WgTm  WgAn ScSt FxDr ObjR
//    cvXMn  cvXMx  cvYMn  cvYMx  cvCMn  cvCMx
    {6, "Bubble09", NO,  YES,   0,    0,  -10, Move_Auto,   0.0, -0.9,  0.0,   0.0, YES, 5.2, 0.6, NO,   0.0,  3.1,  NO,  0,   0,    0,  0, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,  YES, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   1,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0, YES,  0.0,  0.0, 0.0,  NO, YES,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {7, "Bubble09", NO,  YES, 300, 1100,  -10, Move_Auto,   0.0, -0.4,  0.0,   0.0, YES, 5.0, 0.3, NO,   0.0,  7.0, YES,  0,   0,    0,  0, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,  YES, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0, YES,  0.0,  0.0, 0.0,  NO, YES,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {8, "Mermaid02",YES, NO,  163,  230,    1, Move_Touch,  0.0,  0.0,  0.0,   0.0, YES, 5.8, 1.2, YES,  0.0,  0.0, YES,  9, 125, -155,  0, NO,  5.0,
        3,  0,  0,  0.0,  1, YES, "png",   0,   0, Paper_Image,   NO, 1.2, 0.6,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Always , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_Med,    0,  NO,   0.0,  NO, vcCenterOnScreen    , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {9, "Bubble08", NO,  YES,   0,    0,  -10, Move_Auto,   0.0, -1.2,  0.0,   0.0, YES, 6.0, 0.2, NO,   0.0,  4.2,  NO,  0,   0,    0,  0, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,  YES, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   2,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0, YES,  0.0,  0.0, 0.0,  NO, YES,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {10,"Bubble07", NO,  YES, 600, 1100,  -10, Move_Auto,   0.0, -1.8,  0.0,   0.0, YES, 6.2, 0.9, NO,   0.0,  6.4, YES,  0,   0,    0,  0, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,  YES, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0, YES,  0.0,  0.0, 0.0,  NO, YES,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    
//  ID ImageName   Bnd  Rndm PosX  PosY  PosZ MoveType     VelX  VelY  Decel  DTm  Bob  BAmp BOff FlipX FlpTm Spwn Init Cld  CldX CldY Anm Coll Mass
//     TS Grp  Frm FDur Ornt Pnch File   Hgt   Wd  PaperType    KOnT  PMx  PMn RVOn RVTMx RVTMn  RVMx  RVMn  BindType     Shke KlTm bSpd bKll
//     bSkOX  bSkOY anmTm DecelType   SpwC Auto SkDly Angle ViewCheckType       MvPth PhTm PkTm MxP Flk  SnkA ClRmv WgTm  WgAn ScSt FxDr
//    cvXMn  cvXMx  cvYMn  cvYMx  cvCMn  cvCMx
    {11,"Seaweed",  NO,  NO,  384,  512,   -5, Move_Static, 0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0, YES,  0,   0,    0,  0, NO,  0.0,
        0,  0,  0,  0.0,  0,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {12,"Bubble06", NO,  YES, 450, 1100,  -10, Move_Auto,   0.0, -1.0,  0.0,   0.0, YES, 4.0, 0.7, NO,   0.0,  7.9, YES,  0,   0,    0,  0, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,  YES, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0, YES,  0.0,  0.0, 0.0,  NO, YES,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {13,"Fish03",   NO,  YES, 840,  650,   -5, Move_Auto,  -0.7,  0.0,  0.0,   0.0, YES, 4.0, 1.1, YES,  1.6,  9.0, YES,  0,   0,    0,  0, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {14,"Bubble08", NO,  YES, 200, 1200,  -10, Move_Auto,   0.0, -0.5,  0.0,   0.0, YES, 7.0, 0.4, NO,   0.0, 11.7, YES,  0,   0,    0,  0, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,  YES, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0, YES,  0.0,  0.0, 0.0,  NO, YES,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {15,"FishBig",  NO,  NO, -185,  490,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, YES,  0.0,  0.0,  NO,  0,   0,    0,  1, NO,  0.0,
        0,  0,  0,  0.0,  0,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcCompletelyOffScreen,NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    
//  ID ImageName   Bnd  Rndm PosX  PosY  PosZ MoveType     VelX  VelY  Decel  DTm  Bob  BAmp BOff FlipX FlpTm Spwn Init Cld  CldX CldY Anm Coll Mass
//     TS Grp  Frm FDur Ornt Pnch File   Hgt   Wd  PaperType    KOnT  PMx  PMn RVOn RVTMx RVTMn  RVMx  RVMn  BindType     Shke KlTm bSpd bKll
//     bSkOX  bSkOY anmTm DecelType   SpwC Auto SkDly Angle ViewCheckType       MvPth PhTm PkTm MxP Flk  SnkA ClRmv WgTm  WgAn ScSt FxDr ObjR
//    cvXMn  cvXMx  cvYMn  cvYMx  cvCMn  cvCMx
    {16,"Fish03LG", NO,  YES, 840,  900,   -5, Move_Auto,  -0.5,  0.0,  0.0,   0.0, YES, 3.5, 0.7, YES,  1.9, 14.6, YES,  0,   0,    0,  0, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {17,"SHWings",  NO,  NO,  180,  660,   -5, Move_Group,  0.0,  0.0,  0.0,   0.0, YES, 0.0, 0.0, YES,  0.0,  0.0, YES,  0, -13,  -40,  0, NO,  0.0,
        0,  0,  5,  1.0,  0,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0, YES,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {18,"Note01",   NO,  NO,  300,  500,   -5, Move_Auto,   0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, NO,   0.0,  0.0,  NO, 19, 0.0,  0.0,  0, NO,  0.0,
        0,  0,  0,  3.0,  0,  NO, "svg",   0,   0, Paper_Vector,  NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0, YES,  0.0,  0.0, 0.0,  NO,  NO,
      100.0, 130.0, 250.0, 400.0,  20.0,  50.0 },
    {19,"NoteFh01",YES,  NO,    0,    0,   -2, Move_Touch, -0.6,  0.0, -0.005, 1.2, YES, 4.0, 1.6, YES,  1.4,  0.0,  NO,  0,   0,    0,  0, NO,  0.3,
        0,  0,  0,  0.0, -1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0, YES,  9.0,  1.2,  1.5,  0.1, Bind_Always , NO , 0.0, 1.0,  NO,
        0.0,   0.0,  0.0, Decel_Slow,   0,  NO,   0.0,  NO, vcWithinBoundedBox  , NO , 0.0, 0.0, 0, YES,  0.0, YES,  0.0,  0.0, 0.0,  NO, YES,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {20,"Bottle",   NO,  NO,  337, -100,   -7, Move_Auto,   0.0,  0.8,  0.0,   0.0, YES,12.0, 0.8,  NO,  0.0,  0.0,  NO,  0,   0,    0,  0, NO, 10.2,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_OnEnter, YES,20.4, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcCompletelyOnScreen, NO , 0.0, 0.0, 0,  NO, 80.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    
//  ID ImageName   Bnd  Rndm PosX  PosY  PosZ MoveType     VelX  VelY  Decel  DTm  Bob  BAmp BOff FlipX FlpTm Spwn Init Cld  CldX CldY Anm Coll Mass
//     TS Grp  Frm FDur Ornt Pnch File   Hgt   Wd  PaperType    KOnT  PMx  PMn RVOn RVTMx RVTMn  RVMx  RVMn  BindType     Shke KlTm bSpd bKll
//     bSkOX  bSkOY anmTm DecelType   SpwC Auto SkDly Angle ViewCheckType       MvPth PhTm PkTm MxP Flk  SnkA ClRmv WgTm  WgAn ScSt FxDr
//    cvXMn  cvXMx  cvYMn  cvYMx  cvCMn  cvCMx
    {21,"Boot",     NO,  NO,  400, -100,   -7, Move_Anim,   0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, YES,  0.0,  0.0,  NO, 22,  50, 1380,  8, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {22,"Boot",     NO,  NO,  440, -100,   -7, Move_Auto,   0.0,  0.9,  0.0,   0.0, YES,13.0, 0.5,  NO,  0.0,  0.0,  NO,  0,   0,    0,  0, NO, 12.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_OnEnter, YES,16.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcCompletelyOnScreen, NO , 0.0, 0.0, 0,  NO, 30.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {23,"Note02",   NO,  NO,  300,  500,   -5, Move_Auto,   0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, NO,   0.0,  0.0,  NO, 24, 0.0,  0.0,  0, NO,  0.0,
        0,  0,  0,  4.0,  0,  NO, "svg",   0,   0, Paper_Vector,  NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0, YES,  0.0,  0.0, 0.0,  NO,  NO,
       90.0, 140.0, 200.0, 500.0,  30.0,  80.0 },
    {24,"NoteFh02",YES,  NO,    0,    0,   -2, Move_Touch, -0.4,  0.0, -0.005, 1.2, YES, 3.4, 1.6, YES,  1.0,  0.0,  NO,  0,   0,    0,  0, NO,  0.2,
        0,  0,  0,  0.0, -1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0, YES, 10.0,  1.5,  1.5,  0.1, Bind_Always , NO , 0.0, 1.3,  NO,
        0.0,   0.0,  0.0, Decel_Slow,   0,  NO,   0.0,  NO, vcWithinBoundedBox  , NO , 0.0, 0.0, 0, YES,  0.0, YES,  0.0,  0.0, 0.0,  NO, YES,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {25,"FishCln",  NO,  NO, -185,  800,   -5, Move_Auto,   0.9,  0.0,  0.0,   0.0, YES, 4.0, 0.2, YES,  0.0,  0.0,  NO,  0,   0,    0,  1, NO,  8.0,
        0,  0,  3,  0.6,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO, 15.0,  8.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 1.4,  NO,
        0.0,   0.0,  0.0, Decel_Slow,   0, YES,   8.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0, YES,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },

//  ID ImageName   Bnd  Rndm PosX  PosY  PosZ MoveType     VelX  VelY  Decel  DTm  Bob  BAmp BOff FlipX FlpTm Spwn Init Cld  CldX CldY Anm Coll Mass
//     TS Grp  Frm FDur Ornt Pnch File   Hgt   Wd  PaperType    KOnT  PMx  PMn RVOn RVTMx RVTMn  RVMx  RVMn  BindType     Shke KlTm bSpd bKll
//     bSkOX  bSkOY anmTm DecelType   SpwC Auto SkDly Angle ViewCheckType       MvPth PhTm PkTm MxP Flk  SnkA ClRmv WgTm  WgAn ScSt FxDr ObjR
//    cvXMn  cvXMx  cvYMn  cvYMx  cvCMn  cvCMx
    {26,"Note03",   NO,  NO,  300,  500,   -5, Move_Auto,   0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0,  NO,  0.0,  0.0,  NO, 27, 0.0,  0.0,  0, NO,  0.0,
        0,  0,  0,  4.6,  0,  NO, "svg",   0,   0, Paper_Vector,  NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0, YES,  0.0,  0.0, 0.0,  NO,  NO,
      110.0, 140.0, 230.0, 470.0,  10.0,  90.0 },
    {27,"NoteFh03",YES,  NO,    0,    0,   -2, Move_Touch, -0.5,  0.0, -0.005, 1.2, YES, 3.0, 1.6, YES,  1.3,  0.0,  NO,  0,   0,    0,  0, NO,  0.5,
        0,  0,  0,  0.0, -1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0, YES,  8.0,  2.0,  1.3,  0.1, Bind_Always , NO , 0.0, 1.1,  NO,
        0.0,   0.0,  0.0, Decel_Slow,   0,  NO,   0.0,  NO, vcWithinBoundedBox  , NO , 0.0, 0.0, 0, YES,  0.0, YES,  0.0,  0.0, 0.0,  NO, YES,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {28,"Diver",    NO,  YES, 1700,  80,   -5, Move_Auto,  -1.6,  0.0,  0.0,   0.0, YES, 6.0, 1.2, YES,  0.0, 90.0, YES,  0,   0,    0,  1, NO,  0.0,
        0,  0,  2,  0.4, -1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  5.3, Decel_Slow,   0, YES,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {29,"Eel01",    NO,  YES, 350, -100,   -5, Move_Auto,   0.0,  1.1,  0.0,   0.0, YES, 4.0, 0.3,  NO,  0.0,  9.0,  NO,  0, 0.5,  0.5, -1, NO,  0.0,
        0,  0,  0,  1.5,  1,  NO, "svg",   0,   0, Paper_Vector,  NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0, YES,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {30,"Squid",    NO,  YES, 1500, 600,   -5, Move_Auto,  -3.0, -0.5, -5.0,   0.0,  NO, 0.0, 0.0, YES,  0.0, 32.0, YES,  0,   0,    0,  1, NO,  0.0,
        0,  0,  3,  0.8, -1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.1,   0.8,  6.5, Decel_Med,    0, YES,   0.0, YES, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    
//  ID ImageName   Bnd  Rndm PosX  PosY  PosZ MoveType     VelX  VelY  Decel  DTm  Bob  BAmp BOff FlipX FlpTm Spwn Init Cld  CldX CldY Anm Coll Mass
//     TS Grp  Frm FDur Ornt Pnch File   Hgt   Wd  PaperType    KOnT  PMx  PMn RVOn RVTMx RVTMn  RVMx  RVMn  BindType     Shke KlTm bSpd bKll
//     bSkOX  bSkOY anmTm DecelType   SpwC Auto SkDly Angle ViewCheckType       MvPth PhTm PkTm MxP Flk  SnkA ClRmv WgTm  WgAn ScSt FxDr
//    cvXMn  cvXMx  cvYMn  cvYMx  cvCMn  cvCMx
    {31,"Starfish",YES,  NO,  250,  969,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, YES,  0.0,  0.0,  NO,  0,   0,    0,  0, NO,  0.9,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_Med,    0,  NO,   0.0,  NO, vcNone              , YES,69.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },//NU
    {32,"Starfsh2",YES,  NO,  250,  969,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, YES,  0.0,  0.0, YES,  0,   0,    0,  0, NO,  0.9,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO, 15.0,  8.5,  0.1, 0.05, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_Med,    0,  NO,   0.0,  NO, vcNone              , YES,80.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {33,"FishBig2", NO,  NO,  810,  620,   -5, Move_Auto  , 0.2,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, YES,  0.0,  0.0, YES,  0,  42,    0,  0, NO,  0.0,
        0,  0,  0,  0.0, -1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.3,   1.1,  0.0, Decel_None,   0,  NO,   0.0, YES, vcNone              , NO , 0.0, 7.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {34,"Star"    ,YES,  NO,  250,  969,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, YES,  0.0,  0.0, YES,  0,   0,    0,  0, NO,  0.9,
        0,  0,  5,  3.2,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO, 15.0,  8.5,  0.1, 0.05, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_Med,    0,  NO,   0.0,  NO, vcNone              , YES,69.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {35,"Blow"    ,YES,  NO,    0,    0,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, YES,  0.0,  0.0,  NO,  0,   0,    0,  1, NO,  0.0,
        0,  0, 22, 18.0,  1,  NO, "png",   0,   0, Paper_Image,  YES, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_Med,    0,  NO,   0.0,  NO, vcNone              , YES,18.0, 0.0, 3,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    
//  ID ImageName   Bnd  Rndm PosX  PosY  PosZ MoveType     VelX  VelY  Decel  DTm  Bob  BAmp BOff FlipX FlpTm Spwn Init Cld  CldX CldY Anm Coll Mass
//     TS Grp  Frm FDur Ornt Pnch File   Hgt   Wd  PaperType    KOnT  PMx  PMn RVOn RVTMx RVTMn  RVMx  RVMn  BindType     Shke KlTm bSpd bKll
//     bSkOX  bSkOY anmTm DecelType   SpwC Auto SkDly Angle ViewCheckType       MvPth PhTm PkTm MxP Flk  SnkA ClRmv WgTm  WgAn ScSt FxDr ObjR
//    cvXMn  cvXMx  cvYMn  cvYMx  cvCMn  cvCMx
    {36,"BlowSm"  ,YES,  NO,    0,    0,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, YES,  0.0,  0.0,  NO,  0,   0,    0,  1, NO,  0.0,
        0,  0, 10, 12.0, -1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_Med,    0,  NO,   0.0,  NO, vcNone              , YES,12.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },//NU
    {37,"BlowLg"  ,YES,  NO,    0,    0,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, YES,  0.0,  0.0,  NO,  0,   0,    0,  1, NO,  0.0,
        0,  0, 10,  8.9, -1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_Med,    0,  NO,   0.0,  NO, vcNone              , YES, 9.0, 0.0, 3,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {38,"Octo",     NO,  YES, 400, 2000,   -5, Move_Auto,  -0.5, -2.8, -5.0,   0.0,  NO, 0.0, 0.0,  NO,  0.0, 55.0,  NO,  0,   0,    0,  1, NO,  0.0,
        0,  0,  4,  0.7, -1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_Med,    0, YES,   0.0, YES, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },//NU
    {39,"Bubble05", NO,  YES,   0,    0,  -10, Move_Auto,   0.0, -0.7,  0.0,   0.0, YES, 7.3, 0.5, NO,   0.0, 11.7, YES,  0,   0,    0,  0, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,  YES, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   1,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0, YES,  0.0,  0.0, 0.0,  NO, YES,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {40,"Fish03",   NO,  YES, 900,  800,   -5, Move_Auto,  -0.6,  0.0,  0.0,   0.0, YES, 4.5, 1.7, YES,  1.7, 16.0, YES,  0,   0,    0,  0, NO,  0.0,
        0,  2,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    
//  ID ImageName   Bnd  Rndm PosX  PosY  PosZ MoveType     VelX  VelY  Decel  DTm  Bob  BAmp BOff FlipX FlpTm Spwn Init Cld  CldX CldY Anm Coll Mass
//     TS Grp  Frm FDur Ornt Pnch File   Hgt   Wd  PaperType    KOnT  PMx  PMn RVOn RVTMx RVTMn  RVMx  RVMn  BindType     Shke KlTm bSpd bKll
//     bSkOX  bSkOY anmTm DecelType   SpwC Auto SkDly Angle ViewCheckType       MvPth PhTm PkTm MxP Flk  SnkA ClRmv WgTm  WgAn ScSt FxDr
//    cvXMn  cvXMx  cvYMn  cvYMx  cvCMn  cvCMx
    {41,"Fish03",   NO,  YES, 810,  800,   -5, Move_Group,  0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, YES,  0.0,  0.0, YES,  0, -20,  -20,  0, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {42,"Fish03",   NO,  YES, 810,  800,   -5, Move_Group,  0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, YES,  0.0,  0.0, YES,  0, -20,   20,  0, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {43,"Octo",     NO,  YES, 400,  850,   -2, Move_Touch,  0.0,  0.0,  0.0,   0.0, YES,10.0, 0.3, YES,  0.0,  0.0,  NO,  0,   0,    0,  0, NO,  0.0,
        0,  0,  4,  1.4,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Always , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_Stop,   0, YES,   0.0,  NO, vcKeepOnGround      , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },//NU
    {44,"Murene",   NO,   NO, -57,  120,   -5, Move_Auto,   0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0, YES,  0.0,  0.0, YES,  0,   0,    0,  1, NO,  4.0,
        0,  0,  3,  0.6,  1,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Always , NO , 0.0, 2.5,  NO,
        0.0,   0.0,  0.0, Decel_Slow,   0, YES,   0.0,  NO,vcCompletelyOffScreen, NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0, YES,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {45,"Info",     NO,  YES,  35,  990,   10, Move_Anim,   0.0,  0.0,  0.0,   0.0,  NO, 0.0, 0.0,  NO,  0.0,  0.0, YES,  0,   0,    0,  9, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,  YES, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {46,"Bubble10", NO,  YES,   0,    0,  -10, Move_Auto,   0.0, -0.4,  0.0,   0.0, YES, 5.2, 1.3, NO,   0.0,  9.3,  NO,  0,   0,    0,  0, NO,  0.0,
        0,  0,  0,  0.0,  1,  NO, "png",   0,   0, Paper_Image,  YES, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   1,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0, YES,  0.0,  0.0, 0.0,  NO, YES,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    
//  ANIMATED BACKGROUND PIECES - spawn position is relative to anchor point in animation properties
//  ID ImageName   Bnd  Rndm PosX  PosY  PosZ MoveType     VelX  VelY  Decel  DTm  Bob  BAmp BOff FlipX FlpTm Spwn Init Cld  CldX CldY Anm Coll Mass
//     TS Grp  Frm FDur Ornt Pnch File   Hgt   Wd  PaperType    KOnT  PMx  PMn RVOn RVTMx RVTMn  RVMx  RVMn  BindType     Shke KlTm bSpd bKll
//     bSkOX  bSkOY anmTm DecelType   SpwC Auto SkDly Angle ViewCheckType       MvPth PhTm PkTm MxP Flk  SnkA ClRmv WgTm  WgAn ScSt FxDr
//    cvXMn  cvXMx  cvYMn  cvYMx  cvCMn  cvCMx
    {50,"Weed01",   NO,  NO,  290, 1010,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0,  NO,  0,   0,    0,  2, NO,  0.0,
        0,  0,  0,  0.0,  0,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },//47NU
    {51,"Weed02",   NO,  NO,   80, 1010,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0,  NO,  0,   0,    0,  3, NO,  0.0,
        0,  0,  0,  0.0,  0,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },//NU
    {52,"Weed03",   NO,  NO,  725, 1000,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0, YES,  0,   0,    0,  4, NO,  0.0,
        0,  0,  0,  0.0,  0,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {53,"Weed04",   NO,  NO,  750,  480,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0, YES,  0,   0,    0,  5, NO,  0.0,
        0,  0,  0,  0.0,  0,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {54,"Weed05",   NO,  NO,   32,  610,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0, YES,  0,   0,    0,  6, NO,  0.0,
        0,  0,  0,  0.0,  0,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {55,"Weed06",   NO,  NO,  448, 1010,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0,  NO,  0,   0,    0,  7, NO,  0.0,
        0,  0,  0,  0.0,  0,  NO, "png",   0,   0, Paper_Image,   NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0,  NO,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },//52NU
    
//  ID ImageName   Bnd  Rndm PosX  PosY  PosZ MoveType     VelX  VelY  Decel  DTm  Bob  BAmp BOff FlipX FlpTm Spwn Init Cld  CldX CldY Anm Coll Mass
//     TS Grp  Frm FDur Ornt Pnch File   Hgt   Wd  PaperType    KOnT  PMx  PMn RVOn RVTMx RVTMn  RVMx  RVMn  BindType     Shke KlTm bSpd bKll
//     bSkOX  bSkOY anmTm DecelType   SpwC Auto SkDly Angle ViewCheckType       MvPth PhTm PkTm MxP Flk  SnkA ClRmv WgTm  WgAn ScSt FxDr
//    cvXMn  cvXMx  cvYMn  cvYMx  cvCMn  cvCMx
    {70,"Weed07",   NO,  NO,  274,  903,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0, YES,  0, 0.5,  1.0, -1, NO,  1.2,
        0,  0,  0,  9.0,  0,  NO, "svg",   0,   0, Paper_Vector,  NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0, YES,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.7,  2.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {71,"Weed08",   NO,  NO,  -28,   81,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0, YES,  0, 0.0,  1.0, -1, NO,  1.0,
        0,  0,  0,  7.3,  0,  NO, "svg",   0,   0, Paper_Vector,  NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0, YES,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {72,"Weed09",   NO,  NO,    6,  870,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0, YES,  0, 0.0,  1.0, -1, NO,  1.9,
        0,  0,  0, 10.5,  0,  NO, "svg",   0,   0, Paper_Vector,  NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0, YES,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.5,  2.2, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {73,"Weed10",   NO,  NO,  690,   79,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0, YES,  0, 1.0,  1.0, -1, NO,  1.3,
        0,  0,  0,  9.5,  0,  NO, "svg",   0,   0, Paper_Vector,  NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0, YES,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.0,  0.0, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 },
    {74,"Weed11",   NO,  NO,  442,  935,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0, YES,  0, 0.5,  1.0, -1, NO,  1.1,
        0,  0,  0,  8.6,  0,  NO, "svg",   0,   0, Paper_Vector,  NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0, YES,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  0.8,  1.8, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 }, //57
    {75,"Weed12",   NO,  NO,  653,  951,   -5, Move_Anim,   0.0,  0.0,  0.0,   0.0, NO,  0.0, 0.0, NO,   0.0,  0.0, YES,  0, 0.5,  1.0, -1, NO,  1.6,
        0,  0,  0,  7.1,  0,  NO, "svg",   0,   0, Paper_Vector,  NO, 0.0, 0.0,  NO,  0.0,  0.0,  0.0,  0.0, Bind_Never  , NO , 0.0, 0.0,  NO,
        0.0,   0.0,  0.0, Decel_None,   0, YES,   0.0,  NO, vcNone              , NO , 0.0, 0.0, 0,  NO,  0.0,  NO,  1.0,  2.5, 0.0,  NO,  NO,
        0.0,   0.0,   0.0,   0.0,   0.0,   0.0 }
    
};

static PaperPropsAnim __unused paperMermaidsAnimations[] = {
    
    // FIRST ROW IS A DUMMY DEFAULT ROW
    // ID  AncX AncY Durtn  Rpt   #Ang   A01     A02     A03     A04     A05     A06     A07     A08     A09
    {   0, 0.0, 0.0,  0.0,  0.0,    0,   0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,
    //  #Pts   P01X    P01Y    P02X    P02Y    P03X    P03Y    P04X    P04Y    P05X    P05Y
        0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0 },
    
    // ID  AncX AncY Durtn  Rpt   #Ang   A01     A02     A03     A04     A05     A06     A07     A08     A09
    {   1, 0.5, 0.5, 33.0,  1.0,    8, -15.0,  -10.0,   -7.0,  -10.0,  -15.0,  -10.0,   -7.0,  -10.0,    0.0,
    //  #Pts   P01X    P01Y    P02X    P02Y    P03X    P03Y    P04X    P04Y    P05X    P05Y
        2, -185.0,  490.0,  950.0, -100.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0 },
    
    // ID  AncX AncY Durtn  Rpt   #Ang   A01     A02     A03     A04     A05     A06     A07     A08     A09
    {   2, 0.5, 1.0, 6.0, FLT_MAX,  5,   2.0,    3.0,    4.0,    3.0,    2.0,    0.0,    0.0,    0.0,    0.0,
    //  #Pts   P01X    P01Y    P02X    P02Y    P03X    P03Y    P04X    P04Y    P05X    P05Y
        0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0 },
    
    // ID  AncX AncY Durtn  Rpt   #Ang   A01     A02     A03     A04     A05     A06     A07     A08     A09
    {   3, 0.0, 1.0, 10.5,FLT_MAX,  5,  -0.5,   -1.0,   -2.0,   -1.0,   -0.5,    0.0,    0.0,    0.0,    0.0,
    //  #Pts   P01X    P01Y    P02X    P02Y    P03X    P03Y    P04X    P04Y    P05X    P05Y
        0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0 },
    
    // ID  AncX AncY Durtn  Rpt   #Ang   A01     A02     A03     A04     A05     A06     A07     A08     A09
    {   4, 1.0, 1.0, 7.5, FLT_MAX,  7,  -0.4,   -0.9,   -1.3,   -1.5,   -1.3,   -0.9,   -0.4,    0.0,    0.0,
    //  #Pts   P01X    P01Y    P02X    P02Y    P03X    P03Y    P04X    P04Y    P05X    P05Y
        0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0 },
    
    // ID  AncX AncY Durtn  Rpt   #Ang   A01     A02     A03     A04     A05     A06     A07     A08     A09
    {   5, 1.0, 1.0, 6.5, FLT_MAX,  6,   0.3,    0.8,    1.2,    1.2,    0.8,    0.3,    0.0,    0.0,    0.0,
    //  #Pts   P01X    P01Y    P02X    P02Y    P03X    P03Y    P04X    P04Y    P05X    P05Y
        0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0 },
    
    // ID  AncX AncY Durtn  Rpt   #Ang   A01     A02     A03     A04     A05     A06     A07     A08     A09
    {   6, 0.0, 1.0, 9.5, FLT_MAX,  8,  -0.5,   -1.0,   -1.4,   -1.9,   -1.9,   -1.4,   -1.0,   -0.5,    0.0,
    //  #Pts   P01X    P01Y    P02X    P02Y    P03X    P03Y    P04X    P04Y    P05X    P05Y
        0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0 },
    
    // ID  AncX AncY Durtn  Rpt   #Ang   A01     A02     A03     A04     A05     A06     A07     A08     A09
    {   7, 0.0, 1.0, 7.5, FLT_MAX,  7,  -0.4,   -0.9,   -1.3,   -1.6,   -1.3,   -0.9,   -0.4,    0.0,    0.0,
    //#Pts   P01X    P01Y    P02X    P02Y    P03X    P03Y    P04X    P04Y    P05X    P05Y
        3,  448.0, 1010.0,  449.0, 1012.0,  448.0, 1010.0,    0.0,    0.0,    0.0,    0.0 },
    
    // ID  AncX AncY Durtn  Rpt   #Ang   A01     A02     A03     A04     A05     A06     A07     A08     A09
    {   8, 0.5, 0.5, 10.5,  1.0,    3,   7.0,   15.0,   30.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,
    //#Pts   P01X    P01Y    P02X    P02Y    P03X    P03Y    P04X    P04Y    P05X    P05Y
        2,  400.0, -400.0,  450.0,  980.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0 },
    
    // INFO MENU
    // ID  AncX AncY Durtn  Rpt   #Ang   A01     A02     A03     A04     A05     A06     A07     A08     A09
    {   9, 0.5, 0.5, 34.0, FLT_MAX, 6,   4.0,    7.0,   14.0,   14.0,    7.0,    4.0,    0.0,    0.0,    0.0,
    //#Pts   P01X    P01Y    P02X    P02Y    P03X    P03Y    P04X    P04Y    P05X    P05Y
        5,   35.0,  990.0,   36.0,  994.0,   36.0,  990.0,   35.0,  994.0,   35.0,  990.0 }
    
};

static PaperPropsTouchspot __unused paperMermaidsTouchspots[] = {
    
    // FIRST ROW IS A DUMMY DEFAULT ROW
    // ID    X Off   Y Off  Width Height Obj Rndm
    {   0,    0.0,    0.0,   0.0,   0.0,  6,  NO },   // Obj in first row is # of rows
    {   1,  -60.0,  -50.0,  30.0,  30.0,  1, YES },   // Mermaid01 horn bubble
    {   2,  300.0,    0.0, 100.0, 100.0, 15,  NO },   // Non-linked FishBig
    {   3,   95.0, -130.0,  25.0,  40.0,  3, YES },   // Mermaid02 horn bubble
    {   4,  360.0,    0.0,  80.0,  80.0, 21,  NO },   // Random TS Spawn - Top Middle
    {   5,  200.0,  704.0,  50.0,  50.0, 35,  NO },   // Random TS Spawn - Bottom Left Corner
    {   6,  668.0,  904.0, 100.0, 100.0, 37,  NO }    // Random TS Spawn - Bottom Right Corner
    
};

static PaperRandom __unused paperMermaidsRandom[] = {
    
    // FIRST ROW IS A DUMMY DEFAULT ROW
    // R01 R02 R03 R04 R05
    {   0,  0,  0,  0,  0 },
    {  18, 18, 26, 26, 18 },    // Mermaid01 horn
    {  15,  0, 35,  0, 37 },    // Touchspots
    {  23, 18, 18, 23, 18 }     // Mermaid02 horn
    
};

static PaperGroups __unused paperMermaidsGroups[] = {
    
    // FIRST ROW IS A DUMMY DEFAULT ROW
    // ID Mstr  #  S01 S02 S03 S04 S05 S06 S07 S08 S09 S10
    {   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
    {   1,  2,  1, 17,  0,  0,  0,  0,  0,  0,  0,  0,  0 },  // Seahorse & wings
    {   2, 40,  2, 41, 42,  0,  0,  0,  0,  0,  0,  0,  0 }   // school of small fish
};

static PaperPropsSounds __unused paperMermaidsSounds[] = {

    // FIRST ROW IS A DUMMY DEFAULT ROW
    {  22, "default",  "wav" }, // first value is # of sounds
    {   1, "FX_Sax1",  "wav" },
    {   2, "FX_Sax2",  "wav" },
    {   3, "FX_Sax3",  "wav" },
    {   4, "FX_Sax4",  "wav" },
    {   5, "FX_Hrn1",  "wav" },
    {   6, "FX_Hrn2",  "wav" },
    {   7, "FX_Splt2", "wav" },
    {   8, "FX_Reset", "wav" },
    {   9, "FX_Start", "wav" },
    {  10, "FX_Plop1", "wav" },
    {  11, "FX_Plop2", "wav" },
    {  12, "FX_Plop3", "wav" },
    {  13, "FX_Plop4", "wav" },
    {  14, "FX_Plop5", "wav" },
    {  15, "FX_Pop1",  "wav" },
    {  16, "FX_Pop2",  "wav" },
    {  17, "FX_Pop3",  "wav" },
    {  18, "FX_Pop4",  "wav" },
    {  20, "FX_ChimeL1", "wav" },
    {  21, "FX_ChimeL2", "wav" },
    {  22, "FX_ChimeR1", "wav" },
    {  23, "FX_ChimeR2", "wav" }
};

static PaperWorldTimers __unused paperMemmaidsTimers[] = {
  
    // FIRST ROW IS A DUMMY DEFAULT ROW
    // msgType  timerType  objID time  tMax  tMin
    { mtNone,   wtNone,      3,   0.0,  0.0,  0.0 },    // objID = # of rows
    { mtSpawn,  wtSpawn10,  10,  60.0, 67.0, 57.0 },    // Spawn Bubble
    { mtSpawn,  wtSpawn12,  12,  66.0, 70.0, 64.0 },    // Spawn Bubble
    { mtNone,   wtMurene,    0,  20.0, 18.0, 24.0 }     // Murene wait between bites
        
};

@interface Variables : NSObject 

@end
