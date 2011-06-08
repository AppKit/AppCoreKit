//
//  CKUIColorAdditions.m
//  CloudKit
//
//  Created by Fred Brunel on 10-02-12.
//  Copyright 2010 WhereCloud Inc. All rights reserved.
//

#import "CKUIColorAdditions.h"

@implementation UIColor (CKUIColorAdditions)

+ (UIColor *)colorWithRGBValue:(NSUInteger)value {
	return [UIColor colorWithRed:((value & 0xFF0000) >> 16) / 255.0
						   green:((value & 0xFF00) >> 8) / 255.0
							blue:(value & 0xFF) / 255.0
						   alpha:1.0];
}

+ (UIColor *)blueTextColor {
	return [UIColor colorWithRGBValue:0x385487];
}

- (UIColor *)RGBColor {
	CGColorSpaceModel model = CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
	
	switch (model) {
		case kCGColorSpaceModelRGB:
			return self;
			break;
		case kCGColorSpaceModelMonochrome: {
			const CGFloat *comps = CGColorGetComponents(self.CGColor);
			return [UIColor colorWithRed:comps[0] green:comps[0] blue:comps[0] alpha:comps[1]];
			break;
		}
			
		default:
			NSAssert(FALSE, @"CGColorSpaceModel (%d) not supported.", model);
			break;
	}	
	
	return nil;
}

@end
