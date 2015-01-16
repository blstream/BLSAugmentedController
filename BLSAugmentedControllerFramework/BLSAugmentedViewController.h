//
//  BLSAugmentedViewController.h
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 07.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>

@class BLSAugmentedAnnotationView;
@protocol BLSAugmentedAnnotation;
@protocol BLSAugmentedViewControllerDelegate;


/**
 @enum BLSAugmentedViewControllerStyle
 An enumeration of augmented view styles.
 */
typedef NS_ENUM(NSUInteger, BLSAugmentedViewControllerStyle) {
    BLSAugmentedViewControllerStyleMap,     /**< Map with user location and annotations. */
    BLSAugmentedViewControllerStyleAR       /**< Augmented reality view from back camera with annotations. */
};


#pragma mark -
/**
 View Controller that displays map or augmented reality view with annotations.
 */
@interface BLSAugmentedViewController : UIViewController

/**
 The delegate object that is responsible for creating views for annotations.
 */
@property (nonatomic, weak) id <BLSAugmentedViewControllerDelegate>delegate;

/**
 Style of view (map or augmented reality).
 
 Default value BLSAugmentedViewControllerStyleMap.
 
 @see BLSAugmentedViewControllerStyle
 */
@property (nonatomic) BLSAugmentedViewControllerStyle style;

/**
 Max distance of drawing annotations on augmented reality view.
 
 Defaut value 750m.
 
 It is also used for calculating vertical position and scale of annotation view on augmented view.
 */
@property (nonatomic) CLLocationDistance maxDistance;

/**
 Array of annotations currently managed by the view controller.
 */
@property (nonatomic, readonly) NSArray *annotations;


#pragma mark - Managing Annottations
/**
 Adds annotation to view.
 
 @param annotation The object that should be added to view.
 */
- (void)addAnnotation:(id <BLSAugmentedAnnotation>)annotation;

/**
 Adds multiple annotations to view.
 
 @param annotations Array of `id<BLSAugmentedAnnotation>` objects that should be added to view.
 */
- (void)addAnnotations:(NSArray *)annotations;

/**
 Removes annotation from view.
 
 @param annotation The object that should be removed from view.
 */
- (void)removeAnnotation:(id <BLSAugmentedAnnotation>)annotation;

/**
 Removes multiple annotations from view.
 
 @param annotations Array of id<BLSAugmentedAnnotation> objects that should be removed from view.
 */
- (void)removeAnnotations:(NSArray *)annotations;

/**
 Removes cached view for annotation. This view will be loaded again.
 
 @param annotation The object which view should be reloaded.
 */
- (void)invalidateAnnotation:(id <BLSAugmentedAnnotation>)annotation;

/**
 Removes cached view for annotations. Those views will be loaded again.
 
 @param annotations Array of id<BLSAugmentedAnnotation> objects which views should be reloaded.
 */
- (void)invalidateAnnotations:(NSArray *)annotations;


#pragma mark - Reusing Annotations
/**
 Returns a reusable annotation view located by its identifier.
 
 For performance reasons, you should generally reuse BLSAugmentedAnnotationView objects. As annotation views move offscreen, the view controller moves them to an internally managed reuse queue. As new annotations move onscreen, and your code is prompted to provide a corresponding annotation view, you should always attempt to dequeue an existing view before creating a new one. Dequeueing saves time and memory during performance-critical operations such as scrolling.
 @param identifier A string identifying the annotation view to be reused. This string is the same one you specify when initializing the annotation view using the initWithAnnotation:reuseIdentifier: method.
 @return An annotation view with the specified identifier, or nil if no such object exists in the reuse queue.
 */
- (BLSAugmentedAnnotationView *)dequeueReusableAnnotationViewWithIdentifier:(NSString *)identifier;

@end

#pragma mark -
@protocol BLSAugmentedViewControllerDelegate <NSObject>

/**
 Returns the view associated with the specified annotation object.
 Rather than create a new view each time this method is called, you should use the dequeueReusableAnnotationViewWithIdentifier: method of the BLSAugmentedViewController class to see if an existing annotation view of the desired type already exists. If one does exist, you should update the view to reflect the attributes of the specified annotation and return it. If a view of the appropriate type does not exist, you should create one, configure it with the needed annotation data, and return it.
 If you return nil from your implementation, the map view uses a standard pin annotation view and the augmented reality view doesn't display any view for this specific annotation.
 @param augmentedViewController The view controller that requested the annotation view.
 @param annotation The object representing the annotation that is about to be displayed. In addition to your custom annotations, this object could be an MKUserLocation object representing the user’s current location.
 @param location Current user location.
 @param distance Distance from user location to the location of annotation.
 @return The annotation view to display for the specified annotation or nil.
*/
- (BLSAugmentedAnnotationView *)augmentedViewController:(BLSAugmentedViewController *)augmentedViewController viewForAnnotation:(id <BLSAugmentedAnnotation>)annotation forUserLocation:(CLLocation *)location distance:(CLLocationDistance)distance;

@end
