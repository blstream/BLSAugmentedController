//
//  BLSAugmentedViewControllerTests.m
//  BLSAugmentedController
//
//  Created by Sebastian Jędruszkiewicz on 13/01/15.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BLSAugmentedViewController.h"

@interface BLSAugmentedViewControllerTests : XCTestCase

@property (nonatomic, strong) BLSAugmentedViewController *vc;

@end

@implementation BLSAugmentedViewControllerTests

- (void)setUp {
    [super setUp];
    self.vc = [[BLSAugmentedViewController alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    XCTAssert(self.vc.view, "View loading");
}

- (void)testPerformanceExample {
    [self measureBlock:^{
        [self.vc view];
    }];
}

@end
