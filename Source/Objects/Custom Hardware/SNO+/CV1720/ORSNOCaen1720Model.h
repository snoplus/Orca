//
//ORSNOCaen1720Model.h
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

#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "ORCaenDataDecoder.h"
#import "SBC_Config.h"
#include <stdint.h>
#include <hiredis.h>

typedef struct  {
	NSString*       regName;
	bool			dataReset;
	bool			softwareReset;
	bool			hwReset;
	unsigned long 	addressOffset;
	short			accessType;
} Caen1720RegisterNamesStruct; 

// Declaration of constants for module.
enum {
	kOutputBuffer,			//0x0000
	kZS_Thres,				//0x1024
	kZS_NsAmp,				//0x1028
	kThresholds,			//0x1084
	kNumOUThreshold,		//0x1084
	kStatus,				//0x1088
	kFirmwareVersion,		//0x108C
	kBufferOccupancy,		//0x1094
	kDacs,					//0x1098	
	kAdcConfig,				//0x109C
	kChanConfig,			//0x8000
	kChanConfigBitSet,		//0x8004
	kChanConfigBitClr,		//0x8008
	kBufferOrganization,	//0x800C
	kBufferFree,			//0x8010
	kCustomSize,			//0x8020
	kAcqControl,			//0x8100
	kAcqStatus,				//0x8104
	kSWTrigger,				//0x8108
	kTrigSrcEnblMask,		//0x810C
	kFPTrigOutEnblMask,		//0x8110
	kPostTrigSetting,		//0x8114
	kFPIOData,				//0x8118
	kFPIOControl,			//0x811C
	kChanEnableMask,		//0x8120
	kROCFPGAVersion,		//0x8124
	kEventStored,			//0x812C
	kSetMonitorDAC,			//0x8138
	kBoardInfo,				//0x8140
	kMonitorMode,			//0x8144
	kEventSize,				//0x814C
	kVMEControl,			//0xEF00
	kVMEStatus,				//0xEF04
	kBoardID,				//0xEF08
	kMultCastBaseAdd,		//0xEF0C
	kRelocationAdd,			//0xEF10		
	kInterruptStatusID,		//0xEF14
	kInterruptEventNum,		//0xEF18
	kBLTEventNum,			//0xEF1C
	kScratch,				//0xEF20
	kSWReset,				//0xEF24
	kSWClear,				//0xEF28
	//kFlashEnable,			//0xEF2C
	//kFlashData,			//0xEF30
	//kConfigReload,		//0xEF34
	//kConfigROM,			//0xF000
	kNumRegisters
};

// Size of output buffer
#define kEventBufferSize 0x0FFC
enum {
	kReadOnly,
	kWriteOnly,
	kReadWrite
};

@class ORRateGroup;
@class ORAlarm;

// Class definition
@interface ORSNOCaen1720Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping>
{
	unsigned long   dataId;
	unsigned short  selectedRegIndex;
    unsigned short  selectedChannel;
    unsigned long   writeValue;
	unsigned short  thresholds[8];
	unsigned short	dac[8];
	unsigned short	overUnderThreshold[8];
    unsigned short	channelConfigMask;
    unsigned long	customSize;
	BOOL		isCustomSize;
	BOOL		isFixedSize;
    BOOL			countAllTriggers;
    unsigned short	acquisitionMode;
    unsigned short  coincidenceLevel;
    unsigned long   triggerSourceMask;
	unsigned long   triggerOutMask;
	unsigned long   frontPanelControlMask;
    unsigned long	postTriggerSetting;
    unsigned short	enabledMask;
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[8];
    int				bufferState;
	ORAlarm*        bufferFullAlarm;
	int				bufferEmptyCount;
	BOOL			isRunning;
    int				eventSize;
    unsigned long   numberBLTEventsToReadout;
    BOOL            continuousMode;
	
	//cached variables, valid only during running
	unsigned int    statusReg;
	unsigned long   location;
	unsigned long	eventSizeReg;
	unsigned long	dataReg;
    redisContext *context;
}

