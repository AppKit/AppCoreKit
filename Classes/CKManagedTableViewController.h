//
//  CKManagedTableViewController.h
//  CloudKit
//
//  Created by Olivier Collet on 10-03-02.
//  Copyright 2010 WhereCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CKTableViewController.h"

@class CKTableViewCellController;
@class CKManagedTableViewController;

/** TODO
 */
@interface CKTableSection : NSObject {
	NSMutableArray *_cellControllers;
	NSString *_headerTitle;
	NSString *_footerTitle;
	UIView *_headerView;
	UIView *_footerView;
	BOOL _canMoveRowsOut;
	BOOL _canMoveRowsIn;
	BOOL _collapsed;
	CKManagedTableViewController* _parentController;
}

@property (nonatomic, retain, readonly) NSArray *cellControllers;
@property (nonatomic, retain, readwrite) NSString *headerTitle;
@property (nonatomic, retain, readwrite) NSString *footerTitle;
@property (nonatomic, retain, readwrite) UIView *headerView;
@property (nonatomic, retain, readwrite) UIView *footerView;
@property (nonatomic, assign) BOOL canMoveRowsOut;
@property (nonatomic, assign) BOOL canMoveRowsIn;
@property (nonatomic, assign, readonly) BOOL collapsed;
@property (nonatomic, assign, readonly) CKManagedTableViewController* parentController;

- (id)initWithCellControllers:(NSArray *)cellControllers;
- (id)initWithCellControllers:(NSArray *)cellControllers collapsed:(BOOL)collapsed;
- (void)insertCellController:(CKTableViewCellController *)cellController atIndex:(NSUInteger)index;
- (void)removeCellControllerAtIndex:(NSUInteger)index;

- (void)setCollapsed:(BOOL)collapsed withRowAnimation:(UITableViewRowAnimation)animation;

@end



/** TODO
 */
typedef enum {
	CKManagedTableViewOrientationPortrait,
	CKManagedTableViewOrientationLandscape
} CKManagedTableViewOrientation;

//


/** TODO
 */
@interface CKManagedTableViewController : CKTableViewController <UIScrollViewDelegate> {
	id _managedTableViewDelegate;
	NSMutableArray *_sections;
	NSMutableDictionary *_valuesForKeys;
	CKManagedTableViewOrientation _orientation;
	BOOL _resizeOnKeyboardNotification;
}

@property (nonatomic, assign) id managedTableViewDelegate;
@property (nonatomic, readonly) NSDictionary *valuesForKeys;
@property (nonatomic, assign, readwrite) CKManagedTableViewOrientation orientation;
@property (nonatomic, assign) BOOL resizeOnKeyboardNotification;

- (void)setup;
- (void)clear;
- (void)reload;

// Cell Controllers Management

- (void)addSection:(CKTableSection *)section;
- (CKTableSection *)addSectionWithCellControllers:(NSArray *)cellControllers;
- (CKTableSection *)addSectionWithCellControllers:(NSArray *)cellControllers headerTitle:(NSString *)headerTitle footerTitle:(NSString *)footerTitle;
- (void)insertCellController:(CKTableViewCellController*)cellController atIndex:(NSUInteger)index inSection:(NSUInteger)sectionIndex animated:(BOOL)animated;
- (void)removeCellControllerAtIndex:(NSUInteger)index inSection:(NSUInteger)sectionIndex animated:(BOOL)animated;
- (CKTableSection*)sectionAtIndex:(NSUInteger)index;
- (NSInteger)indexOfSection:(CKTableSection*)section;

@end

//

/** TODO
 */
@protocol CKManagedTableViewControllerDelegate
@optional
- (void)tableViewController:(CKManagedTableViewController *)tableViewController cellControllerValueDidChange:(CKTableViewCellController *)cellController;
- (void)tableViewController:(CKManagedTableViewController *)tableViewController cellControllerDidDelete:(CKTableViewCellController *)cellController;
- (void)tableViewController:(CKManagedTableViewController *)tableViewController cellControllerDidMoveFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
@end