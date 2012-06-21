//
//  CKCollectionViewController.h
//  CloudKit
//
//  Created by Sebastien Morel on 11-05-25.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CKUIViewController.h"

#import "CKObjectController.h"
#import "CKCollectionCellControllerFactory.h"
#import "CKCollection.h"
#import "CKCollectionCellController.h"
#import "CKCollectionController.h"

/* This controller implements the logic to deals with objects via objectcontroller and controllerfactory.
   It will gives all the basic logic for live update from documents/view creation and reusing, controller creation/reusing
   and manage the item controller flags/selection/remove, ...
 
   By derivating this controller, you'll just have to implement the UIKit specific delegates and view creation and redirect
   to the basic implementation of CKCollectionViewController
 
   By this way we centralize all the document/viewcontroller logic taht is redondant in this class
 
   For some specific implementations see : CKTableCollectionViewController, CKCarouselCollectionViewController and CKMapCollectionViewController
 
 
  *  derivating this controller means
 
   you MUST implement :
 
 - (UIView*)viewAtIndexPath:(NSIndexPath *)indexPath
 - (NSIndexPath*)indexPathForView:(UIView*)view
 - (void)updateParams
 - (UIView*)dequeueReusableViewWithIdentifier:(NSString*)identifier
 
   you SHOULD implement :
 
 - (void)onReload
 - (void)onBeginUpdates
 - (void)onEndUpdates
 - (void)onInsertObjects:(NSArray*)objects atIndexPaths:(NSArray*)indexPaths
 - (void)onRemoveObjects:(NSArray*)objects atIndexPaths:(NSArray*)indexPaths
*/


/** TODO
 */
@interface CKCollectionViewController : CKUIViewController<CKObjectControllerDelegate> {
	id _objectController;
	CKCollectionCellControllerFactory* _controllerFactory;
	
	//Internal view/controller management
	NSMutableDictionary* _viewsToControllers;
	NSMutableDictionary* _viewsToIndexPath;
	NSMutableDictionary* _indexPathToViews;
	NSMutableArray* _weakViews;
    NSMutableArray* _sectionsToControllers; //containing NSMutableArray of CKCollectionCellController
	
	id _delegate;
	int _numberOfObjectsToprefetch;
}

@property (nonatomic, retain) id objectController;
@property (nonatomic, retain) CKCollectionCellControllerFactory* controllerFactory;
@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) int numberOfObjectsToprefetch;

@property (nonatomic, assign, readonly) BOOL rotating;

//init
- (id)initWithCollection:(CKCollection*)collection factory:(CKCollectionCellControllerFactory*)factory;

//setup
- (void)setupWithCollection:(CKCollection*)collection factory:(CKCollectionCellControllerFactory*)factory;

//update
- (void)updateVisibleViewsIndexPath;
- (void)updateVisibleViewsRotation;
- (void)updateViewsVisibility:(BOOL)visible;

//view representation management
- (CKCollectionCellController*)controllerAtIndexPath:(NSIndexPath *)indexPath;
- (UIView*)viewAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath*)indexPathForView:(UIView*)view;
- (NSArray*)visibleIndexPaths;
- (UIView*)createViewAtIndexPath:(NSIndexPath*)indexPath;
- (UIView*)dequeueReusableViewWithIdentifier:(NSString*)identifier;
- (BOOL)isValidIndexPath:(NSIndexPath*)indexPath;

- (id)objectAtIndexPath:(NSIndexPath*)indexPath;
- (NSArray*)objectsForSection:(NSInteger)section;
- (NSInteger)indexOfObject:(id)object inSection:(NSInteger)section;
- (NSIndexPath*)indexPathForObject:(id)object;

//content management
- (NSInteger)numberOfSections;
- (NSInteger)numberOfObjectsForSection:(NSInteger)section;

- (void)fetchObjectsInRange:(NSRange)range  forSection:(NSInteger)section;
- (void)fetchMoreData;
- (void)fetchMoreIfNeededAtIndexPath:(NSIndexPath*)indexPath;

//items controller interactions
- (CGSize)sizeForViewAtIndexPath:(NSIndexPath *)indexPath;
- (CKItemViewFlags)flagsForViewAtIndexPath:(NSIndexPath*)indexPath;

- (BOOL)willSelectViewAtIndexPath:(NSIndexPath *)indexPath;
- (void)didSelectViewAtIndexPath:(NSIndexPath *)indexPath;
- (void)didSelectAccessoryViewAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)isViewEditableAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isViewMovableAtIndexPath:(NSIndexPath *)indexPath;

//Parent controller interactions
- (void)didRemoveViewAtIndexPath:(NSIndexPath*)indexPath;
- (void)didMoveViewAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (NSIndexPath*)targetIndexPathForMoveFromIndexPath:(NSIndexPath*)sourceIndexPath toProposedIndexPath:(NSIndexPath*)proposedDestinationIndexPath;

//Object Controller update callbacks
- (void)onReload;
- (void)onBeginUpdates;
- (void)onEndUpdates;
- (void)onInsertObjects:(NSArray*)objects atIndexPaths:(NSArray*)indexPaths;
- (void)onRemoveObjects:(NSArray*)objects atIndexPaths:(NSArray*)indexPaths;
- (void)onInsertSectionAtIndex:(NSInteger)index;
- (void)onRemoveSectionAtIndex:(NSInteger)index;

- (void)onSizeChangeAtIndexPath:(NSIndexPath*)index;

- (void)reload;

//Helpers
- (CKFeedSource*)collectionDataSource;

@end



/** TODO
 */
@protocol CKCollectionViewControllerDelegate
@optional
- (void)itemViewContainerController:(CKCollectionViewController*)controller didSelectViewAtIndexPath:(NSIndexPath*)indexPath withObject:(id)object;
- (void)itemViewContainerController:(CKCollectionViewController*)controller didSelectAccessoryViewAtIndexPath:(NSIndexPath*)indexPath withObject:(id)object;
@end