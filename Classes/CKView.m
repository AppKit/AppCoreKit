//
//  CKNibViewController.m
//  NFB
//
//  Created by Sebastien Morel on 11-01-26.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKView.h"
#import <CloudKit/CKConstants.h>
#import <QuartzCore/QuartzCore.h>

@implementation CKViewTemplate
@synthesize viewCreationBlock;
@synthesize viewSetupBlock;

-(void)dealloc{
	self.viewSetupBlock = nil;
	self.viewCreationBlock = nil;
	[super dealloc];
}

@end


@interface CKView ()
@property (nonatomic, retain) NSMutableArray *internal;
@property (nonatomic, retain) UIView *subView;
-(void)createInternalView;
@end

@implementation CKView
@synthesize internal;
@synthesize viewTemplate;
@synthesize subView;


-(void)dealloc{
	NSLog(@"CKView dealloc");
	[self unbind];
	[viewTemplate release];
	viewTemplate = nil;
	self.subView = nil;
	[super dealloc];
}

-(void)unbind{
	for(id object in self.internal){
		if([object respondsToSelector:@selector(unbind)]){
			[object unbind];
		}
	}
	
	self.internal = nil;//delete previous setup objects
	
}

- (void)addObject:(id)object{
	NSAssert(self.internal != nil, @"Try to insert an object outside the setupBlock");
	[self.internal addObject:object];
}

-(void)setViewTemplate:(CKViewTemplate*)template{
	[viewTemplate release];
	viewTemplate = [template retain];
	[self unbind];
	[self createInternalView];
}

-(void)bind:(id)object{
	if(viewTemplate){
		[self unbind];
		self.internal = [NSMutableArray array];
		viewTemplate.viewSetupBlock(self.subView,object,self);
	}
}

-(void)createInternalView{
	if(self.subView != nil){
		[subView removeFromSuperview];
		self.subView = nil;
	}
	
	if(viewTemplate){
		self.subView = viewTemplate.viewCreationBlock();
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth |  UIViewAutoresizingFlexibleHeight;
		self.subView.autoresizingMask = UIViewAutoresizingFlexibleWidth |  UIViewAutoresizingFlexibleHeight;
		[self addSubview:self.subView];
	}
}

- (void)layoutSubviews{
	[super layoutSubviews];
	self.subView.frame = self.bounds;
}

@end

@implementation UIView (Snapshot)

- (UIImage*)snapshot{
	UIGraphicsBeginImageContext(self.bounds.size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[self.layer renderInContext:ctx];
	UIImage* image  = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

@end