@property (assign, nonatomic)   BOOL    continuousMode;

#pragma mark ***Accessors
- (int)				eventSize;
- (void)			setEventSize:(int)aEventSize;
- (int)				bufferState;
- (void)			clearWaveFormCounts;
- (void)			setRateIntegrationTime:(double)newIntegrationTime;
- (id)				rateObject:(int)channel;
- (ORRateGroup*)	waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (unsigned short) 	selectedRegIndex;
- (void)			setSelectedRegIndex: (unsigned short) anIndex;
- (unsigned short) 	selectedChannel;
- (void)			setSelectedChannel: (unsigned short) anIndex;
- (unsigned long) 	writeValue;
- (void)			setWriteValue: (unsigned long) anIndex;
- (unsigned short)	enabledMask;
- (void)			setEnabledMask:(unsigned short)aEnabledMask;
- (unsigned long)	postTriggerSetting;
- (void)			setPostTriggerSetting:(unsigned long)aPostTriggerSetting;
- (unsigned long)	triggerSourceMask;
- (void)			setTriggerSourceMask:(unsigned long)aTriggerSourceMask;
- (unsigned long)	triggerOutMask;
- (void)			setTriggerOutMask:(unsigned long)aTriggerOutMask;
- (unsigned long)	frontPanelControlMask;
- (void)			setFrontPanelControlMask:(unsigned long)aFrontPanelControlMask;
- (unsigned short)	coincidenceLevel;
- (void)			setCoincidenceLevel:(unsigned short)aCoincidenceLevel;
- (unsigned short)	acquisitionMode;
- (void)			setAcquisitionMode:(unsigned short)aMode;
- (BOOL)			countAllTriggers;
- (void)			setCountAllTriggers:(BOOL)aCountAllTriggers;
- (BOOL)		isCustomSize;
- (void)		setIsCustomSize:(BOOL)aIsCustomSize;
- (BOOL)		isFixedSize;
- (void)		setIsFixedSize:(BOOL)aIsFixedSize;
- (unsigned long)	customSize;
- (void)			setCustomSize:(unsigned long)aCustomSize;
- (unsigned short)	channelConfigMask;
- (void)			setChannelConfigMask:(unsigned short)aChannelConfigMask;
- (unsigned short)	dac:(unsigned short) aChnl;
- (void)			setDac:(unsigned short) aChnl withValue:(unsigned short) aValue;
- (unsigned short)	overUnderThreshold:(unsigned short) aChnl;
- (void)			setOverUnderThreshold:(unsigned short) aChnl withValue:(unsigned short) aValue;
- (unsigned long)	numberBLTEventsToReadout;
- (void)			setNumberBLTEventsToReadout:(unsigned long)aNumberOfBLTEvents;

#pragma mark ***Register - General routines
- (void) connect;
- (void) disconnect;
- (redisReply *) command: (char *)fmt, ...;
- (redisReply *) vcommand: (char *)fmt args:(va_list)ap;
- (int) intCommand: (char *)fmt, ...;
- (void) okCommand: (char *)fmt, ...;
- (void)			read;
- (void)			write;
- (void)			report;
- (uint32_t)			read:(uint32_t) pReg;
- (void)			write:(uint32_t) pReg sendValue:(uint32_t) pValue;
- (short)			getNumberRegisters;
- (void)			generateSoftwareTrigger;
- (void)			softwareReset;
- (void)			clearAllMemory;
- (void)			checkBufferAlarm;

#pragma mark ***HW Init
- (void)			initBoard;
- (void)			writeChannelConfiguration;
- (void)			writeCustomSize;
- (void)			writeAcquistionControl:(BOOL)start;
- (void)			writeTriggerSource;
- (void)			writeTriggerOut;
- (void)			writeFrontPanelControl;
- (void)			readFrontPanelControl;
- (void)			writePostTriggerSetting;
- (void)			writeChannelEnabledMask;
- (void)            writeNumberBLTEvents:(BOOL)enable;
- (void)            writeEnableBerr:(BOOL)enable;
- (void)			writeOverUnderThresholds;

