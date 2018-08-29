
//
//ORCV1721Decoder.m
//Orca
//
//Created by Mark Howe on Mon Apr 14 2008.
//Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//
//-------------------------------------------------------------
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
#import "ORCV1721Decoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORCV1721Model.h"
#import <time.h>

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 --------^-^^^--------------------------- Crate number
 -------------^-^^^^--------------------- Card number
 --------------------------------------^- 1=Standard, 0=Pack2.5
 ....Followed by the event as described in the manual
 */

@implementation ORCV1721WaveformDecoder

- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualCards release];
    [super dealloc];
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
    
	ptr++; //point to location
	int crate = (*ptr&0x01e00000)>>21;
	int card  = (*ptr& 0x001f0000)>>16;
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
    
    //there are multiple events per packet, the data in the last DMA block are followed by zeros
    uint32_t eventLength = length - 2;
    ptr++;
    while (eventLength > 3) { //make sure at least the CAEN header is there
        if (*ptr == 0 || *ptr >> 28 != 0xa) break; //trailing zeros or
        uint32_t eventSize = *ptr & 0x0fffffff;
        if (eventSize > eventLength) return length;
        
        uint32_t channelMask = *++ptr & 0x000000ff;
        ptr += 3; //point to the start of data
        
        short numChans = 0;
        short chan[8];
        int i;
        for(i=0;i<8;i++){
            if(channelMask & (1<<i)){
                chan[numChans] = i;
                numChans++;
            }
        }
        
        //event may be empty if triggered by EXT trigger and no channel is selected
        if (numChans == 0) {
            continue;
            //return length;
        }
        
        eventSize -= 4;
        eventSize = eventSize/numChans;
        int j;
        
       for(j=0;j<numChans;j++){
            NSData* tmpData = [NSData dataWithBytes:ptr length:eventSize*4];
            
            [aDataSet loadWaveform:tmpData
                            offset:0 //bytes!
                          unitSize:1 //unit size in bytes!
                            sender:self
                          withKeys:@"CAEN1721", @"Waveforms",crateKey,cardKey,[self getChannelKey: chan[j]],nil];
            ptr+= eventSize;

            if(getRatesFromDecodeStage && !skipRateCounts){
                NSString* aKey = [crateKey stringByAppendingString:cardKey];
                if(!actualCards)actualCards = [[NSMutableDictionary alloc] init];
                ORCV1721Model* obj = [actualCards objectForKey:aKey];
                if(!obj){
                    NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORCV1721Model")];
                    NSEnumerator* e = [listOfCards objectEnumerator];
                    ORCV1721Model* aCard;
                    while(aCard = [e nextObject]){
                        if([aCard crateNumber] == crate && [aCard slot] == card){
                            [actualCards setObject:aCard forKey:aKey];
                            obj = aCard;
                            break;
                        }
                    }
                }
                getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:chan[j]];
            }
        }
        eventLength -= eventSize*numChans;
    }
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	uint32_t length = ExtractLength(*ptr);
    ptr += 2;
    length -= 2;
	NSMutableString* dsc = [NSMutableString string];
    
	while (length > 3) { //make sure we have at least the CAEN header
        uint32_t eventLength = *ptr & 0x0fffffffUL;
        NSString* eventSize = [NSString stringWithFormat:@"Event size = %u\n", eventLength];
        NSString* isZeroLengthEncoded = [NSString stringWithFormat:@"Zero length enc: %@\n", ((*ptr >> 24) & 0x1UL)?@"On":@"Off"];
        NSString* lvioPattern = [NSString stringWithFormat:@"LVIO Pattern = 0x%04lx\n", (ptr[1] >> 8) & 0xffffUL];
        NSString* sChannelMask = [NSString stringWithFormat:@"Channel mask = 0x%02lx\n", ptr[1] & 0xffUL];
        NSString* eventCounter = [NSString stringWithFormat:@"Event counter = 0x%06lx\n", ptr[2] & 0xffffffUL];
        NSString* timeTag = [NSString stringWithFormat:@"Time tag = 0x%08x\n\n", ptr[3]];
        
        [dsc appendFormat:@"%@%@%@%@%@%@", eventSize, isZeroLengthEncoded, lvioPattern, sChannelMask, eventCounter, timeTag];
        length -= eventLength;
        ptr += eventLength;
	}
    
	return dsc;
}

@end
