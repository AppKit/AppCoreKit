//
//  CKBindings.m
//  CloudKit
//
//  Created by Sebastien Morel on 11-03-11.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKNSObject+Bindings.h"
#import "CKBindingsManager.h"
#import "CKUIControlBlockBinder.h"
#import "CKDataBinder.h"
#import "CKNotificationBlockBinder.h"
#import "CKDataBlockBinder.h"

@interface CKBindingsManager ()
@property (nonatomic, retain) NSDictionary *bindingsPoolForClass;
@property (nonatomic, retain) NSDictionary *bindingsForContext;
@property (nonatomic, retain) NSMutableSet *contexts;
@end

static NSMutableArray* CKBindingsContextStack = nil;
static NSString* CKBindingsNoContext = @"CKBindingsNoContext";

typedef enum CKDebugCheckState{
    CKDebugCheckState_none,
    CKDebugCheckState_NO,
    CKDebugCheckState_YES
}CKDebugCheckState;

static CKDebugCheckState CKDebugAssertForBindingsOutOfContextState = CKDebugCheckState_none;

@implementation NSObject (CKBindings)

//Class method for bindings management

+ (id)currentBindingContext{
	if(CKBindingsContextStack && [CKBindingsContextStack count] > 0){
		return [[CKBindingsContextStack lastObject]objectForKey:@"context"];
	}
	return CKBindingsNoContext;
}


+ (CKBindingsContextOptions)currentBindingContextOptions{
    if(CKBindingsContextStack && [CKBindingsContextStack count] > 0){
		return (CKBindingsContextOptions)[[[CKBindingsContextStack lastObject]objectForKey:@"options"]intValue];
	}
	return CKBindingsContextPerformOnMainThread | CKBindingsContextWaitUntilDone;
}

+ (NSString *)allBindingsDescription{
	return [[CKBindingsManager defaultManager]description];
}

+ (void)beginBindingsContext:(id)context{
	[NSObject beginBindingsContext:context policy:CKBindingsContextPolicyAdd options:CKBindingsContextPerformOnMainThread | CKBindingsContextWaitUntilDone];
}

+ (void)beginBindingsContext:(id)context policy:(CKBindingsContextPolicy)policy{
	[NSObject beginBindingsContext:context policy:policy options:CKBindingsContextPerformOnMainThread | CKBindingsContextWaitUntilDone];
}

+ (void)beginBindingsContext:(id)context options:(CKBindingsContextOptions)options{
	[NSObject beginBindingsContext:context policy:CKBindingsContextPolicyAdd options:options];
}

+ (void)beginBindingsContext:(id)context policy:(CKBindingsContextPolicy)policy options:(CKBindingsContextOptions)options{
    if(CKBindingsContextStack == nil){
		CKBindingsContextStack = [[NSMutableArray alloc]init];
	}
	
	[CKBindingsContextStack addObject:[NSDictionary dictionaryWithObjectsAndKeys:context,@"context",[NSNumber numberWithInt:options],@"options",nil]];
	
	if(policy == CKBindingsContextPolicyRemovePreviousBindings){
		[[CKBindingsManager defaultManager] unbindAllBindingsWithContext:context];
	}
}

+ (void)endBindingsContext{
	NSAssert(CKBindingsContextStack != nil && [CKBindingsContextStack count] > 0,@"No context opened");
	[CKBindingsContextStack removeLastObject];
}

+ (void)removeAllBindingsForContext:(id)context{
	[[CKBindingsManager defaultManager]unbindAllBindingsWithContext:context];
}

+ (void)validateCurrentBindingsContext{
#ifdef DEBUG
    if(CKDebugAssertForBindingsOutOfContextState == CKDebugCheckState_none){
        BOOL bo = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CKDebugAssertForBindingsOutOfContext"]boolValue];
        CKDebugAssertForBindingsOutOfContextState = bo ? CKDebugCheckState_YES : CKDebugCheckState_NO;
    }
    
    if(CKDebugAssertForBindingsOutOfContextState != CKDebugCheckState_YES)
        return;
    
    NSAssert([NSObject currentBindingContext] != CKBindingsNoContext,@"You're creating a binding without having opened a context !");
#endif
}

//Instance method for bindings management

- (CKWeakRef*)weakRefBindingsContext{
    for(id context in [[CKBindingsManager defaultManager]contexts]){
        if([context isKindOfClass:[CKWeakRef class]]){
            CKWeakRef* contextWeakRef = (CKWeakRef*)context;
            if(contextWeakRef.object == self){
                return contextWeakRef;
            }
        }
    }
    return nil;
}

