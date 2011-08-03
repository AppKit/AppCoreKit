//
//  CKNSObject+JSON.h
//  CloudKit
//
//  Created by Fred Brunel on 11-01-10.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (CKNSObjectJSON) 

- (id)JSONRepresentation;

+ (id)objectFromJSONData:(NSData *)data;
+ (id)objectFromJSONData:(NSData *)data error:(NSError **)error;

@end
