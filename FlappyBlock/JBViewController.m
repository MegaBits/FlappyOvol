//
//  JBViewController.m
//  FlappyBlock
//
//  Created by Joe Blau on 2/9/14.
//  Copyright (c) 2014 joeblau. All rights reserved.
//

#import "JBViewController.h"
#import "CLLocation+SunriseSunset.h"
#import <AddressBook/ABPerson.h>

@interface JBViewController ()

@end

#define PIPE_SPACE 200
#define PIPE_WIDTH 44
#define DEFAULT_OFFSET 320.0
#define NEPHRITIS [UIColor colorWithRed:39.0/255 green:174.0/255.0 blue:96.0/255.0 alpha:1.0]

@implementation JBViewController {
  UIView *pipeBounds;
  UIDynamicAnimator *blockAnimator;
  
  UICollisionBehavior *blockCollision;
  UICollisionBehavior *groundCollision;
    UICollisionBehavior *ceilingCollision;
  UIDynamicItemBehavior *blockDynamicProperties;
  UIDynamicItemBehavior *pipesDynamicProperties;
  UIGravityBehavior *gravity;
  UIPushBehavior *flapUp;
  UIPushBehavior *movePipes;
  int points2x;
  int lastYOffset;
  UIAlertView *gameOver;
  
  Boolean firstFlap;
}

- (void)viewDidLoad {
  [super viewDidLoad];
    self.currentScore = -1;
    self.currentScoreLabel.text = @"00";

    self.aboutButton.hidden = YES;

    self.block.layer.magnificationFilter = kCAFilterNearest;
    self.sky.layer.magnificationFilter = kCAFilterNearest;
    self.label.font = [UIFont fontWithName: @"Press Start K" size: 17];
    self.currentScoreLabel.font = [UIFont fontWithName: @"Press Start K" size: 17];

    self.medalLabel.font = [UIFont fontWithName: @"Press Start K" size: 14];
    self.scoreLabel.font = [UIFont fontWithName: @"Press Start K" size: 14];
    self.scoreValueLabel.font = [UIFont fontWithName: @"Press Start K" size: 17];
    self.bestLabel.font = [UIFont fontWithName: @"Press Start K" size: 14];
    self.bestValueLabel.font = [UIFont fontWithName: @"Press Start K" size: 17];

    self.aboutButton.titleLabel.font = [UIFont fontWithName: @"Press Start K" size: 12];
    self.doneButton.titleLabel.font = [UIFont fontWithName: @"Press Start K" size: 12];

    [[[CLGeocoder alloc] init] geocodeAddressDictionary: @{(NSString *)kABPersonAddressCountryCodeKey: [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode]} completionHandler:^(NSArray *placemarks, NSError *error) {
        CLLocation *location = [(CLPlacemark *)[placemarks firstObject] location];

        // Limit by diurnality (time)
        NSTimeInterval timeSinceTodaysSunrise = [[NSDate date] timeIntervalSinceDate: [location sunriseDate]];
        NSTimeInterval timeSinceTodaysSunset = [[NSDate date] timeIntervalSinceDate: [location sunsetDate]];


        if (!((timeSinceTodaysSunrise > 0) && (timeSinceTodaysSunset < 0)))
        {
            self.sky.image = [UIImage imageNamed: @"Background_Night"];
        }
    }];

  firstFlap = NO;
  // Create Block Animator
  blockAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
  
  blockDynamicProperties = [[UIDynamicItemBehavior alloc] initWithItems:@[self.ground]];
  blockDynamicProperties.allowsRotation = NO;
  blockDynamicProperties.density = 1000;
  
  // Block flap behavior
  flapUp = [[UIPushBehavior alloc] initWithItems:@[self.block] mode:UIPushBehaviorModeInstantaneous];
  flapUp.pushDirection = CGVectorMake(0, -1.1);
  flapUp.dynamicAnimator.delegate = self;
  flapUp.active = NO;
  
  // Block Pipe Collision
  blockCollision = [[UICollisionBehavior alloc] initWithItems:@[self.block]];
  [blockCollision addBoundaryWithIdentifier:@"LEFT_WALL" fromPoint:CGPointMake(-1*PIPE_WIDTH, 0) toPoint:CGPointMake(-1*PIPE_WIDTH, self.view.bounds.size.height)];
  blockCollision.collisionDelegate = self;
  
  // Block Ground Collision
  groundCollision = [[UICollisionBehavior alloc] initWithItems:@[self.block, self.ground]];
  groundCollision.collisionDelegate = self;
  
  [blockAnimator addBehavior:blockDynamicProperties];

  [blockAnimator addBehavior:flapUp];
  [blockAnimator addBehavior:blockCollision];
  [blockAnimator addBehavior:groundCollision];
  
  // Create Pipes Animator
  points2x = 0;
  lastYOffset = -100;
  
  UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture:)];
  [self.view addGestureRecognizer:singleTapGestureRecognizer];
  [singleTapGestureRecognizer setNumberOfTapsRequired:1];
}

