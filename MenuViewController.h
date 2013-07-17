//
//  MenuViewController.h
//  Papercut
//
//  Created by Jeff Bumgardner on 4/3/13.
//  Copyright (c) 2013 Jeff Bumgardner. All rights reserved.
//
//  The small menu that appears in the bottom left of the main view controller.
//

#import <UIKit/UIKit.h>
#import "Variables.h"

@class ObjManager;
@class PapercutPadViewController;

@interface MenuViewController : UIViewController {
    
    UIImageView *menu;      // background
    UIImageView *menuStory; // background story
    UIImageView *menu1;     // story
    UIImageView *menu2;     // clear
    UIImageView *menu3;     // interact
    UIImageView *menu4;     // sound
    UIImageView *menu5;     // reset
    UIImageView *menu6;     // exit
    
    UILabel *label1;        // story
    UILabel *label2;        // clear
    UILabel *label3;        // interact
    UILabel *label4;        // sound
    UILabel *label5;        // reset
    UILabel *label6;        // exit
    
}

@property (nonatomic, strong) ObjManager *world;
@property (nonatomic, strong) PapercutPadViewController *parentVC;

- (id)initWithVC:(PapercutPadViewController *)pVC nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

@end
