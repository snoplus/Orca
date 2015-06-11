//
//  ORMksPdr2000Decoders.m
//  Orca
//
// Created by Mark  A. Howe on Tue Jan 6, 2009
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


#import "ORMksPdr2000Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

//------------------------------------------------------------------------------------------------
// Data Format
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// ^^^^ ^^^^ ^^^^ ^^------------------------data id
//                  ^^ ^^^^ ^^^^ ^^^^ ^^^^--length in longs
//
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//                          ^^^^ ^^^^ ^^^^--device id
//                ^^^^----------------------units id (0=unknown,1=Torr,2=mBar,3=Pascal,4=Arb)
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  pressure chan 0 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time pressure 0 taken in seconds since Jan 1, 1970
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  pressure chan 1 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time pressure 1 taken in seconds since Jan 1, 1970
//-----------------------------------------------------------------------------------------------
static NSString* kMkePdrUnit[2] = {
    //pre-make some keys for speed.
    @"Gauge 0",  @"Gauge 1"

};

@implementation ORMksPdr2000DecoderForPressure

- (NSString*) getGaugeKey:(unsigned short)aUnit
{
    if(aUnit<3) return kMkePdrUnit[aUnit];
    else return [NSString stringWithFormat:@"Gauge %d",aUnit];			
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long *dataPtr = (unsigned long*)someData;
	union {
		float asFloat;
		unsigned long asLong;
	}theTemp;
	int ident = dataPtr[1] & 0xfff;
	int i;
	int index = 2;
	for(i=0;i<2;i++){
		theTemp.asLong = dataPtr[index];									//encoded as float, use union to convert
		[aDataSet loadTimeSeries:theTemp.asFloat										
						  atTime:dataPtr[index+1]
						  sender:self 
						withKeys:@"BOCTIC3",
								[NSString stringWithFormat:@"Unit %d",ident],
								[self getGaugeKey:i],
								nil];
		index+=2;
	}
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSString* title= @"BOC TIC Controller\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	int units = (dataPtr[1]>>16) & 0xf;
	if(units == 0)		[theString stringByAppendingString: @"Units = Unknown\n"];
	else if(units == 1)	[theString stringByAppendingString: @"Units = Torr\n"];
	else if(units == 2)	[theString stringByAppendingString: @"Units = mBar\n"];
	else if(units == 3)	[theString stringByAppendingString: @"Units = Pascal\n"];
	else				[theString stringByAppendingString: @"Units = Arb\n"];
	int ident = dataPtr[1] & 0xfff;
	theString = [theString stringByAppendingFormat:@"Unit %d\n",ident];
	union {
		float asFloat;
		unsigned long asLong;
	}theData;
	int i;
	int index = 2;
	for(i=0;i<2;i++){
		theData.asLong = dataPtr[index];
		
		NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[index+1]];
		
		theString = [theString stringByAppendingFormat:@"Gauge %d: %.2E %@\n",i,theData.asFloat,[date stdDescription]];
		index+=2;
	}
	return theString;
}
@end


