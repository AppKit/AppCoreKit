 //
//  CKRuntime.m
//  AppCoreKit
//
//  Created by Sebastien Morel.
//  Copyright (c) 2011 WhereCloud Inc. All rights reserved.
//

#import "CKRuntime.h"
#import "NSObject+Runtime.h"
#import "CKClassPropertyDescriptor_private.h"
#import <objc/runtime.h>
#import "CKVersion.h"

static char NSObjectRuntimePropertiesObjectKey;

//Private methods Declaration

void CKSwizzleSelector(Class c,SEL selector, SEL newSelector){
	Method origMethod = class_getInstanceMethod(c, selector);
    Method newMethod = class_getInstanceMethod(c, newSelector);
	
    if (class_addMethod(c, selector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(c, newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }
    else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

void CKSwizzleClassSelector(Class c,SEL selector, SEL newSelector){
	Method origMethod = class_getClassMethod(c, selector);
    Method newMethod = class_getClassMethod(c, newSelector);
	
    method_exchangeImplementations(origMethod, newMethod);
}