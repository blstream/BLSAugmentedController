//
//  BLSAugmentedAnnotationView.h
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 07.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import <MapKit/MapKit.h>

@protocol BLSAugmentedAnnotation;

@interface BLSAugmentedAnnotationView : MKAnnotationView

/**
 Initializes and returns a new annotation view.
 The reuse identifier provides a way for you to improve performance by recycling annotation views as they are scrolled on and off of the view. As views are no longer needed, they are moved to a reuse queue by the view controller. When a new annotation becomes visible, your application can request a view for that annotation by passing the appropriate reuse identifier string to the dequeueReusableAnnotationViewWithIdentifier: method of BLSAugmentedViewController.
 @param annotation The annotation object to associate with the new view.
 @param reuseIdentifier If you plan to reuse the annotation view for similar types of annotations, pass a string to identify it. Although you can pass nil if you do not intend to reuse the view, reusing annotation views is generally recommended.
 @return The initialized annotation view or nil if there was a problem initializing the object.
 */
- (instancetype)initWithAnnotation:(id<BLSAugmentedAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier;

@end
