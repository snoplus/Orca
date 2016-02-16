//
//  XmlrpcClent.h
//  Orca
//
//  Created by Edward Leming on 10/02/2016.
//

#ifndef xmlrpc_testing_XmlrpcClient_h
#define xmlrpc_testing_XmlrpcClient_h
@interface XmlrpcClient : NSObject<NSURLConnectionDelegate>
{
    //Privates go here
    NSMutableData* _responseData;
    NSMutableString* _responseString;
    float _timeout;
}

@property (nonatomic) NSString* host;
@property (nonatomic) NSString* port;

-(id)init;
-(id)initWithHostName:(NSString *)_host withPort:(NSString *)_port;

-(void)setTimeout:(float)_timeout;
-(NSString *)getResult;

-(void)command:(NSString *)fmt;
-(void)command:(NSString *)fmt withArgs:(NSArray *)args;

//NSURLConnection Delegate methods - For asynchronous requests.
// Implementing the async stuff was taking too long so never fully implemented
// this option in the command function.
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
-(NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
@end

#endif
