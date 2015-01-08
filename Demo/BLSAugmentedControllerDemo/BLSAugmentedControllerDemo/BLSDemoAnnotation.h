//
//  BLSDemoAnnotation.h
//  BLSAugmentedControllerDemo
//
//  Created by Piotr Tobolski on 08.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import <BLSAugmentedController/BLSAugmentedController.h>

@interface BLSDemoAnnotation : NSObject <BLSAugmentedAnnotation>

@property (nonatomic) NSString *type;
@property (nonatomic) CLLocationCoordinate2D coordinate;

- (instancetype)initWithType:(NSString *)type coordinate:(CLLocationCoordinate2D)coordinate;

@end
