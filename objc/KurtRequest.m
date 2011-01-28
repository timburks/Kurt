/*!
 @file KurtRequest.m
 @discussion Kurt web server request model.
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

#import "KurtMain.h"
#import "KurtRequest.h"
#import <Nu/Nu.h>

#include <sys/types.h>
#include <sys/time.h>
#include <sys/queue.h>

#include <event2/event.h>
#include <event2/http.h>
#include <event2/event_compat.h>
#include <event2/http_compat.h>
#include <event2/http_struct.h>
#include <event2/buffer.h>
#include <event2/buffer_compat.h>
#include <event2/event_struct.h>

#include <netdb.h>
#include <arpa/inet.h>                            // inet_ntoa
#include <event2/dns.h>
#include <event2/dns_compat.h>

void kurt_response_helper(struct evhttp_request *req, int code, NSString *message, NSData *data);
NSDictionary *kurt_request_headers_helper(struct evhttp_request *req);

@interface NSString (Helpers)
- (NSDictionary *) urlQueryDictionary;
@end

@implementation KurtRequest

- (id) initWithKurt:(Kurt *)n request:(struct evhttp_request *)r
{
    [super init];
    kurt = n;
    req = r;
    // get the URI
    _uri = [[NSString alloc] initWithCString:evhttp_request_uri(req) encoding:NSUTF8StringEncoding];
    // scan for the path
    int max = [_uri length];
    int base = 0;
    int i = 0;
    unichar c = 0;
    while ((i < max) && ((c = [_uri characterAtIndex:i])) && (c != ';') && (c != '?'))
        i++;
    _path = [[_uri substringToIndex:i] retain];
    // if necessary, scan the object parameters
    _parameters = nil;
    if (c == ';') {
        i = i + 1;
        base = i;
        while ((i < max) && ((c = [_uri characterAtIndex:i])) && (c != '?'))
            i++;
        NSString *parameterString = [_uri substringWithRange:NSMakeRange(base, i-base)];
        _parameters = [[parameterString urlQueryDictionary] retain];
    }
    // if necessary, scan the query string
    _query = nil;
    if (c == '?') {
        i = i + 1;
        base = i;
        while ((i < max) && [_uri characterAtIndex:i])
            i++;
        NSString *queryString = [_uri substringWithRange:NSMakeRange(base, i-base)];
        _query = [[queryString urlQueryDictionary] retain];
    }
	// set the body data
	[self initializeBody];
    // we haven't responded yet
    _responded = NO;
    // default response code is that everything is ok
    _responseCode = HTTP_OK;
    _responseMessage = @"OK";
    return self;
}

- (void) dealloc
{
    [_uri release];
    [_path release];
    [_parameters release];
    [_query release];
    [_bindings release];
    [_cookies release];
	[_body release];
    [super dealloc];
}

- (Kurt *) kurt {return kurt;}

- (NSString *) uri
{
    return _uri;
}

- (NSString *) path
{
    return _path;
}

- (NSDictionary *) parameters
{
    return _parameters ? _parameters : [NSDictionary dictionary];
}

- (NSDictionary *) query
{
    return _query ? _query : [NSDictionary dictionary];
}

- (NSDictionary *) post
{
    NSData *bodyData = [self body];
    if (!bodyData)
        return [NSDictionary dictionary];
    NSString *bodyString = [[[NSString alloc]
        initWithData:bodyData encoding:NSUTF8StringEncoding]
        autorelease];
    if (!bodyString)
        return [NSDictionary dictionary];
    return [bodyString urlQueryDictionary];
}

- (id) bindings
{
    return _bindings ? _bindings : [NSDictionary dictionary];
}

- (void) setBindings:(id) bindings
{
    [bindings retain];
    [_bindings release];
    _bindings = bindings;
}

- (void) initializeBody
{
	int length = evbuffer_get_length(req->input_buffer);
    if (!length)
        [self setBody:nil];
    else {
		unsigned char *bytes = evbuffer_pullup(req->input_buffer, -1);
        [self setBody:[NSData dataWithBytes:bytes length:length]];
    }
}

- (NSData *) body 
{
	return _body;
}

- (void) setBody:(NSData *) b 
{
	[b retain];
	[_body release];
	_body = b;
}

- (NSString *) HTTPMethod
{
    switch (req->type) {
        case EVHTTP_REQ_GET:
            return @"GET";
        case EVHTTP_REQ_POST:
            return @"POST";
        case EVHTTP_REQ_HEAD:
            return @"HEAD";
        case EVHTTP_REQ_PUT:
            return @"PUT";
        case EVHTTP_REQ_DELETE:
            return @"DELETE";
        default:
            return @"UNKNOWN";
    }
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"(REQUEST %@ %@)", [self HTTPMethod], [self path]];
}

- (NSString *) remoteHost
{
    return [NSString stringWithCString:req->remote_host encoding:NSUTF8StringEncoding];
}

- (int) remotePort
{
    return req->remote_port;
}

NSDictionary *kurt_request_headers_helper(struct evhttp_request *req)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    struct evkeyval *header;
    TAILQ_FOREACH(header, req->input_headers, next) {
        [dict setObject:[NSString stringWithCString:header->value encoding:NSUTF8StringEncoding]
            forKey:[NSString stringWithCString:header->key encoding:NSUTF8StringEncoding]];
    }
    return dict;
}

- (NSDictionary *) requestHeaders
{
    return kurt_request_headers_helper(req);
}

static NSDictionary *kurt_response_headers_helper(struct evhttp_request *req)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    struct evkeyval *header;
    TAILQ_FOREACH(header, req->output_headers, next) {
        NSString *value = [NSString stringWithCString:header->value encoding:NSUTF8StringEncoding];
        NSString *key = [NSString stringWithCString:header->key encoding:NSUTF8StringEncoding];
        if (value && key) {
            [dict setObject:value forKey:key];
        }
    }
    return dict;
}

- (NSDictionary *) responseHeaders
{
    return kurt_response_headers_helper(req);
}

- (int) setValue:(NSString *) value forResponseHeader:(NSString *) key
{
    return evhttp_add_header(req->output_headers, [key cStringUsingEncoding:NSUTF8StringEncoding], [value cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (NSString *) valueForResponseHeader:(NSString *) key
{
    const char *value = evhttp_find_header(req->output_headers, [key cStringUsingEncoding:NSUTF8StringEncoding]);
    return value ? [NSString stringWithCString:value encoding:NSUTF8StringEncoding] : nil;
}

- (int) removeResponseHeader:(NSString *) key
{
    return evhttp_remove_header(req->output_headers, [key cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void) clearResponseHeaders
{
    evhttp_clear_headers(req->output_headers);
}

- (int) responseCode
{
    return _responseCode;
}

- (void) setResponseCode:(int) code message:(NSString *) message
{
    _responseCode = code;
    [message retain];
    [_responseMessage release];
    _responseMessage = message;
}

void kurt_response_helper(struct evhttp_request *req, int code, NSString *message, NSData *data)
{
    if ([Kurt verbose]) {
        NSLog(@"RESPONSE %d %@ %@", code, message, [kurt_response_headers_helper(req) description]);
    }
    struct evbuffer *buf = evbuffer_new();
    if (buf == NULL) {
        NSLog(@"FATAL: failed to create response buffer");
        assert(0);
    }
    if (req->type != EVHTTP_REQ_HEAD) {
        int result = evbuffer_add(buf, [data bytes], [data length]);
        if (result == -1) {
            NSLog(@"WARNING: failed to write %d bytes to response buffer", [data length]);
        }
    }
    else {
        char buffer[100];
        sprintf(buffer, "%d", (int) [data length]);
        evhttp_add_header(req->output_headers, "Content-Length", buffer);
    }
    evhttp_send_reply(req, code, [message cStringUsingEncoding:NSUTF8StringEncoding], buf);
    evbuffer_free(buf);
}

- (BOOL) respondWithString:(NSString *) string
{
    if (!_responded) {
        kurt_response_helper(req, _responseCode, _responseMessage, [string dataUsingEncoding:NSUTF8StringEncoding]);
        _responded = YES;
    }
    return YES;
}

- (BOOL) respondWithData:(NSData *) data
{
    if (!_responded) {
        kurt_response_helper(req, _responseCode, _responseMessage, data);
        _responded = YES;
    }
    return YES;
}

- (BOOL) respondWithCode:(int) code message:(NSString *) message string:(NSString *) string
{
    if (!_responded) {
        kurt_response_helper(req, code, message, [string dataUsingEncoding:NSUTF8StringEncoding]);
        _responded = YES;
    }
    return YES;
}

- (BOOL) respondWithCode:(int) code message:(NSString *) message data:(NSData *) data
{
    if (!_responded) {
        kurt_response_helper(req, code, message, data);
        _responded = YES;
    }
    return YES;
}

- (NSDictionary *) cookies
{
    static NuRegex *cookie_pattern = nil;
    if (!cookie_pattern) {
        cookie_pattern = [[NuRegex regexWithPattern:@"[ ]*([^=]*)=(.*)"] retain];
    }
    if (!_cookies) {
        _cookies = [[NSMutableDictionary alloc] init];
        NSString *cookieText = [[self requestHeaders] objectForKey:@"Cookie"];
        NSArray *parts = [cookieText componentsSeparatedByString:@";"];
        for (int i = 0; i < [parts count]; i++) {
            NSString *cookieDescription = [parts objectAtIndex:i];
            id match = [cookie_pattern findInString:cookieDescription];
            if (match) {
                [_cookies setObject:[match groupAtIndex:2] forKey:[match groupAtIndex:1]];
            }
        }
    }
    return _cookies;
}

- (void) setContentType:(NSString *)content_type
{
    [self setValue:content_type forResponseHeader:@"Content-Type"];
}

- (NSString *) redirectResponseToLocation:(NSString *) location
{
    [self setValue:location forResponseHeader:@"Location"];
    [self respondWithCode:303 message:@"redirecting" string:@"redirecting"];
    return [NSString stringWithFormat:@"redirecting to %@", location];
}

@end
