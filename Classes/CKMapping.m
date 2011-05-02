//
//  NFBDataSourceMapper.m
//  NFB
//
//  Created by Sebastien Morel on 11-02-24.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKMapping.h"
#import "CKNSString+Parsing.h"
#import "RegexKitLite.h"
#import "CKDebug.h"
#import <objc/runtime.h>
#import "CKNSDate+Conversions.h"


#define DebugLog 0

@implementation CKMapping
@synthesize key;
@synthesize mapperBlock;
@synthesize policy;
@synthesize transformerClass;

- (void)dealloc{
	self.key = nil;
	self.mapperBlock = nil;
	self.transformerClass = nil;
	[super dealloc];
}

- (NSValueTransformer*)valueTransformer{
	if(transformerClass == nil)
		return nil;
	
	NSString* className = [NSString stringWithUTF8String:class_getName(transformerClass)];
	NSValueTransformer * transformer = [NSValueTransformer valueTransformerForName:className];
	if(transformer == nil){
		transformer = [[transformerClass alloc]init];
		[NSValueTransformer setValueTransformer:transformer forName:className];
	}
	return transformer;
}

@end

//

@implementation CKCustomMapping
@synthesize mapperBlock;

- (void)dealloc{
	self.mapperBlock = nil;
	[super dealloc];
}

@end

//

@implementation NSObject (CKMapping)

- (id)initWithDictionary:(NSDictionary*)sourceDictionary withMappings:(NSMutableDictionary*)mappings error:(NSError**)error{
	[self init];
	[self mapWithDictionary:sourceDictionary withMappings:mappings error:error];
	return self;
}

- (void)mapWithDictionary:(NSDictionary*)sourceDictionary withMappings:(NSMutableDictionary*)mappings error:(NSError**)error{
	if(![sourceDictionary isKindOfClass:[NSDictionary class]]){
		//TODO : fill error
		if(DebugLog){
			CKDebugLog(@"source for mapping is not a dictionary but a %@ when mapping on object %@",sourceDictionary,self);
		}
		return;
	}
	
	for (id key in mappings) {
		id obj = [mappings objectForKey:key];
		NSAssert(([obj isKindOfClass:[CKMapping class]] || [obj isKindOfClass:[CKCustomMapping class]]),@"The mapper object is not a CKMapping");
		NSAssert([key isKindOfClass:[NSString class]],@"The mapper key is not a string");

		if ([obj isKindOfClass:[CKMapping class]]) {
			CKMapping* mappingObject = (CKMapping*)obj;
			id sourceObject = [sourceDictionary valueForKeyPath:mappingObject.key];
			if(sourceObject == nil){
				//TODO : fill error
				if(DebugLog){
					CKDebugLog(@"Could not find %@ key in source\n",mappingObject.key);
				}
				if(mappingObject.policy == CKMappingPolicyRequired){
					NSAssert(NO,@"Field %@ not found in dataSource for object %@",mappingObject.key,self);
				}
			}
			else{
				NSValueTransformer* valueTransformer = [mappingObject valueTransformer];
				if(valueTransformer){
					id transformedValue = [valueTransformer transformedValue:sourceObject];
					[self setValue:transformedValue forKeyPath:key];
				}
				else{
					mappingObject.mapperBlock(sourceObject,self,key,error);
				}
			}
		}
		if ([obj isKindOfClass:[CKCustomMapping class]]) {
			CKCustomMapping *mappingObject = (CKCustomMapping *)obj;
			id value = mappingObject.mapperBlock(sourceDictionary, error);
			if (value) [self setValue:value forKeyPath:key];
		}
	}
}

@end

