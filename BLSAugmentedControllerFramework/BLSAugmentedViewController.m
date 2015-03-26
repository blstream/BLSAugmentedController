//
//  BLSAugmentedViewController.m
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 07.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import "BLSAugmentedController.h"
#import "BLSAugmentedControllerHelpers.h"
#import "BLSAugmentedAnnotationViewCache.h"

static const float kBLSARViewUpdateInterval = 1.0/60.0;

#pragma mark - Class Extension

@interface BLSAugmentedViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) NSMutableArray *_annotations;
@property (nonatomic, strong) BLSAugmentedAnnotationViewCache *viewCache;

@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, weak) UIView *vrView;
@property (nonatomic, weak) AVCaptureDevice *captureDevice;
@property (nonatomic, weak) AVCaptureSession *captureSession;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic, weak) NSTimer *refreshARAnnotationViewsTimer;

@end


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
    _viewCache = [[BLSAugmentedAnnotationViewCache alloc] init];
    _style = BLSAugmentedViewControllerStyleMap;
    _maxDistance = 750.0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.style == BLSAugmentedViewControllerStyleMap) {
        [self loadMapView];
    } else if (self.style == BLSAugmentedViewControllerStyleAR) {
        [self loadVRView];
    }
    
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.viewCache clearUnusedViews];
}

#pragma mark - Setters and Getters

