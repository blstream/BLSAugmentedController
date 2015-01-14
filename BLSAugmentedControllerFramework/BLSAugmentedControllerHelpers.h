//
//  BLSAugmentedControllerHelpers.h
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 14.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

double BLSDegreesToRadians(double degrees);

double BLSNormalizeRadians(double angle);

double BLSBearingBetweenCoordinates(CLLocationCoordinate2D coordinate1, CLLocationCoordinate2D coordinate2);

CLLocationDistance BLSDistanceBetweenCoordinated(CLLocationCoordinate2D coordinate1, CLLocationCoordinate2D coordinate2);

CGPoint BLSCGPointAdd(CGPoint p1, CGPoint p2);
