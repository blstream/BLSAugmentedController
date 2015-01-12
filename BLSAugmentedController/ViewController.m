//
//  ViewController.m
//  BLSAugmentedControllerDemo
//
//  Created by Piotr Tobolski on 07.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import "ViewController.h"
#import <BLSAugmentedControllerFramework/BLSAugmentedControllerFramework.h>
#import "BLSDemoAnnotation.h"

@interface ViewController () <BLSAugmentedViewControllerDelegate>

@property (nonatomic, strong) BLSAugmentedViewController *augmentedViewController;

@end


@implementation ViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"BLSAugmentedViewController"]) {
        self.augmentedViewController = segue.destinationViewController;
        self.augmentedViewController.delegate = self;
        [self.augmentedViewController addAnnotations:[self createDemoAnnotations]];
    }
}

- (NSArray *)createDemoAnnotations {
    NSArray *annotations = @[
                             [[BLSDemoAnnotation alloc] initWithType:@"Police" coordinate:CLLocationCoordinate2DMake(53.429078, 14.558859)],
                             [[BLSDemoAnnotation alloc] initWithType:@"Police" coordinate:CLLocationCoordinate2DMake(53.428154, 14.559803)],
                             [[BLSDemoAnnotation alloc] initWithType:@"ATM" coordinate:CLLocationCoordinate2DMake(53.428781, 14.555125)],
                             [[BLSDemoAnnotation alloc] initWithType:@"ATM" coordinate:CLLocationCoordinate2DMake(53.430813, 14.554760)],
                             [[BLSDemoAnnotation alloc] initWithType:@"ATM" coordinate:CLLocationCoordinate2DMake(53.428397, 14.551692)],
                             [[BLSDemoAnnotation alloc] initWithType:@"ATM" coordinate:CLLocationCoordinate2DMake(53.425648, 14.554288)],
                             ];
    return annotations;
}

- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.augmentedViewController.style = BLSAugmentedViewControllerStyleMap;
    } else if (sender.selectedSegmentIndex == 1) {
        self.augmentedViewController.style = BLSAugmentedViewControllerStyleAR;
    }
}

- (BLSAugmentedAnnotationView *)augmentedViewController:(BLSAugmentedViewController *)augmentedViewController viewForAnnotation:(id<BLSAugmentedAnnotation>)annotation forUserLocation:(CLLocation *)location distance:(CLLocationDistance)distance{
    BLSDemoAnnotation *demoAnnotation = annotation;
    BLSAugmentedAnnotationView *view = [augmentedViewController dequeueReusableAnnotationViewWithIdentifier:demoAnnotation.type];
    if (view == nil) {
        view = [[BLSAugmentedAnnotationView alloc] initWithAnnotation:demoAnnotation reuseIdentifier:demoAnnotation.type];
        if ([demoAnnotation.type isEqualToString:@"ATM"]) {
            view.image = [UIImage imageNamed:@"atm"];
        } else {
            view.image = [UIImage imageNamed:@"police"];
        }
    } else {
        view.annotation = annotation;
    }
    return view;
}

@end
