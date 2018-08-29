/*
 *  ORADC2249Model.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORCamacIOCard.h"
#import "ORDataTaker.h"
#import "ORCamacListProtocol.h"

@class ORDataPacket;

enum EADC2249ModelConsts { kRegisterNumberADC2249 = 12 };

@interface ORADC2249Model : ORCamacIOCard <ORDataTaker, ORCamacListProtocol> {	
	@private
		BOOL  checkLAM;
		BOOL includeTiming;
        uint32_t dataId;
        unsigned short onlineMask;
        BOOL suppressZeros;
	
        //place to cache some stuff for alittle more speed.
        uint32_t 	unChangingDataPart;
        unsigned short cachedStation;
        short onlineChannelCount;
		short onlineList[kRegisterNumberADC2249]; 
}

#pragma mark ���Initialization
- (id) init;
- (void) dealloc;
        
#pragma mark ���Accessors
- (BOOL) includeTiming;
- (void) setIncludeTiming:(BOOL)aIncludeTiming;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (unsigned short)   onlineMask;
- (void)	    setOnlineMask:(unsigned short)anOnlineMask;
- (BOOL)	    onlineMaskBit:(int)bit;
- (void)	    setOnlineMaskBit:(int)bit withValue:(BOOL)aValue;
- (void)		setSuppressZeros:(BOOL)aFlag;
- (BOOL)		suppressZeros;
- (void)		setCheckLAM:(BOOL)aState;

#pragma mark ���Hardware Test functions
- (void) readNoReset;
- (void) readReset;
- (void) testLAM;
- (void) resetLAM;
- (void) disableLAMEnableLatch;
- (void) enableLAMEnableLatch;
- (void) testAllChannels;
- (void) generalReset;
//- (void) testBusy;

#pragma mark ���DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;

#pragma mark ���CamacList
- (BOOL) partOfLAMMask;
- (void) addReadOutCommandsToStack:(NSMutableData*)stack;

#pragma mark ���Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

@end

extern NSString* ORADC2249ModelIncludeTimingChanged;
extern NSString* ORADC2249OnlineMaskChangedNotification;
extern NSString* ORADC2249SettingsLock;
extern NSString* ORADC2249SuppressZerosChangedNotification;
