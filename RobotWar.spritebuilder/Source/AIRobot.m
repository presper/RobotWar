//
//  AIRobot.m
//  RobotWar
//
//  Created by ronin on 7/1/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "AIRobot.h"

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

static int _DEGREES_IN_CIRCLE = 360;
static int _EXTRA_GUN_OFFSET = 0;
static CGFloat _STUN_TIME = 0.5f;

typedef NS_ENUM(NSInteger, RobotSectorPosition) {
    RobotSectorNone,
    RobotSectorOne,
    RobotSectorTwo,
    RobotSectorThree,
    RobotSectorFour,
    RobotSectorFive,
    RobotSectorSix,
    RobotSectorSeven,
    RobotSectorEight
};

typedef NS_ENUM(NSInteger, RobotState) {
    RobotStateDefault,
    RobotStateTurnaround,
    RobotStateFiring,
    RobotStateSearching,
    RobotStateSearchingLeft,
    RobotStateSearchingRight
};

typedef NS_ENUM(NSInteger, RobotAction) {
    RobotActionDefault,
    RobotActionTurnaround
};

@implementation AIRobot {
    RobotAction _currentRobotAction;
    CGFloat _lastShotTime;
    
    CGPoint _lastKnownEnemyPosition;
    CGFloat _lastKnownEnemyPositionTimestamp;
    
    RobotState _currentRobotState;
    
    CGSize _sectorSize;
}


- (void)run {
    
    while (YES) {
        
    }
}

- (void)evadeByState:(RobotState)state {
    
    
}


- (void)scannedRobot:(Robot *)robot atPosition:(CGPoint)position {
    if (_currentRobotAction != RobotActionTurnaround) {
        [self cancelActiveAction];
        
        // goal is to turn turret toward detected enemy
        
        CGFloat angleToEnemy = [self angleBetweenGunHeadingDirectionAndWorldPosition:position];
        angleToEnemy += _EXTRA_GUN_OFFSET;
        
        if (angleToEnemy < 0) {
            [self turnGunLeft:abs(angleToEnemy)];
        } else {
            [self turnGunRight:abs(angleToEnemy)];
        }
        
        CGFloat _currentTime = [self currentTimestamp];
        if ( _currentTime > _STUN_TIME + _lastShotTime) {
            NSLog(@"TIME: %f",_currentTime);
            [self shoot];
        }
        
        [self turnRobotLeft:15];
        [self turnGunRight:15];
        [self moveAhead:40];
        
    }
}

- (void)bulletHitEnemy:(Bullet*)bullet {
    /*
     ideas
     given the cone-scanning method, we'd need to keep shooting
     IF MISSED, then immediate start moving
     */
    
    NSLog(@"HERE");
    [self cancelActiveAction];
    NSLog(@"CANCELLED");
    CGFloat _currentTime = [self currentTimestamp];
    if ( _currentTime > _STUN_TIME + _lastShotTime) {
        NSLog(@"BULLET TIME: %f",_currentTime);
        [self shoot];
    }
    [self turnRobotRight:15];
    [self turnGunLeft:15];
    [self moveBack:40];
}

- (void)shoot {
    _lastShotTime = [self currentTimestamp];
    [super shoot];
}

- (void)hitWall:(RobotWallHitDirection)hitDirection hitAngle:(CGFloat)angle {
    if (_currentRobotState != RobotStateTurnaround) {
        [self cancelActiveAction];
        
        RobotState previousState = _currentRobotState;
        _currentRobotState = RobotStateTurnaround;
        
        // always turn to head straight away from the wall
        if (angle >= 0) {
            [self turnRobotLeft:abs(angle)];
        } else {
            [self turnRobotRight:abs(angle)];
            
        }
        
        [self moveAhead:20];
        
        _currentRobotState = previousState;
    }
}

/*
 - (void)gotHit {
 [self shoot];
 [self turnRobotLeft:45];
 [self moveAhead:100];
 }
 */

/*
 - (CGSize)arenaDimensions;
 */


@end