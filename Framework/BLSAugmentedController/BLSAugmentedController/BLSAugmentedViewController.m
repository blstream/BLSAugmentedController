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

#pragma mark - Class Extension

@interface BLSAugmentedViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) NSMutableArray *annotations;
@property (nonatomic, strong) NSMutableArray *viewsInUse;
@property (nonatomic, strong) NSMutableSet *reusableViews;

@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, weak) UIView *vrView;
@property (nonatomic, weak) AVCaptureDevice *captureDevice;
@property (nonatomic, weak) AVCaptureSession *captureSession;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic, weak) NSTimer *refreshARAnnotationViewsTimer;

@end

#pragma mark - Helper Functions

static inline double BLSDegreesToRadians(double degrees) {
    return (degrees * M_PI / 180.0);
}

static inline double BLSNormalizeRadians(double angle) {
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

static inline CGPoint BLSCGPointAdd(CGPoint p1, CGPoint p2)
{
    return (CGPoint){p1.x + p2.x, p1.y + p2.y};
}

#pragma mark -

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
    [self.locationManager requestWhenInUseAuthorization];
    
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
        _locationManager.headingFilter = kCLHeadingFilterNone;
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (CMMotionManager *)motionManager {
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = 1.0/30.0;
        _motionManager.showsDeviceMovementDisplay = YES;
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
    if (self.style == BLSAugmentedViewControllerStyleMap) {
        return (BLSAugmentedAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    } else {
        for (BLSAugmentedAnnotationView *view in self.reusableViews) {
            if ([view.reuseIdentifier isEqualToString:identifier]) {
                BLSAugmentedAnnotationView *viewToReuse = view;
                [self.reusableViews removeObject:view];
                return viewToReuse;
            }
        }
    }
    return nil;
}

- (void)loadMapView {
    [self.mapView removeFromSuperview];
    [self.vrView removeFromSuperview];
    [self.refreshARAnnotationViewsTimer invalidate];
    
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
    
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.captureDevice = captureDevice;
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    self.captureSession = session;
    
    [session addInput:input];
    
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    self.videoPreviewLayer = videoPreviewLayer;
    
    videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    videoPreviewLayer.frame = vrView.bounds;
    [vrView.layer addSublayer:videoPreviewLayer];
    
    [self configureVideoOrientation];
    
    //move to appear method
    [session startRunning];
    [self.motionManager startDeviceMotionUpdates];
    
    self.refreshARAnnotationViewsTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(refreshARAnnotationViewsTimerTimeout:) userInfo:nil repeats:YES];
}

- (void)configureVideoOrientation {
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    } else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    } else if (deviceOrientation == UIDeviceOrientationPortrait) {
        self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    } else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
        self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    }
}

- (void)refreshARAnnotationViewsTimerTimeout:(NSTimer *)timer {
    double viewBearing = BLSDegreesToRadians(self.locationManager.heading.trueHeading);
    double fov = [self fieldOfView];
    double minBearing = BLSNormalizeRadians(viewBearing - fov/2);
    double maxBearing = BLSNormalizeRadians(minBearing+fov);
    CLLocation *currentLocation = self.locationManager.location;
    CLLocationCoordinate2D currentCoordinate = currentLocation.coordinate;
    
    for (id <BLSAugmentedAnnotation>annotation in self.annotations) {
        double bearing = BLSBearingBetweenCoordinates(currentCoordinate, annotation.coordinate);
        
        BLSAugmentedAnnotationView *view = [self visibleViewForAnnotation:annotation];
        
        if ((minBearing < maxBearing && (bearing > minBearing && bearing < maxBearing)) ||
            (minBearing > maxBearing && (bearing > minBearing || bearing > maxBearing))) {
            
            if (view == nil) {
                view = [self.delegate augmentedViewController:self viewForAnnotation:annotation forUserLocation:currentLocation];
                [self.vrView addSubview:view];
                [self.viewsInUse addObject:view];
                NSLog(@"Added view: %@", view);
            }
            
            CGPoint centerPoint = self.vrView.center;
            
            centerPoint.x = BLSNormalizeRadians(bearing - minBearing) / fov * CGRectGetWidth(self.vrView.bounds);
            centerPoint = BLSCGPointAdd(centerPoint, view.centerOffset);
            
            view.center = centerPoint;
            
            NSLog(@"centerPoint: %@", NSStringFromCGPoint(centerPoint));
            
        } else if (view != nil) {
            [view removeFromSuperview];
            [self.viewsInUse removeObjectIdenticalTo:view];
            [self.reusableViews addObject:view];
            NSLog(@"Removed view: %@", view);
        }
    }
}

- (BLSAugmentedAnnotationView *)visibleViewForAnnotation:(id<BLSAugmentedAnnotation>)annotation {
    for (BLSAugmentedAnnotationView *view in self.viewsInUse) {
        if ([view.annotation isEqual:annotation]) {
            return view;
        }
    }
    return nil;
}

- (double)fieldOfView {
    double fov = BLSDegreesToRadians(self.captureDevice.activeFormat.videoFieldOfView);
    
    //TODO: calculate cropped fov
    
    return fov;
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
    
    NSUInteger index = [self.annotations indexOfObject:annotation];
    if (index != NSNotFound) {
        [self.annotations removeObjectAtIndex:index];
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

//- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    [self refreshARAnnotationsWithViewBearing:BLSDegreesToRadians(newHeading.trueHeading)];
//}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [manager startUpdatingLocation];
        [manager startUpdatingHeading];
    }
}

#pragma mark - Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (self.style == BLSAugmentedViewControllerStyleVR) {
        self.videoPreviewLayer.frame = CGRectMake(0, 0, size.width, size.height);
        [self configureVideoOrientation];
    }
}

@end
