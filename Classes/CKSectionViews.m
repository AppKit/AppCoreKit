//
//  CKSectionViews.m
//  CloudKit
//
//  Created by Martin Dufort on 12-05-31.
//  Copyright (c) 2012 Wherecloud. All rights reserved.
//

#import "CKSectionViews.h"
#import "CKNSObject+Bindings.h"
#import "CKUIViewAutoresizing+Additions.h"
#import "CKUIView+Style.h"
#import "CKStyleManager.h"
#import "CKUIColor+Additions.h"
#import "CKTableViewCellController+CKDynamicLayout.h"
#import "CKUIView+Positioning.h"


@interface CKSectionHeaderView()
@property(nonatomic,retain,readwrite) UILabel* label;
@property(nonatomic,assign,readwrite) CKTableViewController* tableViewController;
@property(nonatomic,retain) CKWeakRef* tableViewControllerRef;
- (void)setupDefaults;
@end

@implementation CKSectionHeaderView
@synthesize label = _label;
@synthesize tableViewController;
@synthesize tableViewControllerRef = _tableViewControllerRef;
@synthesize text = _text;
@synthesize contentInsets = _contentInsets;

- (void)dealloc{
    [self clearBindingsContext];
    
    [_label release];
    [_tableViewControllerRef release];
    [super dealloc];
}

- (void)setTableViewController:(CKTableViewController *)theTableViewController{
    self.tableViewControllerRef = [CKWeakRef weakRefWithObject:theTableViewController];
    
    __block CKSectionHeaderView* bself = self;
    [self beginBindingsContextByRemovingPreviousBindings];
    [self.tableViewController bind:@"tableView" withBlock:^(id value) {
        [bself beginBindingsContextByKeepingPreviousBindings];
        [bself.tableViewController.tableView bind:@"style" executeBlockImmediatly:YES withBlock:^(id value) {
            [bself setupDefaults];
        }];
        [bself endBindingsContext];
    }];
    [self endBindingsContext];
}

- (CKTableViewController*)tableViewController{
    return [_tableViewControllerRef object];
}

- (void)setText:(NSString *)theText{
    [_text release];
    _text = [theText copy];
    
    if(!_label){
        self.label = [[[UILabel alloc]initWithFrame:self.frame]autorelease];
        _label.autoresizingMask = UIViewAutoresizingFlexibleSize;
        [self addSubview:_label];
    }
}

- (void)setupDefaults{
    if(!self.tableViewController.tableView)
        return;
    
    NSMutableDictionary* style = [self appliedStyle];
    if(!style || [style isEmpty]){
        self.label.backgroundColor = [UIColor clearColor];
        if(self.tableViewController.tableView.style == UITableViewStyleGrouped){
            self.label.font = [UIFont boldSystemFontOfSize:17];
            self.label.shadowOffset = CGSizeMake(0, 1);
            self.label.shadowColor = [UIColor whiteColor];
            self.label.textColor = [UIColor colorWithRed:0.298039 green:0.3372255 blue:0.423529 alpha:1];
            self.backgroundColor = [UIColor clearColor];
            
            self.embossTopColor = nil;
            self.borderColor = nil;
            self.borderLocation = CKStyleViewBorderLocationNone;
            self.gradientColors = nil;
            self.gradientColorLocations = nil;
        }else{
            self.label.font = [UIFont boldSystemFontOfSize:18];
            self.label.shadowOffset = CGSizeMake(0, 1);
            self.label.shadowColor = [UIColor colorWithRed:0.44 green:0.44 blue:0.44 alpha:1];
            self.label.textColor = [UIColor whiteColor];
            self.embossTopColor = [UIColor colorWithIntegerRed:165 green:177 blue:186 alpha:255];
            self.borderColor = [UIColor colorWithIntegerRed:113 green:125 blue:133 alpha:255];
            self.borderWidth = 1;
            self.borderLocation = CKStyleViewBorderLocationTop | CKStyleViewBorderLocationBottom;
            self.gradientColors = [NSArray arrayWithObjects:
                                   [UIColor colorWithIntegerRed:144 green:159 blue:170 alpha:255],
                                   [UIColor colorWithIntegerRed:183 green:192 blue:199 alpha:255], 
                                   nil];
            self.gradientColorLocations = [NSArray arrayWithObjects:
                                           [NSNumber numberWithFloat:0],
                                           [NSNumber numberWithFloat:1], 
                                           nil];
        }
    }    
}

