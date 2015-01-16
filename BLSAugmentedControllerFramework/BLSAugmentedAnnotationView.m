//
//  BLSAugmentedAnnotationView.m
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 07.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import "BLSAugmentedController.h"

@implementation BLSAugmentedAnnotationView

- (instancetype)initWithAnnotation:(id<BLSAugmentedAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    NSParameterAssert([annotation conformsToProtocol:@protocol(BLSAugmentedAnnotation)]);
    return [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
}

@end
