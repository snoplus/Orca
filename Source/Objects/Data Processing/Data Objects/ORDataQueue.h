//
//  ORDataQueu.h
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
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
#import "ORDataQueueing.h"

#define kMaxReservedPoolSize 2045
#define kFastLoopupCacheSize 16384

@interface ORDataQueue : NSObject <ORDataQueueing>{
    @private
		NSMutableArray*  	 dataArray;             //data records
		NSMutableArray*  	 cacheArray;			//data records that are to be cached for later inclusion into data
		BOOL				 dataInCache;
		NSMutableData*		 frameBuffer;			//accumulator for data
		uint32_t		 frameIndex;
		NSRecursiveLock*     theDataLock;
		uint32_t		 reserveIndex;
        uint32_t        reservePool[kMaxReservedPoolSize];
        uint32_t        lastFrameBufferSize;
		BOOL				 dataAvailable;

        BOOL            addedData;
		int32_t			frameCounter;
		int32_t			oldFrameCounter;
		BOOL			needToSwap;
}

- (id) init;
- (void) dealloc;

#pragma mark •••Accessors
- (void) startFrameTimer;
- (void) stopFrameTimer;
- (void) forceFrameLoad;
- (NSMutableArray*)  dataArray;
- (void) setDataArray:(NSMutableArray*)someData;
- (NSMutableData*)  frameBuffer;
- (void) setFrameBuffer:(NSMutableData*)someData;
- (NSMutableArray*) cacheArray;
- (void) setCacheArray:(NSMutableArray*)newCacheArray;

#pragma mark •••Data Addition
- (uint32_t) frameIndex;
- (void) replaceReservedDataInFrameBufferAtIndex:(uint32_t)index withLongs:(uint32_t*)data length:(uint32_t)length;
- (uint32_t) addLongsToFrameBuffer:(uint32_t*)someData length:(uint32_t)length;
- (uint32_t*) getBlockForAddingLongs:(uint32_t)length;
- (uint32_t)reserveSpaceInFrameBuffer:(uint32_t)length;
- (void) removeReservedLongsFromFrameBuffer:(NSRange)aRange;
- (void) addFrameBuffer:(BOOL)forceAdd;
- (void) addData:(NSData*)someData;
- (void) addDataFromArray:(NSArray*)aDataArray;
- (void) addCachedData;
- (uint32_t) dataCount;
- (void) addDataToCach:(NSData*)someData;
- (void) addArrayToCache:(NSArray*)aDataArray;
- (void) clearData;
- (BOOL) addedData;
- (void) setAddedData:(BOOL)flag;
@end

