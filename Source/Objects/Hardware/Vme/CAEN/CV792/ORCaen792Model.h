//--------------------------------------------------------------------------------
// ORCaen792Model.h
//  Created by Mark Howe on Tues June 1 2010.
//  Copyright � 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORCaenCardModel.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "ORAdcInfoProviding.h"

@class ORRateGroup;

// Declaration of constants for module.
enum {
    kOutputBuffer,		// 0000
    kFirmWareRevision,	// 1000
    kGeoAddress,		// 1002
    kMCST_CBLTAddress,	// 1004
    kBitSet1,			// 1006
    kBitClear1,			// 1008
    kInterrupLevel,		// 100A
    kInterrupVector,	// 100C
    kStatusRegister1,	// 100E
    kControlRegister1,	// 1010
    kADERHigh,			// 1012
    kADERLow,			// 1014
    kSingleShotReset,	// 1016
    kMCST_CBLTCtrl,		// 101A
    kEventTriggerReg,	// 1020
    kStatusRegister2,	// 1022
    kEventCounterL,		// 1024
    kEventCounterH,		// 1026
    kIncrementEvent,	// 1028
    kIncrementOffset,	// 102A
    kLoadTestRegister,	// 102C
    kFCLRWindow,		// 102E
    kBitSet2,			// 1032
    kBitClear2,			// 1034
    kWMemTestAddress,	// 1036
    kMemTestWord_High,	// 1038
    kMemTestWord_Low,	// 103A
    kCrateSelect,		// 103C
    kTestEventWrite,	// 103E
    kEventCounterReset,	// 1040
	kIpedReg,			// 1060
    kRTestAddress,		// 1064
    kSWComm,			// 1068
    kSlideConsReg,		// 106A
    kADD,               // 1070
    kBADD,              // 1072
    kThresholds,		// 1080
    kNumRegisters
};


// Size of output buffer
#define kADCOutputBufferSize 0x07FF + 0x0004
#define kModel792  0
#define kModel792N 1
 

// Class definition
@interface ORCaen792Model : ORCaenCardModel <ORDataTaker,ORHWWizard,ORHWRamping,ORAdcInfoProviding>
{
	ORRateGroup*	qdcRateGroup;
    int modelType;
	unsigned long   onlineMask;
	unsigned long   dataIdN;
	unsigned long   location;
    unsigned short  iPed;
    BOOL            overflowSuppressEnable;
    BOOL            zeroSuppressEnable;
    BOOL            zeroSuppressThresRes; //v5.1 only
    BOOL            eventCounterInc;
    BOOL            slidingScaleEnable;
    unsigned short  slideConstant;
    BOOL            cycleZeroSuppression;
    int             percentZeroOff;
    int             totalCycleZTime;
    BOOL            isRunning;
    BOOL            useHWReset;
    
}

#pragma mark ***Accessors
- (BOOL)            useHWReset;
- (void)            setUseHWReset:(BOOL)aValue;
- (int)             totalCycleZTime;
- (void)            setTotalCycleZTime:(int)aTotalCycleZTime;
- (int)             percentZeroOff;
- (void)            setPercentZeroOff:(int)aPercentZeroOff;
- (BOOL)            cycleZeroSuppression;
- (void)            setCycleZeroSuppression:(BOOL)aCycleZeroSuppression;
- (unsigned short)  slideConstant;
- (void)            setSlideConstant:(unsigned short)aSlideConstant;
- (BOOL)            slidingScaleEnable;
- (void)            setSlidingScaleEnable:(BOOL)aSlidingScaleEnable;
- (BOOL)            eventCounterInc;
- (void)            setEventCounterInc:(BOOL)aEventCounterInc;
- (BOOL)            zeroSuppressThresRes;
- (void)            setZeroSuppressThresRes:(BOOL)aZeroSuppressThresRes;
- (BOOL)            zeroSuppressEnable;
- (void)            setZeroSuppressEnable:(BOOL)aZeroSuppressEnable;
- (BOOL)            overflowSuppressEnable;
- (void)            setOverflowSuppressEnable:(BOOL)aOverflowSuppressEnable;
- (unsigned short)  iPed;
- (void)            setIPed:(unsigned short)aIPed;
- (unsigned long)   dataIdN;
- (void)            setDataIdN: (unsigned long) DataId;
- (int)             modelType;
- (void)            setModelType:(int)aModelType;
- (unsigned long)   onlineMask;
- (void)			setOnlineMask:(unsigned long)anOnlineMask;
- (BOOL)			onlineMaskBit:(int)bit;
- (void)			setOnlineMaskBit:(int)bit withValue:(BOOL)aValue;
- (ORRateGroup*)    qdcRateGroup;
- (void)            setQdcRateGroup:(ORRateGroup*)newRateGroup;

#pragma mark ***Register - General routines
- (int)             numberOfChannels;
- (short)           getNumberRegisters;
- (unsigned long) 	getBufferOffset;
- (unsigned short) 	getDataBufferSize;
- (unsigned long)   getThresholdOffset:(int)aChan;
- (short)           getStatusRegisterIndex: (short) aRegister;
- (short)           getThresholdIndex;
- (short)           getOutputBufferIndex;
- (void)            writeThresholds;
- (void)            writeIPed;
- (void)            writeBit2Register;
- (void)            writeSlideConstReg;
- (void)            setToDefaults;
- (unsigned short)  readIPed;
- (unsigned long)   eventCount:(int)aChannel;
- (BOOL)            bumpRateFromDecodeStage:(short)channel;
- (void)            startRates;
- (void)            clearEventCounts;
- (unsigned long)   getCounter:(int)counterTag forGroup:(int)groupTag;
- (void)            clearData;
- (void)            writeOneShotReset;
- (void)            doSoftClear;

#pragma mark ***Register - Register specific routines
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;
- (short)           getAccessType: (short) anIndex;
- (short)           getAccessSize: (short) anIndex;
- (BOOL)            dataReset: (short) anIndex;
- (BOOL)            swReset: (short) anIndex;
- (BOOL)            hwReset: (short) anIndex;

#pragma mark ���AdcProviding Protocol
- (BOOL) partOfEvent:(unsigned short)aChannel;
- (unsigned long) eventCount:(int)aChannel;
- (void) clearEventCounts;
- (unsigned long) thresholdForDisplay:(unsigned short) aChan;
- (unsigned short) gainForDisplay:(unsigned short) aChan;
- (void) postAdcInfoProvidingValueChanged;

#pragma mark ���Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORCaen792ModelUseHWResetChanged;
extern NSString* ORCaen792ModelTotalCycleZTimeChanged;
extern NSString* ORCaen792ModelPercentZeroOffChanged;
extern NSString* ORCaen792ModelCycleZeroSuppressionChanged;
extern NSString* ORCaen792ModelSlideConstantChanged;
extern NSString* ORCaen792ModelSlidingScaleEnableChanged;
extern NSString* ORCaen792ModelEventCounterIncChanged;
extern NSString* ORCaen792ModelZeroSuppressThresResChanged;
extern NSString* ORCaen792RateGroupChangedNotification;

extern NSString* ORCaen792ModelZeroSuppressEnableChanged;
extern NSString* ORCaen792ModelOverflowSuppressEnableChanged;
extern NSString* ORCaen792ModelIPedChanged;
extern NSString* ORCaen792ModelModelTypeChanged;
extern NSString* ORCaen792ModelOnlineMaskChanged;
