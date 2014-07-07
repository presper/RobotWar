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
    RobotActionSearching,
    RobotActionPursuing,
    RobotActionFiring,
    RobotActionTracking,
    RobotActionTurnaround
};

@interface DalekDoomBot : Robot

@property (nonatomic, assign) RobotAction currentRobotAction;

@end
