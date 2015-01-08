//
//  BLSDemoAnnotation.m
//  BLSAugmentedControllerDemo
//
//  Created by Piotr Tobolski on 08.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import "BLSDemoAnnotation.h"

@implementation BLSDemoAnnotation

- (instancetype)initWithType:(NSString *)type coordinate:(CLLocationCoordinate2D)coordinate {
    if (self = [self init]) {
        _type = type;
        _coordinate = coordinate;
    }
    return self;
}
@end