//CKNSStringToNSURLTransformer
@interface      CKNSStringToNSURLTransformer : NSValueTransformer {} @end
@implementation CKNSStringToNSURLTransformer
+ (Class)transformedValueClass { return [NSURL class]; }
- (id)transformedValue:(id)value { return  [NSURL URLWithString:[(NSString*)value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]; }
@end

//CKNSStringToNSURLTransformer
@interface      CKNSStringToHttpNSURLTransformer : NSValueTransformer {} @end
@implementation CKNSStringToHttpNSURLTransformer
+ (Class)transformedValueClass { return [NSURL class]; }
- (id)transformedValue:(id)value { 
	NSURL* url = [NSURL URLWithString:[(NSString*)value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if([[url scheme] isMatchedByRegex:@"^(http|https)$"]){
		return url;
	}
	else{
		if(DebugLog){
			CKDebugLog(@"%@ is not an httpUrl",url);
		}
	}
	return nil;
}
@end

//CKNSStringToNSStringTransformer
@interface      CKNSStringToNSStringTransformer : NSValueTransformer {} @end
@implementation CKNSStringToNSStringTransformer
+ (Class)transformedValueClass { return [NSString class]; }
- (id)transformedValue:(id)value { return (NSString*)value; }
@end

//CKNSStringToNSStringWithoutHTMLTransformer
@interface      CKNSStringToNSStringWithoutHTMLTransformer : NSValueTransformer {} @end
@implementation CKNSStringToNSStringWithoutHTMLTransformer
+ (Class)transformedValueClass { return [NSString class]; }
- (id)transformedValue:(id)value { return [(NSString*)value stringByDeletingHTMLTags]; }
@end

//CKNSStringToTrimmedNSStringTransformer
@interface      CKNSStringToTrimmedNSStringTransformer : NSValueTransformer {} @end
@implementation CKNSStringToTrimmedNSStringTransformer
+ (Class)transformedValueClass { return [NSString class]; }
- (id)transformedValue:(id)value { return [(NSString*)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; }
@end

//CKNSStringToIntTransformer
@interface      CKNSStringToIntTransformer : NSValueTransformer {} @end
@implementation CKNSStringToIntTransformer
+ (Class)transformedValueClass { return [NSNumber class]; }
- (id)transformedValue:(id)value { 
	NSInteger i = [value intValue];
	return [NSNumber numberWithInt:i]; }
@end

//CKNSStringToIntTransformer
@interface      CKNSStringToDateTransformer : NSValueTransformer {} @end
@implementation CKNSStringToDateTransformer
+ (Class)transformedValueClass { return [NSString class]; }
- (id)transformedValue:(id)value { 
	if ([value isKindOfClass:[NSString class]] == NO) return nil;
	NSString* strDate = value;
	return [NSDate dateFromString:strDate withDateFormat:@"yyyy-MM-dd"];
}
@end

@implementation NSMutableDictionary (CKMapping)

- (void)mapKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo withBlock:(CKMappingBlock)block{
	CKMapping* mapperObject = [[[CKMapping alloc]init]autorelease];
	mapperObject.key = keyPath;
	mapperObject.mapperBlock = block;
	mapperObject.policy = bo ? CKMappingPolicyRequired : CKMappingPolicyOptional;
	[self setObject:mapperObject forKey:destination];
}

- (void)mapKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo withValueTransformerClass:(Class)valueTransformerClass{
	CKMapping* mapperObject = [[[CKMapping alloc]init]autorelease];
	mapperObject.key = keyPath;
	mapperObject.transformerClass = valueTransformerClass;
	mapperObject.policy = bo ? CKMappingPolicyRequired : CKMappingPolicyOptional;
	[self setObject:mapperObject forKey:destination];
}

- (void)mapKeyPath:(NSString *)keyPath withValueFromBlock:(CKCustomMappingBlock)block {
	CKCustomMapping* mapperObject = [[[CKCustomMapping alloc] init] autorelease];
	mapperObject.mapperBlock = block;
	[self setObject:mapperObject forKey:keyPath];
}

- (void)mapURLForKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo{
	[self mapKeyPath:keyPath toKeyPath:destination required:bo withValueTransformerClass:[CKNSStringToNSURLTransformer class]];
}

- (void)mapHttpURLForKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo{
	[self mapKeyPath:keyPath toKeyPath:destination required:bo withValueTransformerClass:[CKNSStringToHttpNSURLTransformer class]];
}

- (void)mapStringForKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo{
	[self mapKeyPath:keyPath toKeyPath:destination required:bo withValueTransformerClass:[CKNSStringToNSStringTransformer class]];
}

- (void)mapStringWithoutHTMLForKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo{
	[self mapKeyPath:keyPath toKeyPath:destination required:bo withValueTransformerClass:[CKNSStringToNSStringWithoutHTMLTransformer class]];
}

- (void)mapTrimmedStringForKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo{
	[self mapKeyPath:keyPath toKeyPath:destination required:bo withValueTransformerClass:[CKNSStringToTrimmedNSStringTransformer class]];
}

- (void)mapIntForKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo{
	[self mapKeyPath:keyPath toKeyPath:destination required:bo withValueTransformerClass:[CKNSStringToIntTransformer class]];
}

- (void)mapDateForKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo{
	[self mapKeyPath:keyPath toKeyPath:destination required:bo withValueTransformerClass:[CKNSStringToDateTransformer class]];
}

@end