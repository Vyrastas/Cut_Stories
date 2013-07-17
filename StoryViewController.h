//
//  SplashViewController.m
//  Papercut
//
//  Created by Jeff Bumgardner on 10/27/12.
//  Copyright (c) 2012 Jeff Bumgardner. All rights reserved.
//
//  Initial view controller when app is launched.
//

#import "SplashViewController.h"
#import "ObjManager.h"
#import "Messenger.h"
#import "UIViewController+MJPopupViewController.h"
#import "StoryViewController.h"

@interface SplashViewController ()

@end

@implementation SplashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Create singletons
        _world = [[ObjManager alloc] initWithBlank];
        _messenger = [[Messenger alloc] init];
        startClick = NO;
        storyClick = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //NSString *fontName = [NSString stringWithFormat:@"Travesty"];
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"Menu_Background.png"]]];
    
    // Load and display each menu element
    menuStory = [[UIImageView alloc] initWithImage:
                 [UIImage imageNamed:[NSString stringWithFormat:@"Menu1.png"]]];
    [menuStory setCenter:CGPointMake(self.view.center.x, 514)];
    [self.view addSubview:menuStory];
    
    menuStart = [[UIImageView alloc] initWithImage:
                 [UIImage imageNamed:[NSString stringWithFormat:@"Menu2.png"]]];
    [menuStart setCenter:CGPointMake(self.view.center.x, 552)];
    [self.view addSubview:menuStart];
    
    // Load and display the titles
    title01 = [[UIImageView alloc] initWithImage:
             [UIImage imageNamed:[NSString stringWithFormat:@"Title01.png"]]];
    [title01 setCenter:CGPointMake(self.view.center.x, 293)];
    [self.view addSubview:title01];
    
    title02 = [[UIImageView alloc] initWithImage:
             [UIImage imageNamed:[NSString stringWithFormat:@"Title02.png"]]];
    [title02 setCenter:CGPointMake(self.view.center.x, 352)];
    [self.view addSubview:title02];
    
    title03 = [[UIImageView alloc] initWithImage:
             [UIImage imageNamed:[NSString stringWithFormat:@"Title03.png"]]];
    [title03 setCenter:CGPointMake(self.view.center.x, 409)];
    [self.view addSubview:title03];
    
    
    // Load and display each menu text
    labelStory = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 122, 30)];
    [labelStory setTextColor:[UIColor whiteColor]];
    [labelStory setBackgroundColor:[UIColor clearColor]];
    [labelStory setFont:[UIFont fontWithName: @"Travesty Bold" size: 24.0f]];
    [labelStory setText:[NSString stringWithFormat:@"story"]];
    [labelStory setCenter:CGPointMake(self.view.center.x, 512)];
    [self.view addSubview:labelStory];
    
    labelStart = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 122, 30)];
    [labelStart setTextColor:[UIColor whiteColor]];
    [labelStart setBackgroundColor:[UIColor clearColor]];
    [labelStart setFont:[UIFont fontWithName: @"Travesty Bold" size: 24.0f]];
    [labelStart setText:[NSString stringWithFormat:@"start"]];
    [labelStart setTextAlignment:NSTextAlignmentRight];
    [labelStart setCenter:CGPointMake(self.view.center.x, 554)];
    [self.view addSubview:labelStart];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    // Find the point touched
    CGPoint currentPos = [[touches anyObject] locationInView:self.view];
    
    // STORY
    if ((CGRectContainsPoint(labelStory.frame, currentPos)) && (!storyClick)) {
        
#ifdef TEST_FLIGHT_ON
        //[TestFlight passCheckpoint:@"Splash_Story"];
#endif
        
        // prevent the user from double-tapping the button
        storyClick = YES;
        
        // present the Story view controller
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
            menuStory.alpha = 0.5;
            
        } completion:^(BOOL finished) {
            
            [_world playSplashSound:1];
            
            StoryViewController *popupVC = [[StoryViewController alloc] initWithNibName:@"StoryViewController" bundle:nil];
            [self presentPopupViewController:popupVC animationType:MJPopupViewAnimationFade];
            
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                
                menuStory.alpha = 1.0;
                storyClick = NO;
                
            } completion:^(BOOL finished) {
                
            }];
        }];
        
    }
    
    // START
    if ((CGRectContainsPoint(labelStart.frame, currentPos)) && (!startClick)) {
        
#ifdef TEST_FLIGHT_ON
        //[TestFlight passCheckpoint:@"Splash_Start"];
#endif
        
        // prevent the user from double-tapping the button
        startClick = YES;
        
        [_world playSplashSound:2];
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
            menuStart.alpha = 0.5;
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                
                menuStart.alpha = 1.0;
                
            } completion:^(BOOL finished) {
                
                [UIView animateWithDuration:1.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    
                    // Pull the title and menu fish away from the screen
                    menuStory.center = CGPointMake(-100, 514);
                    menuStart.center = CGPointMake(868, 552);
                    labelStory.center = CGPointMake(-100, 512);
                    labelStart.center = CGPointMake(868, 554);
                    title01.center = CGPointMake(1013, 293);
                    title02.center = CGPointMake(-200, 352);
                    title03.center = CGPointMake(928, 409);
                    
                    // Fade everything
                    menuStory.alpha = 0.0;
                    menuStart.alpha = 0.0;
                    labelStart.alpha = 0.0;
                    labelStory.alpha = 0.0;
                    title01.alpha = 0.0;
                    title02.alpha = 0.0;
                    title03.alpha = 0.0;
                    
                } completion:^(BOOL finished) {
                    
                    // Load the Papercut
                    viewPapercutController = [[PapercutPadViewController alloc]
                                              initPapercut:paperMermaidsTable
                                              anim:paperMermaidsAnimations
                                              touch:paperMermaidsTouchspots
                                              group:paperMermaidsGroups
                                              random:paperMermaidsRandom
                                              sound:paperMermaidsSounds
                                              timer:paperMemmaidsTimers];
                    
                    // Fade in the Papercut to make the transition smoother
                    viewPapercutController.view.alpha = 0;
                    [self.view addSubview:viewPapercutController.view];
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.3];
                    viewPapercutController.view.alpha = 1.0;
                    [UIView commitAnimations];
                    
                    // Now reset all the Splash menu objects behind the scenes
                    [UIView animateWithDuration:0.1 delay:0.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        
                        // Put all the menu objects back
                        menuStory.center = CGPointMake(self.view.center.x, 514);
                        menuStart.center = CGPointMake(self.view.center.x, 552);
                        labelStory.center = CGPointMake(self.view.center.x, 512);
                        labelStart.center = CGPointMake(self.view.center.x, 554);
                        title01.center = CGPointMake(self.view.center.x, 293);
                        title02.center = CGPointMake(self.view.center.x, 352);
                        title03.center = CGPointMake(self.view.center.x, 409);
                        
                        // Fade in everything
                        menuStory.alpha = 1.0;
                        menuStart.alpha = 1.0;
                        labelStory.alpha = 1.0;
                        labelStart.alpha = 1.0;
                        title01.alpha = 1.0;
                        title02.alpha = 1.0;
                        title03.alpha = 1.0;
                        
                        startClick = NO;
                        
                    } completion:^(BOOL finished) {
                        
                    }];
                    
                }];
                
            }];
            
        }];
        
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
