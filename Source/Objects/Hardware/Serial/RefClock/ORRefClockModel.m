//--------------------------------------------------------
// ORRefClockModel
// Created by Mark  A. Howe on Fri Jul 22 2005 / Julius Hartmann, KIT, November 2017
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//Washington at the Center for Experimental Nuclear Physics and
//Astrophysics (CENPA) sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files

#import "ORRefClockModel.h"
#import "ORSynClockModel.h"
#import "ORMotoGPSModel.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"

#pragma mark ***External Strings
NSString* ORRefClockModelVerboseChanged         = @"ORRefClockModelVerboseChanged";
NSString* ORRefClockModelSerialPortChanged      = @"ORRefClockModelSerialPortChanged";
NSString* ORRefClockModelUpdatedQueue           = @"ORRefClockModelUpdatedQueue";
NSString* ORRefClockLock                        = @"ORRefClockLock";

NSString* ORSynClock                            = @"ORSynClock";
NSString* ORMotoGPS                             = @"ORMotoGPS";

//#define maxReTx 3  // above this number, stop trying to
// retransmit and place an Error.

@interface ORRefClockModel (private)
- (void) timeout;
- (void) processOneCommandFromQueue;
- (void) processResponse:(NSData*)someData;
@end

@implementation ORRefClockModel

- (void) dealloc
{
    [synClockModel  release];
    [motoGPSModel   release];
	[super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"RefClock"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORRefClockController"];
}

- (NSString*) helpURL
{
	return @"RS232/RefClock.html";
}

#pragma mark ***Accessors

- (ORSynClockModel*) synClockModel{
    return synClockModel;
}
- (ORMotoGPSModel*) motoGPSModel{
    return motoGPSModel;
}

- (BOOL) verbose
{
    return verbose;
}

- (void) setVerbose:(BOOL)aVerbose
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVerbose:verbose];

    verbose = aVerbose;
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool: verbose] forKey:@"verbose"];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRefClockModelVerboseChanged object:self userInfo:userInfo];
}

- (void) setLastRequest:(NSDictionary*)aRequest
{
	[aRequest retain];
	[lastRequest release];
	lastRequest = aRequest;
}

- (void) setPortName:(NSString*)aPortName
{
    //over-riden from super
    [[[self undoManager] prepareWithInvocationTarget:self] setPortName:portName];
    if(aPortName==nil)aPortName = @"";
    
    if(![aPortName isEqualToString:portName]){
        [portName autorelease];
        portName = [aPortName copy];
        
        ORSerialPort* aPort = [[ORSerialPort alloc] init:[self portName] withName:@"RefClock"];
        [self setSerialPort:aPort];
        [aPort release];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSerialPortModelPortNameChanged object:self];
}

- (void) openPort:(BOOL)state
{
    if(state) {
        [serialPort open];
		[serialPort setSpeed:9600];
		[serialPort setParityNone];
		[serialPort setStopBits2:NO];
		[serialPort setDataBits:8];
 		[serialPort commitChanges];
        [serialPort setDelegate:self];
    }
    else [serialPort close];
    
    portWasOpen = [serialPort isOpen];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSerialPortModelPortStateChanged object:self];

}
- (BOOL) portIsOpen
{
    return [serialPort isOpen];
}

//put our parameters into any run header
// todo
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];

	[dictionary setObject:objDictionary forKey:[self identifier]];
	return objDictionary;
}

#pragma mark *** Commands
- (void) addCmdToQueue:(NSDictionary*)aCmd
{
    [self enqueueCmd:aCmd];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRefClockModelUpdatedQueue object:self];
    if(!lastRequest){
        [self processOneCommandFromQueue];
    }
}

- (void) dataReceived:(NSNotification*)note
{
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
        [self processResponse:[[note userInfo] objectForKey:@"data"]];
    }
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    
    synClockModel = [[decoder decodeObjectForKey:@"synClockModel"] retain];
    motoGPSModel  = [[decoder decodeObjectForKey:@"motoGPSModel"] retain];
    if(!synClockModel) synClockModel = [[ORSynClockModel alloc]init];
    if(!motoGPSModel)  motoGPSModel  = [[ORMotoGPSModel alloc]init];
    [synClockModel setRefClock:self];
    [motoGPSModel  setRefClock:self];

    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder  // todo: function needed?
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:synClockModel    forKey:@"synClockModel"];
    [encoder encodeObject:motoGPSModel    forKey:@"motoGPSModel"];
}