- (void) handleSingleTapGesture:(UITapGestureRecognizer *)gestureRecognizer {
    if (!self.aboutView.hidden)
        return;

  if (!firstFlap) {
    // Block gravity
    gravity = [[UIGravityBehavior alloc] initWithItems:@[self.block]];
    gravity.magnitude = 1.1;
    [blockAnimator addBehavior:gravity];
      self.logo.hidden = YES;
      self.label.hidden = YES;
      self.currentScoreLabel.hidden = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      if (!gameOver.isHidden)[self generatePipesAndMove:DEFAULT_OFFSET];
    });
      self.adBannerView.hidden = NO;

      self.hasStarted = YES;
    firstFlap = YES;
  }

    if (!self.gameOverView.hidden)
    {
        self.medalImageView.image = [UIImage imageNamed: @"Medal_Empty"];
        self.gameOverView.hidden = YES;
        self.block.frame = (CGRect){{55,284},{56,38}};
        self.block.transform = CGAffineTransformIdentity;

        for (UIView *view in [[self view] subviews])
        {
            if ([[view restorationIdentifier] isEqualToString: @"TOP"])
                [view removeFromSuperview];
            else if ([[view restorationIdentifier] isEqualToString: @"BOTTOM"])
                [view removeFromSuperview];
        }

        self.hasStarted = NO;
        self.logo.image = [UIImage imageNamed: @"Logo"];
        self.label.text = @"tap to flap";

        [self viewDidLoad];
        return;
    }

    if (CGRectGetMinY(self.block.frame) < CGRectGetHeight(self.block.frame))
        return;

  [self.block setImage: [UIImage imageNamed: @"Owl_WingsUp"]];
  [flapUp setActive:YES];

    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.block setImage: [UIImage imageNamed: @"Owl_WingsDown"]];
    });
}

