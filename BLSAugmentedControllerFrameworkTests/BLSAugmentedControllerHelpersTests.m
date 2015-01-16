//
//  BLSAugmentedControllerHelpersTests.m
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 14.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BLSAugmentedControllerHelpers.h"

@interface BLSAugmentedControllerHelpersTests : XCTestCase

@property (nonatomic) CLLocationCoordinate2D szczecinCoordinate;
@property (nonatomic) CLLocationCoordinate2D tokyoCoordinate;

@property (nonatomic) double bearingAccuracy;
@property (nonatomic) CLLocationDistance distanceAccuracy;

@end


@implementation BLSAugmentedControllerHelpersTests

- (void)setUp {
    [super setUp];
    self.szczecinCoordinate = CLLocationCoordinate2DMake(53.428544, 14.552812);
    self.tokyoCoordinate = CLLocationCoordinate2DMake(35.689487, 139.691706);
    self.bearingAccuracy = 0.01;
    self.distanceAccuracy = 10000;
}

- (void)testDegreesToRadians {
    XCTAssertEqual(BLSDegreesToRadians(-720), -M_PI * 4);
    XCTAssertEqual(BLSDegreesToRadians(-360), -M_PI * 2);
    XCTAssertEqual(BLSDegreesToRadians(-180), -M_PI);
    XCTAssertEqual(BLSDegreesToRadians(-90), -M_PI_2);
    XCTAssertEqual(BLSDegreesToRadians(0), 0);
    XCTAssertEqual(BLSDegreesToRadians(90), M_PI_2);
    XCTAssertEqual(BLSDegreesToRadians(180), M_PI);
    XCTAssertEqual(BLSDegreesToRadians(360), M_PI * 2);
    XCTAssertEqual(BLSDegreesToRadians(720), M_PI * 4);
}

- (void)testNormalizeRadians {
    XCTAssertEqual(BLSNormalizeRadians(-1), M_PI * 2 - 1);
    XCTAssertEqual(BLSNormalizeRadians(0), 0);
    XCTAssertEqual(BLSNormalizeRadians(M_PI), M_PI);
    XCTAssertEqual(BLSNormalizeRadians(M_PI * 2), 0);
    XCTAssertEqual(BLSNormalizeRadians(M_PI * 2 + 1), 1);
}

- (void)testCGPointAdd {
    CGPoint p1 = CGPointMake(1.1, 2);
    CGPoint p2 = CGPointMake(3, -4);
    
    XCTAssert(CGPointEqualToPoint(BLSCGPointAdd(p1, p1), CGPointMake(2.2, 4)));
    XCTAssert(CGPointEqualToPoint(BLSCGPointAdd(p1, p2), CGPointMake(4.1, -2)));
    XCTAssert(CGPointEqualToPoint(BLSCGPointAdd(p2, p1), CGPointMake(4.1, -2)));
    XCTAssert(CGPointEqualToPoint(BLSCGPointAdd(p2, p2), CGPointMake(6, -8)));
}

- (void)testBearingBetweenCoordinates {
    XCTAssertEqualWithAccuracy(BLSBearingBetweenCoordinates(self.szczecinCoordinate, self.tokyoCoordinate), 0.743, self.bearingAccuracy);
    XCTAssertEqualWithAccuracy(BLSBearingBetweenCoordinates(self.tokyoCoordinate, self.szczecinCoordinate), 5.764, self.bearingAccuracy);
}

- (void)testDistanceBetweenCoordinates {
    XCTAssertEqualWithAccuracy(BLSDistanceBetweenCoordinates(self.szczecinCoordinate, self.tokyoCoordinate), 8790000, self.distanceAccuracy);
    XCTAssertEqualWithAccuracy(BLSDistanceBetweenCoordinates(self.tokyoCoordinate, self.szczecinCoordinate), 8790000, self.distanceAccuracy);
}

@end
