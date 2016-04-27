
//  ORDispatcherClient.m
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

#import "ORDispatcherClient.h"
#import "NetSocket.h"
#import "ORCommandCenter.h"

@implementation ORDispatcherClient

- (void)netsocket:(NetSocket*)insocket dataAvailable:(unsigned)inAmount
{
    if(insocket == socket){
        [[ORCommandCenter sharedCommandCenter] handleCommand:[socket readString:NSASCIIStringEncoding amount:inAmount] fromClient:self];
    }
}
- (void) setAmountBlocked:(unsigned long long)numBytes
{
    amountBlocked += numBytes;
}

- (unsigned long long)amountBlocked
{
    return amountBlocked;
}

- (float)percentBlocked
{
    unsigned long long sent = [self totalSent];
    if((sent+amountBlocked)!=0)return (float)(100 - 100*sent/(double)(sent + amountBlocked));
    else return 0;
}

- (void)clearCounts
{
    amountBlocked = 0;
   [super clearCounts];
}

@end
