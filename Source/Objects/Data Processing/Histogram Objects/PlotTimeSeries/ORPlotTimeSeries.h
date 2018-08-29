//
//  ORPlotTimeSeries.h
//  Orca
//
//  Created by Mark Howe on Sun Nov 17 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ���Imported Files

#import "ORDataSetModel.h"

#pragma mark ���Forward Declarations
@class ORChannelData;
@class ORPlotTimeSeriesController;
@class ORTimeSeries;

@interface ORPlotTimeSeries : ORDataSetModel  {
	ORTimeSeries*		timeSeries;
	NSRecursiveLock*	dataLock;
}


#pragma mark ���Accessors
- (void) processResponse:(NSDictionary*)aResponse;

#pragma mark ���Data Management
- (void) clear;
- (ORTimeSeries*) timeSeries;
- (void) addValue:(float)aValue atTime:(uint32_t)aTime;
- (int)	count;

#pragma mark ���Writing Data
- (void) writeDataToFile:(FILE*)aFile;

@end

extern NSString* ORPlotTimeSeriesShowChanged;


