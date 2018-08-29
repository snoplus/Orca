//
//  ORFileReader.h
//  OrcaIntel
//
//  Created by Mark Howe on 11/14/2009.
//  Copyright 2009 CENPA, University of North Carolina. All rights reserved.
//
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
#import "ORDecoderOperation.h"

@interface ORFileReader : ORDecoderOperation {
	NSMutableData* dataToProcess;
	uint32_t runDataID;
	NSMutableArray* dataArray;
	NSMutableDictionary* runInfo;
	BOOL runEnded;
}

- (id)   initWithPath:(NSString*)aPath delegate:(id)aDelegate;
- (void) dealloc;
- (void) processData;
- (void) processRunRecord:(uint32_t*)p;
- (void) loadRunInfo:(uint32_t*)p;
- (void) shipCurrentHeader;

@end

@interface NSObject (ORFileReader)
- (void) updateProgress:(NSNumber*)amountDone;
- (BOOL) cancelAndStop;
- (void) setFileToReplay:(NSString*)newFileToReplay;
- (void) sendDataArray:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
- (void) sendRunStart:(NSDictionary*)userInfo;
- (void) sendCloseOutRun:(NSDictionary*)userInfo;
- (void) sendRunEnd:(NSDictionary*)userInfo;
- (void) sendRunSubRunStart:(NSDictionary*)userInfo;
@end
