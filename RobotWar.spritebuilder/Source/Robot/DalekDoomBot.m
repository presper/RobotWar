//
//  AIRobot.m
//  RobotWar
//
//  Created by ronin on 7/1/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "DalekDoomBot.h"

/*
 Goal is to beat the SimpleRobot
 Then goal is to build AI such that it can defeat others
 
 Thoughts re: AI
 Have it shoot first, out of the gate
 Then, do a circle around the center of the Arena
 Edge of circle to corner of Arena is 150 distance (scan distance)
 When enemy detected, move first along diagonal created by centers of self and enemy
 Then keep cornering enemy,
 firing based on new position
 
 */

static int _TURN_AROUND = 360;
static int _GUN_ANGLE_OFFSET = 0;     // @NOTE used in order to cushion rotation angles, primarily for firing
static int _COLLISION_OFFSET = 0;     // @NOTE used in order to cushion distances, primarily for moving
static CGFloat _STUN_TIME = 1.0f;
static CGFloat _MIN_FIRING_DISTANCE = 0.0f;

int enemyHealth = 20;

@implementation DalekDoomBot {
    
    int actionIndex;
    
    // @NOTE update on TURN
    BOOL isTurning;
    
    // @NOTE update on SCAN
    CGFloat lastKnownEnemyPostionTimestamp;
    CGPoint lastKnownEnemyPosition;
    CGFloat distanceToEnemy;
    
    // @NOTE update on FIRE
    CGFloat timeLastShotAtEnemy;
    CGPoint positionLastShotAtEnemy;
    
    // @NOTE update on HIT ENEMY
    //int enemyHealth;
    
    // @NOTE update on GOT HIT
    CGFloat timeLastShotByEnemy;
    CGPoint positionLastShotByEnemy;
}


- (void)scannedRobot:(Robot *)robot atPosition:(CGPoint)position {
    if (self.currentRobotAction != RobotActionTurnaround) {
        [self cancelActiveAction];
        
        // goal is to turn turret toward detected enemy
        
        CGFloat angleToEnemy = [self angleBetweenGunHeadingDirectionAndWorldPosition:position];
        angleToEnemy += _GUN_ANGLE_OFFSET;
        
        if (angleToEnemy < 0) {
            angleToEnemy += _TURN_AROUND;
            [self turnGunLeft:angleToEnemy];
        } else {
            [self turnGunRight:angleToEnemy];
        }
        
        CGFloat _currentTime = [self currentTimestamp];
        if ( _currentTime > _STUN_TIME + timeLastShotAtEnemy) {
            NSLog(@"TIME: %f",_currentTime);
            [self shoot];
        }
        
        //[self turnRobotLeft:20];
        //[self moveBack:80];
        [self turnRobotLeft:15];
        [self moveAhead:40];
        
    }
}

- (void)bulletHitEnemy:(Bullet*)bullet {
    NSLog(@"HERE");
    [self cancelActiveAction];
    NSLog(@"CANCELLED");
    enemyHealth--;
    CGFloat _currentTime = [self currentTimestamp];
    if ( _currentTime > _STUN_TIME + timeLastShotAtEnemy) {
        NSLog(@"BULLET TIME: %f",_currentTime);
        [self shoot];
    }
    if (enemyHealth < 18) {
        NSLog(@"Hit enemy twice");
    }
    [self moveBack:40];
}

- (void)shoot {
    timeLastShotAtEnemy = [self currentTimestamp];
    [super shoot];
}

/*
 - (void)gotHit {
 [self shoot];
 [self turnRobotLeft:45];
 [self moveAhead:100];
 }
 */

- (void)hitWall:(RobotWallHitDirection)hitDirection hitAngle:(CGFloat)hitAngle {
    NSLog(@"Triggered wall hit");
}

#pragma mark Subroutines

- (void)run {
    actionIndex = 0;
    while (true) {
        /*
        RobotActionDefault,
        RobotActionSearching,
        RobotActionPursuing,
        RobotActionFiring,
        RobotActionTracking,
        RobotActionTurnaround
        while (self.currentRobotAction == RobotActionFiring) {
            [self performNextFiringAction];
        }
        */
        
        
        while (self.currentRobotAction == RobotActionSearching) {
            [self performNextSearchingAction];
        }
        
        while (self.currentRobotAction == RobotActionTracking) {
            [self performNextTrackingAction];
        }
        
        while (self.currentRobotAction == RobotActionPursuing) {
            [self performNextPursuingAction];
        }
        
        while (self.currentRobotAction == RobotActionFiring) {
            [self performNextFiringAction];
        }
        
        while (self.currentRobotAction == RobotActionDefault) {
            [self performNextDefaultAction];
        }
    }
}

- (void)performNextDefaultAction {
    switch (actionIndex%1) {
        case 0:
            [self moveAhead:100];
            break;
    }
    actionIndex++;
}

- (void) performNextFiringAction {
    if ((self.currentTimestamp - lastKnownEnemyPostionTimestamp) > 1.f) {
        self.currentRobotAction = RobotActionSearching;
        NSLog(@"STATE CHANGE to SEARCHING");
    } else {
        CGFloat angle = [self angleBetweenGunHeadingDirectionAndWorldPosition:lastKnownEnemyPosition];
        if (angle >= 0) {
            [self turnGunRight:abs(angle)];
        } else {
            [self turnGunLeft:abs(angle)];
        }
        [self shoot];
    }
}

- (void)performNextSearchingAction {
    switch (actionIndex%4) {
        case 0:
            [self moveAhead:50];
            break;
            
        case 1:
            [self turnRobotLeft:20];
            break;
            
        case 2:
            [self moveAhead:50];
            break;
            
        case 3:
            [self turnRobotRight:20];
            break;
    }
    actionIndex++;
}

- (void)performNextTrackingAction {
    switch (actionIndex%4) {
        case 0:
            [self moveAhead:50];
            break;
            
        case 1:
            [self turnRobotLeft:20];
            break;
            
        case 2:
            [self moveAhead:50];
            break;
            
        case 3:
            [self turnRobotRight:20];
            break;
    }
    actionIndex++;
}

- (void)performNextPursuingAction {
    switch (actionIndex%4) {
        case 0:
            [self moveAhead:50];
            break;
            
        case 1:
            [self turnRobotLeft:20];
            break;
            
        case 2:
            [self moveAhead:50];
            break;
            
        case 3:
            [self turnRobotRight:20];
            break;
    }
    actionIndex++;
}


@end
