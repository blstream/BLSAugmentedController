//
//  BLSAugmentedAnnotationViewCache.m
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 14.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import "BLSAugmentedAnnotationViewCache.h"
#import "BLSAugmentedAnnotation.h"
#import "BLSAugmentedAnnotationView.h"

@interface BLSAugmentedAnnotationViewCache ()

@property (nonatomic, strong) NSMutableDictionary *viewsInUse;
@property (nonatomic, strong) NSMutableSet *reusableViews;

@end


@implementation BLSAugmentedAnnotationViewCache

- (instancetype)init {
    if (self = [super init]) {
        _viewsInUse = [[NSMutableDictionary alloc] init];
        _reusableViews = [[NSMutableSet alloc] init];
    }
    return self;
}
//- (NSMutableDictionary *)viewsInUse {
//    if (_viewsInUse == nil) {
//    }
//    return _viewsInUse;
//}
//
//- (NSMutableSet *)reusableViews {
//    if (_reusableViews == nil) {
//    }
//    return _reusableViews;
//}

- (BLSAugmentedAnnotationView *)dequeueReusableAnnotationViewWithIdentifier:(NSString *)identifier {
        for (BLSAugmentedAnnotationView *view in self.reusableViews) {
            if ([view.reuseIdentifier isEqualToString:identifier]) {
                BLSAugmentedAnnotationView *viewToReuse = view;
                [self.reusableViews removeObject:view];
                return viewToReuse;
            }
        }
    return nil;
}

- (BLSAugmentedAnnotationView *)visibleViewForAnnotation:(id<BLSAugmentedAnnotation>)annotation {
    return self.viewsInUse[@([annotation hash])];
}

- (void)removeViewForAnnotation:(id<BLSAugmentedAnnotation>)annotation {
    BLSAugmentedAnnotationView *view = self.viewsInUse[@([annotation hash])];
    if (view != nil) {
        [view removeFromSuperview];
        [self.viewsInUse removeObjectForKey:@([annotation hash])];
        if (view.reuseIdentifier != nil) {
            [self.reusableViews addObject:view];
        }
    }
}

- (void)useView:(BLSAugmentedAnnotationView *)view forAnnotation:(id<BLSAugmentedAnnotation>)annotation {
    if (annotation != nil) {
        self.viewsInUse[@([annotation hash])] = view;
    }
}

- (void)clearUnusedViews {
    [self.reusableViews removeAllObjects];
}

@end
