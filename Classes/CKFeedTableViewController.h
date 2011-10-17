//
//  CKFeedTableViewController.h
//  NFB
//
//  Created by Sebastien Morel on 11-03-23.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKObjectTableViewController.h"
#import "CKFeedSource.h"


@interface CKFeedTableViewController : CKObjectTableViewController {
	CKFeedSource* _feedSource;
	NSString* _emptyMessage;
}

@property (nonatomic, retain) CKFeedSource *feedSource;
@property (nonatomic, retain) NSString *emptyMessage;

- (id)initWithFeedSource:(CKFeedSource*)source mappings:(NSDictionary*)mappings styles:(NSDictionary*)styles;
- (void)setFeedSource:(CKFeedSource*)source mappings:(NSDictionary*)mappings styles:(NSDictionary*)styles;

@end
