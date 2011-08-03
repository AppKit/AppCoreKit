//
//  NFBDataSourceMapper.m
//  NFB
//
//  Created by Sebastien Morel on 11-02-24.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKNSDictionary+Mappings.h"
#import "CKNSString+Parsing.h"
#import "RegexKitLite.h"
#import "CKDebug.h"
#import <objc/runtime.h>
#import "CKNSDate+Conversions.h"
#import "CKDocumentCollection.h"
#import "CKNSObject+Introspection.h"
#import "CKNSValueTransformer+Additions.h"


/** TODO
 */
typedef enum{
	CKMappingPolicyRequired,
	CKMappingPolicyOptional
}CKMappingPolicy;



/** TODO
 */
@interface CKMappingPrivate : NSObject{
	NSString* key;
	CKMappingBlock mapperBlock;
	CKMappingPolicy policy;
	Class transformerClass;
}

@property (nonatomic, retain) NSString *key;
@property (nonatomic, copy) CKMappingBlock mapperBlock;
@property (nonatomic, assign) CKMappingPolicy policy;
@property (nonatomic, assign) Class transformerClass;

- (NSValueTransformer*)valueTransformer;

@end

//



/** TODO
 */
@interface CKCustomMapping : NSObject {
	CKCustomMappingBlock mapperBlock;
}

@property (nonatomic, copy) CKCustomMappingBlock mapperBlock;

@end


/** TODO
 */
@interface CKObjectMapping : NSObject {
	NSString* key;
	Class objectClass;
	NSMutableDictionary* mappings;
	CKMappingPolicy policy;
}

@property (nonatomic, retain) NSString* key;
@property (nonatomic, retain) NSMutableDictionary* mappings;
@property (nonatomic, assign) Class objectClass;
@property (nonatomic, assign) CKMappingPolicy policy;

@end


#define DebugLog 0

@implementation CKMappingPrivate
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

@implementation CKObjectMapping
@synthesize key,mappings,objectClass,policy;

- (void)dealloc{
	self.key = nil;
	self.mappings = nil;
	self.objectClass = nil;
	[super dealloc];
}

@end

//





@implementation NSObject (CKMapping_DEPRECATED_IN_CLOUDKIT_VERSION_1_7_AND_LATER)

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
		NSAssert(([obj isKindOfClass:[CKMappingPrivate class]] || [obj isKindOfClass:[CKCustomMapping class]] || [obj isKindOfClass:[CKObjectMapping class]]),@"The mapper object is not a CKMapping");
		NSAssert([key isKindOfClass:[NSString class]],@"The mapper key is not a string");

		if ([obj isKindOfClass:[CKMappingPrivate class]]) {
			CKMappingPrivate* mappingObject = (CKMappingPrivate*)obj;
			id sourceObject = [sourceDictionary valueForKeyPath:mappingObject.key];
			if(sourceObject == nil){
				//TODO : fill error
				if(DebugLog){
					CKDebugLog(@"Could not find %@ key in source\n",mappingObject.key);
				}
				if(mappingObject.policy == CKMappingPolicyRequired){
					NSAssert(NO,@"Field %@ not found in dataSource for object %@",mappingObject.key,sourceDictionary);
				}
			}
			else{
				if([sourceObject isKindOfClass:[NSNull class]] == NO){
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
		}
		else if ([obj isKindOfClass:[CKCustomMapping class]]) {
			CKCustomMapping *mappingObject = (CKCustomMapping *)obj;
			id value = mappingObject.mapperBlock(sourceDictionary, error);
			if (value) [self setValue:value forKeyPath:key];
		}
		else if ([obj isKindOfClass:[CKObjectMapping class]]) {
			CKObjectMapping *mappingObject = (CKObjectMapping *)obj;
			id sourceObject = [sourceDictionary valueForKeyPath:mappingObject.key];
			if(sourceObject == nil){
				//TODO : fill error
				if(DebugLog){
					CKDebugLog(@"Could not find %@ key in source\n",mappingObject.key);
				}
				if(mappingObject.policy == CKMappingPolicyRequired){
					NSAssert(NO,@"Field %@ not found in dataSource for object %@",mappingObject.key,sourceDictionary);
				}
			}
			else{
				id target = [self valueForKeyPath:key];
				CKClassPropertyDescriptor* descriptor = [self propertyDescriptorForKeyPath:key];
				if([NSObject isKindOf:descriptor.type parentType:[CKDocumentCollection class]]
				   ||[NSObject isKindOf:descriptor.type parentType:[NSArray class]]){
					NSAssert([sourceObject isKindOfClass:[NSArray class]],@"trying to map a non array object as array");
					NSMutableArray *items = [NSMutableArray array];
					for (NSDictionary *d in sourceObject) {
						id object = [[[mappingObject.objectClass alloc] initWithDictionary:d withMappings:mappingObject.mappings error:error] autorelease];
						[items addObject:object];
					}
					
					if([target isKindOfClass:[CKDocumentCollection class]]){
						CKDocumentCollection* collection = (CKDocumentCollection*)target;
						[collection removeAllObjects];
						[collection addObjectsFromArray:items];
					}
					else {
						if([NSObject isKindOf:descriptor.type parentType:[NSArray class]]){
							[self setValue:items forKeyPath:key];
						}
					}
				}
				else if([NSObject isKindOf:descriptor.type parentType:[NSObject class]]){
					id object = [[[mappingObject.objectClass alloc] initWithDictionary:sourceObject withMappings:mappingObject.mappings error:error] autorelease];
					[self setValue:object forKeyPath:key];
				}
			}
		}
	}
}

