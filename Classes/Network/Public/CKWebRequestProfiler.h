//
//  CKWebRequestProfiler.h
//  AppCoreKit
//
//  Created by Alexandre Hélie on 2014-07-14.
//  Copyright (c) 2014 WhereCloud Inc. All rights reserved.
//

#ifdef DEBUG

#import <AppCoreKit/AppCoreKit.h>
#import "CKWebRequestProfileData.h"

@interface CKWebRequestProfiler : CKObject

//Array containing instances of CKWebRequestProfileData
+ (NSArray *)profilingData;

//Returns profiling log for API calls made to specified path
//If path is nil, the entire profiling log is returned
+ (NSString *)dataStringForCallsWithPath:(NSString *)path;

@end

#endif