//
//  XmlrpcClient.m
//  Orca
//
//  Created by Edward Leming on 10/02/2016.
//

#import <Foundation/Foundation.h>
#import "wpxmlrpc.h"
#import "XmlrpcClient.h"

@implementation XmlrpcClient


@synthesize host;
@synthesize port;

-(id)init
{
    self = [self initWithHostName:@"" withPort:@"-1"];
    return self;
}

-(id)initWithHostName:(NSString *)_host withPort:(NSString *)_port
{
    self = [super init];
    
    if(self){
        self.host = _host;
        self.port = _port;
        _timeout = 5; //5s default timeout
    }
    return self;
}

-(void)setTimeout:(float)timeout
{
    _timeout = timeout;
}

-(NSString *)getResult
{
    if(_responseString == nil){
        NSLog(@"WARNING: XMLRPC response string is nil");
    }
    return _responseString;
}

-(void)command:(NSString *)fmt
{
    [self command:(NSString *)fmt withArgs:nil];
}

-(void)command:(NSString *)fmt withArgs:args
{
    /*
     * Encodes a command with the xmlrpc protocol and pipes it up to the
     * http://host:port address using the NSURLConnection class. The 
     * NSURLConnection communication can occur either syncronously or 
     * asyncronously, dependent on the BOOL asyncFlag property of
     * the class instance.
    */

    NSString *URLString = [NSString stringWithFormat:@"http://%@:%@", self.host, self.port];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];

    
    request.timeoutInterval = _timeout;
    [request setHTTPMethod:@"POST"];
    
    WPXMLRPCEncoder *encoder = [[WPXMLRPCEncoder alloc] initWithMethod:fmt andParameters:args];
    [request setHTTPBody:[encoder dataEncodedWithError:nil]];
    
    //Make sure private data variables are set to nil an make request.
    _responseData = nil;
    _responseString = nil;
    
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                            returningResponse:&response
                                                        error:&error];
    if(error){
        NSLog(@"Error with xmlrpc client request");
        NSLog(@"Domain: %@", error.domain);
        NSLog(@"Error Code: %ld", error.code);
        NSLog(@"Description: %@", [error localizedDescription]);
        NSLog(@"Reason: %@", [error localizedFailureReason]);
        NSException *excep = [NSException exceptionWithName:@"XmlrpcClient"
                                                     reason:[error localizedDescription]
                                                   userInfo:nil];
        [excep raise];
    }

    WPXMLRPCDecoder *decoder = [[WPXMLRPCDecoder alloc] initWithData:data];
    
    if ([decoder isFault]) {
        NSException *excep = [NSException exceptionWithName:@"XmlrpcClient"
                                                     reason:[decoder faultString]
                                                   userInfo: nil];
        [excep raise];
    } else {
        _responseString = [NSMutableString stringWithFormat:@"%@",[decoder object]];
    }

    
}


#pragma mark NSURLConnection Delegate Methods
//NSURLConnection Delegate methods - For asynchronous requests.
// Implementing the async stuff was taking too long so never fully implemented
// this option in the command function.

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the
    // instance var you created so that we can append data to it in the
    // didReceiveData method. Furthermore, this method is called each time
    // there is a redirect so reinitializing it also serves to clear it.
    _responseData = [[NSMutableData alloc] init];
    _responseString = [[NSMutableString alloc] init];

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    WPXMLRPCDecoder *decoder = [[WPXMLRPCDecoder alloc] initWithData:data];
    NSMutableString* returnString = [NSMutableString stringWithFormat:@"%@",[decoder object]];
    NSLog(@"XML-RPC response: %@", returnString);
    _responseString = returnString;
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response
    // for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"Error with xmlrpc client request");
    NSLog(@"Domain: %@", error.domain);
    NSLog(@"Error Code: %ld", error.code);
    NSLog(@"Description: %@", [error localizedDescription]);
    NSLog(@"Reason: %@", [error localizedFailureReason]);
}

@end
