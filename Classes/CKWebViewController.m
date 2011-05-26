//
//  CKWebViewController.m
//  YellowPages
//
//  Created by Olivier Collet on 10-02-03.
//  Copyright 2010 WhereCloud Inc. All rights reserved.
//

#import "CKWebViewController.h"
#import "CKUINavigationControllerAdditions.h"
#import "CKConstants.h"
#import "CKBundle.h"

#define CKBarButtonItemFlexibleSpace [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]

@interface CKWebViewController ()
@property (nonatomic, readwrite, retain) NSURL *homeURL;
@property (nonatomic, readwrite, retain) UIBarButtonItem *backButton;
@property (nonatomic, readwrite, retain) UIBarButtonItem *forwardButton;
@property (nonatomic, readwrite, retain) UIBarButtonItem *reloadButton;
@property (nonatomic, readwrite, retain) UIActivityIndicatorView *spinner;
@property (nonatomic, readwrite, retain) NSMutableArray *toolbarButtonsLoading;
@property (nonatomic, readwrite, retain) NSMutableArray *toolbarButtonsStatic;
@end

@interface CKWebViewController ()
@property (nonatomic, retain) NSString *HTMLString;
@property (nonatomic, retain) NSURL *baseURL;
- (void)generateToolbar;
- (void)updateToolbar;
@end

@implementation CKWebViewController

@synthesize homeURL = _homeURL;
@synthesize HTMLString = _HTMLString;
@synthesize baseURL = _baseURL;
@synthesize backButton = _backButton;
@synthesize forwardButton = _forwardButton;
@synthesize reloadButton = _reloadButton;
@synthesize spinner = _spinner;
@synthesize toolbarButtonsLoading = _toolbarButtonsLoading;
@synthesize toolbarButtonsStatic = _toolbarButtonsStatic;
@synthesize _showURLInTitle;
@synthesize hidesToolbar = _hidesToolbar;
@synthesize onLoadScript = _onLoadScript;
@synthesize minContentSizeForViewInPopover = _minContentSizeForViewInPopover;
@synthesize maxContentSizeForViewInPopover = _maxContentSizeForViewInPopover;
@synthesize canBeDismissed = _canBeDismissed;
@synthesize webViewToolbar = _webViewToolbar;

- (void)setup {
	_showURLInTitle = YES;
	
	// Create the toolbar buttons
	[self setImage:[CKBundle imageForName:@"CKWebViewControllerGoBack.png"] forButton:CKWebViewButtonBack];
	[self setImage:[CKBundle imageForName:@"CKWebViewControllerGoForward.png"] forButton:CKWebViewButtonForward];
	self.reloadButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)] autorelease];
	self.spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	
	[self generateToolbar];	
}

- (id)initWithURL:(NSURL *)url {
	if (self = [super init]) {
		self.homeURL = url;
		[self setup];
	}
    return self;	
}

- (id)initWithHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
	if (self = [super init]) {
		self.HTMLString = string;
		self.baseURL = baseURL;
		[self setup];
	}
    return self;	
}

- (void)dealloc {
	[_HTMLString release];
	[_baseURL release];
	[_reloadButton release];
	[_webView release];
	[_homeURL release];
	[_backButton release];
	[_forwardButton release];
	[_toolbarButtonsStatic release];
	[_toolbarButtonsLoading release];
	[_navigationControllerStyles release];
	[_onLoadScript release];
	[_webViewToolbar release];
    [super dealloc];
}

//

- (void)viewDidLoad {
	[super viewDidLoad];

	//self.view.autoresizingMask = CKUIViewAutoresizingFlexibleAll;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	// Set up the WebView
	_webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
	_webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	_webView.scalesPageToFit = YES;
	_webView.delegate = self;
	self.view.backgroundColor = [UIColor blackColor];
	[self.view addSubview:_webView];
	
	self.webViewToolbar = [[[UIToolbar alloc] init] autorelease];
	self.webViewToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:_webViewToolbar];
	
	// Not available on iOS < 3.2
	if ([self respondsToSelector:@selector(setContentSizeForViewInPopover:)]) {
		[self setContentSizeForViewInPopover:self.minContentSizeForViewInPopover];
	}
	
	if (_canBeDismissed) {
		UIBarButtonItem *cancelButton = 
		  [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
														 target:self
														 action:@selector(dismiss)] autorelease];
		self.navigationItem.leftBarButtonItem = cancelButton;
	}
	
	_didFinishLoading = NO;
}

- (void)viewDidUnload {
	[_webView release];
	[_backButton release];
	[_forwardButton release];
	[_webViewToolbar release];
}

//

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// Save the NavigationController styles
	_navigationControllerStyles = [[self.navigationController getStyles] retain];
	[self.navigationController setToolbarHidden:YES animated:NO];
	[self.navigationController setNavigationBarHidden:NO animated:animated];

	// Setup the web view
	_webView.frame = self.hidesToolbar ? self.view.bounds : CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 44);
	
	// Setup the custom toolbar
	self.webViewToolbar.frame = CGRectMake(0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44);
	[self updateToolbar];
	[self.webViewToolbar setItems:_toolbarButtonsStatic animated:animated];

	self.webViewToolbar.hidden = self.hidesToolbar;
	
	// Start loading the content
	
	if (_didFinishLoading == NO) {
		_webView.alpha = 0;
	
		if (_homeURL) {
			NSURLRequest *request = [[NSURLRequest alloc] initWithURL:_homeURL];
			[_webView loadRequest:request];
			[request release];
		} else if (_HTMLString) {
			[_webView loadHTMLString:_HTMLString baseURL:self.baseURL];
		}
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if (_webView.loading) [_webView stopLoading];
	_webView.delegate = nil;

	// Restore the NavigationController styles
	[self.navigationController setStyles:_navigationControllerStyles animated:animated];

	[super viewWillDisappear:animated];
}