- (void)setStyle:(BLSAugmentedViewControllerStyle)style {
    if (_style != style && self.isViewLoaded) {
        if (style == BLSAugmentedViewControllerStyleMap) {
            [self loadMapView];
        } else if (style == BLSAugmentedViewControllerStyleAR) {
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

- (NSArray *)annotations {
    return [NSArray arrayWithArray:self._annotations];
}

- (NSMutableArray *)_annotations {
    if (__annotations == nil) {
        __annotations = [[NSMutableArray alloc] init];
    }
    return __annotations;
}

#pragma mark - Actions

- (void)invalidateAnnotation:(id<BLSAugmentedAnnotation>)annotation {
    if (annotation != nil) {
        NSParameterAssert([annotation conformsToProtocol:@protocol(BLSAugmentedAnnotation)]);
        [self.viewCache removeViewForAnnotation:annotation];
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
    }
    return [self.viewCache dequeueReusableAnnotationViewWithIdentifier:identifier];
}

- (void)loadMapView {
    [self.mapView removeFromSuperview];
    [self.vrView removeFromSuperview];
    [self.refreshARAnnotationViewsTimer invalidate];
    
    MKMapView *mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView = mapView;
    
    mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    mapView.delegate = self;
    mapView.showsUserLocation = YES;
    mapView.scrollEnabled = NO;
    mapView.rotateEnabled = NO;
    mapView.zoomEnabled = NO;
    mapView.pitchEnabled = NO;
    [mapView addAnnotations:self._annotations];
    
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
    if (input == nil) {
        NSLog(@"%@", error);
    } else {
        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        self.captureSession = session;
        
        [session addInput:input];
        
        
        AVCaptureVideoPreviewLayer *videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
        self.videoPreviewLayer = videoPreviewLayer;
        
        videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        videoPreviewLayer.frame = vrView.bounds;
        [vrView.layer addSublayer:videoPreviewLayer];
        
        [self configureVideoOrientation];
        
        [session startRunning];
    }
    
    self.refreshARAnnotationViewsTimer = [NSTimer scheduledTimerWithTimeInterval:kBLSARViewUpdateInterval target:self selector:@selector(refreshARAnnotationViewsTimerTimeout:) userInfo:nil repeats:YES];
}

- (void)configureVideoOrientation {
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
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

#pragma mark Main Timer
- (void)refreshARAnnotationViewsTimerTimeout:(NSTimer *)timer {
    double viewBearing = [self viewBearing];
    double fov = [self fieldOfView];
    double minBearing = BLSNormalizeRadians(viewBearing - fov/2);
    double maxBearing = BLSNormalizeRadians(minBearing+fov);
    CLLocation *currentLocation = self.locationManager.location;
    CLLocationCoordinate2D currentCoordinate = currentLocation.coordinate;
    
    for (id <BLSAugmentedAnnotation>annotation in self._annotations) {
        double bearing = BLSBearingBetweenCoordinates(currentCoordinate, annotation.coordinate);
        CLLocationDistance distance = BLSDistanceBetweenCoordinates(currentCoordinate, annotation.coordinate);
        
        BLSAugmentedAnnotationView *view = [self.viewCache visibleViewForAnnotation:annotation];
        if (((minBearing < maxBearing && (bearing > minBearing && bearing < maxBearing)) ||
            (minBearing > maxBearing && (bearing > minBearing || bearing > maxBearing))) &&
            distance <= self.maxDistance) {
            
            if (view == nil) {
                view = [self.delegate augmentedViewController:self viewForAnnotation:annotation forUserLocation:currentLocation distance:distance];
                if (view != nil) {
                    [self.vrView addSubview:view];
                    [self.viewCache useView:view forAnnotation:annotation];
                }
            }
            
            CGFloat relativeDistance = (self.maxDistance - distance) / self.maxDistance; // 0-1, 0 means far, 1 means close
            
            CGPoint centerPoint = self.vrView.center;
            centerPoint.x = BLSNormalizeRadians(bearing - minBearing) / fov * CGRectGetWidth(self.vrView.bounds);
            centerPoint.y = CGRectGetMidY(self.vrView.bounds) * relativeDistance;
            centerPoint = BLSCGPointAdd(centerPoint, view.centerOffset);
            view.center = centerPoint;
            
            CGFloat scale = 0.5 + 0.5 * relativeDistance;
            view.transform = CGAffineTransformMakeScale(scale, scale);
            
            view.frame = CGRectOffset(view.frame, scale * CGRectGetWidth(view.frame) / 2, scale * CGRectGetHeight(view.frame) / 2);
            
        } else if (view != nil) {
            [self.viewCache removeViewForAnnotation:annotation];
        }
    }
}


#pragma mark - map region
- (MKCoordinateRegion)setMapRegionWithTopLeftCoordinate:(CLLocationCoordinate2D)topLeftCoordinate
                               andBottomRightCoordinate:(CLLocationCoordinate2D)bottomRightCoordinate
                                               animated:(BOOL)animated {
    MKCoordinateRegion region;
    region.center.latitude = topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.5;
    region.center.longitude = topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 1.1;
    region.span.longitudeDelta = fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 1.1;
    
    region = [self.mapView regionThatFits:region];
    [self.mapView setRegion:region animated:animated];
    return region;
}

#pragma mark - Helpers

- (CGFloat)fieldOfView {
    CGFloat videoFieldOfView = BLSDegreesToRadians(self.captureDevice.activeFormat.videoFieldOfView);
    CMFormatDescriptionRef format = self.captureDevice.activeFormat.formatDescription;
    CMVideoDimensions videoDimensions = CMVideoFormatDescriptionGetDimensions(format);
    CGSize videoSize = CGSizeMake(videoDimensions.width, videoDimensions.height);
    CGSize viewportSize = self.videoPreviewLayer.bounds.size;
    
    CGFloat fov = 0;
    if (self.videoPreviewLayer.connection.videoOrientation == AVCaptureVideoOrientationLandscapeRight ||
        self.videoPreviewLayer.connection.videoOrientation == AVCaptureVideoOrientationLandscapeLeft) {
        fov = videoFieldOfView * (videoSize.width / videoSize.height) * (viewportSize.height / viewportSize.width);
    } else {
        fov = videoFieldOfView * (videoSize.height / videoSize.width)  * (videoSize.height / videoSize.width) * (viewportSize.height / viewportSize.width);
    }
    
    return fov;
}

- (double)viewBearing {
    double viewBearing = BLSDegreesToRadians(self.locationManager.heading.trueHeading);
    
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) {
        viewBearing -= M_PI_2;
    } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) {
        viewBearing += M_PI_2;
    } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortraitUpsideDown) {
        viewBearing += M_PI;
    }
    return viewBearing;
}

#pragma mark - Adding or removing annotations

- (void)addAnnotation:(id<BLSAugmentedAnnotation>)annotation {
    if (annotation != nil) {
        NSParameterAssert([annotation conformsToProtocol:@protocol(BLSAugmentedAnnotation)]);
        
        if ([self._annotations indexOfObject:annotation] == NSNotFound) {
            [self._annotations addObject:annotation];
            [self.mapView addAnnotation:annotation];
        }
    }
}

- (void)addAnnotations:(NSArray *)annotations {
    for (id <BLSAugmentedAnnotation>annotation in annotations) {
        [self addAnnotation:annotation];
    }
}

- (void)removeAnnotation:(id<BLSAugmentedAnnotation>)annotation {
    if (annotation != nil) {
        NSParameterAssert([annotation conformsToProtocol:@protocol(BLSAugmentedAnnotation)]);
        
        NSUInteger index = [self._annotations indexOfObject:annotation];
        if (index != NSNotFound) {
            [self.viewCache removeViewForAnnotation:annotation];
            [self._annotations removeObjectAtIndex:index];
            [self.mapView removeAnnotation:annotation];
        }
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
        CLLocationDistance distance = BLSDistanceBetweenCoordinates(self.locationManager.location.coordinate, annotation.coordinate);
        return [self.delegate augmentedViewController:self viewForAnnotation:(id <BLSAugmentedAnnotation>)annotation forUserLocation:self.locationManager.location distance:distance];
    } else {
        return nil;
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, self.maxDistance * 2, self.maxDistance * 2);
    [self.mapView setRegion:region animated:YES];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [manager startUpdatingLocation];
        [manager startUpdatingHeading];
        self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    }
}

#pragma mark - Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (self.style == BLSAugmentedViewControllerStyleAR) {
        self.videoPreviewLayer.frame = CGRectMake(0, 0, size.width, size.height);
        [self configureVideoOrientation];
    }
}

@end
