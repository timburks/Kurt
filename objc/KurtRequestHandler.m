/*!
 @file KurtRequestHandler.m
 @discussion Kurt web server request handler.
 @copyright Copyright (c) 2010 Neon Design Technology, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "KurtRequestHandler.h"
#import "KurtRequest.h"
#import <Nu/Nu.h>

@implementation KurtRequestHandler

- (NSString *) path {
   return path;
}

- (NSString *) httpMethod {
   return httpMethod;
}

- (NSMutableArray *) parts {
   return self->parts;
}

+ (KurtRequestHandler *) handlerWithHTTPMethod:(id)httpMethod path:(id)path block:(id)block
{
    KurtRequestHandler *handler = [[[KurtRequestHandler alloc] init] autorelease];
    handler->httpMethod = [httpMethod retain];
    handler->path = [path retain];
    handler->parts = [[[NSString stringWithFormat:@"%@%@", httpMethod, path] componentsSeparatedByString:@"/"] retain];
    handler->block = [block retain];
    return handler;
}

// Handle a request. Used internally.
- (BOOL) handleRequest:(KurtRequest *)request
{
    if ([Kurt verbose]) {
        NSLog(@"handling request %@", [request uri]);
        NSLog(@"request from host %@ port %d", [request remoteHost], [request remotePort]);
    }
	
    id args = [[[NuCell alloc] init] autorelease];
    [args setCar:request];
	
	id body = nil;
	if ([block isKindOfClass:[NuBlock class]]) {
		// evaluate block with request as the single argument
		body = [block evalWithArguments:args context:[NSMutableDictionary dictionary]];
	} 
#ifdef DARWIN
	else {
		// evaluate block as a C block		
		body = ((id(^)(id)) block)(request);
	}
#endif
	
    if ([Kurt verbose]) {
        NSLog(@"evaluated with status %d", [request responseCode]);
    }

    static id text_html_pattern = nil;
    if (!text_html_pattern) {
        text_html_pattern = [[NuRegex regexWithPattern:@"^text/html.*$"] retain];
    }

    id content_type;

    if (!body || (body == [NSNull null])) {
        // return without responding, this means the handler has rejected the URL
        return NO;
    }
    else if ([body isKindOfClass:[NSData class]]) {
        // return data objects as-is
        // we should set the content type if it isn't set
        [request respondWithData:body];
        return YES;                               // just non-nil
    }
    else if (![body isKindOfClass:[NSString class]]) {
        // return other non-strings as their stringValues
        [request respondWithString:[body stringValue]];
        return YES;
    }
    else if ((content_type = [request valueForResponseHeader:@"Content-Type"]) && ![text_html_pattern findInString:content_type]) {
        // if a content type is set and it isn't text/html, return string as-is
        [request respondWithString:body];
        return YES;
    }
    else {
        // return string as html
        [request setContentType:@"text/html; charset=UTF-8"];
        [request respondWithString:body];
        return YES;
    }
}

@end
