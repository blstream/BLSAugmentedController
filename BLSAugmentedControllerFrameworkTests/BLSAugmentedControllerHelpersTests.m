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

@end

@implementation BLSAugmentedControllerHelpersTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
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

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
