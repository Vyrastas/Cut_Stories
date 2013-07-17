//
//  MenuViewController.m
//  Papercut
//
//  Created by Jeff Bumgardner on 4/3/13.
//  Copyright (c) 2013 Jeff Bumgardner. All rights reserved.
//
//  The small menu that appears in the bottom left of the main view controller.
//

#import "MenuViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "StoryViewController.h"
#import "ObjManager.h"
#import "PapercutPadViewController.h"
#import "Paper.h"
#import "Behavior.h"
#import "Vector2D.h"

@interface MenuViewController ()

@end

@implementation MenuViewController

- (id)initWithVC:(PapercutPadViewController *)pVC nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    self = [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    _world = [ObjManager theWorld];
    _parentVC = pVC;
    
#ifdef TEST_FLIGHT_ON
    //[TestFlight passCheckpoint:@"Info"];
#endif
    
    return self;
}

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
    
    // Set the background
    menu = [[UIImageView alloc] initWithImage:
                          [UIImage imageNamed:[NSString stringWithFormat:@"Menu.png"]]];
    [menu setCenter:self.view.center];
    [self.view addSubview:menu];
    
    // Round the corners
    menu.layer.cornerRadius = 15;
    menu.layer.masksToBounds = YES;
    [menu setAlpha:0.9];
    
    // Load and display each menu element
    menu1 = [[UIImageView alloc] initWithImage:
                               [UIImage imageNamed:[NSString stringWithFormat:@"Menu1.png"]]];
    [menu1 setCenter:CGPointMake(self.view.center.x, 39)];
    [self.view addSubview:menu1];
    
    menu2 = [[UIImageView alloc] initWithImage:
                               [UIImage imageNamed:[NSString stringWithFormat:@"Menu2.png"]]];
    [menu2 setCenter:CGPointMake(self.view.center.x, 76)];
    [self.view addSubview:menu2];
    
    menu3 = [[UIImageView alloc] initWithImage:
                               [UIImage imageNamed:[NSString stringWithFormat:@"Menu1.png"]]];
    [menu3 setCenter:CGPointMake(self.view.center.x, 119)];
    [self.view addSubview:menu3];
    
    menu4 = [[UIImageView alloc] initWithImage:
                               [UIImage imageNamed:[NSString stringWithFormat:@"Menu2.png"]]];
    [menu4 setCenter:CGPointMake(self.view.center.x, 156)];
    [self.view addSubview:menu4];
    
    menu5 = [[UIImageView alloc] initWithImage:
                               [UIImage imageNamed:[NSString stringWithFormat:@"Menu1.png"]]];
    [menu5 setCenter:CGPointMake(self.view.center.x, 199)];
    [self.view addSubview:menu5];
    
    menu6 = [[UIImageView alloc] initWithImage:
                               [UIImage imageNamed:[NSString stringWithFormat:@"Menu3.png"]]];
    [menu6 setCenter:CGPointMake(self.view.center.x, 236)];
    [self.view addSubview:menu6];
    
    // Load and display each element text
    label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 122, 30)];
    [label1 setTextColor:[UIColor whiteColor]];
    [label1 setBackgroundColor:[UIColor clearColor]];
    [label1 setFont:[UIFont fontWithName: @"Travesty Bold" size: 24.0f]];
    [label1 setText:[NSString stringWithFormat:@"story"]];
    [label1 setCenter:CGPointMake(self.view.center.x, 37)];
    [self.view addSubview:label1];
    
    label2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 122, 30)];
    [label2 setTextColor:[UIColor whiteColor]];
    [label2 setBackgroundColor:[UIColor clearColor]];
    [label2 setFont:[UIFont fontWithName: @"Travesty Bold" size: 24.0f]];
    [label2 setText:[NSString stringWithFormat:@"clean"]];
    [label2 setTextAlignment:NSTextAlignmentRight];
    [label2 setCenter:CGPointMake(self.view.center.x, 78)];
    [self.view addSubview:label2];
    
    label3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 122, 30)];
    [label3 setTextColor:[UIColor whiteColor]];
    [label3 setBackgroundColor:[UIColor clearColor]];
    [label3 setFont:[UIFont fontWithName: @"Travesty Bold" size: 24.0f]];
    if (_world.optInteract) {
        [label3 setText:[NSString stringWithFormat:@"interact"]];
    }
    else {
        [label3 setText:[NSString stringWithFormat:@"watch"]];
    }
    [label3 setCenter:CGPointMake(self.view.center.x, 118)];
    [self.view addSubview:label3];
    
    label4 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 122, 30)];
    [label4 setTextColor:[UIColor whiteColor]];
    [label4 setBackgroundColor:[UIColor clearColor]];
    [label4 setFont:[UIFont fontWithName: @"Travesty Bold" size: 24.0f]];
    if (_world.optSound) {
        [label4 setText:[NSString stringWithFormat:@"sound"]];
    }
    else {
        [label4 setText:[NSString stringWithFormat:@"mute"]];
    }
    [label4 setTextAlignment:NSTextAlignmentRight];
    [label4 setCenter:CGPointMake(self.view.center.x, 158)];
    [self.view addSubview:label4];
    
    label5 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 122, 30)];
    [label5 setTextColor:[UIColor whiteColor]];
    [label5 setBackgroundColor:[UIColor clearColor]];
    [label5 setFont:[UIFont fontWithName: @"Travesty Bold" size: 24.0f]];
    [label5 setText:[NSString stringWithFormat:@"reset"]];
    [label5 setCenter:CGPointMake(self.view.center.x, 199)];
    [self.view addSubview:label5];
    
    label6 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 122, 30)];
    [label6 setTextColor:[UIColor whiteColor]];
    [label6 setBackgroundColor:[UIColor clearColor]];
    [label6 setFont:[UIFont fontWithName: @"Travesty Bold" size: 24.0f]];
    [label6 setText:[NSString stringWithFormat:@"exit"]];
    [label6 setTextAlignment:NSTextAlignmentRight];
    [label6 setCenter:CGPointMake(self.view.center.x, 238)];
    [self.view addSubview:label6];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    // Find if an object is touched
    CGPoint currentPos = [[touches anyObject] locationInView:self.view];
    
    // STORY
    if (CGRectContainsPoint(label1.frame, currentPos)) {
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            menu1.alpha = 0.5;
        } completion:^(BOOL finished) {
            
            [_world playSound:16];
            
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                menu1.alpha = 1.0;
            } completion:^(BOOL finished) {
        
                // Fade the shadow separately since it's not animatable in blocks
                CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
                anim.fromValue = [NSNumber numberWithFloat:0.5];
                anim.toValue = [NSNumber numberWithFloat:0.0];
                anim.duration = 0.5;
                anim.removedOnCompletion = YES;
                [self.view.layer addAnimation:anim forKey:@"shadowOpacity"];
                self.view.layer.shadowOpacity = 0.0;
                
                [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    
                    // Fade out everything
                    menu1.alpha = 0.0;
                    menu2.alpha = 0.0;
                    menu3.alpha = 0.0;
                    menu4.alpha = 0.0;
                    menu5.alpha = 0.0;
                    menu6.alpha = 0.0;
                    
                    label1.alpha = 0.0;
                    label2.alpha = 0.0;
                    label3.alpha = 0.0;
                    label4.alpha = 0.0;
                    label5.alpha = 0.0;
                    label6.alpha = 0.0;
                    
                    menu.alpha = 0.0;
                    
                    self.view.layer.shadowOpacity = 0.0;
                    
                } completion:^(BOOL finished) {
                    
                    // reset the view properties for the new story size
                    
                    [self.view.layer setBounds:CGRectMake(60, 344, 480, 620)];
                    [self.view.layer setFrame:CGRectMake(60, 344, 480, 620)];
                    self.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.bounds].CGPath;
                    self.view.layer.masksToBounds = NO;
                    
                    // create the story background
                    menuStory = [[UIImageView alloc] initWithImage:
                                 [UIImage imageNamed:[NSString stringWithFormat:@"MenuStory.png"]]];
                    [menuStory setCenter:self.view.center];
                    [menuStory setAlpha:0.0];
                    [self.view addSubview:menuStory];
                    
                    menuStory.layer.cornerRadius = 15;
                    menuStory.layer.masksToBounds = YES;
                    
                    // create the story text
                    UITextView *storyView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 440, 580)];
                    [storyView setTextColor:[UIColor blackColor]];
                    [storyView setDataDetectorTypes:UIDataDetectorTypeLink];
                    [storyView setEditable:NO];
                    [storyView setBackgroundColor:[UIColor clearColor]];
                    [storyView setFont:[UIFont fontWithName: @"Optima" size: 16.0f]];
                    [storyView setScrollEnabled:NO];
                    [storyView setText:[NSString stringWithFormat:@"\"Mermaids\" is an aquarium without the maintenance.  It aims to calm and relax: some elements are interactive, some are not.  Any action may influence the aquarium: a touch, a swipe, a pinch, a tilt... experiment and you may uncover some surprises!\n\nThe creatures that swim through this app come from the imagination of Béatrice Coron.  When Jeff Bumgardner blogged his admiration of Béatrice's papercutting work, she got in touch with him and a unique collaboration was born.  \"Mermaids\" uses new technology to illustrate age-old dreams.\n\n\"Mermaids\" is the first in a series of interactive papercuttings which can be tailored to different stories and commissioned for any public space.\n\nArt and Concept: Béatrice Coron\n  http://www.beatricecoron.com\n\nDevelopment: Jeff Bumgardner\n  http://www.jeffbumgardner.com\n\nSound: Ruth Antrich\n  http://www.ruthantrich.com\n\nSaxophone: Chico Freeman"]];
                    
                    [storyView setCenter:self.view.center];
                    [storyView setAlpha:0.0];
                    [self.view addSubview:storyView];
                    
                    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
                    anim.fromValue = [NSNumber numberWithFloat:0.0];
                    anim.toValue = [NSNumber numberWithFloat:0.5];
                    anim.duration = 0.5;
                    anim.removedOnCompletion = YES;
                    [self.view.layer addAnimation:anim forKey:@"shadowOpacity"];
                    self.view.layer.shadowOpacity = 0.5;
                    
                    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        
                        // Fade it all in
                        menuStory.alpha = 0.9;
                        storyView.alpha = 1.0;
                        
                    } completion:^(BOOL finished) {
                        
                    }];
                    
                }];
                
            }];
            
        }];
        
    }
    
    // CLEAN
    if (CGRectContainsPoint(label2.frame, currentPos)) {
        
#ifdef TEST_FLIGHT_ON
        //[TestFlight passCheckpoint:@"Info_Clean"];
#endif
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            menu2.alpha = 0.5;
        } completion:^(BOOL finished) {
            
            // set remove for each piece
            Paper *cPiece;
            int objRemoved = 0;
            for (NSNumber *key in _world.objects) {
                
                cPiece = [_world.objects objectForKey:key];
                
                if (cPiece.removeOnClean) {
                    
                    cPiece.remove = YES;                    // kill each piece
                    cPiece.manageRemove = YES;              // set this so vectors die without transforming
                    objRemoved++;
                    
                }
                
            }
            
            // handle Murene if seeking while fish cleared
            if ([_world isStateOn:osMurene]) {
                cPiece = [_world getObject:44];
                [cPiece.behavior turnOff:btSeek];
                cPiece.behavior.vel.x *= -0.5;
                cPiece.behavior.vel.y = 0.0;
            }
            
            // only play a sound if something is removed
            if (objRemoved > 0) { [_world playSound:10]; }
            
            // empty clean queue
            [_world.queue_clean removeAllObjects];
            
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                menu2.alpha = 1.0;
            } completion:^(BOOL finished) {
                
            }];
        }];
        
    }
    
    // INTERACT
    if (CGRectContainsPoint(label3.frame, currentPos)) {
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            menu3.alpha = 0.5;
        } completion:^(BOOL finished) {
            
            [_world playSound:16];
            
            if (_world.optInteract) {
                _world.optInteract = NO;
                [label3 setText:[NSString stringWithFormat:@"watch"]];
            }
            else {
                _world.optInteract = YES;
                [label3 setText:[NSString stringWithFormat:@"interact"]];
            }
            
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                menu3.alpha = 1.0;
            } completion:^(BOOL finished) {
                
            }];
        }];
        
        //NSLog(@"Option Changed: Interact to %d", _world.optInteract);
        
    }
    
    // SOUND
    if (CGRectContainsPoint(label4.frame, currentPos)) {
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            menu4.alpha = 0.5;
        } completion:^(BOOL finished) {
            
            [_world playSound:16];
            
            if (_world.optSound) {
                _world.optSound = NO;
                [label4 setText:[NSString stringWithFormat:@"mute"]];
                [_world.bg_audio01 stop];
                [_world.bg_audio02 stop];
            }
            else {
                _world.optSound = YES;
                [label4 setText:[NSString stringWithFormat:@"sound"]];
                [_world.bg_audio01 play];
                [_world.bg_audio02 play];
                [_world playSound:16];
            }
            
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                menu4.alpha = 1.0;
            } completion:^(BOOL finished) {
                
            }];
        }];
        
        //NSLog(@"Option Changed: Sound to %d", _world.optSound);
        
    }
    
    // RESET
    if (CGRectContainsPoint(label5.frame, currentPos)) {
        
#ifdef TEST_FLIGHT_ON
        //[TestFlight passCheckpoint:@"Info_Reset"];
#endif
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            menu5.alpha = 0.5;
        } completion:^(BOOL finished) {
            
            [_world playSound:8];
            
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                menu5.alpha = 1.0;
            } completion:^(BOOL finished) {
                
                // reset the scene by unloading and reloading the Papercut VC
                [_parentVC unloadPapercut];
                [_parentVC loadPapercut];
                _world.optInteract = YES;
                _world.optSound = YES;
                [_parentVC dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
                
            }];
        }];
        
    }
    
    // EXIT
    if (CGRectContainsPoint(label6.frame, currentPos)) {
        
#ifdef TEST_FLIGHT_ON
        //[TestFlight passCheckpoint:@"Info_Exit"];
#endif
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            menu6.alpha = 0.5;
        } completion:^(BOOL finished) {
            
            [_world playSound:16];
            
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                menu6.alpha = 1.0;
            } completion:^(BOOL finished) {
                
                // stop background audio if playing
                if (_world.optSound) {
                    [_world.bg_audio01 stop];
                    [_world.bg_audio02 stop];
                }
                
                // Fade out the view controller to make the transition smoother
                [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                    _parentVC.view.alpha = 0.0;
                } completion:^(BOOL finished) {
                    // invalidate the timer and remove the view controller
                    [_parentVC.displayLoop invalidate];
                    [_world resetObjManager];
                    [_parentVC.view removeFromSuperview];
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

- (void)viewWillDisappear:(BOOL)animated {    
    // Delay this so the pinch objects don't reappear above the
    //   view while it animates out
    [self performSelector:@selector(stupidZPosition) withObject:nil afterDelay:0.3];
    
}

- (void)stupidZPosition {
    // Move pinch objects back to the fore so they can be pinched
    [_world changeZPosition:_world.objects_pinch toPos:1];
}

@end
