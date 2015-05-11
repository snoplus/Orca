//
//  ResistorDBModel.m
//  Orca
//
//  Created by Chris Jones on 28/04/2014.
//
//

#import "ResistorDBModel.h"
#import "ORCouchDB.h"

#define kResistorDbHeaderRetrieved @"kResistorDbHeaderRetrieved"

@implementation ResistorDBModel

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"resistor"]];
}

/*- (void) queryResistorDb
 {
 //view to query
 NSString *requestString = [NSString stringWithFormat:@"_design/resistorQuery/_view/pullResistorInfoByPmt"];
 
 [[self generalDBRef:@"resistor"] getDocumentId:requestString tag:@"kResistorDbHeaderRetrieved"];
 
 //[self setSmellieDBReadInProgress:YES];
 //[self performSelector:@selector(smellieDocumentsRecieved) withObject:nil afterDelay:10.0];
 
 }*/

-(void)couchDBResult:(id)aResult tag:(NSString *)aTag op:(id)anOp{
    @synchronized(self){
        if([aResult isKindOfClass:[NSDictionary class]]){
            NSString* message = [aResult objectForKey:@"Message"];
            if(message){
                [aResult prettyPrint:@"CouchDB Message:"];
            }
            //Look through all of the possible tags for ellie couchDB results
            //This is called when smellie run header is queried from CouchDB
            if ([aTag isEqualToString:kResistorDbHeaderRetrieved])
            {
                NSLog(@"here\n");
                NSLog(@"Object: %@\n",aResult);
                NSLog(@"result: %@\n",[aResult objectForKey:@"SnoPmt"]);
                //[self parseSmellieRunHeaderDoc:aResult];
            }
            //If no tag is found for the query result
            else {
                NSLog(@"No Tag assigned to that query/couchDB View \n");
                NSLog(@"Object: %@\n",aResult);
            }
        }
        else if([aResult isKindOfClass:[NSArray class]]){
            
            [aResult prettyPrint:@"CouchDB"];
            
        }
        else {
            //no docs found 
        }
    }
}

- (void) makeMainController
{
    [self linkToController:@"ResistorDBViewController"];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
}

- (void) sleep
{
	[super sleep];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[super dealloc];
}

@end
