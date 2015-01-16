# BLSAugmentedController
BLS Augmented reality view controller for iOS, part of Patronage 2015 project.


# Installation

1. Download this repository.
2. Switch scheme to the "Framework" and build.
3. Copy the BLSAugmentedController.framework from desktop to your project.


# Usage Example

1. Create an instance and add it's view as subview or use a storyboard:

```objective-c
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"BLSAugmentedViewController"]) {
        self.augmentedViewController = segue.destinationViewController;
    }
}
```

3. Setup the delegate and add some annotations:

```objective-c
self.augmentedViewController.delegate = self;
[self.augmentedViewController addAnnotations:annotations];
```

4. Implement delegate method:

```objective-c
- (BLSAugmentedAnnotationView *)augmentedViewController:(BLSAugmentedViewController *)augmentedViewController viewForAnnotation:(id<BLSAugmentedAnnotation>)annotation forUserLocation:(CLLocation *)location distance:(CLLocationDistance)distance{
    BLSAugmentedAnnotationView *view = [augmentedViewController dequeueReusableAnnotationViewWithIdentifier:demoAnnotation.type];
    if (view == nil) {
        view = [[BLSAugmentedAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:demoAnnotation.type];
    } else {
        view.annotation = annotation;
    }
    view.image = [UIImage imageNamed:@"myImage"];
    return view;
}
```


# Known Issues

1. Compass measurements lack stabilization when while device is rotating around an axis that runs vertically through the device.
2. Unit tests are incomplete.
