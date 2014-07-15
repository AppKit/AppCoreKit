//
//  CKWebRequestProfileData.h
//  AppCoreKit
//
//  Created by Alexandre Hélie on 2014-07-14.
//  Copyright (c) 2014 WhereCloud Inc. All rights reserved.
//

#import <AppCoreKit/AppCoreKit.h>

@interface CKWebRequestProfileData : CKObject

+ (instancetype)profileDataForWebRequest:(CKWebRequest *)request;
- (void)requestDidFinish;

@property (nonatomic, weak) CKWebRequest *request;

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, assign) NSTimeInterval duration;

@end
