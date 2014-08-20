//
//  CKWebRequestProfiler.m
//  AppCoreKit
//
//  Created by Alexandre Hélie on 2014-07-14.
//  Copyright (c) 2014 WhereCloud Inc. All rights reserved.
//

#ifdef DEBUG

#import "CKWebRequestProfiler.h"
#import <objc/runtime.h>

@implementation CKWebRequestProfiler

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //Create "class variable" containing array with web request profiling objects
        objc_setAssociatedObject(self, "dataArray", [NSMutableArray array], OBJC_ASSOCIATION_RETAIN);
        
        //Obtain IMP of CKWebRequest launch method
        SEL startSelector = @selector(startOnRunLoop:);
        Method startOnRunLoop = class_getInstanceMethod([CKWebRequest class], startSelector);
        IMP startMethodImp = method_getImplementation(startOnRunLoop);
        
        //Typecast to void return type so ARC does not attempt to retain a return value
        void (*startFunctionPtr)(id, SEL, ...) = (void (*)(id, SEL, ...))startMethodImp;
        
        //Add creation of profiling data on request launch and glue it on the request, then call original implementation
        IMP newStartImp = imp_implementationWithBlock(^(id self, NSRunLoop *runLoop) {
            CKWebRequest *request = (CKWebRequest *)self;
            CKWebRequestProfileData *profileData = [CKWebRequestProfileData profileDataForWebRequest:request];
            objc_setAssociatedObject(request, "profileData", profileData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            startFunctionPtr(self, startSelector, runLoop);
        });
        
        method_setImplementation(startOnRunLoop, newStartImp);
        
        //Obtain IMP of CKWebRequestManager request completion method
        SEL finishSelector = @selector(requestDidFinish:);
        Method requestDidFinish = class_getInstanceMethod([CKWebRequestManager class], finishSelector);
        IMP endMethodImp = method_getImplementation(requestDidFinish);
        void (*endFunctionPtr)(id, SEL, ...) = (void (*)(id, SEL, ...))endMethodImp;
        
        //Notify request's profiling data object of completion and add it to array
        IMP newEndImp = imp_implementationWithBlock(^(id self, CKWebRequest *request) {
            endFunctionPtr(self, finishSelector, request);
            
            CKWebRequestProfileData *profileData = objc_getAssociatedObject(request, "profileData");
            [profileData requestDidFinish];
            [objc_getAssociatedObject(objc_getClass("CKWebRequestProfiler"), "dataArray") addObject:profileData];
        });
        
        method_setImplementation(requestDidFinish, newEndImp);
    });
}

#pragma clang diagnostic pop

+ (NSArray *)profilingData {
    return [objc_getAssociatedObject(self, "dataArray") copy];
}

+ (NSString *)dataStringForCallsWithPath:(NSString *)path
{
    NSArray *dataArray = objc_getAssociatedObject(self, "dataArray");
    
    if(path)
    {
        NSPredicate *pathPredicate = [NSPredicate predicateWithFormat:@"url.path == %@", path];
        NSArray *filteredArray = [dataArray filteredArrayUsingPredicate:pathPredicate];
        return [self ck_dataStringForArray:filteredArray];
    }
    else
        return [self ck_dataStringForArray:dataArray];
}

+ (NSString *)ck_dataStringForArray:(NSArray *)array
{
    if(!array.count)
        return @"No Profiling Data";
    
    NSString *string = @"Web Request Profiling Data:\n";
    
    for(CKWebRequestProfileData *profileData in array)
        string = [NSString stringWithFormat:@"%@\n\n%@", string, profileData];
    
    return string;
}

@end

#endif