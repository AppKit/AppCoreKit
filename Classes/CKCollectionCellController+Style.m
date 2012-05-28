//
//  CKCollectionCellController+Style.m
//  CloudKit
//
//  Created by Sebastien Morel on 11-04-27.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKCollectionCellController+Style.h"
#import "CKStyleManager.h"
#import "CKStyle+Parsing.h"
#import "CKLocalization.h"

NSString* CKStyleNoItemsMessage = @"noItemsMessage";
NSString* CKStyleOneItemMessage = @"oneItemMessage";
NSString* CKStyleManyItemsMessage = @"manyItemsMessage";
NSString* CKStyleIndicatorStyle = @"indicatorStyle";

@implementation NSMutableDictionary (CKCollectionCellControllerStyle)

- (NSString*)noItemsMessage{
	NSString* str = [self stringForKey:CKStyleNoItemsMessage];
    if(str) return str;
    return _(@"No results");
}

- (NSString*)oneItemMessage{
	NSString* str = [self stringForKey:CKStyleOneItemMessage];
    if(str) return str;
    return _(@"1 result");
}

- (NSString*)manyItemsMessage{
	NSString* str = [self stringForKey:CKStyleManyItemsMessage];
    if(str) return str;
    return _(@"%d results");
}

- (UIActivityIndicatorViewStyle)indicatorStyle{
    if([self containsObjectForKey:CKStyleIndicatorStyle]){
        return (UIActivityIndicatorViewStyle)[self enumValueForKey:CKStyleIndicatorStyle 
												withEnumDescriptor:CKEnumDefinition(@"UIActivityIndicatorViewStyle",
                                                                                    UIActivityIndicatorViewStyleWhiteLarge,
                                                                                    UIActivityIndicatorViewStyleWhite,
                                                                                    UIActivityIndicatorViewStyleGray		
                                                                                    )];
    }
    return UIActivityIndicatorViewStyleGray;
}

@end
