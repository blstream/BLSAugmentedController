//
//  BLSAugmentedViewControllerTests.m
//  BLSAugmentedController
//
//  Created by Sebastian Jędruszkiewicz on 13/01/15.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <MapKit/MapKit.h>

#import "BLSAugmentedViewController.h"
#import "BLSAugmentedAnnotation.h"
#import "BLSAugmentedAnnotationView.h"
#import "BLSAugmentedAnnotationViewCache.h"

@interface BLSTestAnnotation : NSObject <BLSAugmentedAnnotation>
@property (nonatomic) CLLocationCoordinate2D coordinate;
@end

@implementation BLSTestAnnotation
@end


@interface BLSAugmentedViewController ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, weak) UIView *vrView;
@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, strong) BLSAugmentedAnnotationViewCache *viewCache;

- (CGFloat)fieldOfView;
- (double)viewBearing;
- (void)refreshARAnnotationViewsTimerTimeout:(NSTimer *)timer;

@end


@interface BLSAugmentedViewControllerTests : XCTestCase <BLSAugmentedViewControllerDelegate>

@property (nonatomic, strong) BLSAugmentedViewController *vc;
@property (nonatomic, strong) id vcMock;

@property (nonatomic, strong) BLSAugmentedAnnotationView *lastReturnedAnnotationView;

@end


@implementation BLSAugmentedViewControllerTests

- (void)setUp {
    [super setUp];
    
    CLLocation *location = [[CLLocation alloc] init];
    id locationMock = OCMPartialMock(location);
    OCMStub([locationMock coordinate]).andReturn(CLLocationCoordinate2DMake(10, 20));
    
    CLLocationManager *locationManager = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManager location]).andReturn(location);
    
    BLSAugmentedViewController *vc = [[BLSAugmentedViewController alloc] init];
    vc.delegate = self;
    self.vcMock = OCMPartialMock(vc);
    OCMStub([self.vcMock locationManager]).andReturn(locationManager);
    OCMStub([self.vcMock fieldOfView]).andReturn(M_PI_2); //90°
    OCMStub([self.vcMock viewBearing]).andReturn(M_PI); //south
    self.vc = vc;
    [self.vc view];
}

- (void)tearDown {
    self.vc = nil;
    self.vcMock = nil;
    self.lastReturnedAnnotationView = nil;
    [super tearDown];
}

- (void)testInitialValues {
    XCTAssertEqual(self.vc.style, BLSAugmentedViewControllerStyleMap);
    XCTAssertEqual(self.vc.maxDistance, 750);
    XCTAssertEqualObjects(self.vc.annotations, @[]);
}

- (void)testMethodsAcceptNil {
    XCTAssertNoThrow([self.vc addAnnotation:nil]);
    XCTAssertNoThrow([self.vc addAnnotations:nil]);
    XCTAssertNoThrow([self.vc removeAnnotation:nil]);
    XCTAssertNoThrow([self.vc removeAnnotations:nil]);
    XCTAssertNoThrow([self.vc invalidateAnnotation:nil]);
    XCTAssertNoThrow([self.vc invalidateAnnotations:nil]);
    XCTAssertNoThrow([self.vc dequeueReusableAnnotationViewWithIdentifier:nil]);
}

- (void)testMapLoadsProperly {
    self.vc.style = BLSAugmentedViewControllerStyleMap;
    
    XCTAssertNotNil(self.vc.mapView, @"map should be loaded");
    XCTAssert([self.vc.mapView isKindOfClass:[MKMapView class]], @"map should be of mkmapview class");
    XCTAssertEqualObjects(self.vc.mapView.delegate, self.vc, @"vc should be delegate of mapview");
    XCTAssert([self.vc.view.subviews indexOfObject:self.vc.mapView] != NSNotFound, @"map should be added as subview");
    XCTAssert(CGRectEqualToRect(self.vc.mapView.frame, self.vc.view.bounds), @"map should be fullscreen");
}

- (void)testAnnotationsAreAddedToAndRemovedFromMap {
    self.vc.style = BLSAugmentedViewControllerStyleMap;
    BLSTestAnnotation *annotation = [self createAnnotationAtCoordinate:CLLocationCoordinate2DMake(0, 20)];
    id mapViewMock = OCMPartialMock(self.vc.mapView);
    
    [self.vc addAnnotation:annotation];
    OCMVerify([mapViewMock addAnnotation:annotation]);
    
    [self.vc removeAnnotation:annotation];
    OCMVerify([mapViewMock removeAnnotation:annotation]);
}

