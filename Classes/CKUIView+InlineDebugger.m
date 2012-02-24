//
//  CKUIView+InlineDebugger.m
//  CloudKit
//
//  Created by Sebastien Morel on 11-10-17.
//  Copyright (c) 2011 Wherecloud. All rights reserved.
//

#import "CKUIView+InlineDebugger.h"
#import "CKDocumentArray.h"
#import "CKDebug.h"
#import "CKCache.h"
#import <QuartzCore/QuartzCore.h>
#import "CKUIImage+Transformations.h"
#import "CKStyleManager.h"
#import "CKUIView+Style.h"
#import "CKCascadingTree.h"
#import "CKUIColor+ValueTransformer.h"
#import "CKNSObject+Bindings.h"

@implementation UIView (CKInlineDebugger)

+ (UIImage*)createsImageForView:(UIView*)view{
    if(view.layer.contents){
        return [UIImage imageWithCGImage:(CGImageRef)view.layer.contents];
    }
    
    //NSString* key = [NSString stringWithFormat:@"image<%p>",view];
    UIImage* image = nil;//[[CKCache sharedCache] imageForKey:key];
    //if(image){
    //    return image;
    //}

    UIGraphicsBeginImageContext(view.bounds.size);
    [view drawRect:view.bounds];
    image  = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //if(image){
    //    [[CKCache sharedCache] setImage:image  forKey:key];
    //}
    
    return image;
}

+ (UIImage*)createsThumbnailForView:(UIView*)view{
    //NSString* key = [NSString stringWithFormat:@"thumbnail<%p>",view];
    UIImage* thumbnail = nil;//[[CKCache sharedCache] imageForKey:key];
    //if(thumbnail){
    //    return thumbnail;
    //}
    
    UIImage* image = [UIView createsImageForView:view];
    if(image){
        thumbnail = [image imageThatFits:CGSizeMake(40,40) crop:NO];
        
        //if(thumbnail){
        //    [[CKCache sharedCache] setImage:thumbnail  forKey:key];
        //}
    }

    return thumbnail;
}

+ (NSString*)titleForView:(UIView*)view{
    NSString *title = NSStringFromClass([view class]);
    CKObjectProperty* nameProperty = [CKObjectProperty propertyWithObject:view keyPath:@"name"];
    NSString *name = ([nameProperty descriptor] && [NSObject isClass:[[nameProperty descriptor]type] kindOfClass:[NSString class]] )? [nameProperty value] : nil;
    if([name length] <= 0){
        name = nil;
    }
    return name ? [NSString stringWithFormat:@"%@ - %@",title,name] : title;
}

+ (NSString*)subTitleForView:(UIView*)view{
    NSMutableString* subTitle = [NSMutableString string];
    if(view.hidden){
        [subTitle appendFormat:@"(hidden)"];
    }
    if(view.tag != 0){
        [subTitle appendFormat:@"%@(tag:%d)",([subTitle length] > 0) ? @"," : @"",view.tag];
    }
    if([view appliedStyle] == nil || [[view appliedStyle]isEmpty]){
        [subTitle appendFormat:@"%@(No Stylesheet)",([subTitle length] > 0) ? @"," : @""];
    }
    return subTitle;
}

+ (CKItemViewControllerFactoryItem*)factoryItemForSubViewInView:(UIView*)view{
    CKItemViewControllerFactoryItem* item = [[[CKItemViewControllerFactoryItem alloc]init]autorelease];
    item.controllerClass = [CKTableViewCellController class];
    
    [item setFilterBlock:^id(id value) {
        return [NSNumber numberWithBool:[ value isKindOfClass:[UIView class]]];
    }];
    [item setSetupBlock:^id(id value) {
        CKTableViewCellController* controller = (CKTableViewCellController*)value;
        UIView* subView = (UIView*)controller.value;
                
        controller.tableViewCell.textLabel.text = [UIView titleForView:subView];
        controller.tableViewCell.detailTextLabel.text = [UIView subTitleForView:subView];
        controller.tableViewCell.imageView.image = [UIView createsThumbnailForView:subView];
        
        
        __block CKTableViewCellController* bcontroller = controller;
        __block UIView* bsubView = subView;
        [controller.tableViewCell beginBindingsContextByRemovingPreviousBindings];
        CKObjectProperty* nameProperty = [CKObjectProperty propertyWithObject:view keyPath:@"name"];
        if([nameProperty descriptor]){
            [nameProperty.object bind:nameProperty.keyPath withBlock:^(id value) {
                bcontroller.tableViewCell.textLabel.text = [UIView titleForView:bsubView];
            }];
            [subView bind:@"hidden" withBlock:^(id value) {
                bcontroller.tableViewCell.detailTextLabel.text = [UIView subTitleForView:bsubView];
            }];
            [subView bind:@"tag" withBlock:^(id value) {
                bcontroller.tableViewCell.detailTextLabel.text = [UIView subTitleForView:bsubView];
            }];
            [subView.layer bind:@"contents" withBlock:^(id value) {
                bcontroller.tableViewCell.imageView.image = [UIView createsThumbnailForView:bsubView];
            }];
        }
        [controller.tableViewCell endBindingsContext];
        
        NSInteger indent = 0;
        
        UIView* v = subView;
        while(v && v != view){
            indent++;
            v = [v superview];
        }
        
        controller.indentationLevel = indent;
        
        
        controller.tableViewCell.imageView.layer.shadowColor = [[UIColor blackColor]CGColor];
        controller.tableViewCell.imageView.layer.shadowOpacity = 0.6;
        controller.tableViewCell.imageView.layer.shadowOffset = CGSizeMake(0,2);
        controller.tableViewCell.imageView.layer.shadowRadius = 2;
        controller.tableViewCell.imageView.layer.cornerRadius = 3;
        controller.tableViewCell.imageView.layer.borderWidth = 0.5;
        controller.tableViewCell.imageView.layer.borderColor = [[UIColor convertFromNSString:@"0.7 0.7 0.7 1"]CGColor];
        
        controller.tableViewCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                
        return (id)nil;
    }];
    [item setSelectionBlock:^id(id value) {
        CKTableViewCellController* cellcontroller = (CKTableViewCellController*)value;;
        UIView* subView = (UIView*)cellcontroller.value;
        
        CKUIViewController* slideshow = [CKUIViewController controller];
        slideshow.viewDidLoadBlock = ^(CKUIViewController* controller){
            UIImageView* imageView = [[[UIImageView alloc]initWithFrame:controller.view.bounds]autorelease];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.image = [UIView createsImageForView:subView];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [controller.view addSubview:imageView];
            controller.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
        };
        [cellcontroller.parentController.navigationController pushViewController:slideshow animated:YES];
        return (id)nil;
    }];
    [item setAccessorySelectionBlock:^id(id value) {
        CKTableViewCellController* cellcontroller = (CKTableViewCellController*)value;;
        UIView* subView = (UIView*)cellcontroller.value;
        
        CKFormTableViewController* subViewDebugger = [[subView class]inlineDebuggerForObject:subView];
        [cellcontroller.parentController.navigationController pushViewController:subViewDebugger animated:YES];
        return (id)nil;
    }];
    return item;
}

