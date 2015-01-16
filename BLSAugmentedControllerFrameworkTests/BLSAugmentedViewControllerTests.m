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


#pragma mark -

@interface BLSAugmentedViewController ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, weak) UIView *vrView;
@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, strong) BLSAugmentedAnnotationViewCache *viewCache;

- (CGFloat)fieldOfView;
- (double)viewBearing;
- (void)refreshARAnnotationViewsTimerTimeout:(NSTimer *)timer;

@end


#pragma mark -

@interface BLSAugmentedViewControllerTests : XCTestCase <BLSAugmentedViewControllerDelegate>

@property (nonatomic, strong) BLSAugmentedViewController *vc;
@property (nonatomic, strong) BLSAugmentedAnnotationView *lastReturnedAnnotationView;

@end


@implementation BLSAugmentedViewControllerTests

- (void)setUp {
    [super setUp];
    self.vc = [[BLSAugmentedViewController alloc] init];
    self.vc.delegate = self;
}

- (void)setUpWithMockLocation {
    CLLocation *location = [[CLLocation alloc] init];
    id locationMock = OCMPartialMock(location);
    OCMStub([locationMock coordinate]).andReturn(CLLocationCoordinate2DMake(10, 20));
    
    CLLocationManager *locationManager = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManager location]).andReturn(location);
    
    id vcMock = OCMPartialMock(self.vc);
    OCMStub([vcMock locationManager]).andReturn(locationManager);
    OCMStub([vcMock fieldOfView]).andReturn(M_PI_2); //90°
    OCMStub([vcMock viewBearing]).andReturn(M_PI); //south
}

- (void)setUpWithMapStyle {
    self.vc.style = BLSAugmentedViewControllerStyleMap;
    [self.vc view];
}

- (void)setUpWithArStyle {
    self.vc.style = BLSAugmentedViewControllerStyleAR;
    [self.vc view];
}

- (void)tearDown {
    self.vc = nil;
//    self.vcMock = nil;
    self.lastReturnedAnnotationView = nil;
    [super tearDown];
}

#pragma mark - Tests

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

- (void)testChangingStyle {
    [self.vc view]; //loads default view (map view);
    
    MKMapView *mapView = self.vc.mapView;
    [self setUpWithArStyle];
    XCTAssertNotNil(self.vc.vrView);
    XCTAssertEqualObjects(self.vc.vrView.superview, self.vc.view);
    XCTAssertNil(mapView.superview);
    
    UIView *vrView = self.vc.vrView;
    [self setUpWithMapStyle];
    XCTAssertNotNil(self.vc.mapView);
    XCTAssertEqualObjects(self.vc.mapView.superview, self.vc.view);
    XCTAssertNil(vrView.superview);
}

#pragma mark MapView

- (void)testMapLoadsProperly {
    [self setUpWithMapStyle];
    
    XCTAssertNotNil(self.vc.mapView, @"map should be loaded");
    XCTAssert([self.vc.mapView isKindOfClass:[MKMapView class]], @"map should be of mkmapview class");
    XCTAssertEqualObjects(self.vc.mapView.delegate, self.vc, @"vc should be delegate of mapview");
    XCTAssert([self.vc.view.subviews indexOfObject:self.vc.mapView] != NSNotFound, @"map should be added as subview");
    XCTAssert(CGRectEqualToRect(self.vc.mapView.frame, self.vc.view.bounds), @"map should be fullscreen");
}

- (void)testAnnotationsAreAddedToAndRemovedFromMap {
    [self setUpWithMapStyle];
    BLSTestAnnotation *annotation = [self createAnnotationAtCoordinate:CLLocationCoordinate2DMake(0, 20)];
    id mapViewMock = OCMPartialMock(self.vc.mapView);
    
    [self.vc addAnnotation:annotation];
    OCMVerify([mapViewMock addAnnotation:annotation]);
    
    [self.vc removeAnnotation:annotation];
    OCMVerify([mapViewMock removeAnnotation:annotation]);
}

- (void)testDequeueFromMapView {
    [self setUpWithMapStyle];

    id mapViewMock = OCMPartialMock(self.vc.mapView);
    
    [self.vc dequeueReusableAnnotationViewWithIdentifier:@"identifier"];
    OCMVerify([mapViewMock dequeueReusableAnnotationViewWithIdentifier:@"identifier"]);
}

#pragma mark VrView

