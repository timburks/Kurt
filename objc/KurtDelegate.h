/*!
 @file KurtDelegate.h
 @discussion Kurt web server default delegate.
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

@class KurtRequestHandler;
@class KurtRequestRouter;

@interface KurtDefaultDelegate : NSObject <KurtDelegate>
{
    KurtRequestHandler *defaultHandler;
    KurtRequestRouter *router;
}

- (void) configureSite:(NSString *) site;

- (void) addHandler:(KurtRequestHandler *) handler;
- (void) addHandlerWithHTTPMethod:(NSString *)httpMethod path:(NSString *)path block:(id)block;
- (void) setDefaultHandlerWithBlock:(id) block;

- (void) dump;

@end
