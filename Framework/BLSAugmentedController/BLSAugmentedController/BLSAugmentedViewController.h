//
//  BLSAugmentedViewController.h
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 07.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <BLSAugmentedController/BLSAugmentedAnnotationView.h>
#import <BLSAugmentedController/BLSAugmentedAnnotation.h>

typedef enum : NSUInteger {
    BLSAugmentedViewControllerStyleMap,
    BLSAugmentedViewControllerStyleVR
} BLSAugmentedViewControllerStyle;

@protocol BLSAugmentedViewControllerDelegate;

@interface BLSAugmentedViewController : UIViewController

@property (nonatomic, weak) id <BLSAugmentedViewControllerDelegate>delegate;
@property (nonatomic) BLSAugmentedViewControllerStyle style; //default BLSAugmentedViewControllerStyleMap

- (void)addAnnotation:(id <BLSAugmentedAnnotation>)annotation;
- (void)addAnnotations:(NSArray *)annotations;

- (void)removeAnnotation:(id <BLSAugmentedAnnotation>)annotation;
- (void)removeAnnotations:(NSArray *)annotations;

- (void)invalidateAnnotation:(id <BLSAugmentedAnnotation>)annotation;
- (void)invalidateAnnotations:(NSArray *)annotations;

- (BLSAugmentedAnnotationView *)dequeueReusableAnnotationViewWithIdentifier:(NSString *)identifier;

@end


@protocol BLSAugmentedViewControllerDelegate <NSObject>

- (BLSAugmentedAnnotationView *)viewForAnnotation:(id <BLSAugmentedAnnotation>)annotation forUserLocation:(CLLocation *)location;

@end
