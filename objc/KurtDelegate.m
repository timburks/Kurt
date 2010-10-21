/*!
 @file KurtDelegate.m
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

#import "KurtMain.h"
#import "KurtDelegate.h"
#import "KurtRequestRouter.h"
#import "KurtRequestHandler.h"

@implementation KurtDefaultDelegate

static KurtDefaultDelegate *_sharedDelegate;

+ (KurtDefaultDelegate *) sharedDelegate
{
    return _sharedDelegate;
}

- (id) init
{
    if (self = [super init]) {
        self->router = [[KurtRequestRouter routerWithToken:@"SITE"] retain];
    }
    _sharedDelegate = self;
    return self;
}

- (void) configureSite:(NSString *) site
{
    id parser = [Nu parser];

    // set working directory to site path
    NSString *directory = [site stringByDeletingLastPathComponent];
    chdir([directory cStringUsingEncoding:NSUTF8StringEncoding]);

    // load site description
    NSString *filename = [[site pathComponents] lastObject];
    NSString *sourcecode = [NSString stringWithContentsOfFile:filename
        encoding:NSUTF8StringEncoding
        error:nil];
    if (sourcecode) {
        [parser parseEval:sourcecode];
    }
}

- (void) setDefaultHandlerWithBlock:(id) block
{
    id handler = [KurtRequestHandler handlerWithHTTPMethod:@"GET" path:@"" block:block];
    [handler retain];
    [self->defaultHandler release];
    self->defaultHandler = handler;
}

- (void) addHandler:(id) handler
{
    [self->router insertHandler:handler level:0];
}

- (void) addHandlerWithHTTPMethod:(NSString *)httpMethod path:(NSString *)path block:(id)block
{
    [self addHandler:[KurtRequestHandler handlerWithHTTPMethod:httpMethod path:path block:block]];
}

- (void) dump
{
    NSLog(@"Kurt Request Handlers:\n%@", [self->router description]);
}

- (void) handleRequest:(KurtRequest *) request
{
    id path = [request path];
    if ([Kurt verbose]) {
        NSLog(@"REQUEST %@ %@ ----", [request HTTPMethod], path);
        NSLog(@"%@", [request requestHeaders]);
    }
    [request setValue:@"Kurt" forResponseHeader:@"Server"];
    [request setBindings:[NSMutableDictionary dictionary]];

    id httpMethod = [request HTTPMethod];
    if ([httpMethod isEqualToString:@"HEAD"])
        httpMethod = @"GET";

    id parts = [[NSString stringWithFormat:@"%@%@", httpMethod, [request path]] componentsSeparatedByString:@"/"];
    if (([parts count] > 2) && [[parts lastObject] isEqualToString:@""]) {
        parts = [parts subarrayWithRange:NSMakeRange(0, [parts count]-1)];
    }

    BOOL handled = NO;

    if (!handled) {
        handled = [router routeAndHandleRequest:request parts:parts level:0];
    }

    if (!handled) {                               // does the path end in a '/'? If so, append index.html
        unichar lastCharacter = [path characterAtIndex:[path length] - 1];
        if (lastCharacter == '/') {
            if (!handled) {
                NSString *filename = [NSString stringWithFormat:@"public%@index.html", path];
                if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
                    NSData *data = [NSData dataWithContentsOfFile:filename];
                    [request setValue:[Kurt mimeTypeForFileWithName:filename] forResponseHeader:@"Content-Type"];
                    [request setValue:@"max-age=3600" forResponseHeader:@"Cache-Control"];
                    [request respondWithData:data];
                    handled = YES;
                }
            }
            if (!handled) {
                NSString *filename = [NSString stringWithFormat:@"public%@prog_index.m3u8", path];
                if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
                    NSData *data = [NSData dataWithContentsOfFile:filename];
                    [request setValue:[Kurt mimeTypeForFileWithName:filename] forResponseHeader:@"Content-Type"];
                    [request setValue:@"max-age=3600" forResponseHeader:@"Cache-Control"];
                    [request respondWithData:data];
                    handled = YES;
                }
            }
        }
    }

    if (!handled) {
        // look for a file or directory that matches the path
        NSString *filename = [NSString stringWithFormat:@"public%@", path];
        BOOL isDirectory = NO;
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDirectory];
        if (fileExists) {
            if (isDirectory) {
                unichar lastCharacter = [path characterAtIndex:[path length] - 1];
                if (lastCharacter != '/') {
                    // for a directory, redirect to the same path with '/' appended
                    [request setValue:[path stringByAppendingString:@"/"] forResponseHeader:@"Location"];
                    [request respondWithCode:301 message:@"moved permanently" string:@"Moved Permanently"];
                    handled = YES;
                }
            }
            else {
                // for a file, send its contents
                NSData *data = [NSData dataWithContentsOfFile:filename];
                [request setValue:[Kurt mimeTypeForFileWithName:filename] forResponseHeader:@"Content-Type"];
                [request setValue:@"max-age=3600" forResponseHeader:@"Cache-Control"];
                [request respondWithData:data];
                handled = YES;
            }
        }
    }

    if (!handled) {                               // try appending .html to the path
        NSString *filename = [NSString stringWithFormat:@"public%@.html", path];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
            NSData *data = [NSData dataWithContentsOfFile:filename];
            [request setValue:@"text/html" forResponseHeader:@"Content-Type"];
            [request setValue:@"max-age=3600" forResponseHeader:@"Cache-Control"];
            [request respondWithData:data];
            handled = YES;
        }
    }

    if (!handled && defaultHandler) {
        @try
        {
            handled = [defaultHandler handleRequest:request];;
        }
        @catch (id exception) {
            NSLog(@"Kurt default handler exception: %@ %@", [exception description], [request description]);
        }
    }

    if (!handled) {
        [request respondWithCode:404
            message:@"Not Found"
            string:[NSString stringWithFormat:@"Not Found. You said: %@ %@", [request HTTPMethod], [request path]]];
    }

}

- (void) applicationDidFinishLaunching
{

}

@end
