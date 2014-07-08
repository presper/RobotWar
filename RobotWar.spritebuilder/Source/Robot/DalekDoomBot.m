//
//  AIRobot.m
//  RobotWar
//
//  Created by ronin on 7/1/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "DalekDoomBot.h"
#import "Helpers.h"

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

static int _GUN_ANGLE_OFFSET = 0;     // @NOTE used in order to cushion rotation angles, primarily for firing
static int _COLLISION_OFFSET = 2.0f;     // @NOTE used in order to cushion distances, primarily for moving
static CGFloat _STUN_TIME = 1.0f;
static CGFloat _MIN_FIRING_DISTANCE = 0.1f;
static CGFloat _MAX_FIRING_DISTANCE = 145.0f;
static CGFloat _WILD_SCAN_DISTANCE = 40.0f;
static CGFloat _MAX_WILD_SCAN_TIME = 4.0f;
static CGFloat _FIRE_AGAIN_TOLERANCE = 35.5f;   // tan of roughly 100 distance to enemy and width of tank
static CGFloat _SAFE_TIME = 4.0f;
static CGFloat _STRAFE_DISTANCE = 15.0f;
static CGFloat _TIME_WITHOUT_SCAN_AFTER_FIRING = 1.0f;

int enemyHealth = 20;

@implementation DalekDoomBot {
    
    int actionIndex;
    int wildscanTime;
    
    // @NOTE update on TURN
    BOOL isTurning;
    
    // @NOTE update on SCAN
    CGFloat currentEnemyPositionTimestamp;
    CGPoint currentEnemyPosition;
    CGFloat lastKnownEnemyPostionTimestamp;
    CGPoint lastKnownEnemyPosition;
    CGFloat headingFromEnemyPosition;
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

// --------------------------------------------------------------------------------------------------------
#pragma mark Scanning

- (void)scannedRobot:(Robot *)robot atPosition:(CGPoint)position {
    if (self.currentRobotAction != RobotActionTurnaround) {
        [self cancelActiveAction];
        
        distanceToEnemy = [self calculateDistanceFromPoint:[self position] toPoint:position];
        //NSLog(@"TANGENT ANGLE: %f",radToDeg(tanf([self robotBoundingBox].size.width/100)));
        
        // record enemy position and timestamp
        currentEnemyPosition = lastKnownEnemyPosition = position;
        currentEnemyPositionTimestamp = lastKnownEnemyPostionTimestamp = [self currentTimestamp];
        headingFromEnemyPosition = [self angleBetweenHeadingDirectionAndWorldPosition:position];
        
        switch (self.currentRobotAction) {
            case RobotActionDefault: {
                self.priorRobotAction = self.currentRobotAction;
                [self cancelActiveAction];
                self.currentRobotAction = RobotActionTracking;
                NSLog(@"STATE CHANGE to TRACKING");
            }
                break;
            case RobotActionWildScanning: {
                self.priorRobotAction = self.currentRobotAction;
                [self cancelActiveAction];
                
                if (distanceToEnemy < _MAX_FIRING_DISTANCE && distanceToEnemy >= _MIN_FIRING_DISTANCE) {
                    self.currentRobotAction = RobotActionFiring;
                    NSLog(@"STATE CHANGE to FIRING");
                } else {
                    self.currentRobotAction = RobotActionTracking;
                    NSLog(@"STATE CHANGE to TRACKING");
                }
            }
                break;
            case RobotActionSearching: {
                self.priorRobotAction = self.currentRobotAction;
                [self cancelActiveAction];
                self.currentRobotAction = RobotActionTracking;
                NSLog(@"STATE CHANGE to TRACKING");
            }
                break;
            case RobotActionTracking: {
                if (distanceToEnemy < _MAX_FIRING_DISTANCE && distanceToEnemy >= _MIN_FIRING_DISTANCE) {
                    self.priorRobotAction = self.currentRobotAction;
                    [self cancelActiveAction];
                    self.currentRobotAction = RobotActionFiring;
                    NSLog(@"STATE CHANGE to FIRING");
                }
            }
                break;
            case RobotActionFiring: {
                [self adjustToFireAgainAtPosition:position atDistance:distanceToEnemy];
            }
                break;
            default:
                break;
        }
    }
}

// --------------------------------------------------------------------------------------------------------
#pragma mark Firing

- (void)bulletHitEnemy:(Bullet*)bullet {
    enemyHealth--;
    NSLog(@"HIT. ENEMY is at %i",enemyHealth);
    
    // @ASSUME we will always be close enough to fire, so lastKnownEnemyPosition will always be reasonably close to enemy's true position
    lastKnownEnemyPostionTimestamp = [self currentTimestamp];
    distanceToEnemy = [self calculateDistanceFromPoint:[self position] toPoint:lastKnownEnemyPosition];
    [self adjustToFireAgainAtPosition:lastKnownEnemyPosition atDistance:distanceToEnemy];
}

- (void)shoot {
    NSLog(@"FIRED.");
    timeLastShotAtEnemy = [self currentTimestamp];
    positionLastShotAtEnemy = [self position];
    [super shoot];
}


// --------------------------------------------------------------------------------------------------------
#pragma mark Responses

- (void)gotHit {
    [self cancelActiveAction];
    
    timeLastShotByEnemy = [self currentTimestamp];
    positionLastShotByEnemy = [self position];
    
    if (self.currentRobotAction == RobotActionFiring) {
        self.priorRobotAction = RobotActionFiring;
        self.currentRobotAction = RobotActionStrafing;
        NSLog(@"STATE CHANGE to STRAFING");
        
    } else if (self.currentRobotAction == RobotActionStrafing) {
        self.priorRobotAction = RobotActionStrafing;
        self.currentRobotAction = RobotActionStrafing;
    } else {
        self.priorRobotAction = self.currentRobotAction;
        [self moveToCenterOfArena];
        // rotate a random angle (both gun and tank)
        CGFloat randomAngle = arc4random_uniform(361);
        [self turnRobotRight:randomAngle];
        [self moveAhead:_WILD_SCAN_DISTANCE];
        self.currentRobotAction = RobotActionWildScanning;
        NSLog(@"STATE CHANGE to WILDSCAN");
    }
}

- (void)hitWall:(RobotWallHitDirection)hitDirection hitAngle:(CGFloat)hitAngle {
    NSLog(@"Triggered wall hit at angle: %f",hitAngle);
    
    [self cancelActiveAction];
    
    self.priorRobotAction = self.currentRobotAction;
    self.currentRobotAction = RobotActionTurnaround;
    NSLog(@"STATE CHANGE to TURNAROUND");
    
    switch (hitDirection) {
        case RobotWallHitDirectionFront: {
            [self moveBack:(_COLLISION_OFFSET)];
        }
            break;
        case RobotWallHitDirectionLeft: {
            [self turnRobotRight:20];
            [self moveAhead:(_COLLISION_OFFSET)];
        }
            break;
        case RobotWallHitDirectionRight: {
            [self turnRobotLeft:20];
            [self moveAhead:(_COLLISION_OFFSET)];
        }
            break;
        case RobotWallHitDirectionRear: {
            [self moveAhead:(_COLLISION_OFFSET)];
        }
            break;
        default:
            break;
    }
    
    CGFloat angle = hitAngle-90;
    // always turn to head along the wall
    if (angle >= 0) {
        [self turnRobotLeft:fabsf(angle)];
    } else {
        [self turnRobotRight:fabsf(angle)];
    }
    
    angle = [self angleBetweenGunHeadingDirectionAndWorldPosition:CGPointMake([self arenaDimensions].width/2, [self arenaDimensions].height/2)];
    NSLog(@"GUN ANGLE after HITWALL %f",angle);
    if (angle <= 0) {
        [self turnGunLeft:fabsf(angle)];
    } else {
        [self turnGunRight:fabsf(angle)];
    }
    
    switch (self.priorRobotAction) {
        case RobotActionFiring: {
            self.priorRobotAction = self.currentRobotAction;
            self.currentRobotAction = RobotActionFiring;
            NSLog(@"STATE CHANGE to FIRING");
        }
            break;
            
        default: {
            self.priorRobotAction = self.currentRobotAction;
            self.currentRobotAction = RobotActionSearching;
            NSLog(@"STATE CHANGE to SEARCHING");
        }
            break;
    }
}


#pragma mark Helpers

// @TODO ?
- (CGFloat)boundingBoxRadius {
    return pow((pow((54.0/2.0),2.0) + pow((41.0/2.0),2.0)),0.5);
    //return pow((pow((self.robotBoundingBox.size.height/2),2.0) + pow((self.robotBoundingBox.size.width/2),2.0)),0.5);
}

- (CGFloat)calculateDistanceFromPoint:(CGPoint)position1 toPoint:(CGPoint)position2 {
    
    return pow((pow((position2.y-position1.y),2.0) + pow((position2.x-position1.x),2.0)),0.5);
}

- (void)moveToPoint:(CGPoint)point {
    CGFloat distanceToPoint = [self calculateDistanceFromPoint:[self position] toPoint:point];
    
    CGFloat tankAngle = [self angleBetweenHeadingDirectionAndWorldPosition:point];
    CGFloat gunAngle = [self angleBetweenHeadingDirectionAndWorldPosition:point];
    
    if (tankAngle < 0) {
        [self turnRobotLeft:fabsf(tankAngle)];
    } else {
        [self turnRobotRight:tankAngle];
    }
    if (gunAngle < 0) {
        [self turnGunLeft:fabsf(gunAngle)];
    } else {
        [self turnGunRight:gunAngle];
    }
    [self moveAhead:distanceToPoint];
}

// @TODO
- (void)moveToCenterOfArena {
    CGPoint centerOfArena = CGPointMake([self arenaDimensions].width/2, [self arenaDimensions].height/2);
    [self moveToPoint:centerOfArena];
}

- (void)wildscan {
    if (wildscanTime < _MAX_WILD_SCAN_TIME) {
        [self turnRobotRight:120];
        [self moveAhead:_WILD_SCAN_DISTANCE];
        [self turnRobotRight:120];
        [self moveAhead:(2*_WILD_SCAN_DISTANCE)];
        [self turnRobotLeft:120];
        [self moveAhead:_WILD_SCAN_DISTANCE];
        [self turnRobotLeft:120];
        [self moveAhead:(2*_WILD_SCAN_DISTANCE)];
        
        wildscanTime += 8;
        NSLog(@"ACTION TIME: %i",wildscanTime);
    }
    // @TODO - discuss how long to do the wild search
}

// @TODO
- (void)adjustToFireAgainAtPosition:(CGPoint)position atDistance:(CGFloat)distance {
    NSLog(@"ADJUSTING TO FIRE.");
    /*
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
     */
    
    // @ASSUME position is lastKnownEnemyPosition
    CGFloat angle = [self angleBetweenGunHeadingDirectionAndWorldPosition:position];
    NSLog(@"ADJUST ANGLE from GUN TO ENEMY: %f",angle);
    NSLog(@"ADJUST to ENEMY POSITION: (%f,%f)",position.x,position.y);
    NSLog(@"ADJUST ANGLE from GUN TO ENEMY: %f",distance);
    if (angle >= 0) {
        [self turnGunRight:fabsf(angle)];
    } else {
        [self turnGunLeft:fabsf(angle)];
    }
    if (angle < _FIRE_AGAIN_TOLERANCE) {
        [self shoot];
    } else {
        // wait to scan again
    }
    if (distance < _MAX_FIRING_DISTANCE && distance > _MIN_FIRING_DISTANCE) {
        [self moveAhead:10];
    }
    
}


// --------------------------------------------------------------------------------------------------------
#pragma mark Subroutines

- (void)run {
    NSLog(@"Current Robot Position %f + %f", [self position].x, [self position].y);
    
    actionIndex = 0;
    while (true) {
        if ([self currentTimestamp] > lastKnownEnemyPostionTimestamp + _TIME_WITHOUT_SCAN_AFTER_FIRING) {
            self.priorRobotAction = self.currentRobotAction;
            self.currentRobotAction = RobotActionSearching;
        }
         
        while (self.currentRobotAction == RobotActionWildScanning) {
            // go to wild scanning
            // move to center, drive in a circle around center, spin turret
            wildscanTime = 0;
            [self wildscan];
        }
        
        while (self.currentRobotAction == RobotActionStrafing) {
         
            // strafe and destroy.  repeat until enemy is dead.
        }
        
        while (self.currentRobotAction == RobotActionSearching) {
            
            // keep searching until scanned enemy
            // switch to tracking
            
            [self performNextSearchingAction];
        }
        
        while (self.currentRobotAction == RobotActionTracking) {
            
            // center target
            // if in reasonable position, switch to firing, fire
            // if in tracking and it's been (X) time without scan, switch to pursuing
            
            [self performNextTrackingAction];
        }
        
        while (self.currentRobotAction == RobotActionPursuing) {
            
            // move to last known enemy position
            // if no target in scan area, switch to searching
            
            [self performNextPursuingAction];
        }
        
        while (self.currentRobotAction == RobotActionFiring) {
            
            // fire
            // adjust so you can continue firing
            
            [self performNextFiringAction];
        }
        
        while (self.currentRobotAction == RobotActionDefault) {
            [self performNextDefaultAction];
        }
    }
}

// @NOTE start, then dash to a wall.
- (void)performNextDefaultAction {
    switch (actionIndex%1) {
        case 0: {
            if (arc4random_uniform(2) == 1) {
                [self turnRobotRight:80];
            } else {
                [self turnRobotLeft:80];
            }
            [self moveAhead:[self arenaDimensions].width];
        }
            break;
    }
    actionIndex++;
}

// @NOTE @TODO
- (void) performNextFiringAction {
    // @TODO
    if ((self.currentTimestamp - lastKnownEnemyPostionTimestamp) > 1.5f) {
        self.currentRobotAction = RobotActionSearching;
        NSLog(@"STATE CHANGE to SEARCHING");
    } else {
        [self adjustToFireAgainAtPosition:lastKnownEnemyPosition atDistance:distanceToEnemy];
//        CGFloat angle = [self angleBetweenGunHeadingDirectionAndWorldPosition:lastKnownEnemyPosition];
//        if (angle >= 0) {
//            [self turnGunRight:fabsf(angle)];
//        } else {
//            [self turnGunLeft:fabsf(angle)];
//        }
//        if (angle < _FIRE_AGAIN_TOLERANCE) {
//            [self shoot];
//        } else {
//            
//        }
    }
}

// @TODO - spin around enemy, compensate for change in position by moving the turret
- (void)strafeEnemy {
    CGFloat timeElapsedSinceHitByEnemy = [self currentTimestamp] - timeLastShotByEnemy;
    if (timeElapsedSinceHitByEnemy > _SAFE_TIME) {
        self.priorRobotAction = self.currentRobotAction;
        self.currentRobotAction = RobotActionFiring;
        NSLog(@"STATE CHANGE to FIRING");
        
    } else {
        // @TODO - got to TURN the ROBOT more
        if (fabsf(headingFromEnemyPosition) > 75) {
            CGFloat angle = fabsf(headingFromEnemyPosition)-75;
            //CGFloat gunAngle = radToDeg(atan2f(tanf(fabsf(angle)), 1));
            CGFloat gunAngle = 25.0f;
            if (headingFromEnemyPosition >= 0) {
                [self turnRobotLeft:fabsf(angle)];
                [self moveAhead:_STRAFE_DISTANCE];
                [self turnGunRight:gunAngle];
                //[self moveAhead:_STRAFE_DISTANCE];
                //[self turnGunRight:gunAngle];
                //[self moveAhead:_STRAFE_DISTANCE];
                //[self turnGunRight:gunAngle];
            } else {
                [self turnRobotRight:fabsf(angle)];
                [self moveAhead:_STRAFE_DISTANCE];
                [self turnGunLeft:gunAngle];
                //[self moveAhead:_STRAFE_DISTANCE];
                //[self turnGunLeft:gunAngle];
                //[self moveAhead:_STRAFE_DISTANCE];
                //[self turnGunLeft:gunAngle];
            }
        } else {
            CGFloat angle = 75-fabsf(headingFromEnemyPosition);
            //CGFloat gunAngle = radToDeg(atan2f(tanf(fabsf(angle)), 1));
            CGFloat gunAngle = 25.0f;
            if (headingFromEnemyPosition >= 0) {
                [self turnRobotRight:fabsf(angle)];
                [self moveAhead:_STRAFE_DISTANCE];
                [self turnGunLeft:gunAngle];
                //[self moveAhead:_STRAFE_DISTANCE];
                //[self turnGunLeft:gunAngle];
                //[self moveAhead:_STRAFE_DISTANCE];
                //[self turnGunLeft:gunAngle];
            } else {
                [self turnRobotLeft:fabsf(angle)];
                [self moveAhead:_STRAFE_DISTANCE];
                [self turnGunRight:gunAngle];
                //[self moveAhead:_STRAFE_DISTANCE];
                //[self turnGunRight:gunAngle];
                //[self moveAhead:_STRAFE_DISTANCE];
                //[self turnGunRight:gunAngle];
            }
        }
        [self adjustToFireAgainAtPosition:lastKnownEnemyPosition atDistance:distanceToEnemy];
    }
}

- (void)performNextSearchingAction {
    switch (actionIndex%1) {
        case 0: {
            [self moveAhead:[self arenaDimensions].width];
        }
            break;
        /*
        case 1:
            [self turnRobotLeft:20];
            break;
            
        case 2:
            [self moveAhead:50];
            break;
            
        case 3:
            [self turnRobotRight:20];
            break;
         */
    }
    actionIndex++;
}

- (void)performNextTrackingAction {
    /*
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
     */
    [self moveToPoint:lastKnownEnemyPosition];
    actionIndex++;
}

- (void)performNextPursuingAction {
    actionIndex++;
}


@end
