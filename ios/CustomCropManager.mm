#import "CustomCropManager.h"
#import <React/RCTLog.h>

@implementation CustomCropManager

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(crop:(NSDictionary *)points imageUri:(NSString *)imageUri callback:(RCTResponseSenderBlock)callback)
{
    CFDataRef dataRef = (__bridge CFDataRef)[NSData dataWithContentsOfFile:imageUri];
    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData(dataRef);
    CGImageRef intialImageRef = CGImageCreateWithJPEGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
    CIImage *intialImage = [CIImage imageWithCGImage:intialImageRef];
    intialImage = [intialImage imageByApplyingOrientation:kCGImagePropertyOrientationRight];
    
    NSMutableDictionary *rectangleCoordinates = [NSMutableDictionary new];
    
    CGPoint topLeft = CGPointMake([points[@"topLeft"][@"x"] floatValue], [points[@"topLeft"][@"y"] floatValue]);
    CGPoint topRight = CGPointMake([points[@"topRight"][@"x"] floatValue], [points[@"topRight"][@"y"] floatValue]);
    CGPoint bottomLeft = CGPointMake([points[@"bottomLeft"][@"x"] floatValue], [points[@"bottomLeft"][@"y"] floatValue]);
    CGPoint bottomRight = CGPointMake([points[@"bottomRight"][@"x"] floatValue], [points[@"bottomRight"][@"y"] floatValue]);
    
    CGFloat height = intialImage.extent.size.height;
    topLeft = [self cartesianForPoint:topLeft height:height];
    topRight = [self cartesianForPoint:topRight height:height];
    bottomLeft = [self cartesianForPoint:bottomLeft height:height];
    bottomRight = [self cartesianForPoint:bottomRight height:height];

    rectangleCoordinates[@"inputTopLeft"] = [CIVector vectorWithCGPoint:topLeft];
    rectangleCoordinates[@"inputTopRight"] = [CIVector vectorWithCGPoint:topRight];
    rectangleCoordinates[@"inputBottomLeft"] = [CIVector vectorWithCGPoint:bottomLeft];
    rectangleCoordinates[@"inputBottomRight"] = [CIVector vectorWithCGPoint:bottomRight];

    CIImage * croppedImage = [intialImage imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:rectangleCoordinates];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef croppedref = [context createCGImage:croppedImage fromRect:[croppedImage extent]];
    UIImage *image = [UIImage imageWithCGImage:croppedref];
    
    NSData *imageToEncode = UIImageJPEGRepresentation(image, 0.8);
    callback(@[[NSNull null], @{@"image": [imageToEncode base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]}]);
    
    CGImageRelease(croppedref);
    CGImageRelease(intialImageRef);
}

- (CGPoint)cartesianForPoint:(CGPoint)point height:(float)height {
    return CGPointMake(point.x, height - point.y);
}

@end