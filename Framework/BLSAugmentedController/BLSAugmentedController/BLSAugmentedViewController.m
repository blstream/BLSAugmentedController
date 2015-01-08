//
//  BLSAugmentedViewController.m
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 07.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import "BLSAugmentedViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <MapKit/MapKit.h>


@interface BLSAugmentedViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) NSMutableArray *annotations;
@property (nonatomic, strong) NSMutableArray *viewsInUse;
@property (nonatomic, strong) NSMutableSet *reusableViews;

@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, weak) UIView *vrView;

@end


@implementation BLSAugmentedViewController

#pragma mark - Initializing

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self customInitialization];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self customInitialization];
    }
    return self;
}

- (void)customInitialization {
    _style = BLSAugmentedViewControllerStyleMap;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.style == BLSAugmentedViewControllerStyleMap) {
        [self loadMapView];
    } else if (self.style == BLSAugmentedViewControllerStyleVR) {
        [self loadVRView];
    }
    
    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];
    [self.motionManager startDeviceMotionUpdates];
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.reusableViews removeAllObjects];
}

#pragma mark - Setters and Getters

- (void)setStyle:(BLSAugmentedViewControllerStyle)style {
    if (_style != style && self.isViewLoaded) {
        if (style == BLSAugmentedViewControllerStyleMap) {
            [self loadMapView];
        } else if (style == BLSAugmentedViewControllerStyleVR) {
            [self loadVRView];
        }
    }
    _style = style;
}

- (CLLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (CMMotionManager *)motionManager {
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = 1/30;
        
    }
    return _motionManager;
}

- (NSArray *)annotations {
    if (_annotations == nil) {
        _annotations = [[NSMutableArray alloc] init];
    }
    return _annotations;
}

- (NSArray *)viewsInUse {
    if (_viewsInUse == nil) {
        _viewsInUse = [[NSMutableArray alloc] init];
    }
    return _viewsInUse;
}

- (NSMutableSet *)reusableViews {
    if (_reusableViews == nil) {
        _reusableViews = [[NSMutableSet alloc] init];
    }
    return _reusableViews;
}

#pragma mark - Actions

- (void)invalidateAnnotation:(id<BLSAugmentedAnnotation>)annotation {
    for (BLSAugmentedAnnotationView *view in self.viewsInUse) {
        if ([view.annotation isEqual:annotation]) {
            [self.viewsInUse removeObject:view];
            [self.reusableViews addObject:view];
            return;
        }
    }
}

- (void)invalidateAnnotations:(NSArray *)annotations {
    for (id<BLSAugmentedAnnotation>annotation in annotations) {
        [self invalidateAnnotation:annotation];
    }
}

- (BLSAugmentedAnnotationView *)dequeueReusableAnnotationViewWithIdentifier:(NSString *)identifier {
    for (BLSAugmentedAnnotationView *view in self.reusableViews) {
        if ([view.reuseIdentifier isEqualToString:identifier]) {
            [self.reusableViews removeObject:view];
            return view;
        }
    }
    return nil;
}

- (void)loadMapView {
    [self.mapView removeFromSuperview];
    [self.vrView removeFromSuperview];
    
    MKMapView *mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView = mapView;
    
    mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    mapView.delegate = self;
    [mapView addAnnotations:self.annotations];
    
    [self.view insertSubview:mapView atIndex:0];
}


- (void)loadVRView {
    [self.mapView removeFromSuperview];
    [self.vrView removeFromSuperview];
    
    UIView *vrView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.vrView = vrView;
    
    vrView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    [self.view insertSubview:vrView atIndex:0];
    
    NSError *error = nil;
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [session addInput:input];
    
    //TODO: AVCaptureVideoPreviewLayer
    
}

#pragma mark - Adding or removing annotations

- (void)addAnnotation:(id<BLSAugmentedAnnotation>)annotation {
    NSParameterAssert([annotation conformsToProtocol:@protocol(BLSAugmentedAnnotation)]);
    if ([self.annotations indexOfObject:annotation] == NSNotFound) {
        [self.annotations addObject:annotation];
        [self.mapView addAnnotation:annotation];
    }
}

- (void)addAnnotations:(NSArray *)annotations {
    for (id <BLSAugmentedAnnotation>annotation in annotations) {
        [self addAnnotation:annotation];
    }
}

- (void)removeAnnotation:(id<BLSAugmentedAnnotation>)annotation {
    NSParameterAssert([annotation conformsToProtocol:@protocol(BLSAugmentedAnnotation)]);
    if ([self.annotations indexOfObject:annotation] != NSNotFound) {
        [self.annotations removeObject:annotation];
        [self.mapView removeAnnotation:annotation];
    }
}

- (void)removeAnnotations:(NSArray *)annotations {
    for (id <BLSAugmentedAnnotation>annotation in annotations) {
        [self removeAnnotation:annotation];
    }
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation conformsToProtocol:@protocol(BLSAugmentedAnnotation)]) {
        return [self.delegate augmentedViewController:self viewForAnnotation:(id <BLSAugmentedAnnotation>)annotation forUserLocation:self.locationManager.location];
    } else {
        return nil;
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
}

@end
