//
//  CKUIBarButtonItem+Introspection.m
//  CloudKit
//
//  Created by Sebastien Morel on 11-09-07.
//  Copyright 2011 Wherecloud. All rights reserved.
//

#import "CKUIBarButtonItem+Introspection.h"
#import "CKNSValueTransformer+Additions.h"
#import "CKPropertyExtendedAttributes+CKAttributes.h"


@implementation UIBarButtonItem (CKIntrospectionAdditions)

- (void)styleExtendedAttributes:(CKPropertyExtendedAttributes*)attributes{
    attributes.enumDescriptor = CKEnumDefinition(@"UIBarButtonItemStyle", 
                                               UIBarButtonItemStylePlain,
                                               UIBarButtonItemStyleBordered,
                                               UIBarButtonItemStyleDone);
}

@end