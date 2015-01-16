//
//  BLSAugmentedAnnotationViewCache.h
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 14.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BLSAugmentedAnnotation;
@class BLSAugmentedAnnotationView;

@interface BLSAugmentedAnnotationViewCache : NSObject

/**
 Returns a reusable annotation view located by its identifier.
 
 For performance reasons, you should generally reuse BLSAugmentedAnnotationView objects. As annotation views move offscreen, the view controller moves them to an internally managed reuse queue. As new annotations move onscreen, and your code is prompted to provide a corresponding annotation view, you should always attempt to dequeue an existing view before creating a new one. Dequeueing saves time and memory during performance-critical operations such as scrolling.
 @param identifier A string identifying the annotation view to be reused. This string is the same one you specify when initializing the annotation view using the initWithAnnotation:reuseIdentifier: method.
 @return An annotation view with the specified identifier, or nil if no such object exists in the reuse queue.
 */
- (BLSAugmentedAnnotationView *)dequeueReusableAnnotationViewWithIdentifier:(NSString *)identifier;

/**
 Returns cached view for annotation.
 @param annotation Annotation for which the cached view should be returned.
 @return Cached view.
 */
- (BLSAugmentedAnnotationView *)visibleViewForAnnotation:(id<BLSAugmentedAnnotation>)annotation;

/**
 Removes view from superview and visible views cache. Adds this view to reuse cache.
 @param annotation Annotation for which the view should be removed.
 */
- (void)removeViewForAnnotation:(id<BLSAugmentedAnnotation>)annotation;

/**
 Adds view visible views cache.
 @param view View that should be added to cache.
 @param annotation Annotation for which the view should be cached.
 */
- (void)useView:(BLSAugmentedAnnotationView *)view forAnnotation:(id <BLSAugmentedAnnotation>)annotation;

/**
 Clears reusable views to free memory.
 */
- (void)clearUnusedViews;

@end
