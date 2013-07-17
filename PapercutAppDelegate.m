//
//  PapercutAppDelegate.m
//  Papercut
//
//  Created by Jeff Bumgardner on 9/4/12.
//  Copyright (c) 2012 Jeff Bumgardner. All rights reserved.
//

#import "PapercutAppDelegate.h"

@implementation PapercutAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
#ifdef TEST_FLIGHT_ON
    //[TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
    
    //[TestFlight setOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"logToConsole"]];
    //[TestFlight setOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"logToSTDERR"]];
    
    // Enable TestFlight functionality
    //[TestFlight takeOff:@"9d36f79e-53b1-44bb-bb36-0ef45666358c"];
#endif
    
    // Set AudioSession - needed?
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
    [[AVAudioSession sharedInstance] setDelegate:self];
    
    NSError *activationError  = nil;
    [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
    
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Override point for customization after application launch.
    
    // Make sure the screen doesn't go to sleep
    [application setIdleTimerDisabled:YES];

    // Set the default orientation of the window
    [application setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];

    // Set the root view controller for the window
    _viewControllerMenu = [[SplashViewController alloc] initWithNibName:@"SplashViewController" bundle:nil];
    _window.rootViewController = _viewControllerMenu;
    
    [_window setBackgroundColor:[UIColor blackColor]];
    
    [_window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
