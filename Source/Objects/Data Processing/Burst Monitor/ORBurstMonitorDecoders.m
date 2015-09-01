//
//  ORBurstMonitorDecoders.m
//  Orca
//
//  Created by Mark Howe on 08/1/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORBurstMonitorDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"


//------------------------------------------------------------------------------------------------
// Data Format
//0 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// ^^^^ ^^^^ ^^^^ ^^------------------------data id
//                  ^^ ^^^^ ^^^^ ^^^^ ^^^^--length in longs
//1 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  burst count
//2 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  numSecTilBurst
//3 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  float duration encoded as long
//4 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  mult
//5 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  triage
//6 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Rcm
//7 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Rrms
//8 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  neutronP
//9 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  ut time
//-----------------------------------------------------------------------------------------------

@implementation ORBurstMonitorDecoderForBurst

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
		
    NSString* valueString = [NSString stringWithFormat:@"%ld",ptr[2]];
    
	[aDataSet loadGenericData:valueString sender:self withKeys:@"BurstMonitor",@"BurstCount",nil];
	
     return ExtractLength(ptr[0]); //must return the length
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Burst Info Record\n\n";

    //get the duration
    union {
        long theLong;
        float theFloat;
    }duration;
    duration.theLong = ptr[3];
    union {
        long theLong;
        float theFloat;
    }neutP;
    neutP.theLong = ptr[8];

    NSString* theDuration           = [NSString stringWithFormat:@"Duration = %.6f seconds\n",duration.theFloat];
    NSString* theBurstCount         = [NSString stringWithFormat:@"Burst Count = %ld\n",ptr[1]];
    NSString* theNumSecTilBurst     = [NSString stringWithFormat:@"Time of burst(sec) = %ld\n",ptr[2]];
    NSString* countsInBurst         = [NSString stringWithFormat:@"Window Multiplicity = %ld\n",ptr[4]];
    NSString* Triage                = [NSString stringWithFormat:@"Triage = %ld\n",ptr[5]];
    NSString* Rcm                   = [NSString stringWithFormat:@"Center = %ld mm\n",ptr[6]];
    NSString* Rrms                  = [NSString stringWithFormat:@"Position rms = %ld mm\n",ptr[7]];
    NSString* neutronP              = [NSString stringWithFormat:@"Neutron Likelyhood = %.6f\n",neutP.theFloat];
    
    return [NSString stringWithFormat:@"%@%s%@%@%@%@%@%@%@%@",title,ctime((const time_t *)(&ptr[9])),Triage,countsInBurst,neutronP,theDuration,Rcm,Rrms,theBurstCount,theNumSecTilBurst];
}
@end

