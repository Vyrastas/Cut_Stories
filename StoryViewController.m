//
//  StoryViewController.m
//  Papercut
//
//  Created by Jeff Bumgardner on 3/7/13.
//  Copyright (c) 2013 Jeff Bumgardner. All rights reserved.
//
//  Pop-up view controller displaying the "story" text.  This is only
//    used from the SplashViewController.
//

#import "StoryViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "ObjManager.h"
#import <QuartzCore/QuartzCore.h>

@interface StoryViewController ()

@end

@implementation StoryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  // Do any additional setup after loading the view.
    
    // Set the background
    story = [[UIImageView alloc] initWithImage:
            [UIImage imageNamed:[NSString stringWithFormat:@"MenuStory.png"]]];
    [story setCenter:self.view.center];
    [self.view addSubview:story];
    
    // Round the corners
    story.layer.cornerRadius = 15;
    story.layer.masksToBounds = YES;
    [story setAlpha:0.9];
    
    UITextView *storyView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 440, 580)];
    [storyView setTextColor:[UIColor blackColor]];
    [storyView setDataDetectorTypes:UIDataDetectorTypeLink];
    [storyView setEditable:NO];
    [storyView setBackgroundColor:[UIColor clearColor]];
    [storyView setFont:[UIFont fontWithName: @"Optima" size: 16.0f]];
    [storyView setScrollEnabled:NO];
    [storyView setText:[NSString stringWithFormat:@"\"Mermaids\" is an aquarium without the maintenance.  It aims to calm and relax: some elements are interactive, some are not.  Any action may influence the aquarium: a touch, a swipe, a pinch, a tilt... experiment and you may uncover some surprises!\n\nThe creatures that swim through this app come from the imagination of Béatrice Coron.  When Jeff Bumgardner blogged his admiration of Béatrice's papercutting work, she got in touch with him and a unique collaboration was born.  \"Mermaids\" uses new technology to illustrate age-old dreams.\n\n\"Mermaids\" is the first in a series of interactive papercuttings which can be tailored to different stories and commissioned for any public space.\n\nArt and Concept: Béatrice Coron\n  http://www.beatricecoron.com\n\nDevelopment: Jeff Bumgardner\n  http://www.jeffbumgardner.com\n\nSound: Ruth Antrich\n  http://www.ruthantrich.com\n\nSaxophone: Chico Freeman"]];
    
    [storyView setCenter:self.view.center];
    [self.view addSubview:storyView];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    
    // do nothing
    
}


@end
