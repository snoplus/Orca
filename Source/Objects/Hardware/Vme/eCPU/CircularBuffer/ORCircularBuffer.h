//
//  ORCircularBuffer.h
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


//
//  ORCircularBuffer.m
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


/*
 *		PUBLIC Memory Map:
 *
 *
 *		cbBase	->		-------------------------------------------
 *						| SCBHeader                			      |
 *						-------------------------------------------
 *		qBegin	->		| block 0								  |
 *						-------------------------------------------
 *		...				| block 1                                 |
 *						-------------------------------------------
 *                       | ...           					      |
 *						-------------------------------------------
 *
 *
 *		Block Layout:
 *
 *							-----------------------------	+0
 *							| size      				|
 *							-----------------------------	+sizeof(tCBWord)
 *							| data      				|
 *							-----------------------------	+sizeof(tCBWord) * size
 *																+ sizeof(tCBWord)
 *
 */

#pragma mark •••Imported Files
#import "ORCircularBufferTypeDefs.h"

// Define this only is attempting to debug circular buffers in Mac RAM
//#define __DEBUG_CBUFFER__

@interface ORCircularBuffer : NSObject <NSCoding>{
	uint32_t 	baseAddress;
	unsigned short 	addressModifier;
	unsigned short  addressSpace;
	uint32_t   sentinelRetryTotal;
	id				adapter;

	uint32_t	queueSize;
	tCBWord headValue;
	tCBWord	tailValue;
	
}

#pragma mark •••Accessors
- (void) 			setBaseAddress:(uint32_t) anAddress;
- (uint32_t) 	baseAddress;
- (void)			setAddressModifier:(unsigned short)anAddressModifier;
- (unsigned short)  addressModifier;
- (void)			setAddressSpace:(unsigned short)anAddressSpace;
- (unsigned short)  addressSpace;
- (void) 			setSentinelRetryTotal:(uint32_t)value;
- (uint32_t)	sentinelRetryTotal;
- (void)			setAdapter:(id)anAdapter;

#pragma mark •••Hardware Access
- (SCBHeader) readControlBlockHeader;
- (uint32_t) getNumberOfBlocksInBuffer;
- (uint32_t) getBlocksWritten;
- (uint32_t) getBlocksRead;
- (uint32_t) getBytesWritten;

-(uint32_t) getBytesRead;
- (BOOL) sentinelValid;

- (void) writeLongBlock:(uint32_t) anAddress blocks:(uint32_t) aNumberOfBlocks atPtr:(uint32_t*) aReadPtr;

- (void) writeLong:(uint32_t) anAddress value:(uint32_t) aValue;
- (void) readLongBlock:(uint32_t) anAddress blocks:(uint32_t) aNumberOfBlocks atPtr:(uint32_t*)aWritePtr;
- (void) readLong:(uint32_t) anAddress atPtr:(uint32_t*) aValue;

- (void) getQueHead:(uint32_t*)aHeadValue tail:(uint32_t*)aTailValue;

@end
