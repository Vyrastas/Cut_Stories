//
//  SplashViewController.h
//  Papercut
//
//  Created by Jeff Bumgardner on 10/27/12.
//  Copyright (c) 2012 Jeff Bumgardner. All rights reserved.
//
//  Initial view controller when app is launched.
//

#import <UIKit/UIKit.h>
#import "PapercutPadViewController.h"
#import "Variables.h"

@class ObjManager;
@class Messenger;

@interface SplashViewController : UIViewController {
    
    PapercutPadViewController *viewPapercutController;
    
    UIImageView *menuStory;
    UIImageView *menuStart;
    UIImageView *title01;
    UIImageView *title02;
    UIImageView *title03;
    
    UILabel *labelStory;
    UILabel *labelStart;
    
    // used to prevent double-tapping
    //   double-tapping startClick would double the game loop
    BOOL    storyClick;     // YES = button tapped
    BOOL    startClick;
}

@property (nonatomic, strong) ObjManager *world;
@property (nonatomic, strong) Messenger *messenger;
    
@end
