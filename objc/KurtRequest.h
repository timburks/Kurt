/*!
 @file KurtRequest.h
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

#import <Foundation/Foundation.h>

@class Kurt;

@interface KurtRequest : NSObject
{
    Kurt *kurt;
    struct evhttp_request *req;
    NSString *_uri;
    NSString *_path;
    NSDictionary *_parameters;
    NSDictionary *_query;
    NSDictionary *_bindings;
    id _cookies;
    int _responded;
    int _responseCode;
    NSString *_responseMessage;
}

- (id) initWithKurt:(Kurt *)n request:(struct evhttp_request *)r;
- (Kurt *) kurt;
- (NSString *) uri;
- (NSString *) path;
- (NSDictionary *) parameters;
- (NSDictionary *) query;
- (NSDictionary *) post;
- (id) bindings;
- (void) setBindings:(id) bindings;
- (NSData *) body;
- (NSString *) HTTPMethod;
- (NSString *) remoteHost;
- (int) remotePort;
- (NSDictionary *) requestHeaders;
- (NSDictionary *) responseHeaders;
- (int) setValue:(NSString *) value forResponseHeader:(NSString *) key;
- (NSString *) valueForResponseHeader:(NSString *) key;
- (int) removeResponseHeader:(NSString *) key;
- (void) clearResponseHeaders;
- (int) responseCode;
- (void) setResponseCode:(int) code message:(NSString *) message;
- (int) setValue:(NSString *) value forResponseHeader:(NSString *) key;
- (BOOL) respondWithString:(NSString *) string;
- (BOOL) respondWithData:(NSData *) data;
- (BOOL) respondWithCode:(int) code message:(NSString *) message string:(NSString *) string;
- (BOOL) respondWithCode:(int) code message:(NSString *) message data:(NSData *) data;
- (NSDictionary *) cookies;
- (void) setContentType:(NSString *)content_type;
- (NSString *) redirectResponseToLocation:(NSString *) location;


@end
