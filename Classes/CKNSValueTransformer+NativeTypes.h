//
//  CKNSValueTransformer+NativeTypes.h
//  CloudKit
//
//  Created by Sebastien Morel on 11-08-11.
//  Copyright 2011 Wherecloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CKEnumDescriptor : NSObject{}
@property(nonatomic,assign)BOOL isBitMask;
@property(nonatomic,retain)NSString* name;
@property(nonatomic,retain)NSDictionary* valuesAndLabels;
@end


/** TODO
 */
CKEnumDescriptor* CKEnumDefinitionFunc(NSString* name,BOOL bitmask, NSString* strValues, ...);

/** TODO
 */
#define CKEnumDefinition(name,...) CKEnumDefinitionFunc(name,NO,[NSString stringWithUTF8String:#__VA_ARGS__],__VA_ARGS__)
#define CKBitMaskDefinition(name,...) CKEnumDefinitionFunc(name,YES,[NSString stringWithUTF8String:#__VA_ARGS__],__VA_ARGS__)

@interface NSValueTransformer (CKNativeTypes)

+ (NSInteger)convertEnumFromObject:(id)object withEnumDescriptor:(CKEnumDescriptor*)enumDefinition bitMask:(BOOL)bitMask;
+ (NSString*)convertEnumToString:(NSInteger)value withEnumDescriptor:(CKEnumDescriptor*)enumDefinition bitMask:(BOOL)bitMask;

+ (char)convertCharFromObject:(id)object;
+ (NSInteger)convertIntegerFromObject:(id)object;
+ (short)convertShortFromObject:(id)object;
+ (long)convertLongFromObject:(id)object;
+ (long long)convertLongLongFromObject:(id)object;
+ (unsigned char)convertUnsignedCharFromObject:(id)object;
+ (NSUInteger)convertUnsignedIntFromObject:(id)object;
+ (unsigned short)convertUnsignedShortFromObject:(id)object;
+ (unsigned long)convertUnsignedLongFromObject:(id)object;
+ (unsigned long long)convertUnsignedLongLongFromObject:(id)object;
+ (CGFloat)convertFloatFromObject:(id)object;
+ (double)convertDoubleFromObject:(id)object;
+ (BOOL)convertBoolFromObject:(id)object;
+ (Class)convertClassFromObject:(id)object;
+ (SEL)convertSelectorFromObject:(id)object;

@end