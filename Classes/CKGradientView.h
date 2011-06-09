//
//  CKUIGradientView.h
//  GroupedTableStyled
//
//  Created by Olivier Collet on 11-04-07.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//


@interface CKGradientView : UIView {
	NSArray *_gradientColors;
	NSArray *_gradientColorLocations;

	UIColor* _fillColor;
	UIColor *_embossTopColor;
	UIColor *_embossBottomColor;
}

@property (nonatomic, retain) NSArray *gradientColors;
@property (nonatomic, retain) NSArray *gradientColorLocations;
@property (nonatomic, retain) UIColor *embossTopColor;
@property (nonatomic, retain) UIColor *embossBottomColor;

@end
