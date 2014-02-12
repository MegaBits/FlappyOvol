//
//  JBViewController.h
//  FlappyBlock
//
//  Created by Joe Blau on 2/9/14.
//  Copyright (c) 2014 joeblau. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

@interface JBViewController : UIViewController <UICollisionBehaviorDelegate, UIDynamicAnimatorDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *block;
@property (strong, nonatomic) IBOutlet UIView *ground;
@property (strong, nonatomic) IBOutlet UIImageView *sky;
@property IBOutlet UIImageView *logo;
@property IBOutlet UILabel *label;
@property IBOutlet UILabel *currentScoreLabel;

@property IBOutlet UIView *gameOverView;
@property IBOutlet UILabel *medalLabel;
@property IBOutlet UIImageView *medalImageView;
@property IBOutlet UILabel *scoreLabel;
@property IBOutlet UILabel *scoreValueLabel;
@property IBOutlet UILabel *bestLabel;
@property IBOutlet UILabel *bestValueLabel;

@property NSInteger currentScore;
@property BOOL hasStarted;

@property IBOutlet UIButton *aboutButton;
- (IBAction)aboutButtonWasPressed:(id)sender;

@property IBOutlet UIView *aboutView;
@property IBOutlet UIButton *doneButton;
- (IBAction)doneButtonWasPressed:(id)sender;

@property IBOutlet ADBannerView *adBannerView;

@end