- (void)generatePipesAndMove:(float)xOffset {
    if (!self.hasStarted)
        return;

  lastYOffset = lastYOffset +  (arc4random_uniform(3)*40) * myRandom();
  lastYOffset = (lastYOffset < -200)?-200:lastYOffset;
  lastYOffset = (lastYOffset > 0)?0:lastYOffset;

    self.currentScore++;
    self.currentScoreLabel.text = [NSString stringWithFormat: @"%02d", self.currentScore];

  UIImageView *topPipe = [[UIImageView alloc] initWithFrame:CGRectMake(xOffset, lastYOffset, PIPE_WIDTH, 300)];
  [topPipe setRestorationIdentifier:@"TOP"];
    [topPipe setImage: [UIImage imageNamed: @"Top_Pipe"]];
//  [topPipe setBackgroundColor:NEPHRITIS];

  [self.view addSubview:topPipe];
  UIImageView *bottomPipe = [[UIImageView alloc] initWithFrame:CGRectMake(xOffset, lastYOffset+topPipe.bounds.size.height+PIPE_SPACE, PIPE_WIDTH, 300)];
  [bottomPipe setRestorationIdentifier:@"BOTTOM"];
    [bottomPipe setImage: [UIImage imageNamed: @"Bottom_Pipe"]];
//  [bottomPipe setBackgroundColor:NEPHRITIS];
  [self.view addSubview:bottomPipe];

  pipesDynamicProperties= [[UIDynamicItemBehavior alloc] initWithItems:@[topPipe, bottomPipe]];
  pipesDynamicProperties.allowsRotation = NO;
  pipesDynamicProperties.density = 1000;
  
  [blockCollision addItem:topPipe];
  [blockCollision addItem:bottomPipe];

  // Push Pipes across the screen
  movePipes = [[UIPushBehavior alloc] initWithItems:@[topPipe, bottomPipe] mode:UIPushBehaviorModeInstantaneous];
  movePipes.pushDirection = CGVectorMake(-2800, 0);
  movePipes.active = YES;

  [blockAnimator addBehavior:pipesDynamicProperties];
  [blockAnimator addBehavior:movePipes];
}

- (void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p {
  if ([(NSString*)identifier isEqualToString:@"LEFT_WALL"]) {
    points2x++;
    [blockCollision removeItem:item];
    [blockAnimator removeBehavior:pipesDynamicProperties];
    [blockAnimator removeBehavior:movePipes];
    if (points2x%2 == 0) [self generatePipesAndMove:DEFAULT_OFFSET];
  }
}
int myRandom() {
  return (arc4random() % 2 ? 1 : -1);
}

- (void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item1 withItem:(id<UIDynamicItem>)item2 atPoint:(CGPoint)p {
  [blockAnimator removeAllBehaviors];
//  gameOver = [[UIAlertView alloc] initWithTitle:@"Game Over" message:@"You Lose" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
//  [gameOver show];

    [self.view bringSubviewToFront: self.logo];
    [self.view bringSubviewToFront: self.gameOverView];
    [self.view bringSubviewToFront: self.label];
    [self.view bringSubviewToFront: self.aboutButton];
    [self.view bringSubviewToFront: self.aboutView];

    if (MAX(self.currentScore,0) > [[NSUserDefaults standardUserDefaults] integerForKey: @"BEST_SCORE"])
    {
        [[NSUserDefaults standardUserDefaults] setInteger: self.currentScore
                                                   forKey: @"BEST_SCORE"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    self.scoreValueLabel.text = [NSString stringWithFormat: @"%02d", MAX(self.currentScore, 0)];
    self.bestValueLabel.text = [NSString stringWithFormat: @"%02d", [[NSUserDefaults standardUserDefaults] integerForKey: @"BEST_SCORE"]];

    if (self.currentScore >= 30)
        self.medalImageView.image = [UIImage imageNamed: @"Medal_Gold"];
    else if (self.currentScore >= 20)
        self.medalImageView.image = [UIImage imageNamed: @"Medal_Silver"];
    else if (self.currentScore >= 10)
        self.medalImageView.image = [UIImage imageNamed: @"Medal_Bronze"];

    self.label.text = @"tap to play again";
    self.label.hidden = NO;

    self.logo.image = [UIImage imageNamed: @"GameOver"];
    self.logo.hidden = NO;
    self.currentScoreLabel.hidden = YES;
    self.gameOverView.hidden = NO;
    self.aboutButton.hidden = NO;
    self.adBannerView.hidden = YES;
}

- (BOOL)shouldAutorotate {
  return NO;
}

- (void)aboutButtonWasPressed:(id)sender
{
    self.aboutView.hidden = NO;
}

- (void)doneButtonWasPressed:(id)sender
{
    self.aboutView.hidden = YES;
}

@end
