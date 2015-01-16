//
//  BLSAugmentedControllerHelpers.h
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 14.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

/**
 Converts degrees to radians.
 */
NS_INLINE double BLSDegreesToRadians(double degrees) {
    return (degrees * M_PI / 180.0);
}

/**
 Converts input angle to values from (and including) 0 to (not including) 2*π for easier comparison.
 @param angle Angle in radians
 @return Angle in radians between 0 and 2*π
 */
NS_INLINE double BLSNormalizeRadians(double angle) {
    while (angle < 0) { angle += 2 * M_PI; }
    return fmod(angle, 2 * M_PI);
}

/**
 Calculates bearing in radians from coordinate1 to coordinate2.
 @param coordinate1 Coordinate from which the bearing should be calculated.
 @param coordinate2 Coordinate to which the bearing should be calculated.
 @return Bearing between coordinates in radians.
 */
double BLSBearingBetweenCoordinates(CLLocationCoordinate2D coordinate1, CLLocationCoordinate2D coordinate2);

/**
 Calculates distance in meters from coordinate1 to coordinate2.
 @param coordinate1 Coordinate from which the distance should be calculated.
 @param coordinate2 Coordinate to which the distance should be calculated.
 @return Distance between coordinates in meters.
 */
CLLocationDistance BLSDistanceBetweenCoordinates(CLLocationCoordinate2D coordinate1, CLLocationCoordinate2D coordinate2);

/**
 Performs basic calculation of adding two points.
 @param p1 First part of the equation.
 @param p2 Second part of the equation.
 @return Sum of the two points.
 */
NS_INLINE CGPoint BLSCGPointAdd(CGPoint p1, CGPoint p2) {
    return (CGPoint){p1.x + p2.x, p1.y + p2.y};
}
