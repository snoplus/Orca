//
//  ORCircularBufferWriter.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 01 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORCircularBufferWriter.h"


@implementation ORCircularBufferWriter

#pragma mark •••Accessors
- (void) setMaximumMemorySize:(uint32_t) aSize
{
	maximumMemorySize = aSize;
}

- (uint32_t) maximumMemorySize
{
	return maximumMemorySize;
}

- (void) initializeCircularBuffer
{
	SCBHeader theControlBlockHeader = [self readControlBlockHeader];;
	theControlBlockHeader.writeSentinel &= 0xff000000;
	[self writeLong:[self baseAddress]+0x24 value:(uint32_t)theControlBlockHeader.writeSentinel];
	theControlBlockHeader.tCBWordSize = sizeof( tCBWord );
	theControlBlockHeader.cbNumWords = (maximumMemorySize - sizeof(SCBHeader))/sizeof(tCBWord);
	theControlBlockHeader.qHead = (tCBWord *)([self baseAddress] + sizeof( SCBHeader ) - sizeof( tCBWord ));
	theControlBlockHeader.blocksLostToFullBuffer = 0L;
	theControlBlockHeader.blocksWritten = 0L;
	theControlBlockHeader.bytesWritten = 0L;
	theControlBlockHeader.qTail = (tCBWord *)([self baseAddress] + sizeof( SCBHeader ) - sizeof( tCBWord ));
	theControlBlockHeader.blocksRead = 0L;
	theControlBlockHeader.bytesRead = 0L;
	[self writeControlBlockHeader:theControlBlockHeader];
				// Tail is only written at initialization by the writer - so use a special case
	[self writeLong:[self baseAddress]+0x18 value:(uint32_t)theControlBlockHeader.qTail];
	[self writeLong:[self baseAddress]+0x1C value:theControlBlockHeader.blocksRead];
	[self writeLong:[self baseAddress]+0x20 value:theControlBlockHeader.bytesRead];
				// the sentinel is only restored after all loads are complete - so use a special case
	theControlBlockHeader.readSentinel = theControlBlockHeader.writeSentinel + 0x01000000;
	[self writeLong:[self baseAddress]+0x28 value:theControlBlockHeader.readSentinel];
	theControlBlockHeader.writeSentinel = (theControlBlockHeader.writeSentinel + 0x01000000) | CB_SENTINEL;
	[self writeLong:[self baseAddress]+0x24 value:theControlBlockHeader.writeSentinel];
	return;
}

- (void) writeControlBlockHeader:(SCBHeader)aControlBlockHeader
{
		[self writeLong:[self baseAddress]+0x00 value:aControlBlockHeader.tCBWordSize];
		[self writeLong:[self baseAddress]+0x04 value:aControlBlockHeader.cbNumWords];
		[self writeLong:[self baseAddress]+0x08 value:(uint32_t)aControlBlockHeader.qHead];
		[self writeLong:[self baseAddress]+0x0C value:aControlBlockHeader.blocksLostToFullBuffer];
		[self writeLong:[self baseAddress]+0x10 value:aControlBlockHeader.blocksWritten];
		[self writeLong:[self baseAddress]+0x14 value:aControlBlockHeader.bytesWritten];
}

- (tCBWord) addBlock:(tCBWord*)aBlockOfMemory size:(tCBWord) aLongWordsInBlock
{
		SCBHeader theControlBlockHeader = [self readControlBlockHeader];
		uint32_t theQueueSize = theControlBlockHeader.cbNumWords;
		uint32_t theWordsToAdd = (uint32_t)aLongWordsInBlock + 1;
		// Do nothing if sentinel does not exist
		if( (theControlBlockHeader.writeSentinel & 0x00ffffff) != CB_SENTINEL) return CB_SENTINEL_INVALID;
		// Calculate the space remaining in the queue
		uint32_t theQHeadAddress = (uint32_t)theControlBlockHeader.qHead;
		uint32_t theQTailAddress = (uint32_t)theControlBlockHeader.qTail;
		if(theControlBlockHeader.writeSentinel != theControlBlockHeader.readSentinel)
			theQTailAddress = [self baseAddress] + sizeof( SCBHeader ) - sizeof( tCBWord );
		uint32_t theSpaceRemainingInWords;
		if( theQHeadAddress >= theQTailAddress ) {
			theSpaceRemainingInWords = theQueueSize - (theQHeadAddress - theQTailAddress)/sizeof(uint32_t);
		}
		else {
			theSpaceRemainingInWords = (theQTailAddress - theQHeadAddress)/sizeof(uint32_t);
		}
		if( theWordsToAdd >= theSpaceRemainingInWords ) {
			theControlBlockHeader.blocksLostToFullBuffer++;
			[self writeControlBlockHeader:theControlBlockHeader];
			return BUFFER_OVERFLOW;
		}
		// Write the length of the block to the start of the queue
		[self writeLong:theQHeadAddress value:theWordsToAdd];
		theQHeadAddress += sizeof(uint32_t);
		// Now write the block to vme check to see if this will wrap around the buffer
		if( (theQHeadAddress + aLongWordsInBlock*sizeof(uint32_t)) < ([self baseAddress] + sizeof(uint32_t)*theQueueSize + sizeof(SCBHeader) - sizeof( uint32_t)) ) {
			[self writeLongBlock:theQHeadAddress blocks:aLongWordsInBlock atPtr:aBlockOfMemory];
			theQHeadAddress += aLongWordsInBlock*sizeof(uint32_t);
		}
		else {
			uint32_t theNumberOfLongWordsToWrite = ([self baseAddress] + sizeof(SCBHeader) - sizeof(uint32_t) + sizeof(uint32_t)*theQueueSize - theQHeadAddress)/sizeof(uint32_t);
			//		if( theNumberOfLongWordsToWrite != 0 ) theNumberOfLongWordsToWrite--;	// EGW code never writes to the last block so neither will I !!!
			[self writeLongBlock:theQHeadAddress blocks:theNumberOfLongWordsToWrite atPtr:aBlockOfMemory];
			theQHeadAddress = [self baseAddress] + sizeof( SCBHeader ) - sizeof( tCBWord );
			[self writeLongBlock:theQHeadAddress blocks:aLongWordsInBlock - theNumberOfLongWordsToWrite
							  atPtr:aBlockOfMemory+theNumberOfLongWordsToWrite];
			theQHeadAddress += (aLongWordsInBlock - theNumberOfLongWordsToWrite)*sizeof(uint32_t);
		}
		// update the header
		theControlBlockHeader.qHead = (tCBWord *)theQHeadAddress;
		theControlBlockHeader.blocksWritten++;
		theControlBlockHeader.bytesWritten += theWordsToAdd * sizeof( tCBWord );
		if( theControlBlockHeader.bytesWritten > (theQueueSize * sizeof(tCBWord)) )
			theControlBlockHeader.bytesWritten -= (theQueueSize * sizeof(tCBWord));
		[self writeControlBlockHeader:theControlBlockHeader];
		return theWordsToAdd;
}

- (tCBWord) addByteBlock:( char *)inDataP size:(short) dataSize
{
	uint32_t wordsToAdd = dataSize;
	tCBWord bytesAdded;
	wordsToAdd /= sizeof(tCBWord);
	wordsToAdd += (dataSize % sizeof(tCBWord)) ? 1 : 0;
	bytesAdded = [self addBlock: (tCBWord *)inDataP size:wordsToAdd];
	if( !(bytesAdded & 0x80000000) ) bytesAdded *= sizeof(tCBWord);
	return( bytesAdded );
}
@end


