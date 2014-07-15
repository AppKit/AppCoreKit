//
//  CKWebRequestProfileData.m
//  AppCoreKit
//
//  Created by Alexandre Hélie on 2014-07-14.
//  Copyright (c) 2014 WhereCloud Inc. All rights reserved.
//

#import "CKWebRequestProfileData.h"

@implementation CKWebRequestProfileData

+ (instancetype)profileDataForWebRequest:(CKWebRequest *)request
{
    CKWebRequestProfileData *profileData = [self new];
    profileData.url = request.URL;
    profileData.startDate = [NSDate date];
    
    return profileData;
}

- (void)requestDidFinish
{
    self.endDate = [NSDate date];
    self.duration = [_endDate timeIntervalSinceDate:_startDate];
}

- (NSString *)description
{
    NSString *string = [NSString stringWithFormat:@"Web Request URL : %@\n", _url];
    string = [NSString stringWithFormat:@"%@Start time : %@\n", string, _startDate];
    string = [NSString stringWithFormat:@"%@End time : %@\n", string, _endDate];
    string = [NSString stringWithFormat:@"%@Duration : %.3f\n", string, _duration];
    
    return string;
}

@end
