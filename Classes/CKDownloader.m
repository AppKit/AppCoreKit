//
//  CKDownloader.m
//  CloudKit
//
//  Created by Sebastien Morel, Fred Brunel on 11-02-18.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKDownloader.h"

//

static NSOperationQueue *CKDownloaderQueue = nil;
NSString * const CKDownloaderErrorDomain = @"CKDownloaderErrorDomain";

//

@interface CKDownloader ()
@property (nonatomic, copy) CKDownloaderCompletionBlock completionBlock;
@property (nonatomic, retain) CKWebRequest *request;
- (BOOL)retry;
@end

//

@implementation CKDownloader

@synthesize delegate = _delegate;
@synthesize userInfo = _userInfo;
@synthesize request = _request;
@synthesize URL = _URL;
@synthesize destinationPath = _destinationPath;
@synthesize progress = _progress;
@synthesize completionBlock = _completionBlock;

- (id)initWithDelegate:(id)delegate {
	if (self = [super init]) {
		self.delegate = delegate;
		self.progress = 0;
		_byteReceived = 0;
		_expectedLength = 0;
		_skipResponseData = NO;
        _retriesCount = 0;
	}
	return self;
}

- (void)dealloc {
	[self cancel];
    [super dealloc];
}

#pragma mark Public API

- (void)downloadContentOfURL:(NSURL *)URL destination:(NSString *)destination completion:(CKDownloaderCompletionBlock)completion {
    [self cancel];

    self.completionBlock = completion;
    self.URL = URL;
    self.destinationPath = destination;

	self.request = [CKWebRequest requestWithURL:self.URL];
	self.request.delegate = self;

	BOOL allowOverwrite = YES;

	if ([[NSFileManager defaultManager] fileExistsAtPath:self.destinationPath]) {
		NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.destinationPath error:nil];
		_byteReceived = [attributes fileSize];
		self.progress = (float)_byteReceived / (float)_expectedLength;		
		NSString* bytesStr = [NSString stringWithFormat:@"bytes=%qu-", _byteReceived];
		[self.request setHeaders:[NSDictionary dictionaryWithObject:bytesStr forKey:@"Range"]];
		allowOverwrite = NO;
	}
	
	[self.request setDestination:self.destinationPath allowOverwrite:allowOverwrite];
		 
	if (CKDownloaderQueue == nil){
		CKDownloaderQueue = [[NSOperationQueue alloc] init];
		[CKDownloaderQueue setMaxConcurrentOperationCount:4];
	}
	
	[CKDownloaderQueue addOperation:self.request];
} 

- (void)cancel {
    self.request.delegate = nil;
	[self.request cancel];
	self.request = nil;
}

// 

- (void)setExpectedLength:(unsigned long long)length {
	_expectedLength = length;
}

- (NSUInteger)totalBytesWritten {
    return _byteReceived;
}

- (NSUInteger)totalExpectedBytes {
    return _expectedLength;
}

#pragma mark Private API

- (BOOL)retry {
    if (_retriesCount++ == 3)
        return NO;
	[self cancel];
	[self downloadContentOfURL:self.URL destination:self.destinationPath completion:self.completionBlock];
    return YES;
}

#pragma mark CKWebRequestDelegate Protocol

- (void)requestDidFinishLoading:(id)request{
	self.progress = 1.0f;

    if (self.completionBlock) {
        self.completionBlock();
    }    
	
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloaderDidFinish:)]) {
		[self.delegate downloaderDidFinish:self];
	}
}

- (void)request:(id)request didReceiveResponse:(NSURLResponse *)response {
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse *)response;

    if ([httpResponse statusCode] >= 400) {
        _skipResponseData = YES;
        return;
    }
    
    unsigned long long length = [httpResponse expectedContentLength];
    if (length == _byteReceived) {
        [self cancel];
        return;
    }
    
    _expectedLength = ([httpResponse expectedContentLength] + _byteReceived);
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(downloader:didReceiveResponse:)]) {
		[self.delegate downloader:self didReceiveResponse:httpResponse];
	}
}

- (void)request:(id)request didFailWithError:(NSError *)error {
	if ([error code] == NSURLErrorTimedOut) {
		if ([self retry] == YES)
            return;
	}
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloader:didFailWithError:)]) {
        [self.delegate downloader:self didFailWithError:error];
    }
}

- (void)request:(id)request didReceivePartialData:(NSData*)data progress:(NSNumber *)progress {
	if (_skipResponseData)
		return;
    
	_byteReceived += [data length];	
    self.progress = (float)_byteReceived / (float)_expectedLength;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloader:didReceiveDataOfLength:totalBytesWritten:totalBytesExpectedToWrite:)]) {
        [self.delegate downloader:self
           didReceiveDataOfLength:[data length]
                totalBytesWritten:_byteReceived
        totalBytesExpectedToWrite:_expectedLength];
	}
}

@end