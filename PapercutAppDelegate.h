//
//  PapercutAppDelegate.h
//  Papercut
//
//  Created by Jeff Bumgardner on 9/4/12.
//  Copyright (c) 2012 Jeff Bumgardner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "PapercutPadViewController.h"
#import "SplashViewController.h"

@interface PapercutAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, retain) PapercutPadViewController *viewController;
@property (nonatomic, retain) IBOutlet SplashViewController *viewControllerMenu;

@end
