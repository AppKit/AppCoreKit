//
//  CKContainerViewController.h
//  CloudKit
//
//  Created by Sebastien Morel on 11-04-11.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKViewController.h"

typedef enum CKTransitionType{
    CKTransitionNone = UIViewAnimationOptionTransitionNone,
    CKTransitionFlipFromLeft    = UIViewAnimationOptionTransitionFlipFromLeft,
    CKTransitionFlipFromRight   = UIViewAnimationOptionTransitionFlipFromRight,
    CKTransitionCurlUp          = UIViewAnimationOptionTransitionCurlUp,
    CKTransitionCurlDown        = UIViewAnimationOptionTransitionCurlDown,
    CKTransitionCrossDissolve   = UIViewAnimationOptionTransitionCrossDissolve,
    CKTransitionFlipFromTop     = UIViewAnimationOptionTransitionFlipFromTop,
    CKTransitionFlipFromBottom  = UIViewAnimationOptionTransitionFlipFromBottom,
    CKTransitionPush            = 8 << 20,
    CKTransitionPop             = 9 << 20,
}CKTransitionType;

@interface CKContainerViewController : CKViewController {
}

@property (nonatomic, retain) NSArray* viewControllers;
@property (nonatomic, readonly) UIViewController* selectedViewController;
@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nonatomic, retain, readonly) UIView *containerView;

- (id)initWithViewControllers:(NSArray *)viewControllers;

- (void)showViewControllerAtIndex:(NSUInteger)index withTransition:(CKTransitionType)transition;
- (void)setSelectedIndex:(NSUInteger)selectedIndex withTransition:(CKTransitionType)transition;

@end

//

@interface UIViewController (CKContainerViewController)

@property (nonatomic,assign) UIViewController *containerViewController;

@end
