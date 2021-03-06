#import <Foundation/Foundation.h>
#import "Kurt/Kurt.h"

@interface MyKurtDelegate : KurtDefaultDelegate 
{
}
@end

@implementation MyKurtDelegate

- (void) applicationDidFinishLaunching {	
#ifdef DARWIN
	[self addHandlerWithHTTPMethod:@"GET"
							  path:@"/block/me:"
							 block:^(KurtRequest *REQUEST) {
								 NSMutableString *result = [NSMutableString string];
								 [result appendString:@"Handling 'block'\n"];
								 [result appendString:@"Bindings\n"];
								 [result appendString:[[REQUEST bindings] description]];
								 [result appendString:@"\n"];
								 [result appendString:@"Query\n"];
								 [result appendString:[[REQUEST query] description]];
								 [REQUEST setContentType:@"text/plain"];
								 return result;
							 }];
#endif
}
@end

int main (int argc, const char * argv[])
{
	return KurtMain(argc, argv, @"MyKurtDelegate");
}
