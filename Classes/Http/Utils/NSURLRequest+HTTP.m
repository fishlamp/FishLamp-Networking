//
//  NSURLRequest+HTTP.m
//  FishLamp
//
//  Created by Mike Fullerton on 5/19/11.
//  Copyright (c) 2013 GreenTongue Software LLC, Mike Fullerton.
//  The FishLamp Framework is released under the MIT License: http://fishlamp.com/license 
//

#import "NSURLRequest+HTTP.h"
#import "NSFileManager+FLExtras.h"
#import "NSString+URL.h"
#import "FLPrettyString.h"
#import "FLAppInfo.h"

@implementation NSURLRequest (HTTP)

static NSString* s_defaultUserAgent = nil;

+ (void) setDefaultUserAgent:(NSString*) userAgent {
	FLSetObjectWithRetain(s_defaultUserAgent, userAgent);
}

+ (NSString*) defaultUserAgent {
	return s_defaultUserAgent;
}

- (BOOL) hasHeader:(NSString*) header {
	return [self valueForHTTPHeaderField:header] != nil;
}

- (NSString*) postHeader {
	return [NSString stringWithFormat:@"%@ HTTP/1.1", self.URL.path];
}

- (void) logToStringBuilder:(FLPrettyString*) prettyString {
	
    NSDictionary* headers = [self allHTTPHeaderFields];
	[prettyString appendLine:@"HTTP request:"];
    [prettyString appendLineWithFormat:@"HTTP Method:%@", self.HTTPMethod];
    [prettyString appendLineWithFormat:@"URL: %@", [[self.URL absoluteString] urlDecodeString:NSUTF8StringEncoding]];
    [prettyString appendLine:@"All Headers:"];
    
    [prettyString indent: ^{
        for(id key in headers) {
            [prettyString appendLineWithFormat:@"%@: %@", [key description], [[headers objectForKey:key] description]];
            [prettyString closeLine];
        }
    }];
	
    [prettyString appendLine:@"Body:"];
    [prettyString closeLine];

	NSData* data = [self HTTPBody];
	NSString* stringData = FLAutorelease([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	if(FLStringIsNotEmpty(stringData)) {
        [prettyString indent:^{
            [prettyString appendLine:stringData];
            [prettyString closeLine];

        }];
    }
    
    [prettyString appendLine:@"eod"];
    [prettyString closeLine];
}

@end


@implementation NSMutableURLRequest (HTTP)


- (void) setUserAgentHeader:(NSString*) userAgent {
	FLAssertStringIsNotEmptyWithComment(userAgent, nil);
	[self setHeader:@"User-Agent" data:userAgent];
}

- (void) setUserAgentHeader {
	if(FLStringIsNotEmpty([NSURLRequest defaultUserAgent])) {
		[self setUserAgentHeader:s_defaultUserAgent];
	}
}

-(void) setHeader:(NSString*)headerName data:(NSString*)data
{
	[self setValue:data forHTTPHeaderField:headerName];
}

-(void) setUtf8Content:(NSString*) content
{
	[self setContentWithData:[content dataUsingEncoding:NSUTF8StringEncoding]
           typeContentHeader:@"text/xml; charset=utf-8" ];
}

- (void) setFormUrlEncodedContent:(NSString*) content
{
	[self setContentWithData:[content dataUsingEncoding:NSUTF8StringEncoding]
           typeContentHeader:@"application/x-www-form-urlencoded" ]; 
}

-(void) setContentTypeHeader:(NSString*) contentType
{
	[self setHeader:@"Content-Type" data:contentType];
}

-(void) setContentLengthHeader:(unsigned long long) length
{
	NSString* contentLength = [[NSString alloc] initWithFormat:@"%llu", length];
	[self setHeader:@"Content-Length" data:contentLength];
	FLReleaseWithNil(contentLength);
}

- (void) setContentWithData:(NSData*) content
          typeContentHeader:(NSString*) typeContentHeader
{
	[self setHTTPBody:content];
	[self setContentTypeHeader:typeContentHeader];
	[self setContentLengthHeader:[content length]];
}

- (void) setContentWithInputStream:(NSInputStream*) stream
                       typeContentHeader: (NSString*) typeContentHeader 
						inputSize:(unsigned long long) size
{
	[self setContentTypeHeader:typeContentHeader];
	[self setContentLengthHeader:size];
	[self setHTTPBodyStream:stream];
}

- (void) setContentWithFilePath:(NSString*) path 
              typeContentHeader:(NSString*) typeContentHeader
{
	unsigned long long fileSize = 0;
	NSError* err = 0;
	if([NSFileManager getFileSize:path outSize:&fileSize outError:&err]) {
		FLThrowIfError(FLAutorelease(err));
	}

	NSInputStream* stream = FLAutorelease([[NSInputStream alloc] initWithFileAtPath:path]);
	[self setContentWithInputStream:stream
        typeContentHeader:typeContentHeader 
		inputSize:fileSize];
}

- (void) setHostHeader:(NSString*) host
{
	FLAssertStringIsNotEmptyWithComment(host, nil);
	[self setHeader:@"HOST" data:host];
}

- (void) setHTTPMethodToPost
{
	[self setHTTPMethod:@"POST"];
	[self setValue:self.postHeader forHTTPHeaderField:@"POST"];
}

- (void) setImageContentWithFilePath:(NSString*) filePath
{
	FLAssertStringIsNotEmptyWithComment(filePath, nil);
	[self setContentWithFilePath:filePath typeContentHeader:@"image/jpeg"];
}

- (void) setImageContentWithData:(NSData*) imageData
{
	FLAssertIsNotNilWithComment(imageData, nil);
	FLAssertWithComment(imageData.length > 0, @"Empty data");
	[self setContentWithData:imageData typeContentHeader:@"image/jpeg"];
}

- (void) setImageContentWithInputStream:(NSInputStream*) stream   inputSize:(NSUInteger) size
{
	FLAssertIsNotNilWithComment(stream, nil);
	[self setContentWithInputStream:stream typeContentHeader:@"image/jpeg" inputSize:size];
}

@end
