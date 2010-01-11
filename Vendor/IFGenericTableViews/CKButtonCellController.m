//
//  CKButtonCellController.m
//  CloudKit
//
//  Created by Olivier Collet on 10-01-11.
//  Copyright 2010 WhereCloud Inc. All rights reserved.
//

#import "CKButtonCellController.h"


@implementation CKButtonCellController

- (id)initWithLabel:(NSString *)newLabel withAction:(SEL)newAction onTarget:(id)newTarget {
	self = [super init];
	if (self != nil) {
		label = [newLabel retain];
		self.target = newTarget;
		self.action = newAction;
	}
	return self;
}

- (void)dealloc {
	[label release];
	
	[super dealloc];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    UITableViewCell *cell = [self tableView:tableView cellWithStyle:UITableViewCellStyleDefault];

	cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0f];
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.textLabel.textColor = [UIColor colorWithRed:82.0/255.0 green:102.0/255.0 blue:145.0/255.0 alpha:1.0];
	cell.textLabel.text = label;

    return cell;
}

@end