- (void)beginBindingsContextUsingPolicy:(CKBindingsContextPolicy)policy options:(CKBindingsContextOptions)options{
    CKWeakRef* weakRef = [self weakRefBindingsContext];
    if(weakRef == nil){
        weakRef = [CKWeakRef weakRefWithObject:self block:^(CKWeakRef* ref){
            NSMutableSet* bindings = [[[CKBindingsManager defaultManager]bindingsForContext] objectForKey:ref];
            if(!bindings){
                return;
            }
            
            NSLog(@"WARNING : the following context is beeing cleared as it's object is deallocated : {context : %@\n}",ref);
            [NSObject removeAllBindingsForContext:ref];
        }];
    }
	[NSObject beginBindingsContext:weakRef policy:policy options:options];
}

- (void)beginBindingsContextByKeepingPreviousBindings{
	[self beginBindingsContextUsingPolicy:CKBindingsContextPolicyAdd options:CKBindingsContextPerformOnMainThread | CKBindingsContextWaitUntilDone];
}

- (void)beginBindingsContextByRemovingPreviousBindings{
	[self beginBindingsContextUsingPolicy:CKBindingsContextPolicyRemovePreviousBindings options:CKBindingsContextPerformOnMainThread | CKBindingsContextWaitUntilDone];
}

- (void)beginBindingsContextByKeepingPreviousBindingsWithOptions:(CKBindingsContextOptions)options{
	[self beginBindingsContextUsingPolicy:CKBindingsContextPolicyAdd options:options];
}

- (void)beginBindingsContextByRemovingPreviousBindingsWithOptions:(CKBindingsContextOptions)options{
	[self beginBindingsContextUsingPolicy:CKBindingsContextPolicyRemovePreviousBindings options:options];
}

- (void)endBindingsContext{
	[NSObject endBindingsContext];
}

- (void)clearBindingsContext{
	[NSObject removeAllBindingsForContext:[self weakRefBindingsContext]];
}


//NSObject Bindings

- (void)bind:(NSString *)keyPath toObject:(id)object withKeyPath:(NSString *)keyPath2{
    [NSObject validateCurrentBindingsContext];
    
	CKDataBinder* binder = (CKDataBinder*)[[CKBindingsManager defaultManager]dequeueReusableBindingWithClass:[CKDataBinder class]];
    binder.contextOptions = [NSObject currentBindingContextOptions];
	[binder setInstance1:self];
	binder.keyPath1 = keyPath;
	[binder setInstance2:object];
	binder.keyPath2 = keyPath2;
	[[CKBindingsManager defaultManager]bind:binder withContext:[NSObject currentBindingContext]];
	[binder release];
}

- (void)bind:(NSString *)keyPath withBlock:(void (^)(id value))block{
    [NSObject validateCurrentBindingsContext];
    
	CKDataBlockBinder* binder = (CKDataBlockBinder*)[[CKBindingsManager defaultManager]dequeueReusableBindingWithClass:[CKDataBlockBinder class]];
    binder.contextOptions = [NSObject currentBindingContextOptions];
	[binder setInstance:self];
	binder.keyPath = keyPath;
	binder.block = block;
	[[CKBindingsManager defaultManager]bind:binder withContext:[NSObject currentBindingContext]];
	[binder release];
}

- (void)bind:(NSString *)keyPath target:(id)target action:(SEL)selector{
    [NSObject validateCurrentBindingsContext];
    
	CKDataBlockBinder* binder = (CKDataBlockBinder*)[[CKBindingsManager defaultManager]dequeueReusableBindingWithClass:[CKDataBlockBinder class]];
    binder.contextOptions = [NSObject currentBindingContextOptions];
	[binder setInstance:self];
	binder.keyPath = keyPath;
	[binder setTarget:target];
	binder.selector = selector;
	[[CKBindingsManager defaultManager]bind:binder withContext:[NSObject currentBindingContext]];
	[binder release];
}

@end

//

@implementation UIControl (CKBindings)

- (void)bindEvent:(UIControlEvents)controlEvents withBlock:(void (^)())block{
    [NSObject validateCurrentBindingsContext];
    
	CKUIControlBlockBinder* binder = (CKUIControlBlockBinder*)[[CKBindingsManager defaultManager]dequeueReusableBindingWithClass:[CKUIControlBlockBinder class]];
    binder.contextOptions = [NSObject currentBindingContextOptions];
	binder.controlEvents = controlEvents;
	binder.block = block;
	[binder setControl:self];
	[[CKBindingsManager defaultManager]bind:binder withContext:[NSObject currentBindingContext]];
	[binder release];
}

