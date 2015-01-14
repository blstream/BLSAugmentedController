//
//  BLSAugmentedControllerHelpers.m
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 14.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import "BLSAugmentedControllerHelpers.h"

double BLSDegreesToRadians(double degrees) {
    return (degrees * M_PI / 180.0);
}

double BLSNormalizeRadians(double angle) {
    while (angle < 0) {
        angle += 2 * M_PI;
    }
    return fmod(angle, 2 * M_PI);
}

double BLSBearingBetweenCoordinates(CLLocationCoordinate2D coordinate1, CLLocationCoordinate2D coordinate2) {
    double lat1 = BLSDegreesToRadians(coordinate1.latitude);
    double lon1 = BLSDegreesToRadians(coordinate1.longitude);
    double lat2 = BLSDegreesToRadians(coordinate2.latitude);
    double lon2 = BLSDegreesToRadians(coordinate2.longitude);
    double deltaLon = lon2 - lon1;
    double k = cos(lat2);
    double x = sin(deltaLon) * k;
    double y = cos(lat1) * sin(lat2) - sin(lat1) * k * cos(deltaLon);
    double result = atan2(x, y);
    return BLSNormalizeRadians(result);
}

CLLocationDistance BLSDistanceBetweenCoordinated(CLLocationCoordinate2D coordinate1, CLLocationCoordinate2D coordinate2) {
    double lat1 = BLSDegreesToRadians(coordinate1.latitude);
    double lon1 = BLSDegreesToRadians(coordinate1.longitude);
    double lat2 = BLSDegreesToRadians(coordinate2.latitude);
    double lon2 = BLSDegreesToRadians(coordinate2.longitude);
    double deltaLat = lat2 - lat1;
    double deltaLon = lon2 - lon1;
    double p = sin(deltaLat/2);
    double q = sin(deltaLon/2);
    double a = p * p + q * q * cos(lat1) * cos(lat2);
    double c = 2 * asin(sqrt(a));
    double R = 6371000; //earth radius
    return c * R;
}

CGPoint BLSCGPointAdd(CGPoint p1, CGPoint p2) {
    return (CGPoint){p1.x + p2.x, p1.y + p2.y};
}