@end


@implementation NSMutableArray (CKMapping_DEPRECATED_IN_CLOUDKIT_VERSION_1_7_AND_LATER)

- (void)mapWithDictionary:(NSDictionary*)sourceDictionary keyPath:(NSString*)keyPath objectClass:(Class)objectClass withMappings:(NSMutableDictionary*)mappings error:(NSError**)error{
	if(![sourceDictionary isKindOfClass:[NSDictionary class]]){
		//TODO : fill error
		if(DebugLog){
			CKDebugLog(@"source for mapping is not a dictionary but a %@ when mapping on object %@",sourceDictionary,self);
		}
		return;
	}
	
	id sourceObject = [sourceDictionary valueForKeyPath:keyPath];
	if(sourceObject == nil){
		//TODO : fill error
		if(DebugLog){
			CKDebugLog(@"Could not find %@ key in source\n",keyPath);
		}
	}
	else{
		NSAssert([sourceObject isKindOfClass:[NSArray class]],@"trying to map a non array object as array");
		
		for (NSDictionary *d in sourceObject) {
			id object = [[[objectClass alloc] initWithDictionary:d withMappings:mappings error:error] autorelease];
			[self addObject:object];
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
- (id)transformedValue:(id)value { 
	return [NSValueTransformer transform:value toClass:[NSString class]];
}
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
	if(value == nil || [value isKindOfClass:[NSNull class]] == YES)
		return [NSNumber numberWithInt:0];
	
	NSInteger i = [value intValue];
	return [NSNumber numberWithInt:i]; 
}
@end

//CKNSStringToFloatTransformer
@interface      CKNSStringToFloatTransformer : NSValueTransformer {} @end
@implementation CKNSStringToFloatTransformer
+ (Class)transformedValueClass { return [NSNumber class]; }
- (id)transformedValue:(id)value { 
	CGFloat f = [value floatValue];
	return [NSNumber numberWithFloat:f]; 
}
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

@implementation NSMutableDictionary (CKMapping_DEPRECATED_IN_CLOUDKIT_VERSION_1_7_AND_LATER)

- (void)mapKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo withBlock:(CKMappingBlock)block{
	CKMappingPrivate* mapperObject = [[[CKMappingPrivate alloc]init]autorelease];
	mapperObject.key = keyPath;
	mapperObject.mapperBlock = block;
	mapperObject.policy = (bo == YES) ? CKMappingPolicyRequired : CKMappingPolicyOptional;
	[self setObject:mapperObject forKey:destination];
}

- (void)mapKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo withValueTransformerClass:(Class)valueTransformerClass{
	CKMappingPrivate* mapperObject = [[[CKMappingPrivate alloc]init]autorelease];
	mapperObject.key = keyPath;
	mapperObject.transformerClass = valueTransformerClass;
	mapperObject.policy = (bo == YES) ? CKMappingPolicyRequired : CKMappingPolicyOptional;
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

- (void)mapFloatForKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo{
	[self mapKeyPath:keyPath toKeyPath:destination required:bo withValueTransformerClass:[CKNSStringToFloatTransformer class]];
}

- (void)mapDateForKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination required:(BOOL)bo{
	[self mapKeyPath:keyPath toKeyPath:destination required:bo withValueTransformerClass:[CKNSStringToDateTransformer class]];
}

- (void)mapCollectionForKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination objectClass:(Class)objectClass withMappings:(NSMutableDictionary*)mappings required:(BOOL)bo{
	CKObjectMapping* mapperObject = [[[CKObjectMapping alloc] init] autorelease];
	mapperObject.key = keyPath;
	mapperObject.objectClass = objectClass;
	mapperObject.mappings = mappings;
	mapperObject.policy = (bo == YES) ? CKMappingPolicyRequired : CKMappingPolicyOptional;
	[self setObject:mapperObject forKey:destination];
}

- (void)mapObjectForKeyPath:(NSString*)keyPath toKeyPath:(NSString*)destination objectClass:(Class)objectClass withMappings:(NSMutableDictionary*)mappings required:(BOOL)bo{
	CKObjectMapping* mapperObject = [[[CKObjectMapping alloc] init] autorelease];
	mapperObject.key = keyPath;
	mapperObject.objectClass = objectClass;
	mapperObject.mappings = mappings;
	mapperObject.policy = (bo == YES) ? CKMappingPolicyRequired : CKMappingPolicyOptional;
	[self setObject:mapperObject forKey:destination];
}

@end