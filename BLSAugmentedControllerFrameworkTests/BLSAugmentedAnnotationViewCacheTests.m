//
//  BLSAugmentedAnnotationViewCacheTests.m
//  BLSAugmentedController
//
//  Created by Piotr Tobolski on 14.01.2015.
//  Copyright (c) 2015 BLStream Sp. z o.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "BLSAugmentedAnnotationViewCache.h"
#import "BLSAugmentedAnnotationView.h"

@interface BLSAugmentedAnnotationViewCache ()

@property (nonatomic, strong) NSMutableDictionary *viewsInUse;
@property (nonatomic, strong) NSMutableSet *reusableViews;

@end


@interface BLSAugmentedAnnotationViewCacheTests : XCTestCase

@property (nonatomic, strong) BLSAugmentedAnnotationViewCache *viewCache;
@property (nonatomic, strong) id annotationMock1;
@property (nonatomic, strong) id annotationViewMock1;
@property (nonatomic, strong) id annotationMock2;
@property (nonatomic, strong) id annotationViewMock2;

@end


@implementation BLSAugmentedAnnotationViewCacheTests

- (void)setUp {
    [super setUp];
    self.viewCache = [[BLSAugmentedAnnotationViewCache alloc] init];
    
    self.annotationMock1 = OCMProtocolMock(@protocol(BLSAugmentedAnnotation));
    self.annotationMock2 = OCMProtocolMock(@protocol(BLSAugmentedAnnotation));
    
    self.annotationViewMock1 = OCMClassMock([BLSAugmentedAnnotationView class]);
    self.annotationViewMock2 = OCMClassMock([BLSAugmentedAnnotationView class]);
    
    OCMStub([self.annotationViewMock1 reuseIdentifier]).andReturn(@"identifier1");
    OCMStub([self.annotationViewMock2 reuseIdentifier]).andReturn(@"identifier2");
    
    [self.viewCache useView:self.annotationViewMock1 forAnnotation:self.annotationMock1];
    [self.viewCache useView:self.annotationViewMock2 forAnnotation:self.annotationMock2];
}

- (void)testMethodsAcceptNil {
    XCTAssertNil([self.viewCache dequeueReusableAnnotationViewWithIdentifier:nil]);
    XCTAssertNil([self.viewCache visibleViewForAnnotation:nil]);
    XCTAssertNoThrow([self.viewCache removeViewForAnnotation:nil]);
    XCTAssertNoThrow([self.viewCache useView:nil forAnnotation:nil]);
}

- (void)testGetVisibleView {
    XCTAssertEqual([self.viewCache visibleViewForAnnotation:self.annotationMock1], self.annotationViewMock1);
    XCTAssertEqual([self.viewCache visibleViewForAnnotation:self.annotationMock2], self.annotationViewMock2);
}

- (void)testUseView {
    OCMVerify([self.viewCache.viewsInUse setObject:self.annotationViewMock1 forKey:@([self.annotationMock1 hash])]);
    OCMVerify([self.viewCache.viewsInUse setObject:self.annotationViewMock2 forKey:@([self.annotationMock2 hash])]);
}

- (void)testRemoveAndDequeueViews {
    XCTAssertNil([self.viewCache dequeueReusableAnnotationViewWithIdentifier:[self.annotationViewMock1 reuseIdentifier]]);
    [self.viewCache removeViewForAnnotation:self.annotationMock1];
    XCTAssertNil([self.viewCache visibleViewForAnnotation:self.annotationMock1]);
    OCMVerify([self.viewCache.reusableViews addObject:self.annotationViewMock1]);
    XCTAssertEqual([self.viewCache dequeueReusableAnnotationViewWithIdentifier:[self.annotationViewMock1 reuseIdentifier]], self.annotationViewMock1);
}

- (void)testClearUnusedViews {
    [self.viewCache removeViewForAnnotation:self.annotationMock1];
    [self.viewCache removeViewForAnnotation:self.annotationMock2];
    [self.viewCache clearUnusedViews];
    XCTAssertNil([self.viewCache dequeueReusableAnnotationViewWithIdentifier:[self.annotationViewMock1 reuseIdentifier]]);
    XCTAssertNil([self.viewCache dequeueReusableAnnotationViewWithIdentifier:[self.annotationViewMock2 reuseIdentifier]]);
}

@end
