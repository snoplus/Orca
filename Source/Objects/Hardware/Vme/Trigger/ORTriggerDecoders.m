//
//  ORTriggerDecoders.m
//  Orca
//
//  Created by Mark Howe on 9/21/04.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORTriggerDecoders.h"
#import "ORTriggerModel.h"
#import "ORDataTypeAssigner.h"


@implementation ORTriggerDecoderFor100MHzClockRecord
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t *ptr = (uint32_t*)someData;
    uint32_t length;
	ptr++;
	length = 3;
    uint32_t value = *ptr;
    if((value >> 24) & kEvent1Mask){
        [aDataSet loadGenericData:@" " sender:self withKeys:@"Latched Clock",@"Evnt1 Clk",nil];
    }
    else if((value >> 24) & kEvent2Mask){
        [aDataSet loadGenericData:@" " sender:self withKeys:@"Latched Clock",@"Evnt2 Clk",nil];
    }
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"Trigger Clock Record\n\n";
    return [NSString stringWithFormat:@"%@Decoder Not Implemented.\n",title];
}


@end


@implementation ORTriggerDecoderForGTIDRecord
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

    uint32_t* ptr = (uint32_t*)someData;
    uint32_t length;
    
    if(IsShortForm(*ptr)){
        length = sizeof(int32_t);
    }
    else {
        ptr++; //int32_t version
        length = 2*sizeof(int32_t);
    }
    
    NSString* valueString = [NSString stringWithFormat:@"%u",*ptr&0x00ffffff];
    if(((*ptr>>24)&0x3)==1){
        [aDataSet loadGenericData:valueString sender:self  withKeys:@"Latched Clock",@"GTID1",nil];
    }
    else {
        [aDataSet loadGenericData:valueString sender:self withKeys:@"Latched Clock",@"GTID2",nil];
    }
    
    
    return length; //must return number of longs processed.
    
}
- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"Trigger GTID Record\n\n";
    if(!IsShortForm(*ptr)){
        ptr++; //int32_t version
    }
    NSString* trigger = [NSString stringWithFormat:@"Trigger = %d\n",(*ptr>>24)&0x1 ? 1 : 2];
    NSString* gtid    = [NSString stringWithFormat:@"GTID    = %u\n",*ptr&0x00ffffff];

    return [NSString stringWithFormat:@"%@%@%@",title,trigger,gtid];
}

@end