- (void)testVrViewLoadsProperly {
    [self setUpWithArStyle];
    
    XCTAssertNotNil(self.vc.vrView, @"vrView should be loaded");
    XCTAssert([self.vc.view.subviews indexOfObject:self.vc.vrView] != NSNotFound, @"vrView should be added as subview");
    XCTAssert(CGRectEqualToRect(self.vc.vrView.frame, self.vc.view.bounds), @"vrView should be fullscreen");
}

- (void)testVrViewIsBeingRefreshed {
    id vcMock = OCMPartialMock(self.vc);
    OCMExpect([vcMock refreshARAnnotationViewsTimerTimeout:[OCMArg any]]);
    
    self.vc.style = BLSAugmentedViewControllerStyleAR;
    [self.vc view];
    
    OCMVerifyAllWithDelay(vcMock, 1);
}

- (void)testAnnotationViewsAreAddedToVrView {
    [self setUpWithMockLocation];
    [self setUpWithArStyle];
    BLSTestAnnotation *annotation = [self createAnnotationAtCoordinate:CLLocationCoordinate2DMake(9.999, 20)];
    id vrViewMock = OCMPartialMock(self.vc.vrView);
    OCMExpect([vrViewMock addSubview:[OCMArg isKindOfClass:[BLSAugmentedAnnotationView class]]]);

    [self.vc addAnnotation:annotation];
    
    OCMVerifyAllWithDelay(vrViewMock, 1);
}

- (void)testAnnotationViewsAreRemovedFromVrViewIfRemovedFromViewController {
    [self setUpWithMockLocation];
    [self setUpWithArStyle];
    BLSTestAnnotation *annotation = [self createAnnotationAtCoordinate:CLLocationCoordinate2DMake(9.999, 20)];

    id vrViewMock = OCMPartialMock(self.vc.vrView);
    OCMExpect([vrViewMock addSubview:[OCMArg isKindOfClass:[BLSAugmentedAnnotationView class]]]);
    [self.vc addAnnotation:annotation];
    OCMVerifyAllWithDelay(vrViewMock, 1);

    [self.vc removeAnnotation:annotation];
    
    OCMVerify([self.lastReturnedAnnotationView removeFromSuperview]);
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

- (void)testInvalidatingAnnotationRemovesAnnotationViewFromSuperviewAndCache {
    [self setUpWithMockLocation];
    [self setUpWithArStyle];
    BLSTestAnnotation *annotation = [self createAnnotationAtCoordinate:CLLocationCoordinate2DMake(9.999, 20)];
    
    id vrViewMock = OCMPartialMock(self.vc.vrView);
    OCMExpect([vrViewMock addSubview:[OCMArg isKindOfClass:[BLSAugmentedAnnotationView class]]]);
    [self.vc addAnnotation:annotation];
    OCMVerifyAllWithDelay(vrViewMock, 1);
    
    
    OCMExpect([vrViewMock addSubview:[OCMArg isKindOfClass:[BLSAugmentedAnnotationView class]]]);
    
    [self.vc invalidateAnnotation:annotation];
    
    OCMVerify([self.lastReturnedAnnotationView removeFromSuperview]);
    OCMVerify([self.vc.viewCache removeViewForAnnotation:annotation]);
    OCMVerifyAllWithDelay(vrViewMock, 1);
}

- (void)testInvalidationgMultipleAnnotations {
    BLSTestAnnotation *annotation1 = [[BLSTestAnnotation alloc] init];
    BLSTestAnnotation *annotation2 = [[BLSTestAnnotation alloc] init];
    
    [self.vc invalidateAnnotations:@[annotation1, annotation2]];
    
    OCMVerify([self.vc invalidateAnnotation:annotation1]);
    OCMVerify([self.vc invalidateAnnotation:annotation2]);
}

- (void)testAddingMultipleAnnotations {
    BLSTestAnnotation *annotation1 = [[BLSTestAnnotation alloc] init];
    BLSTestAnnotation *annotation2 = [[BLSTestAnnotation alloc] init];
    
    [self.vc addAnnotations:@[annotation1, annotation2]];
    
    OCMVerify([self.vc addAnnotation:annotation1]);
    OCMVerify([self.vc addAnnotation:annotation2]);
}

- (void)testRemovingMultipleAnnotations {
    BLSTestAnnotation *annotation1 = [[BLSTestAnnotation alloc] init];
    BLSTestAnnotation *annotation2 = [[BLSTestAnnotation alloc] init];
    
    [self.vc removeAnnotations:@[annotation1, annotation2]];
    
    OCMVerify([self.vc removeAnnotation:annotation1]);
    OCMVerify([self.vc removeAnnotation:annotation2]);
}

#pragma mark Helpers

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
