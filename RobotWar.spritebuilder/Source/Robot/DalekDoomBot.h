//
//  DalekDoomBot.h
//  RobotWar
//
//  Created by ronin on 7/7/14.
//  Copyright (c) 2014 MakeGamesWithUs. All rights reserved.
//

#import "Robot.h"

typedef NS_ENUM(NSInteger, RobotAction) {
    RobotActionDefault,
    RobotActionWildScanning,
    RobotActionSearching,
    RobotActionPursuing,
    RobotActionFiring,
    RobotActionStrafing,
    RobotActionTracking,
    RobotActionTurnaround
};

typedef NS_ENUM(NSInteger, ArenaQuadrant) {
    BottomLeft,
    BottomRight,
    TopRight,
    TopLeft
};

@interface DalekDoomBot : Robot

@property (nonatomic, assign) RobotAction currentRobotAction;
@property (nonatomic, assign) RobotAction priorRobotAction;

@end