- (void)testDequeueFromMapView {
    self.vc.style = BLSAugmentedViewControllerStyleMap;
    id mapViewMock = OCMPartialMock(self.vc.mapView);
    
    [self.vc dequeueReusableAnnotationViewWithIdentifier:@"identifier"];
    OCMVerify([mapViewMock dequeueReusableAnnotationViewWithIdentifier:@"identifier"]);
}

- (void)testVrViewLoadsProperly {
    self.vc.style = BLSAugmentedViewControllerStyleAR;
    
    XCTAssertNotNil(self.vc.vrView, @"vrView should be loaded");
    XCTAssert([self.vc.view.subviews indexOfObject:self.vc.vrView] != NSNotFound, @"vrView should be added as subview");
    XCTAssert(CGRectEqualToRect(self.vc.vrView.frame, self.vc.view.bounds), @"vrView should be fullscreen");
}

- (void)testVrViewIsBeingRefreshed {
    OCMExpect([self.vcMock refreshARAnnotationViewsTimerTimeout:[OCMArg any]]);
    
    self.vc.style = BLSAugmentedViewControllerStyleAR;
    
    OCMVerifyAllWithDelay(self.vcMock, 1);
}

- (void)testAnnotationViewsAreAddedToVrView {
    self.vc.style = BLSAugmentedViewControllerStyleAR;
    BLSTestAnnotation *annotation = [self createAnnotationAtCoordinate:CLLocationCoordinate2DMake(9.999, 20)];
    id vrViewMock = OCMPartialMock(self.vc.vrView);
    OCMExpect([vrViewMock addSubview:[OCMArg isKindOfClass:[BLSAugmentedAnnotationView class]]]);

    [self.vc addAnnotation:annotation];
    
    OCMVerifyAllWithDelay(vrViewMock, 1);
}

- (void)testAnnotationViewsAreRemovedFromVrViewIfRemovedFromViewController {
    self.vc.style = BLSAugmentedViewControllerStyleAR;
    BLSTestAnnotation *annotation = [self createAnnotationAtCoordinate:CLLocationCoordinate2DMake(9.999, 20)];

    id vrViewMock = OCMPartialMock(self.vc.vrView);
    OCMExpect([vrViewMock addSubview:[OCMArg isKindOfClass:[BLSAugmentedAnnotationView class]]]);
    [self.vc addAnnotation:annotation];
    OCMVerifyAllWithDelay(vrViewMock, 1);

    id annotationViewMock = OCMPartialMock(self.lastReturnedAnnotationView);
    OCMExpect([annotationViewMock removeFromSuperview]);
    
    [self.vc removeAnnotation:annotation];
    
    OCMVerifyAllWithDelay(annotationViewMock, 1);
}

- (void)testAnnotationsAreRemovedFromVrViewIfDistanceRequirementIsNotMet {
    [self testAnnotationViewsAreAddedToVrView];
    
    id annotationViewMock = OCMPartialMock(self.lastReturnedAnnotationView);
    OCMExpect([annotationViewMock removeFromSuperview]);
    
    self.vc.maxDistance = 1;
    
    OCMVerifyAllWithDelay(annotationViewMock, 1);
}

- (void)testAnnotationsAreRemovedFromVrViewIfNotInFieldOfView {
    [self testAnnotationViewsAreAddedToVrView];
    
    id annotationViewMock = OCMPartialMock(self.lastReturnedAnnotationView);
    OCMExpect([annotationViewMock removeFromSuperview]);
    
    self.vc.maxDistance = 1;
    
    OCMVerifyAllWithDelay(annotationViewMock, 1);
}

- (void)testCacheIsClearedAfterMemoryWarning {
    [self.vc didReceiveMemoryWarning];
    OCMVerify([self.vc.viewCache clearUnusedViews]);
}


- (BLSTestAnnotation *)createAnnotationAtCoordinate:(CLLocationCoordinate2D)coordinate {
    BLSTestAnnotation *annotation = [[BLSTestAnnotation alloc] init];
    annotation.coordinate = coordinate;
    return annotation;
}

#pragma mark - BLSAugmentedViewControllerDelegate

- (BLSAugmentedAnnotationView *)augmentedViewController:(BLSAugmentedViewController *)augmentedViewController viewForAnnotation:(id<BLSAugmentedAnnotation>)annotation forUserLocation:(CLLocation *)location distance:(CLLocationDistance)distance {
    BLSAugmentedAnnotationView *view = [augmentedViewController dequeueReusableAnnotationViewWithIdentifier:@"identifier"];
    if (view == nil) {
        view = [[BLSAugmentedAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"identifier"];
    } else {
        view.annotation = annotation;
    }
    self.lastReturnedAnnotationView = view;
    return view;
}

@end