+ (void)addView:(UIView*)view toCollection:(CKDocumentCollection*)collection{
    if(view.tag == CKInlineDebuggerControllerHighlightViewTag)
        return;
    
    [collection addObject:view];
    
    for(UIView* subView in view.subviews){
        [UIView addView:subView toCollection:collection];
    }
}

+ (CKFormTableViewController*)inlineDebuggerForSubViewsOfView:(UIView*)view{
    CKFormTableViewController* debugger = [[[CKFormTableViewController alloc]initWithStyle:UITableViewStylePlain]autorelease];
    debugger.name = @"CKInlineDebuggerForSubViews";
    
    CKDocumentArrayCollection* collection = [CKDocumentArrayCollection object];
    [UIView addView:view toCollection:collection];
    
    CKItemViewControllerFactory* factory = [CKItemViewControllerFactory factory];
    [factory addItem:[UIView factoryItemForSubViewInView:view]];
    
    CKFormDocumentCollectionSection* section = [CKFormDocumentCollectionSection sectionWithCollection:collection factory:factory];
    [debugger addSections:[NSArray arrayWithObject:section]];
    return debugger;
}

+ (CKFormTableViewController*)inlineDebuggerForObject:(id)object{
    CKFormTableViewController* debugger = [NSObject inlineDebuggerForObject:object];
    UIView* view = (UIView*)object;
    
    __block CKFormTableViewController* bController = debugger;
    
    CKFormSection* superViewSection = [CKFormSection section];
    superViewSection.headerTitle = @"Views";
    
    if([view superview]){
        NSString* title = [NSString stringWithFormat:@"%@ <%p>",[[view superview] class],[view superview]];
        CKFormCellDescriptor* superViewCell = [CKFormCellDescriptor cellDescriptorWithTitle:@"Super View" subtitle:title action:^(CKTableViewCellController* controller){
            CKFormTableViewController* superViewForm = [[[view superview]class] inlineDebuggerForObject:[view superview]];
            superViewForm.title = title;
            [bController.navigationController pushViewController:superViewForm animated:YES];
        }];
        [superViewSection addCellDescriptor:superViewCell];
    }
    
    CKFormCellDescriptor* hierarchyCell = [CKFormCellDescriptor cellDescriptorWithTitle:@"Hierarchy" action:^(CKTableViewCellController* controller){
        /*CKUIViewController* hierarchyController = [[[CKUIViewController alloc]init]autorelease];
        hierarchyController.name = @"CKInlineDebugger";
        hierarchyController.viewDidLoadBlock = ^(CKUIViewController* controller){
            UIView* view = (UIView*)object;
            UITextView* txtView = [[[UITextView alloc]initWithFrame:controller.view.bounds]autorelease];
            txtView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            txtView.text = [view viewHierarchy];
            txtView.editable = NO;
            [controller.view addSubview:txtView];
        };*/
        
        CKFormTableViewController* hierarchyController = [UIView inlineDebuggerForSubViewsOfView:(UIView*)object];
        [bController.navigationController pushViewController:hierarchyController animated:YES];
    }];
    [superViewSection addCellDescriptor:hierarchyCell];
    
    [debugger insertSection:superViewSection atIndex:0];
    return debugger;
}

@end