+ (BOOL)applyStyle:(NSMutableDictionary*)style toView:(UIView*)view appliedStack:(NSMutableSet*)appliedStack delegate:(id)delegate{
    BOOL result = [[CKStyleView class] applyStyle:style toView:view appliedStack:appliedStack delegate:delegate];
    
    CKSectionHeaderView* headerView = (CKSectionHeaderView*)view;
    [headerView layoutSubviews];
    
    return result;
}

- (void)layoutSubviews{
    if(!self.tableViewController.tableView)
        return;
    
    [self.label setText:self.text];
    
    //update position and size
    if(self.tableViewController.tableView.style == UITableViewStyleGrouped){
        CGFloat margin = [CKTableViewCellController computeTableViewCellMarginUsingTableView:self.tableViewController.tableView];
        CGFloat labelOffsetFromLeftMargin = 9;
        
        CGFloat labelOffsetFromTop = 7;
        if([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            labelOffsetFromTop = 5;
        }
        CGFloat widthMax = self.tableViewController.tableView.width - (2 * margin) - (2*labelOffsetFromLeftMargin) - _contentInsets.left - _contentInsets.right;
        
        CGSize labelSize = [self.label.text sizeWithFont:self.label.font constrainedToSize:CGSizeMake(widthMax, self.label.font.lineHeight) lineBreakMode:self.label.lineBreakMode];
        
        CGFloat x = 0;
        switch(self.label.textAlignment){
            case UITextAlignmentLeft: x =  _contentInsets.left + margin + labelOffsetFromLeftMargin; break;
            case UITextAlignmentRight: x = _contentInsets.left + margin + labelOffsetFromLeftMargin + widthMax - labelSize.width; break;
            case UITextAlignmentCenter: x = _contentInsets.left + margin + labelOffsetFromLeftMargin + (widthMax / 2) - (labelSize.width / 2); break;
        }
        
        self.label.frame = CGRectIntegral(CGRectMake(x,_contentInsets.top + labelOffsetFromTop,labelSize.width,labelSize.height));
        
        //Set y = 10 for section at index 0
        self.frame = CGRectIntegral(CGRectMake(0,self.frame.origin.y,
                                               self.tableViewController.tableView.width,
                                               _contentInsets.top + _contentInsets.bottom + labelSize.height + (2*labelOffsetFromTop) + (([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 3 : 0)));
    }else{
        CGFloat labelOffsetFromLeftMargin = 12;
        CGFloat labelOffsetFromTop = 1;
        CGFloat widthMax = self.tableViewController.tableView.width - (2 * labelOffsetFromLeftMargin) - _contentInsets.left - _contentInsets.right;
        
        CGSize labelSize = [self.label.text sizeWithFont:self.label.font constrainedToSize:CGSizeMake(widthMax, self.label.font.lineHeight) lineBreakMode:self.label.lineBreakMode];
        
        CGFloat x = 0;
        switch(self.label.textAlignment){
            case UITextAlignmentLeft: x = _contentInsets.left + labelOffsetFromLeftMargin; break;
            case UITextAlignmentRight: x = _contentInsets.left + labelOffsetFromLeftMargin + widthMax - labelSize.width; break;
            case UITextAlignmentCenter: x = _contentInsets.left + labelOffsetFromLeftMargin + (widthMax / 2) - (labelSize.width / 2); break;
        }
        self.label.frame = CGRectIntegral(CGRectMake(x,_contentInsets.top + labelOffsetFromTop,labelSize.width,labelSize.height));
        
        //Set y = 10 for section at index 0
        self.frame = CGRectIntegral(CGRectMake(0,self.frame.origin.y,self.tableViewController.tableView.width,_contentInsets.top + _contentInsets.bottom + labelSize.height));
    }
}

@end



@implementation CKSectionFooterView

- (void)setupDefaults{
    if(!self.tableViewController.tableView)
        return;
    
    NSMutableDictionary* style = [self appliedStyle];
    if(!style || [style isEmpty]){
        self.label.backgroundColor = [UIColor clearColor];
        if(self.tableViewController.tableView.style == UITableViewStyleGrouped){
            self.label.font = [UIFont systemFontOfSize:15];
            self.label.shadowOffset = CGSizeMake(0, 1);
            self.label.shadowColor = [UIColor whiteColor];
            self.label.textColor = [UIColor colorWithIntegerRed:69 green:79 blue:99 alpha:255];
            self.label.numberOfLines = 0;
            self.label.textAlignment = UITextAlignmentCenter;
            self.backgroundColor = [UIColor clearColor];
            
            self.embossTopColor = nil;
            self.borderColor = nil;
            self.borderLocation = CKStyleViewBorderLocationNone;
            self.gradientColors = nil;
            self.gradientColorLocations = nil;
        }else{
            //SAME AS HEADERVIEW
            self.label.font = [UIFont boldSystemFontOfSize:18];
            self.label.shadowOffset = CGSizeMake(0, 1);
            self.label.shadowColor = [UIColor colorWithRed:0.44 green:0.44 blue:0.44 alpha:1];
            self.label.textColor = [UIColor whiteColor];
            self.label.textAlignment = UITextAlignmentLeft;
            
            
            self.embossTopColor = [UIColor colorWithIntegerRed:165 green:177 blue:186 alpha:255];
            self.borderColor = [UIColor colorWithIntegerRed:113 green:125 blue:133 alpha:255];
            self.borderWidth = 1;
            self.borderLocation = CKStyleViewBorderLocationTop | CKStyleViewBorderLocationBottom;
            self.gradientColors = [NSArray arrayWithObjects:
                                   [UIColor colorWithIntegerRed:144 green:159 blue:170 alpha:255],
                                   [UIColor colorWithIntegerRed:183 green:192 blue:199 alpha:255], 
                                   nil];
            self.gradientColorLocations = [NSArray arrayWithObjects:
                                           [NSNumber numberWithFloat:0],
                                           [NSNumber numberWithFloat:1], 
                                           nil];
        }
    }    
}

- (void)layoutSubviews{
    if(!self.tableViewController.tableView)
        return;
    
    //update position and size
    if(self.tableViewController.tableView.style == UITableViewStyleGrouped){
        [self.label setText:self.text];
        
        CGFloat margin = [CKTableViewCellController computeTableViewCellMarginUsingTableView:self.tableViewController.tableView];
        
        CGFloat labelOffsetFromLeftMargin = 9;
        CGFloat labelOffsetFromTop = 6;
        CGFloat widthMax = self.tableViewController.tableView.width - (2 * margin) - (2*labelOffsetFromLeftMargin) - self.contentInsets.left - self.contentInsets.right;
        
        CGSize labelSize = [self.label.text sizeWithFont:self.label.font constrainedToSize:CGSizeMake(widthMax, MAXFLOAT) lineBreakMode:self.label.lineBreakMode];
        
        CGFloat x = 0;
        switch(self.label.textAlignment){
            case UITextAlignmentLeft: x = self.contentInsets.left + margin + labelOffsetFromLeftMargin; break;
            case UITextAlignmentRight: x = self.contentInsets.left + margin + labelOffsetFromLeftMargin + widthMax - labelSize.width; break;
            case UITextAlignmentCenter: x = self.contentInsets.left + margin + labelOffsetFromLeftMargin + (widthMax / 2) - (labelSize.width / 2); break;
        }
        
        self.label.frame = CGRectIntegral(CGRectMake(x,self.contentInsets.top + labelOffsetFromTop,labelSize.width,labelSize.height));
        self.frame = CGRectIntegral(CGRectMake(0,self.frame.origin.y,self.tableViewController.tableView.width,self.contentInsets.top + self.contentInsets.bottom + labelSize.height + (2*labelOffsetFromTop)));
    }else{
        [self.label setText:[self.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "]];
        
        //SAME AS HEADERVIEW
        CGFloat labelOffsetFromLeftMargin = 12;
        CGFloat labelOffsetFromTop = 1;
        CGFloat widthMax = self.tableViewController.tableView.width - (2 * labelOffsetFromLeftMargin) - self.contentInsets.left - self.contentInsets.right;
        
        CGSize labelSize = [self.label.text sizeWithFont:self.label.font constrainedToSize:CGSizeMake(widthMax, self.label.font.lineHeight) lineBreakMode:self.label.lineBreakMode];
        
        CGFloat x = 0;
        switch(self.label.textAlignment){
            case UITextAlignmentLeft: x = self.contentInsets.left + labelOffsetFromLeftMargin; break;
            case UITextAlignmentRight: x = self.contentInsets.left + labelOffsetFromLeftMargin + widthMax - labelSize.width; break;
            case UITextAlignmentCenter: x = self.contentInsets.left + labelOffsetFromLeftMargin + (widthMax / 2) - (labelSize.width / 2); break;
        }
        
        self.label.frame = CGRectIntegral(CGRectMake(x,self.contentInsets.top + labelOffsetFromTop,labelSize.width,labelSize.height));
        self.frame = CGRectIntegral(CGRectMake(0,self.frame.origin.y,self.tableViewController.tableView.width,self.contentInsets.top + self.contentInsets.bottom + labelSize.height));
    }
}


@end

