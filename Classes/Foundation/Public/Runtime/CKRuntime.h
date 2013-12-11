//
//  CKRuntime.h
//  AppCoreKit
//
//  Created by Sebastien Morel.
//  Copyright (c) 2011 WhereCloud Inc. All rights reserved.
//

#import "CKClassPropertyDescriptor.h"

#ifdef __cplusplus
extern "C" {
#endif
    
    /**
     */
    void CKSwizzleSelector(Class c,SEL selector, SEL newSelector);
    
    /**
     */
    void CKSwizzleClassSelector(Class c,SEL selector, SEL newSelector);

    
#ifdef __cplusplus
}
#endif