- (void)bindEvent:(UIControlEvents)controlEvents target:(id)target action:(SEL)selector{
    [NSObject validateCurrentBindingsContext];
    
	CKUIControlBlockBinder* binder = (CKUIControlBlockBinder*)[[CKBindingsManager defaultManager]dequeueReusableBindingWithClass:[CKUIControlBlockBinder class]];
    binder.contextOptions = [NSObject currentBindingContextOptions];
	binder.controlEvents = controlEvents;
	[binder setControl:self];
	[binder setTarget:target];
	binder.selector = selector;
	[[CKBindingsManager defaultManager]bind:binder withContext:[NSObject currentBindingContext]];
	[binder release];
}

@end

//

@implementation NSNotificationCenter (CKBindings)

- (void)bindNotificationName:(NSString *)notification object:(id)notificationSender withBlock:(void (^)(NSNotification *notification))block{
    [NSObject validateCurrentBindingsContext];
    
	CKNotificationBlockBinder* binder = (CKNotificationBlockBinder*)[[CKBindingsManager defaultManager]dequeueReusableBindingWithClass:[CKNotificationBlockBinder class]];
    binder.contextOptions = [NSObject currentBindingContextOptions];
	[binder setInstance:notificationSender];
	binder.notificationName = notification;
	binder.block = block;
	[[CKBindingsManager defaultManager]bind:binder withContext:[NSObject currentBindingContext]];
	[binder release];
}

- (void)bindNotificationName:(NSString *)notification withBlock:(void (^)(NSNotification *notification))block{
    [NSObject validateCurrentBindingsContext];
    
	CKNotificationBlockBinder* binder = (CKNotificationBlockBinder*)[[CKBindingsManager defaultManager]dequeueReusableBindingWithClass:[CKNotificationBlockBinder class]];
    binder.contextOptions = [NSObject currentBindingContextOptions];
	binder.notificationName = notification;
	binder.block = block;
	[[CKBindingsManager defaultManager]bind:binder withContext:[NSObject currentBindingContext]];
	[binder release];
}

- (void)bindNotificationName:(NSString *)notification object:(id)notificationSender target:(id)target action:(SEL)selector{
    [NSObject validateCurrentBindingsContext];
    
	CKNotificationBlockBinder* binder = (CKNotificationBlockBinder*)[[CKBindingsManager defaultManager]dequeueReusableBindingWithClass:[CKNotificationBlockBinder class]];
    binder.contextOptions = [NSObject currentBindingContextOptions];
	[binder setInstance:notificationSender];
	[binder setTarget:target];
	binder.notificationName = notification;
	binder.selector = selector;
	[[CKBindingsManager defaultManager]bind:binder withContext:[NSObject currentBindingContext]];
	[binder release];
}

- (void)bindNotificationName:(NSString *)notification target:(id)target action:(SEL)selector{
    [NSObject validateCurrentBindingsContext];
    
	CKNotificationBlockBinder* binder = (CKNotificationBlockBinder*)[[CKBindingsManager defaultManager]dequeueReusableBindingWithClass:[CKNotificationBlockBinder class]];
    binder.contextOptions = [NSObject currentBindingContextOptions];
	[binder setTarget:target];
	binder.notificationName = notification;
	binder.selector = selector;
	[[CKBindingsManager defaultManager]bind:binder withContext:[NSObject currentBindingContext]];
	[binder release];
}


+ (void)bindNotificationName:(NSString *)notification object:(id)notificationSender withBlock:(void (^)(NSNotification *notification))block{
	[[NSNotificationCenter defaultCenter]bindNotificationName:notification object:notificationSender withBlock:block];
}
+ (void)bindNotificationName:(NSString *)notification withBlock:(void (^)(NSNotification *notification))block{
	[[NSNotificationCenter defaultCenter]bindNotificationName:notification withBlock:block];
}

+ (void)bindNotificationName:(NSString *)notification object:(id)notificationSender target:(id)target action:(SEL)selector{
	[[NSNotificationCenter defaultCenter]bindNotificationName:notification object:notificationSender target:target action:selector];
}
+ (void)bindNotificationName:(NSString *)notification target:(id)target action:(SEL)selector{
	[[NSNotificationCenter defaultCenter]bindNotificationName:notification target:target action:selector];
}

@end


/*id subView = (viewTag >= 0) ? [self.view viewWithTag:viewTag] : self.view;
 id controlId = (keyPath == nil || [keyPath isEqualToString:@""]) ? subView : [subView valueForKeyPath:keyPath];
 if(!controlId){
 NSAssert(NO,@"Invalid control object in CKUIControlActionBlockBinder");
 }*/