//
//  ORTimeRate.h
//  Orca
//
//  Created by Mark Howe on Tue Sep 09 2003.
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




#define kTimeAverageBufferSize 4096
#define kAverageStackSize 512

@interface ORTimeRate : NSObject {
	
	double averageStack[kAverageStackSize];
	double timeAverage[kTimeAverageBufferSize];
	NSTimeInterval timeSampled[kTimeAverageBufferSize];
	int timeAverageWrite;
	int timeAverageRead;
	int averageStackCount;
	NSDate* lastAverageTime;
	unsigned long sampleTime;
}


- (NSDate*) lastAverageTime;
- (void) setLastAverageTime:(NSDate*)newLastAverageTime;
- (unsigned long) sampleTime;
- (void) setSampleTime:(unsigned long)newSampleTime;
- (unsigned) count;
- (double)valueAtIndex:(unsigned)index;
- (NSTimeInterval)timeSampledAtIndex:(unsigned)index;
- (NSArray*) ratesAsArray;


- (void) addDataToTimeAverage:(float)aValue;

@end

extern NSString* ORRateAverageChangedNotification;


