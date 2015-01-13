//
//  BLSAugmentedControllerFrameworkTests.m
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 13.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "BLSAugmentedControllerFramework.h"

@interface BLSDemoAnnotation : NSObject <BLSAugmentedAnnotation>

@property (nonatomic) NSString *type;
@property (nonatomic) CLLocationCoordinate2D coordinate;

- (instancetype)initWithType:(NSString *)type coordinate:(CLLocationCoordinate2D)coordinate;

@end

@implementation BLSDemoAnnotation

- (instancetype)initWithType:(NSString *)type coordinate:(CLLocationCoordinate2D)coordinate {
    if (self = [self init]) {
        _type = type;
        _coordinate = coordinate;
    }
    return self;
}
@end


@interface BLSAugmentedControllerFrameworkTests : XCTestCase

@property (nonatomic, strong) BLSAugmentedViewController *vc;
@property (nonatomic, strong) NSArray *annotations;

@end

@implementation BLSAugmentedControllerFrameworkTests

- (void)setUp {
    [super setUp];
    
    id augmentedAnnotation = OCMProtocolMock(@protocol(BLSAugmentedAnnotation));
    
    
    
    self.vc = [[BLSAugmentedViewController alloc] init];
    self.annotations = @[[[BLSDemoAnnotation alloc] initWithType:@"Police" coordinate:CLLocationCoordinate2DMake(53.429078, 14.558859)],
                         [[BLSDemoAnnotation alloc] initWithType:@"Police" coordinate:CLLocationCoordinate2DMake(53.428154, 14.559803)],
                         [[BLSDemoAnnotation alloc] initWithType:@"ATM" coordinate:CLLocationCoordinate2DMake(53.428781, 14.555125)],
                         [[BLSDemoAnnotation alloc] initWithType:@"ATM" coordinate:CLLocationCoordinate2DMake(53.430813, 14.554760)],
                         [[BLSDemoAnnotation alloc] initWithType:@"ATM" coordinate:CLLocationCoordinate2DMake(53.428397, 14.551692)],
                         [[BLSDemoAnnotation alloc] initWithType:@"ATM" coordinate:CLLocationCoordinate2DMake(53.425648, 14.554288)],
                         ];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