- (void)serialPortWriteProgress:(NSDictionary *)dataDictionary
{  // this function is required to writeDataInBackground via Serial Port
}

@end

@implementation ORRefClockModel (private)

- (void) processOneCommandFromQueue
{
    NSDictionary* aCmdDictionary = [self nextCmd];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRefClockModelUpdatedQueue object:self];

    if(aCmdDictionary){
        NSData* cmdData = [aCmdDictionary objectForKey:@"data"];
        float delay = [cmdData length]/500.0;  // give it some extra time for big data chunks
        [self startTimeout:3 + delay];
        [self setLastRequest:aCmdDictionary];
        [serialPort writeDataInBackground:cmdData];
    }
}

- (void) processResponse:(NSData*)someData
{
    //process the incoming data here and pass it to either the gps or the synclock
    if(!lastRequest)return;
    if(!inComingData)inComingData = [[NSMutableData data] retain];
    [inComingData appendData:someData];
    
    //while (((char*)[inComingData mutableBytes])[0] != 'X' && [inComingData length] > 0){  //  remove possible error bytes at beginning until 'X';
    // this can occur when the device has sent faulty data.
    //NSRange range = NSMakeRange(0, 1);
    //[inComingData replaceBytesInRange:range withBytes:NULL length:0];
    //if([self verbose]){
    //  NSLog(@"removed wrong starting Byte! \n");
    //}
    //}
    //int a = @40;
    //a = @50;
    unsigned short nBytes = [inComingData length];
    unsigned char* bytes  = (unsigned char *)[inComingData bytes];
    NSLog(@"receiving... (so far %d bytes ) \n", nBytes);
    //[self startTimeout:3]; //reset incase there is a lot of data
    if([[lastRequest objectForKey:@"replySize"] intValue] == nBytes){
        //if([inComingData length] >= 7) {
        if(bytes[nBytes - 2] == '\r' && bytes[nBytes - 1] == '\n' ) { // check for trailing \n (LF)
            NSLog(@"received %s \n", bytes);
            //NSLog(@"lastRequest contains %d bytes", [lastRequest length]);
            //       char* lastCmd;
            //
            //        lastCmd = (char*)[lastRequest bytes];
            //        //}
            //
            //        if([self verbose]){
            //            NSLog(@"last command: %s \n", lastCmd);
            //        }
            
            //unsigned int senderDevice;  // extract the device here
            //senderDevice = (bytes[0] == '@' && bytes[1] == '@') ? 'MGPS' : 'SYCK';  // check if the last incoming Data came from the MOTOGPS Clock (first two chars are '@'); otherwise, the Synclock (which shares the serial connection) sent the last message.
            NSString* senderDevice = [lastRequest objectForKey:@"device"];
            if([senderDevice isEqualToString:ORSynClock]){
                [synClockModel processResponse:inComingData];
            }
            else if ([senderDevice isEqualToString:ORMotoGPS]){
                [motoGPSModel processResponse:inComingData];
            }
            
            [inComingData release];
            inComingData = nil;
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
            [self setLastRequest:nil];             //clear the last request
            [self processOneCommandFromQueue];     //do the next command in the queue
        }
    }
}

- (void) timeout  // todo
{
	@synchronized (self){
        NSLog(@"Warning: timeout (RefClock)! \n");
        // reTxCount++;  // schedule retransmission
        // if([self verbose]){
        //   NSLog(@"Warning: timeout (RefClock)! trying(%d) retransmit. \n", reTxCount);  //Request was: %@ \n", lastRequest);
        // }
        //
        // [cmdQueue enqueue:lastRequest];

        
        //Don't dump the cmdQueue if you re-sent last request above!!!
        NSLog(@"Emptying remaining commands to RefClock... \n");
        [cmdQueue removeAllObjects];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORRefClockModelUpdatedQueue object:self];
        [self setLastRequest:nil];
	}
}



@end