//

- (void)setActionButtonWithStyle:(UIBarButtonSystemItem)style action:(SEL)action target:(id)target {
	UIBarButtonItem *actionButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:style target:target action:action] autorelease];
	[_toolbarButtonsStatic addObject:CKBarButtonItemFlexibleSpace];
	[_toolbarButtonsStatic addObject:actionButton];
	[_toolbarButtonsLoading addObject:CKBarButtonItemFlexibleSpace];
	[_toolbarButtonsLoading addObject:actionButton];
}

- (NSURL *)currentURL {
	return [[NSURL URLWithString:[_webView stringByEvaluatingJavaScriptFromString:@"window.location.href"]] standardizedURL];
}

#pragma mark -
#pragma mark Toolbar

- (void)updateToolbar {
	_backButton.enabled = _webView.canGoBack;
	_forwardButton.enabled = _webView.canGoForward;
	
	[self generateToolbar];
	if ([_webView isLoading]) [self.webViewToolbar setItems:self.toolbarButtonsLoading animated:NO];
	else [self.webViewToolbar setItems:self.toolbarButtonsStatic animated:NO];
}

- (void)goBack {
	[_webView goBack];
}

- (void)goForward {
	[_webView goForward];
}

- (void)reload {
	[_webView reload];
}

#pragma mark -
#pragma mark Toolbar Customization

- (void)generateToolbar {
	self.toolbarButtonsStatic = [NSMutableArray arrayWithObjects:self.backButton, CKBarButtonItemFlexibleSpace, self.forwardButton, CKBarButtonItemFlexibleSpace, CKBarButtonItemFlexibleSpace, CKBarButtonItemFlexibleSpace, self.reloadButton, nil];
	[self.spinner startAnimating];
	UIBarButtonItem *loadingItem = [[[UIBarButtonItem alloc] initWithCustomView:self.spinner] autorelease];
	self.toolbarButtonsLoading = [NSMutableArray arrayWithObjects:self.backButton, CKBarButtonItemFlexibleSpace, self.forwardButton, CKBarButtonItemFlexibleSpace, CKBarButtonItemFlexibleSpace, CKBarButtonItemFlexibleSpace, loadingItem, nil];
}

- (void)setImage:(UIImage *)image forButton:(CKWebViewButton)button {
	if (image == nil) return;

	UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)] autorelease];
	[btn setImage:image forState:UIControlStateNormal];
	
	switch (button) {
		case CKWebViewButtonBack:
			[btn addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
			self.backButton = [[[UIBarButtonItem alloc] initWithCustomView:btn] autorelease];
			break;
		case CKWebViewButtonForward:
			[btn addTarget:self action:@selector(goForward) forControlEvents:UIControlEventTouchUpInside];
			self.forwardButton = [[[UIBarButtonItem alloc] initWithCustomView:btn] autorelease];
			break;
		case CKWebViewButtonReload:
			[btn addTarget:self action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
			self.reloadButton = [[[UIBarButtonItem alloc] initWithCustomView:btn] autorelease];
			break;
		default:
			break;
	}
	
	[self updateToolbar];
}

- (void)setSpinnerStyle:(UIActivityIndicatorViewStyle)style {
	_spinner.activityIndicatorViewStyle = style;
}

#pragma mark -
#pragma mark WebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if ([request.URL isEqual:[NSURL URLWithString:@"about:blank"]] && navigationType == UIWebViewNavigationTypeReload) return NO;
	if ([[request.URL scheme] isEqual:@"itms-apps"]) { 
		[[UIApplication sharedApplication] openURL:request.URL];
		return NO;
	}
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[self updateToolbar];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		
	[self updateToolbar];

	// Update the title
	if (_showURLInTitle) self.title = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
	
	// Run the optional after the view has finished loading
	if (_onLoadScript) [_webView stringByEvaluatingJavaScriptFromString:_onLoadScript];
	
	// Change the size of the popover according to the size of the body
	CGFloat height = [[_webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight"] floatValue];
	
	if (height > 0) {
		if (height < self.minContentSizeForViewInPopover.height) height = self.minContentSizeForViewInPopover.height;
		if (height > self.maxContentSizeForViewInPopover.height) height = self.maxContentSizeForViewInPopover.height;
		
		// Not available in iOS < 3.2
		if ([self respondsToSelector:@selector(setContentSizeForViewInPopover:)]) {
			[self setContentSizeForViewInPopover:CGSizeMake(self.contentSizeForViewInPopover.width, height)];
		}
	}
	_didFinishLoading = YES;

	[UIView beginAnimations:@"WebView" context:nil];
	_webView.alpha = 1.0f;
	[UIView commitAnimations];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;	
	[self updateToolbar];
}

#pragma mark -
#pragma mark Dismiss

- (void)dismiss {
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

@end