#pragma mark ***Register - Register specific routines
- (unsigned short) selectedRegIndex;
- (void) setSelectedRegIndex:(unsigned short) anIndex;
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;
- (short)			getAccessType: (short) anIndex;
- (BOOL)			dataReset: (short) anIndex;
- (BOOL)			swReset: (short) anIndex;
- (BOOL)			hwReset: (short) anIndex;
- (void)			writeThresholds;
- (unsigned short)	threshold:(unsigned short) aChnl;
- (void)			setThreshold:(unsigned short) aChnl withValue:(unsigned long) aValue;
- (void)			writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(unsigned long) pValue;
- (uint32_t)			readChan:(unsigned short)chan reg:(unsigned short) pReg;
- (void)			writeDacs;
- (void)			writeDac:(unsigned short) pChan;
- (float)			convertDacToVolts:(unsigned short)aDacValue;
- (unsigned short)	convertVoltsToDac:(float)aVoltage;
- (void)			writeThreshold:(unsigned short) pChan;
- (void)			readOverUnderThresholds;
- (void)			writeBufferOrganization;

#pragma mark •••DataTaker
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (unsigned long)	dataId;
- (void)			setDataId: (unsigned long) DataId;
- (void)			setDataIds:(id)assigner;
- (void)			syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*)	dataRecordDescription;
- (void)			runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(id)userInfo;
- (void)			takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void)			runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(id)userInfo;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORSNOCaen1720ModelEventSizeChanged;
extern NSString* ORSNOCaen1720SelectedRegIndexChanged;
extern NSString* ORSNOCaen1720SelectedChannelChanged;
extern NSString* ORSNOCaen1720WriteValueChanged;
extern NSString* ORSNOCaen1720ModelEnabledMaskChanged;
extern NSString* ORSNOCaen1720ModelPostTriggerSettingChanged;
extern NSString* ORSNOCaen1720ModelTriggerSourceMaskChanged;
extern NSString* ORSNOCaen1720ModelTriggerOutMaskChanged;
extern NSString* ORSNOCaen1720ModelFrontPanelControlMaskChanged;
extern NSString* ORSNOCaen1720ModelCoincidenceLevelChanged;
extern NSString* ORSNOCaen1720ModelAcquisitionModeChanged;
extern NSString* ORSNOCaen1720ModelCountAllTriggersChanged;
extern NSString* ORSNOCaen1720ModelCustomSizeChanged;
extern NSString* ORSNOCaen1720ModelIsCustomSizeChanged;
extern NSString* ORSNOCaen1720ModelIsFixedSizeChanged;
extern NSString* ORSNOCaen1720ModelChannelConfigMaskChanged;
extern NSString* ORSNOCaen1720ModelNumberBLTEventsToReadoutChanged;
extern NSString* ORSNOCaen1720ChnlDacChanged;
extern NSString* ORSNOCaen1720OverUnderThresholdChanged;
extern NSString* ORSNOCaen1720Chnl;
extern NSString* ORSNOCaen1720ChnlThresholdChanged;
extern NSString* ORSNOCaen1720SelectedRegIndexChanged;
extern NSString* ORSNOCaen1720SelectedRegIndexChanged;
extern NSString* ORSNOCaen1720SelectedChannelChanged;
extern NSString* ORSNOCaen1720WriteValueChanged;
extern NSString* ORSNOCaen1720BasicLock;
extern NSString* ORSNOCaen1720SettingsLock;
extern NSString* ORSNOCaen1720RateGroupChanged;
extern NSString* ORSNOCaen1720ModelBufferCheckChanged;
extern NSString* ORSNOCaen1720ModelContinuousModeChanged;
//the decoder concrete decoder class
@interface ORSNOCaen1720DecoderForCAEN : ORCaenDataDecoder
{}
- (NSString*) identifier;
@end
