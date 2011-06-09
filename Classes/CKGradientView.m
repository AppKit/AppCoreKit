//
//  CKUIGradientView.m
//  GroupedTableStyled
//
//  Created by Olivier Collet on 11-04-07.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKGradientView.h"
#import "CKUIColorAdditions.h"
#import "CKNSArrayAdditions.h"
#import "CKCompatibility.h"

#import <QuartzCore/QuartzCore.h>

@interface CKGradientView () 
@property(nonatomic,retain)UIColor* fillColor;
@end



@implementation CKGradientView

@synthesize gradientColors = _gradientColors;
@synthesize gradientColorLocations = _gradientColorLocations;
@synthesize fillColor = _fillColor;
@synthesize embossTopColor = _embossTopColor;
@synthesize embossBottomColor = _embossBottomColor;

- (void)postInit {
	self.fillColor = [UIColor clearColor];
}

- (id)init {
	self = [super init];
	if (self) {
		[self postInit];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self postInit];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self postInit];
	}
	return self;
}

//HACK to control how to paint using the background color !
- (void)setBackgroundColor:(UIColor *)color{
	self.fillColor = color;
	[super setBackgroundColor:[UIColor clearColor]];
}

- (void)dealloc {
	[_gradientColors release]; _gradientColors = nil;
	[_gradientColorLocations release]; _gradientColorLocations = nil;
	[_fillColor release]; _fillColor = nil;
	[_embossTopColor release]; _embossTopColor = nil;
	[_embossBottomColor release]; _embossBottomColor = nil;
	[super dealloc];
}

#pragma mark - Emboss Paths

- (CGMutablePathRef)topEmbossPath {
	CGFloat x = self.bounds.origin.x;
	CGFloat y = self.bounds.origin.y;
	CGFloat width = self.bounds.size.width;
	CGMutablePathRef path = CGPathCreateMutable ();
	
	CGPathMoveToPoint (path, nil, x, -1);
	CGPathAddLineToPoint (path, nil, x, y);
	CGPathAddLineToPoint (path, nil, width, y);
	CGPathAddLineToPoint (path, nil, width, -1);
	CGPathAddLineToPoint (path, nil, x, -1);
	
	CGPathCloseSubpath(path);
	return path;
}

- (CGMutablePathRef)bottomEmbossPath {
	CGFloat x = self.bounds.origin.x;
	CGFloat width = self.bounds.size.width;
	CGFloat height = self.bounds.size.height;
	CGMutablePathRef path = CGPathCreateMutable ();
	
	CGPathMoveToPoint(path, nil, x, self.bounds.size.height + 1);
	CGPathAddLineToPoint(path, nil, width, self.bounds.size.height + 1);
	CGPathAddLineToPoint (path, nil, width, height);
	CGPathAddLineToPoint (path, nil, x, height);
	CGPathAddLineToPoint(path, nil, x, self.bounds.size.height + 1);
	
	CGPathCloseSubpath(path);
	return path;
}

#pragma mark - drawRect

- (void)drawRect:(CGRect)rect {
	CGContextRef gc = UIGraphicsGetCurrentContext();
	
//	if(self.gradientColors == nil){
//		if(self.fillColor != nil){
//			[self.fillColor setFill];
//			CGContextFillPath(gc);
//		}
//		else{
//			[[UIColor clearColor] setFill];
//			CGContextFillPath(gc);
//		}
//	}
	
	
	// Gradient
	if(self.gradientColors){
		CGFloat colorLocations[self.gradientColorLocations.count];
		int i = 0;
		for (NSNumber *n in self.gradientColorLocations) {
			colorLocations[i++] = [n floatValue];
		}
		
		NSMutableArray *colors = [NSMutableArray array];
		for (UIColor *color in self.gradientColors) {
			[colors addObject:(id)([[color RGBColor]CGColor])];
		}
		
		CGGradientRef gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), (CFArrayRef)colors, colorLocations);
		CGContextDrawLinearGradient(gc, gradient, CGPointMake(0.0f, 0.0f), CGPointMake(0, self.bounds.size.height), 0);
	}
	
	// Top Emboss
	if (_embossTopColor && (_embossTopColor != [UIColor clearColor])) {
		CGContextSaveGState(gc);
		CGContextSetShadowWithColor(gc, CKShadowSizeMake(0, 1), 0, _embossTopColor.CGColor);
		CGContextAddPath(gc, [self topEmbossPath]);
		[[self.gradientColors objectAtIndex:0] setFill];
		CGContextFillPath(gc);
		CGContextRestoreGState(gc);
	}
	
	// Bottom Emboss
	if (_embossBottomColor && (_embossBottomColor != [UIColor clearColor])) {
		CGContextSaveGState(gc);
		CGContextSetShadowWithColor(gc, CKShadowSizeMake(0, -1), 0, _embossBottomColor.CGColor);
		CGContextAddPath(gc, [self bottomEmbossPath]);
		[[self.gradientColors last] setFill];
		CGContextFillPath(gc);
		CGContextRestoreGState(gc);
	}
}

@end
