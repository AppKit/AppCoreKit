//
//  CKStringHelper.m
//  AppCoreKit
//
//  Created by Sebastien Morel on 2013-10-03.
//  Copyright (c) 2013 Wherecloud. All rights reserved.
//

#import "CKStringHelper.h"
#import "CKVersion.h"

@implementation CKStringHelper 

+ (CGSize)sizeForText:(NSString*)text font:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode{
    if(!text || !font){
        return CGSizeMake(0,0);
    }
    
    return [text sizeWithFont:font constrainedToSize:size lineBreakMode:lineBreakMode];
}


@end
