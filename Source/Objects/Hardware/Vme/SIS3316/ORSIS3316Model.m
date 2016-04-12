//-------------------------------------------------------------------------
//  ORSIS3316Model.m
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2015 CENPA. University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolinaponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORSIS3316Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"

NSString* ORSIS3316EnabledChanged			 = @"ORSIS3316EnabledChanged";
NSString* ORSIS3316HistogramsEnabledChanged  = @"ORSIS3316HistogramsEnabledChanged";

NSString* ORSIS3316PileUpEnabledChanged            = @"ORSIS3316PileUpEnabledChanged";
NSString* ORSIS3316ClrHistogramWithTSChanged       = @"ORSIS3316ClrHistogramWithTSChanged";
NSString* ORSIS3316WriteHitsIntoEventMemoryChanged = @"ORSIS3316WriteHitsIntoEventMemoryChanged";

NSString* ORSIS3316ThresholdChanged          = @"ORSIS3316ThresholdChanged";
NSString* ORSIS3316HeSuppressTrigModeChanged = @"ORSIS3316HeSuppressTrigModeChanged";
NSString* ORSIS3316CfdControlBitsChanged     = @"ORSIS3316CfdControlBitsChanged";

NSString* ORSIS3316EnergyDividerChanged      = @"ORSIS3316EnergyDividerChanged";
NSString* ORSIS3316EnergySubtractorChanged   = @"ORSIS3316EnergySubtractorChanged";
NSString* ORSIS3316TauFactorChanged          = @"ORSIS3316TauFactorChanged";
NSString* ORSIS3316PeakingTimeChanged        = @"ORSIS3316PeakingTimeChanged";
NSString* ORSIS3316GapTimeChanged            = @"ORSIS3316GapTimeChanged";
NSString* ORSIS3316HeTrigThresholdChanged    = @"ORSIS3316HeTrigThresholdChanged";
NSString* ORSIS3316TrigBothEdgesChanged      = @"ORSIS3316TrigBothEdgesChanged";
NSString* ORSIS3316IntHeTrigOutPulseChanged  = @"ORSIS3316IntHeTrigOutPulseChanged";
NSString* ORSIS3316IntTrigOutPulseBitsChanged= @"ORSIS3316IntTrigOutPulseBitsChanged";

NSString* ORSIS3316ActiveTrigGateWindowLenChanged = @"ORSIS3316ActiveTrigGateWindowLenChanged";
NSString* ORSIS3316PreTriggerDelayChanged    = @"ORSIS3316PreTriggerDelayChanged";
NSString* ORSIS3316RawDataBufferLenChanged   = @"ORSIS3316RawDataBufferLenChanged";
NSString* ORSIS3316RawDataBufferStartChanged = @"ORSIS3316RawDataBufferStartChanged";

NSString* ORSIS3316AccGate1LenChanged     = @"ORSIS3316AccGate1LenChanged";
NSString* ORSIS3316AccGate1StartChanged   = @"ORSIS3316AccGate1StartChanged";
NSString* ORSIS3316AccGate2LenChanged     = @"ORSIS3316AccGate2LenChanged";
NSString* ORSIS3316AccGate2StartChanged   = @"ORSIS3316AccGate2StartChanged";
NSString* ORSIS3316AccGate3LenChanged     = @"ORSIS3316AccGate3LenChanged";
NSString* ORSIS3316AccGate3StartChanged   = @"ORSIS3316AccGate3StartChanged";
NSString* ORSIS3316AccGate4LenChanged     = @"ORSIS3316AccGate4LenChanged";
NSString* ORSIS3316AccGate4StartChanged   = @"ORSIS3316AccGate4StartChanged";
NSString* ORSIS3316AccGate5LenChanged     = @"ORSIS3316AccGate5LenChanged";
NSString* ORSIS3316AccGate5StartChanged   = @"ORSIS3316AccGate5StartChanged";
NSString* ORSIS3316AccGate6LenChanged     = @"ORSIS3316AccGate6LenChanged";
NSString* ORSIS3316AccGate6StartChanged   = @"ORSIS3316AccGate6StartChanged";
NSString* ORSIS3316AccGate7LenChanged     = @"ORSIS3316AccGate7LenChanged";
NSString* ORSIS3316AccGate7StartChanged   = @"ORSIS3316AccGate7StartChanged";
NSString* ORSIS3316AccGate8LenChanged     = @"ORSIS3316AccGate8LenChanged";
NSString* ORSIS3316AccGate8StartChanged   = @"ORSIS3316AccGate8StartChanged";



NSString* ORSIS3316CSRRegChanged			= @"ORSIS3316CSRRegChanged";
NSString* ORSIS3316AcqRegChanged			= @"ORSIS3316AcqRegChanged";
NSString* ORSIS3316EventConfigChanged		= @"ORSIS3316EventConfigChanged";
NSString* ORSIS3316PageSizeChanged			= @"ORSIS3316PageSizeChanged";

NSString* ORSIS3316ClockSourceChanged		= @"ORSIS3316ClockSourceChanged";
NSString* ORSIS3316StopDelayChanged         = @"ORSIS3316StopDelayChanged";
NSString* ORSIS3316StartDelayChanged		= @"ORSIS3316StartDelayChanged";
NSString* ORSIS3316RandomClockChanged		= @"ORSIS3316RandomClockChanged";

NSString* ORSIS3316StopTriggerChanged           = @"ORSIS3316StopTriggerChanged";
NSString* ORSIS3316RateGroupChangedNotification	= @"ORSIS3316RateGroupChangedNotification";
NSString* ORSIS3316SettingsLock					= @"ORSIS3316SettingsLock";

NSString* ORSIS3316SampleDone				= @"ORSIS3316SampleDone";
NSString* ORSIS3316IDChanged				= @"ORSIS3316IDChanged";


//VME FPGA interface registers
#define kControlStatusReg           0x00000000
#define kModuleIDReg				0x00000004
#define kInterruptConfigReg			0x00000008
#define kInterruptControlReg        0x0000000C

#define kInterfacArbCntrStatusReg   0x00000010
#define kCBLTSetupReg               0x00000014
#define kInternalTestReg            0x00000018
#define kHWVersionReg               0x0000001C

//VME FPGA registers
#define kTemperatureReg             0x00000020
#define k1WireEEPROMcontrolReg      0x00000024
#define kSerialNumberReg            0x00000028
#define kDataTransferSpdSettingReg  0x0000002C

#define kAdcFPGAsBootControllerReg  0x00000030
#define kSpiFlashControlStatusReg   0x00000034
#define kSpiFlashData               0x00000038
#define kReservedforPROMReg         0x0000003C

#define kAdcClockI2CReg             0x00000040
#define kMgt2ClockI2CReg            0x00000044

#define kAdcSampleClockDistReg      0x00000050
#define kExtNIMClockMulSpiReg       0x00000054
#define kFPBusControlReg            0x00000058
#define kNimInControlReg            0x0000005C

#define kAcqControlStatusReg        0x00000060
#define kTrigCoinLUTControlReg      0x00000064
#define kTrigCoinLUTAddReg          0x00000068
#define kTrigCoinLUTDataReg         0x0000006C

#define kLemoOutCOSelectReg         0x00000070
#define kLemoOutTOSelectReg         0x00000074
#define kLemoOutUOSelectReg         0x00000078
#define kIntTrigFeedBackSelReg      0x0000007C

#define kAdcCh1_Ch4DataCntrReg      0x00000080
#define kAdcCh5_Ch8DataCntrReg      0x00000084
#define kAdcCh9_Ch12DataCntrReg     0x00000088
#define kAdcCh13_Ch16DataCntrReg    0x0000008C

#define kAdcCh1_Ch4DataStatusReg    0x00000090
#define kAdcCh5_Ch8DataStatusReg    0x00000094
#define kAdcCh9_Ch12DataStatusReg   0x00000098
#define kAdcCh13_Ch16DataStatusReg  0x0000009C

#define kAdcDataLinkStatusReg       0x000000A0
#define kAdcSpiBusyStatusReg        0x000000A4
#define kPrescalerOutDivReg         0x000000B8
#define kPrescalerOutLenReg         0x000000BC

#define kChan1TrigCounterReg        0x000000C0
#define kChan2TrigCounterReg        0x000000C4
#define kChan3TrigCounterReg        0x000000C8
#define kChan4TrigCounterReg        0x000000CC

#define kChan5TrigCounterReg        0x000000D0
#define kChan6TrigCounterReg        0x000000D4
#define kChan7TrigCounterReg        0x000000D8
#define kChan8TrigCounterReg        0x000000DC

#define kChan9TrigCounterReg        0x000000E0
#define kChan10TrigCounterReg       0x000000E4
#define kChan11TrigCounterReg       0x000000E8
#define kChan12TrigCounterReg       0x000000EC

#define kChan13TrigCounterReg       0x000000F0
#define kChan14TrigCounterReg       0x000000F4
#define kChan15TrigCounterReg       0x000000F8
#define kChan16TrigCounterReg       0x000000FC

//Key address registers
#define kKeyResetReg                0x00000400
#define kKeyUserFuncReg             0x00000404

#define kKeyArmSampleLogicReg       0x00000410
#define kKeyDisarmSampleLogicReg    0x00000414
#define kKeyTriggerReg              0x00000418
#define kKeyTimeStampClrReg         0x0000041C

#define kKeyDisarmXArmBank1Reg      0x00000420
#define kKeyDisarmXArmBank2Reg      0x00000424
#define kKeyEnableBankSwapNimReg    0x00000428
#define kKeyDisablePrescalerLogReg  0x0000042C

#define kKeyPPSLatchBitClrReg       0x00000430
#define kKeyResetAdcLogicReg        0x00000434
#define kKeyAdcClockPllResetReg     0x00000438

//ADC Group1 registers Add 0x1000 for each group
#define kAdcInputTapDelayReg        0x00001000
#define kAdcGainTermCntrlReg        0x00001004
#define kAdcOffsetDacCntrlReg       0x00001008
#define kAdcSpiControlReg           0x0000100C

#define kEventConfigReg             0x00001010
#define kChanHeaderIdReg            0x00001014
#define kEndAddressThresholdReg     0x00001018
#define kActTriggerGateWindowLenReg 0x0000101C

#define kRawDataBufferConfigReg     0x00001020
#define kPileupConfigReg            0x00001024
#define kPreTriggerDelayReg         0x00001028
#define kAveConfigReg               0x0000102C

#define kDataFormatConfigReg        0x00001030
#define kMawTestBufferConfigReg     0x00001034
#define kInternalTrigDelayConfigReg 0x00001038
#define kInternalGateLenConfigReg   0x0000103C

#define kFirTrigSetupCh1Reg         0x00001040
#define kTrigThresholdCh1Reg        0x00001044
#define kHiEnergyTrigThresCh1Reg    0x00001048

#define kFirTrigSetupCh2Reg         0x00001050
#define kTrigThresholdCh2Reg        0x00001054
#define kHiEnergyTrigThresCh2Reg    0x00001058

#define kFirTrigSetupCh3Reg         0x00001060
#define kTrigThresholdCh3Reg        0x00001064
#define kHiEnergyTrigThresCh3Reg    0x00001068

#define kFirTrigSetupCh4Reg         0x00001070
#define kTrigThresholdCh4Reg        0x00001074
#define kHiEnergyTrigThresCh4Reg    0x00001078

#define kFirTrigSetupSumCh1Ch4Reg   0x00001080
#define kTrigThreholdSumCh1Ch4Reg   0x00001084
#define kHiETrigThresSumCh1Ch4Reg   0x00001088

#define kTrigStatCounterModeCh1Ch4Reg 0x00001090
#define kPeakChargeConfigReg        0x00001094
#define kExtRawDataBufConfigReg     0x00001098
#define kExtEventConfigCh1Ch4Reg    0x0000109C

#define kAccGate1ConfigReg          0x000010A0
#define kAccGate2ConfigReg          0x000010A4
#define kAccGate3ConfigReg          0x000010A8
#define kAccGate4ConfigReg          0x000010AC
#define kAccGate5ConfigReg          0x000010B0
#define kAccGate6ConfigReg          0x000010B4
#define kAccGate7ConfigReg          0x000010B8
#define kAccGate8ConfigReg          0x000010BC

#define kFirEnergySetupCh1Reg       0x000010C0
#define kFirEnergySetupCh2Reg       0x000010C4
#define kFirEnergySetupCh3Reg       0x000010C8
#define kFirEnergySetupCh4Reg       0x000010CC

#define kEnergyHistoConfigCh1Reg    0x000010D0
#define kEnergyHistoConfigCh2Reg    0x000010D4
#define kEnergyHistoConfigCh3Reg    0x000010D8
#define kEnergyHistoConfigCh4Reg    0x000010DC


#define kMawStartIndexConfigCh1Reg  0x000010E0
#define kMawStartIndexConfigCh2Reg  0x000010E4
#define kMawStartIndexConfigCh3Reg  0x000010E8
#define kMawStartIndexConfigCh4Reg  0x000010EC

#define kAdcVersionReg              0x00001100
#define kAdcVStatusReg              0x00001104
#define kAdcOffsetReadbackReg       0x00001108
#define kAdcSpiReadbackReg          0x0000110C

#define kActualSampleCh1Reg         0x00001110
#define kActualSampleCh2Reg         0x00001114
#define kActualSampleCh3Reg         0x00001118
#define kActualSampleCh4Reg         0x0000111C

#define kPreviousBankSampleCh1Reg   0x00001120
#define kPreviousBankSampleCh2Reg   0x00001124
#define kPreviousBankSampleCh3Reg   0x00001128
#define kPreviousBankSampleCh4Reg   0x0000112C

#define kPPSTimeStampHiReg          0x00001130
#define kPPSTimeStampLoReg          0x00001134
#define kTestReadback01018Reg       0x00001138
#define kTestReadback0101CReg       0x0000113C

#define I2C_ACK             8
#define I2C_START			9
#define I2C_REP_START		10
#define I2C_STOP			11
#define I2C_WRITE			12
#define I2C_READ			13
#define I2C_BUSY			31
#define OSC_ADR             0x55

unsigned long prevBankSampleRegs[kNumSIS3316Channels] ={
    kPreviousBankSampleCh1Reg,
    kPreviousBankSampleCh2Reg,
    kPreviousBankSampleCh3Reg,
    kPreviousBankSampleCh4Reg,
    kPreviousBankSampleCh1Reg + 0x1000,
    kPreviousBankSampleCh2Reg + 0x1000,
    kPreviousBankSampleCh3Reg + 0x1000,
    kPreviousBankSampleCh4Reg + 0x1000,
    kPreviousBankSampleCh1Reg + 0x2000,
    kPreviousBankSampleCh2Reg + 0x2000,
    kPreviousBankSampleCh3Reg + 0x2000,
    kPreviousBankSampleCh4Reg + 0x2000,
    kPreviousBankSampleCh1Reg + 0x3000,
    kPreviousBankSampleCh2Reg + 0x3000,
    kPreviousBankSampleCh3Reg + 0x3000,
    kPreviousBankSampleCh4Reg + 0x3000
};


unsigned long thresholdRegs[kNumSIS3316Channels] = {
    kTrigThresholdCh1Reg,
    kTrigThresholdCh2Reg,
    kTrigThresholdCh3Reg,
    kTrigThresholdCh4Reg,
    kTrigThresholdCh1Reg + 0x1000,
    kTrigThresholdCh2Reg + 0x1000,
    kTrigThresholdCh3Reg + 0x1000,
    kTrigThresholdCh4Reg + 0x1000,
    kTrigThresholdCh1Reg + 0x2000,
    kTrigThresholdCh2Reg + 0x2000,
    kTrigThresholdCh3Reg + 0x2000,
    kTrigThresholdCh4Reg + 0x2000,
    kTrigThresholdCh1Reg + 0x3000,
    kTrigThresholdCh2Reg + 0x3000,
    kTrigThresholdCh3Reg + 0x3000,
    kTrigThresholdCh4Reg + 0x3000,
};

unsigned long energyHistogramConfigRegs[kNumSIS3316Channels] = {
    kEnergyHistoConfigCh1Reg,
    kEnergyHistoConfigCh2Reg,
    kEnergyHistoConfigCh3Reg,
    kEnergyHistoConfigCh4Reg,
    kEnergyHistoConfigCh1Reg + 0x1000,
    kEnergyHistoConfigCh2Reg + 0x1000,
    kEnergyHistoConfigCh3Reg + 0x1000,
    kEnergyHistoConfigCh4Reg + 0x1000,
    kEnergyHistoConfigCh1Reg + 0x2000,
    kEnergyHistoConfigCh2Reg + 0x2000,
    kEnergyHistoConfigCh3Reg + 0x2000,
    kEnergyHistoConfigCh4Reg + 0x2000,
    kEnergyHistoConfigCh1Reg + 0x3000,
    kEnergyHistoConfigCh2Reg + 0x3000,
    kEnergyHistoConfigCh3Reg + 0x3000,
    kEnergyHistoConfigCh4Reg + 0x3000,
};
NSString* cfdCntrlString[4] = {
    @"Disabled     ",
    @"Disabled     ",
    @"Zero Crossing",
    @"50%          "
};
unsigned long heThresholdRegs[kNumSIS3316Channels] = {
    kHiEnergyTrigThresCh1Reg,
    kHiEnergyTrigThresCh2Reg,
    kHiEnergyTrigThresCh3Reg,
    kHiEnergyTrigThresCh4Reg + 0x1000,
    kHiEnergyTrigThresCh1Reg + 0x1000,
    kHiEnergyTrigThresCh2Reg + 0x1000,
    kHiEnergyTrigThresCh3Reg + 0x1000,
    kHiEnergyTrigThresCh4Reg + 0x2000,
    kHiEnergyTrigThresCh1Reg + 0x2000,
    kHiEnergyTrigThresCh2Reg + 0x2000,
    kHiEnergyTrigThresCh3Reg + 0x2000,
    kHiEnergyTrigThresCh4Reg + 0x3000,
    kHiEnergyTrigThresCh1Reg + 0x3000,
    kHiEnergyTrigThresCh2Reg + 0x3000,
    kHiEnergyTrigThresCh3Reg + 0x3000,
    kHiEnergyTrigThresCh4Reg + 0x3000
};
NSString* intTrigOutPulseString[3] = {
    @"Internal    ",
    @"High Energy ",
    @"Pileup Pulse"
};

// frequency presets setup
unsigned char freqPreset62_5MHz[6] = {0x23,0xC2,0xBC,0x33,0xE4,0xF2};
unsigned char freqPreset125MHz[6]  = {0x21,0xC2,0xBC,0x33,0xE4,0xF2};
unsigned char freqPreset250MHz[6]  = {0x20,0xC2,0xBC,0x33,0xE4,0xF2};

//----------------------------------------------
//Control Status Register Bits
#define kLedUOnBit				(0x1<<0)
#define kLed1OnBit              (0x1<<1)
#define kLed2OnBit              (0x1<<2)
#define kLedUAppModeBit         (0x1<<4)
#define kLed1AppModeBit         (0x1<<5)
#define kLed2AppModeBitBit      (0x1<<6)
#define kRebootFPGA             (0x1<<15)

#define kLedUOffBit				(0x1<<0)
#define kLed1OffBit             (0x1<<1)
#define kLed2OffBit             (0x1<<2)
#define kLedUAppModeClrBit      (0x1<<4)
#define kLed1AppModeClrBit      (0x1<<5)
#define kLed2AppModeVlrBit      (0x1<<6)
#define kRebootFPGAClrBit       (0x1<<15)

@interface ORSIS3316Model (private)
//low level stuff that should never be called by scripts or other objects
- (int) si570FreezeDCO:(int) osc;
- (int) si570Divider:(int) osc values:(unsigned char*)data;
- (int) si570UnfreezeDCO:(int)osc;
- (int) si570NewFreq:(int) osc;
- (int) i2cStop:(int) osc;
- (int) i2cStart:(int) osc;
- (int) i2cWriteByte:(int)osc data:(unsigned char) data ack:(char*)ack;
- (int) i2cReadByte:(int) osc data:(unsigned char*) data ack:(char)ack;
- (void) addCurrentState:(NSMutableDictionary*)dictionary unsignedLongArray:(unsigned long*)anArray   size:(long)numItems forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary unsignedShortArray:(unsigned short*)anArray size:(long)numItems forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray                    size:(long)numItems forKey:(NSString*)aKey;
@end

@implementation ORSIS3316Model

#pragma mark •••Static Declarations
//static unsigned long bankMemory[4][2]={
//{0x00400000,0x00600000},
//{0x00480000,0x00680000},
//{0x00500000,0x00700000},
//{0x00580000,0x00780000},
//};

static unsigned long eventCountOffset[4][2]={ //group,bank
{0x00200010,0x00200014},
{0x00280010,0x00280014},
{0x00300010,0x00300014},
{0x00380010,0x00380014},
};

static unsigned long eventDirOffset[4][2]={ //group,bank
{0x00201000,0x00202000},
{0x00281000,0x00282000},
{0x00301000,0x00302000},
{0x00381000,0x00382000},
};

static unsigned long addressCounterOffset[4][2]={ //group,bank
{0x00200008,0x0020000C},
{0x00280008,0x0028000C},
{0x00300008,0x0030000C},
{0x00380008,0x0038000C},
};

#define kTriggerEvent1DirOffset 0x101000
#define kTriggerEvent2DirOffset 0x102000

#define kTriggerTime1Offset 0x1000
#define kTriggerTime2Offset 0x2000

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x01000000];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
    [waveFormRateGroup release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3316Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3316Controller"];
}

//- (NSString*) helpURL
//{
//	return @"VME/SIS3316.html";
//}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x00780000+0x80000);
}

#pragma mark ***Accessors
- (void) setDefaults
{
	int i;
	for(i=0;i<kNumSIS3316Channels;i++){
		[self setThreshold:i withValue:0xFFFFFFF];
	}
    
	[self setEnableInternalRouting:YES];
	[self setPageWrap:YES];
	[self setPageSize:1];
	[self setStopDelay:15000];
	[self setStartDelay:15000];
	[self setStopDelayEnabled:YES];
	[self setStartDelayEnabled:YES];
}

- (unsigned short) moduleID;
{
	return moduleID;
}

//---------------------------------------------------------------------------
//-----------------------Threshold Register Accessors------------------------
- (long) enabledMask                        { return enabledMask;                                       }
- (BOOL) enabled:(short)chan                { return enabledMask & (1<<chan);                           }
- (long) heSuppressTriggerMask              { return heSuppressTriggerMask;                             }
- (BOOL) heSuppressTriggerMask:(short)chan  { return heSuppressTriggerMask & (1<<chan);                 }
- (short) cfdControlBits:(short)aChan       { if(aChan<kNumSIS3316Channels)return cfdControlBits[aChan]; else return 0; }
- (long) threshold:(short)aChan             { if(aChan<kNumSIS3316Channels)return threshold[aChan];     else return 0;}

- (void) setEnabledMask:(long)aMask
{
    if(enabledMask==aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
    enabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EnabledChanged object:self];
}

- (void) setEnabledBit:(short)chan withValue:(BOOL)aValue
{
    unsigned char   aMask = enabledMask;
    if(aValue)      aMask |= (1<<chan);
    else            aMask &= ~(1<<chan);
    [self setEnabledMask:aMask];
}

- (void) setHeSuppressTriggerMask:(long)aMask
{
    if(heSuppressTriggerMask==aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setHeSuppressTriggerMask:heSuppressTriggerMask];
    heSuppressTriggerMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HeSuppressTrigModeChanged object:self];
}

- (void) setHeSuppressTriggerBit:(short)chan withValue:(BOOL)aValue
{
    unsigned char aMask = heSuppressTriggerMask;
    if(aValue)aMask |= (1<<chan);
    else aMask &= ~(1<<chan);
    [self setHeSuppressTriggerMask:aMask];
}

- (void) setThreshold:(short)aChan withValue:(long)aValue
{
    if(aValue<0)aValue = 0;
    if(aValue>0xFFFFFFF)aValue = 0xFFFFFFF;
    if(aValue != [self threshold:aChan]){
        [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:threshold[aChan]];
        threshold[aChan] = aValue;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ThresholdChanged object:self];
    }
}

- (void) setCfdControlBits:(short)aChan withValue:(short)aValue
{
    if(aValue<0)aValue = 0;
    if(aValue>0x3)aValue = 0x3;
    if([self cfdControlBits:aChan] == aValue)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setCfdControlBits:aChan withValue:[self cfdControlBits:aChan]];
    cfdControlBits[aChan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316CfdControlBitsChanged object:self];
}

//---------------------------------------------------------------------------
//Energy Histogram Configuration

- (long) histogramsEnabledMask                        { return histogramsEnabledMask;                                       }
- (BOOL) histogramsEnabled:(short)chan                { return histogramsEnabledMask & (1<<chan);                           }
- (void) setHistogramsEnabledMask:(long)aMask
{
    if(histogramsEnabledMask==aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setHistogramsEnabledMask:histogramsEnabledMask];
    histogramsEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HistogramsEnabledChanged object:self];
}

- (void) setHistogramsEnabled:(short)chan withValue:(BOOL)aValue
{
    unsigned char   aMask = histogramsEnabledMask;
    if(aValue)      aMask |= (1<<chan);
    else            aMask &= ~(1<<chan);
    [self setHistogramsEnabledMask:aMask];
}

- (long) pileupEnabledMask                        { return pileupEnabledMask;                                       }
- (BOOL) pileupEnabled:(short)chan                { return pileupEnabledMask & (1<<chan);                           }
- (void) setPileupEnabledMask:(long)aMask
{
    if(pileupEnabledMask==aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setPileupEnabledMask:pileupEnabledMask];
    pileupEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316PileUpEnabledChanged object:self];
}

- (void) setPileupEnabled:(short)chan withValue:(BOOL)aValue
{
    unsigned char   aMask = pileupEnabledMask;
    if(aValue)      aMask |= (1<<chan);
    else            aMask &= ~(1<<chan);
    [self setPileupEnabledMask:aMask];
}

- (long) clrHistogramsWithTSMask                { return clrHistogramsWithTSMask;}
- (BOOL) clrHistogramsWithTS:(short)chan        { return clrHistogramsWithTSMask & (1<<chan); }
- (void) setClrHistogramsWithTSMask:(long)aMask
{
    if(clrHistogramsWithTSMask==aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setClrHistogramsWithTSMask:clrHistogramsWithTSMask];
    clrHistogramsWithTSMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ClrHistogramWithTSChanged object:self];
}

- (void) setClrHistogramsWithTS:(short)chan withValue:(BOOL)aValue
{
    unsigned char   aMask = clrHistogramsWithTSMask;
    if(aValue)      aMask |= (1<<chan);
    else            aMask &= ~(1<<chan);
    [self setClrHistogramsWithTSMask:aMask];
}

- (long) writeHitsToEventMemoryMask                 { return writeHitsToEventMemoryMask;}
- (BOOL) writeHitsToEventMemory:(short)chan         { return writeHitsToEventMemoryMask & (1<<chan); }
- (void) setWriteHitsToEventMemoryMask:(long)aMask
{
    if(writeHitsToEventMemoryMask==aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteHitsToEventMemoryMask:writeHitsToEventMemoryMask];
    writeHitsToEventMemoryMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316WriteHitsIntoEventMemoryChanged object:self];
}

- (void) setWriteHitsToEventMemory:(short)chan withValue:(BOOL)aValue
{
    unsigned char   aMask = writeHitsToEventMemoryMask;
    if(aValue)      aMask |= (1<<chan);
    else            aMask &= ~(1<<chan);
    [self setWriteHitsToEventMemoryMask:aMask];
}

- (unsigned short) energyDivider:(short) aChan
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return 0;
    else return energyDivider[aChan];
}

- (void) setEnergyDivider:(short)aChan withValue:(unsigned short)aValue
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return;
    if(aValue<=0)aValue = 1;
    if(aValue>0x3f)aValue = 0xfff;
    if([self energyDivider:aChan] == aValue) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyDivider:aChan withValue:[self energyDivider:aChan]];
    energyDivider[aChan]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EnergyDividerChanged object:self];
}

- (unsigned short) energySubtractor:(short) aChan
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return 0;
    else return energySubtractor[aChan];
}

- (void) setEnergySubtractor:(short)aChan withValue:(unsigned short)aValue
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x3f)aValue = 0xff;
    if([self energySubtractor:aChan] == aValue) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergySubtractor:aChan withValue:[self energySubtractor:aChan]];
    energySubtractor[aChan]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EnergySubtractorChanged object:self];
}

//---------------------------------------------------------------------------

- (unsigned short) tauFactor:(short) aChan
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return 0;
    else return tauFactor [aChan];
}

- (void) setTauFactor:(short)aChan withValue:(unsigned short)aValue
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x3f)aValue = 0x3f;
    if([self tauFactor:aChan] == aValue) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setTauFactor:aChan withValue:[self tauFactor:aChan]];
    tauFactor[aChan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316TauFactorChanged object:self];
}


- (unsigned short) peakingTime:(short) aChan
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return 0;
    else return peakingTime[aChan];
}

- (void) setPeakingTime:(short)aChan withValue:(unsigned short)aValue
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return;
    if(aValue<0)aValue = 0;
    if(aValue>0xffff)aValue = 0xffff;
    aValue &= ~0xFFFE; //bit zero is always zero
    if([self peakingTime:aChan] == aValue) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setPeakingTime:aChan withValue:peakingTime[aChan]];
    peakingTime[aChan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316PeakingTimeChanged object:self];
}


- (unsigned short) gapTime:(short) aChan
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return 0;
    else return gapTime[aChan];
}

- (void) setGapTime:(short)aChan withValue:(unsigned short)aValue
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return;
    if(aValue<0)aValue = 0;
    if(aValue>0xffff)aValue = 0xffff;
    aValue &= ~0xFFFE; //bit zero is always zero
    if([self gapTime:aChan] == aValue) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setGapTime:aChan withValue:[self gapTime:aChan]];
    gapTime[aChan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316GapTimeChanged object:self];
}

//-------------High Energy Trigger Threshold Reg Access----------------------
//---------------------------------------------------------------------------
- (unsigned long) heTrigThreshold:(short)aChan   { return heTrigThreshold[aChan];           }
- (long) trigBothEdgesMask                       { return trigBothEdgesMask;                }
- (BOOL) trigBothEdgesMask:(short)chan           { return trigBothEdgesMask & (1<<chan);    }
- (long) intHeTrigOutPulseMask                   { return intHeTrigOutPulseMask;            }
- (BOOL) intHeTrigOutPulseMask:(short)chan       { return intHeTrigOutPulseMask & (1<<chan);}
- (unsigned short) intTrigOutPulseBit:(short)aChan         { return intTrigOutPulseBit[aChan];        }


- (void) setHeTrigThreshold:(short)aChan withValue:(unsigned long)aValue
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return;
    if(aValue>0xFFFFFFF)aValue = 0xFFFFFFF;
    if([self heTrigThreshold:aChan] == aValue)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setHeTrigThreshold:aChan withValue:[self heTrigThreshold:aChan]];
    heTrigThreshold[aChan] =aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HeTrigThresholdChanged object:self];
}

- (void) setTrigBothEdgesMask:(long)aMask
{
    if(trigBothEdgesMask == aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigBothEdgesMask:trigBothEdgesMask];
    trigBothEdgesMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316TrigBothEdgesChanged object:self];
}

- (void) setTrigBothEdgesBit:(short)aChan withValue:(BOOL)aValue
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return;
    unsigned char   aMask  = trigBothEdgesMask;
    if(aValue)      aMask |= (1<<aChan);
    else            aMask &= ~(1<<aChan);
    [self setTrigBothEdgesMask:aMask];
}

- (void) setIntHeTrigOutPulseMask:(long)aMask
{
    if(intHeTrigOutPulseMask == aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setIntHeTrigOutPulseMask:intHeTrigOutPulseMask];
    intHeTrigOutPulseMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316IntHeTrigOutPulseChanged object:self];
}

- (void) setIntHeTrigOutPulseBit:(short)aChan withValue:(BOOL)aValue
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return;
    unsigned char   aMask  = intHeTrigOutPulseMask;
    if(aValue)      aMask |= (1<<aChan);
    else            aMask &= ~(1<<aChan);
    [self setIntHeTrigOutPulseMask:aMask];
}

- (void) setIntTrigOutPulseBit:(short)aChan withValue:(unsigned short)aValue
{
    if(aChan<0 || aChan>kNumSIS3316Channels)return;

    if(aValue<0)aValue   = 0;
    if(aValue>0x3)aValue = 0x3;
    if(intTrigOutPulseBit[aChan] == aValue)return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setIntTrigOutPulseBit:aChan withValue:[self intTrigOutPulseBit:aChan]];
    intTrigOutPulseBit[aChan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316IntTrigOutPulseBitsChanged object:self];
}
//---------------------------------------------------------------------------


- (unsigned short) activeTrigGateWindowLen:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return activeTrigGateWindowLen[aGroup];
}

- (void) setActiveTrigGateWindowLen:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if(aValue != [self activeTrigGateWindowLen:aGroup]){
        [[[self undoManager] prepareWithInvocationTarget:self] setActiveTrigGateWindowLen:aGroup withValue:[self activeTrigGateWindowLen:aGroup]];
        activeTrigGateWindowLen[aGroup] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ActiveTrigGateWindowLenChanged object:self];
    }
}


- (unsigned short) preTriggerDelay:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return preTriggerDelay[aGroup];
}

- (void) setPreTriggerDelay:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self preTriggerDelay:aGroup] == aValue) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setPreTriggerDelay:aGroup withValue:[self preTriggerDelay:aGroup]];
    preTriggerDelay[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316PreTriggerDelayChanged object:self];
}

- (unsigned long) rawDataBufferLen:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return rawDataBufferLen [aGroup];
}

- (void) setRawDataBufferLen:(short)aGroup withValue:(unsigned long)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self rawDataBufferLen:aGroup] == aValue)return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setRawDataBufferLen:aGroup withValue:[self rawDataBufferLen:aGroup]];
    rawDataBufferLen[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316RawDataBufferLenChanged object:self];
}

- (unsigned long) rawDataBufferStart:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return rawDataBufferStart[aGroup];
}

- (void) setRawDataBufferStart:(short)aGroup withValue:(unsigned long)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)  return;
    if([self rawDataBufferStart:aGroup] == aValue)return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setRawDataBufferStart:aGroup withValue:[self rawDataBufferStart:aGroup]];
    rawDataBufferStart[aGroup]=aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316RawDataBufferStartChanged object:self];
}
//-----------------
//----Accumlator gate1

- (unsigned short) accGate1Start:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate1Start[aGroup];
}

- (void) setAccGate1Start:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate1Start:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate1Start:aGroup withValue:[self accGate1Start:aGroup]];
    accGate1Start[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate1StartChanged object:self];
}


- (unsigned short) accGate1Len:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate1Len[aGroup];
}

- (void) setAccGate1Len:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate1Len:aGroup] == aValue)    return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate1Len:aGroup withValue:[self accGate1Len:aGroup]];
    accGate1Len[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate1LenChanged object:self];
}
//----Accumlator gate2
- (unsigned short) accGate2Start:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate2Start[aGroup];
}

- (void) setAccGate2Start:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate2Start:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate2Start:aGroup withValue:[self accGate2Start:aGroup]];
    accGate2Start[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate2StartChanged object:self];
}

- (unsigned short) accGate2Len:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate2Len[aGroup];
}

- (void) setAccGate2Len:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate2Len:aGroup] == aValue)     return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate2Len:aGroup withValue:[self accGate2Len:aGroup]];
    accGate2Len[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate2LenChanged object:self];
}
//----Accumlator gate3
- (unsigned short) accGate3Start:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate3Start[aGroup];
}

- (void) setAccGate3Start:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate3Start:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate3Start:aGroup withValue:[self accGate3Start:aGroup]];
    accGate3Start[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate3StartChanged object:self];
}

- (unsigned short) accGate3Len:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate3Len[aGroup];
}

- (void) setAccGate3Len:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate3Len:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate3Len:aGroup withValue:[self accGate3Len:aGroup]];
    accGate3Len[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate3LenChanged object:self];
}
//----Accumlator gate4
- (unsigned short) accGate4Start:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate4Start[aGroup];
}

- (void) setAccGate4Start:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate4Start:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate4Start:aGroup withValue:[self accGate4Start:aGroup]];
    accGate4Start[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate4StartChanged object:self];
}

- (unsigned short) accGate4Len:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate4Len[aGroup];
}

- (void) setAccGate4Len:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate4Len:aGroup] == aValue)     return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate4Len:aGroup withValue:[self accGate4Len:aGroup]];
    accGate4Len[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate4LenChanged object:self];
}
//----Accumlator gate5
- (unsigned short) accGate5Start:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate5Start[aGroup];
}

- (void) setAccGate5Start:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate5Start:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate5Start:aGroup withValue:[self accGate5Start:aGroup]];
    accGate5Start[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate5StartChanged object:self];
}

- (unsigned short) accGate5Len:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate5Len[aGroup];
}

- (void) setAccGate5Len:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate5Len:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate5Len:aGroup withValue:[self accGate5Len:aGroup]];
    accGate5Len[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate5LenChanged object:self];
}
//----Accumlator gate6
- (unsigned short) accGate6Start:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate6Start[aGroup];
}

- (void) setAccGate6Start:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate6Start:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate6Start:aGroup withValue:[self accGate6Start:aGroup]];
    accGate6Start[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate6StartChanged object:self];
}

- (unsigned short) accGate6Len:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate6Len[aGroup];
}

- (void) setAccGate6Len:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate6Len:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate6Len:aGroup withValue:[self accGate6Len:aGroup]];
    accGate6Len[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate6LenChanged object:self];
}
//----Accumlator gate7
- (unsigned short) accGate7Start:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate7Start[aGroup];
}

- (void) setAccGate7Start:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate7Start:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate7Start:aGroup withValue:[self accGate7Start:aGroup]];
    accGate7Start[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate7StartChanged object:self];
}

- (unsigned short) accGate7Len:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate7Len[aGroup];
}

- (void) setAccGate7Len:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate7Len:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate7Len:aGroup withValue:[self accGate7Len:aGroup]];
    accGate7Len[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate7LenChanged object:self];
}
//----Accumlator gate8
- (unsigned short) accGate8Start:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate8Start[aGroup];
}

- (void) setAccGate8Start:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate8Start:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate8Start:aGroup withValue:[self accGate8Start:aGroup]];
    accGate8Start[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate8StartChanged object:self];
}

- (unsigned short) accGate8Len:(short) aGroup
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return 0;
    else return accGate8Len[aGroup];
}

- (void) setAccGate8Len:(short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup<0 || aGroup>kNumSIS3316Groups)return;
    if([self accGate8Len:aGroup] == aValue)   return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate8Len:aGroup withValue:[self accGate8Len:aGroup]];
    accGate8Len[aGroup]=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate8LenChanged object:self];
}

//-----------------

- (BOOL) bankFullTo3
{
    return bankFullTo3;
}

- (void) setBankFullTo3:(BOOL)aBankFullTo3
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBankFullTo3:bankFullTo3];
    bankFullTo3 = aBankFullTo3;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316CSRRegChanged object:self];
}

- (BOOL) bankFullTo2
{
    return bankFullTo2;
}

- (void) setBankFullTo2:(BOOL)aBankFullTo2
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBankFullTo2:bankFullTo2];
    bankFullTo2 = aBankFullTo2;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316CSRRegChanged object:self];
}

- (BOOL) bankFullTo1
{
    return bankFullTo1;
}

- (void) setBankFullTo1:(BOOL)aBankFullTo1
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBankFullTo1:bankFullTo1];
    bankFullTo1 = aBankFullTo1;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316CSRRegChanged object:self];
}
- (BOOL) enableInternalRouting
{
    return enableInternalRouting;
}

- (void) setEnableInternalRouting:(BOOL)aEnableInternalRouting
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableInternalRouting:enableInternalRouting];
    enableInternalRouting = aEnableInternalRouting;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316CSRRegChanged object:self];
}

- (BOOL) activateTriggerOnArmed
{
    return activateTriggerOnArmed;
}

- (void) setActivateTriggerOnArmed:(BOOL)aActivateTriggerOnArmed
{
    [[[self undoManager] prepareWithInvocationTarget:self] setActivateTriggerOnArmed:activateTriggerOnArmed];
    activateTriggerOnArmed = aActivateTriggerOnArmed;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316CSRRegChanged object:self];
}

- (BOOL) invertTrigger
{
    return invertTrigger;
}

- (void) setInvertTrigger:(BOOL)aInvertTrigger
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInvertTrigger:invertTrigger];
    invertTrigger = aInvertTrigger;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316CSRRegChanged object:self];
}

- (BOOL) enableTriggerOutput
{
    return enableTriggerOutput;
}

- (void) setEnableTriggerOutput:(BOOL)aEnableTriggerOutput
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableTriggerOutput:enableTriggerOutput];
    enableTriggerOutput = aEnableTriggerOutput;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316CSRRegChanged object:self];
}

//Acquisition control reg
- (BOOL) multiplexerMode
{
    return multiplexerMode;
}

- (void) setMultiplexerMode:(BOOL)aMultiplexerMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMultiplexerMode:multiplexerMode];
    multiplexerMode = aMultiplexerMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcqRegChanged object:self];
}

- (BOOL) bankSwitchMode
{
    return bankSwitchMode;
}

- (void) setBankSwitchMode:(BOOL)aBankSwitchMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBankSwitchMode:bankSwitchMode];
    bankSwitchMode = aBankSwitchMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcqRegChanged object:self];
}

- (BOOL) autoStart
{
    return autoStart;
}

- (void) setAutoStart:(BOOL)aAutoStart
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoStart:autoStart];
    autoStart = aAutoStart;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcqRegChanged object:self];
}

- (BOOL) multiEventMode
{
    return multiEventMode;
}

- (void) setMultiEventMode:(BOOL)aMultiEventMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMultiEventMode:multiEventMode];
    multiEventMode = aMultiEventMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcqRegChanged object:self];
}
- (BOOL) p2StartStop
{
    return p2StartStop;
}

- (void) setP2StartStop:(BOOL)ap2StartStop
{
    [[[self undoManager] prepareWithInvocationTarget:self] setP2StartStop:p2StartStop];
    p2StartStop = ap2StartStop;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcqRegChanged object:self];
}

- (BOOL) lemoStartStop
{
    return lemoStartStop;
}

- (void) setLemoStartStop:(BOOL)aLemoStartStop
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoStartStop:lemoStartStop];
    lemoStartStop = aLemoStartStop;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcqRegChanged object:self];
}
- (BOOL) gateMode
{
    return gateMode;
}

- (void) setGateMode:(BOOL)aGateMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGateMode:gateMode];
    gateMode = aGateMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcqRegChanged object:self];
}

//clocks and delays (Acquistion control reg)
- (BOOL) randomClock
{
    return randomClock;
}

- (void) setRandomClock:(BOOL)aRandomClock
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRandomClock:randomClock];
    randomClock = aRandomClock;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcqRegChanged object:self];
}

- (BOOL) startDelayEnabled
{
    return startDelayEnabled;
}

- (void) setStartDelayEnabled:(BOOL)aStartDelayEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartDelayEnabled:startDelayEnabled];
    startDelayEnabled = aStartDelayEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcqRegChanged object:self];
}

- (BOOL) stopDelayEnabled
{
    return stopDelayEnabled;
}

- (void) setStopDelayEnabled:(BOOL)aStopDelayEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStopDelayEnabled:stopDelayEnabled];
    stopDelayEnabled = aStopDelayEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcqRegChanged object:self];
}

- (int) stopDelay
{
    return stopDelay;
}

- (void) setStopDelay:(int)aStopDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStopDelay:stopDelay];
    stopDelay = aStopDelay;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316StopDelayChanged object:self];
}

- (int) startDelay
{
    return startDelay;
}

- (void) setStartDelay:(int)aStartDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartDelay:startDelay];
    startDelay = aStartDelay;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316StartDelayChanged object:self];
}
- (int) clockSource
{
    return clockSource;
}

- (void) setClockSource:(int)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = aClockSource;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ClockSourceChanged object:self];
}


//Event configuration
- (BOOL) pageWrap
{
    return pageWrap;
}

- (void) setPageWrap:(BOOL)aPageWrap
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPageWrap:pageWrap];
    pageWrap = aPageWrap;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EventConfigChanged object:self];
}

- (BOOL) gateChaining
{
    return gateChaining;
}

- (void) setGateChaining:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGateChaining:gateChaining];
    gateChaining = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EventConfigChanged object:self];
}

- (BOOL) stopTrigger
{
    return stopTrigger;
}

- (void) setStopTrigger:(BOOL)aStopTrigger
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStopTrigger:stopTrigger];
    
    stopTrigger = aStopTrigger;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316StopTriggerChanged object:self];
}

- (int) pageSize
{
    return pageSize;
}

- (void) setPageSize:(int)aPageSize
{
	if(aPageSize<0)		aPageSize = 0;
	else if(aPageSize>7)aPageSize = 7;
    [[[self undoManager] prepareWithInvocationTarget:self] setPageSize:pageSize];
    pageSize = aPageSize;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316PageSizeChanged object:self];
}

- (int) numberOfSamples
{
	static unsigned long sampleSize[8]={
		0x20000,
		0x4000,
		0x1000,
		0x800,
		0x400,
		0x200,
		0x100,
		0x80
	};
	
	return sampleSize[pageSize];
}

- (ORRateGroup*) waveFormRateGroup
{
    return waveFormRateGroup;
}
- (void) setWaveFormRateGroup:(ORRateGroup*)newRateGroup
{
    [newRateGroup retain];
    [waveFormRateGroup release];
    waveFormRateGroup = newRateGroup;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSIS3316RateGroupChangedNotification
	 object:self];    
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) initParams
{
	enabledMask = 0xFFFFFFFF;
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

#pragma mark •••Rates
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumSIS3316Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}



#pragma mark •••Hardware Access
- (void) writeControlStatusReg:(unsigned long)aValue
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kControlStatusReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (unsigned long) readControlStatusReg
{
    unsigned long aValue = 0;
    [[self adapter] readLongBlock:&aValue
                         atAddress:[self baseAddress] + kControlStatusReg
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    return aValue;
}

- (void) readModuleID:(BOOL)verbose
{
    unsigned long result = 0;
    [[self adapter] readLongBlock:&result
                        atAddress:[self baseAddress] + kModuleIDReg
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    moduleID = result >> 16;
    unsigned short majorRev = (result >> 8) & 0xff;
    unsigned short minorRev = result & 0xff;
    if(verbose)NSLog(@"SIS3316 ID: %x  Firmware:%x.%x\n",moduleID,majorRev,minorRev);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316IDChanged object:self];
}

- (void) readHWVersion:(BOOL)verbose
{
    unsigned long result = 0;
    [[self adapter] readLongBlock:&result
                        atAddress:[self baseAddress] + kHWVersionReg
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if(verbose)NSLog(@"%@ HW Version: %d\n",[self fullID],result);
}

- (void) readTemperature:(BOOL)verbose
{
    unsigned long result = 0;
    [[self adapter] readLongBlock:&result
                        atAddress:[self baseAddress] + kTemperatureReg
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if(verbose)NSLog(@"%@ HW Version: 0x`%0x\n",[self fullID],result);
}

- (void) readSerialNumber:(BOOL)verbose
{
    unsigned long result = 0;
    [[self adapter] readLongBlock:&result
                        atAddress:[self baseAddress] + kSerialNumberReg
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    unsigned short serialNumber = result & 0xFF;
    if(verbose)NSLog(@"%@ Serial Number: 0x%0x\n",[self fullID],serialNumber);
}

- (void) writeClockSource
{
    unsigned long value = clockSource;
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kAdcSampleClockDistReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}



//- (void) writeAcquistionRegister
//{
//	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.	
//	unsigned long aMask = 0x0;
//	if(bankSwitchMode)			aMask |= kSISBankSwitch;
//	if(autoStart)				aMask |= kSISAutostart;
//	if(multiEventMode)			aMask |= kSISMultiEvent;
//	if(startDelayEnabled)		aMask |= kSISEnableStartDelay;			
//	if(stopDelayEnabled)		aMask |= kSISEnableStopDelay;			
//	if(lemoStartStop)			aMask |= kSISEnableLemoStartStop;			
//	if(p2StartStop)				aMask |= kSISEnableP2StartStop;			
//	if(gateMode)				aMask |= kSISEnableGateMode;
//	if(randomClock)				aMask |= kSISEnableRandomClock;
//	/*clock src bits*/			aMask |= ((clockSource & 0x7) << kSISClockSetShiftCount);
//	if(multiplexerMode)			aMask |= kSISMultiplexerMode;
//		
//	//put the inverse in the top bits to turn off everything else
//	aMask = ((~aMask & 0x0000ffff)<<16) | aMask;
//	
//	[[self adapter] writeLongBlock:&aMask
//                         atAddress:[self baseAddress] + kAcquisitionControlReg
//                        numToWrite:1
//                        withAddMod:[self addressModifier]
//                     usingAddSpace:0x01];
//}

//- (void) writeEventConfigurationRegister
//{
//	//enable/disable autostop at end of page
//	//set pagesize
//	unsigned long aMask = 0x0;
//	aMask					  |= pageSize;
//	if(pageWrap)		aMask |= kSISWrapMask;
//	if(randomClock)		aMask |= kSISRandomClock;		//This must be set in both Acq Control and Event Config Registers
//	if(multiplexerMode) aMask |= kSISMultiplexerMode2;  //This must be set in both Acq Control and Event Config Registers
//	[[self adapter] writeLongBlock:&aMask
//                         atAddress:[self baseAddress] + kEventConfigAll
//                        numToWrite:1
//                        withAddMod:[self addressModifier]
//                     usingAddSpace:0x01];
//}
//

- (void) setLed:(BOOL)state
{
    unsigned long aValue = state ? 0x1:(0x1<<16);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kControlStatusReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}



- (unsigned long) eventNumberGroup:(int)group bank:(int) bank
{
	//Note, here banks are 0,1,2,3 NOT 1,2,3,4
	unsigned long eventNumber = 0x0;   
	[[self adapter] readLongBlock:&eventNumber
						atAddress:[self baseAddress] + eventCountOffset[group][bank]
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	
	return eventNumber;
}

- (unsigned long) eventTriggerGroup:(int)group bank:(int) bank
{
	//Note, here banks are 0,1,2,3 NOT 1,2,3,4
	unsigned long triggerWord = 0x0;   
	[[self adapter] readLongBlock:&triggerWord
						atAddress:[self baseAddress] + eventDirOffset[group][bank]
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	
	return triggerWord;
}

- (void) readAddressCounts
{
	unsigned long aValue;   
	unsigned long aValue1; 
	int i;
	for(i=0;i<4;i++){
		[[self adapter] readLongBlock:&aValue
							atAddress:[self baseAddress] + addressCounterOffset[i][0]
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		[[self adapter] readLongBlock:&aValue1
							atAddress:[self baseAddress] + addressCounterOffset[i][1]
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		NSLog(@"Group %d Address Counters:  0x%04x   0x%04x\n",i,aValue,aValue1);
	}
}

- (void) clearTimeStamp
{
    unsigned long aValue = 1;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kKeyTimeStampClrReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}


- (void) trigger
{
    unsigned long aValue = 1;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kKeyTriggerReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}
- (void) resetADCClockDCM
{
    unsigned long aValue = 1;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kKeyAdcClockPllResetReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) setClockChoice:(int) clck_choice
{
    unsigned int iob_delay_value = 0 ;
    int return_code = 0;
    // set clock , wait 20ms in sis3316_adc1->set_frequency
    // reset DCM in sis3316_adc1->set_frequency
    switch (clck_choice) {
        case 0:
            return_code = [self setFrequency:0 values:freqPreset250MHz];
            iob_delay_value = 0x48 ;
            break;
        case 1:
            return_code = [self setFrequency:0 values:freqPreset125MHz];
            iob_delay_value = 0x48 ;
            break;
        case 2:
            return_code = [self setFrequency:0 values:freqPreset62_5MHz];
            iob_delay_value = 0x10 ;
            break;
        case 3:
            return_code = [self setFrequency:0 values:freqPreset125MHz];
            iob_delay_value = 0x48 ;
            break;
        case 4:
            return_code = [self setFrequency:0 values:freqPreset125MHz];
            iob_delay_value = 0x48 ;
            break;
        case 5:
            return_code = [self setFrequency:0 values:freqPreset125MHz];
            iob_delay_value = 0x48 ;
            break;
    }
    if(return_code){
        NSLog(@"%@:Error setting clock ERROR(%d)\n",[self fullID],return_code);
    }
    usleep(10000);
    int group;
    for(group=0;group<4;group++){
        unsigned long aValue = 0xf00;
        [[self adapter] writeLongBlock:&aValue
                             atAddress:[self baseAddress] + kAdcInputTapDelayReg + (0x1000*group)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
    }
    usleep(10000);
    for(group=0;group<4;group++){
        unsigned long aValue = 0x300 + iob_delay_value;
        [[self adapter] writeLongBlock:&aValue
                             atAddress:[self baseAddress] + kAdcInputTapDelayReg + (0x1000*group)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
    }
    usleep(10000) ;

}

- (int) setFrequency:(int) osc values:(unsigned char*)values
{
    
    if(values == nil)return -100;
    if(osc > 3 || osc < 0)return -100;
    
    int rc = [self si570FreezeDCO:osc];
    if(rc){
        NSLog(@"%@ : si570FreezeDCO Error(%d)\n",[self fullID],rc);
        return rc;
    }
    
    rc = [self si570Divider:osc values:values];
    if(rc){
        NSLog(@"%@ : si570Divider Error(%d)\n",[self fullID],rc);
        return rc;
    }

    rc = [self si570UnfreezeDCO:osc];
    if(rc){
        NSLog(@"%@ : si570UnfreezeDCO Error(%d)\n",[self fullID],rc);
        return rc;
    }
    
    rc = [self si570NewFreq:osc];
    if(rc){
        NSLog(@"%@ : si570NewFreq Error(%d)\n",[self fullID],rc);
        return rc;
    }
    
    // min. 10ms wait
    usleep(20000);
    
    [self resetADCClockDCM];

    return rc;
}


- (void) switchBanks
{
    if(currentBank == 1)    [self armBank2];
    else                    [self armBank1];
}

- (void) disarmSampleLogic
{
    unsigned long aValue = 1;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kKeyDisarmSampleLogicReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (void) armBank1
{
    unsigned long aValue = 1;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kKeyDisarmXArmBank1Reg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
 
    currentBank = 1;
}

- (void) armBank2
{
    unsigned long aValue = 1;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kKeyDisarmXArmBank2Reg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    currentBank = 2;
}


- (BOOL) addressThresholdFlag
{
    unsigned long aValue=0;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + kAcqControlStatusReg
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return (aValue & (0x1<<19)) != 0;
}

- (BOOL) sampleLogicIsBusy
{
	unsigned long aValue=0;
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + kAcqControlStatusReg
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	return (aValue & (0x1<<18)) != 0;
}

- (void) writeFirEnergySetup
{
    int i;
    for(i = 0; i < kNumSIS3316Channels; i++) {
        unsigned long valueToWrite =  (([self tauFactor:i] & 0x3f)<<12) | (([self gapTime:i] & 0xffff)<<12) | ([self peakingTime:i] & 0xffff);
        
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kFirEnergySetupCh1Reg + (0x10*i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
    }
}

- (void) writeFirTriggerSetup
{
    int i;
    for(i = 0; i < kNumSIS3316Channels; i++) {
        unsigned long valueToWrite =  (([self gapTime:i] & 0xffff)<<12) | ([self peakingTime:i] & 0xffff);
        
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kFirTrigSetupCh1Reg + (0x10*i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
    }
}

- (void) writeThresholds
{   
	int i;
	if(!moduleID)[self readModuleID:NO];
	for(i = 0; i < kNumSIS3316Channels; i++) {
		unsigned long valueToWrite =  (((enabledMask>>i)           & 0x1) << 31)  |
                                      (((heSuppressTriggerMask>>i) & 0x1) << 30)  |
                                      ((cfdControlBits[i]+1  & 0x3) <<28)   |
                                      (threshold[i]          & 0xffffffff);
							
		[[self adapter] writeLongBlock:&valueToWrite
							 atAddress:[self baseAddress] + thresholdRegs[i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (void) readThresholds:(BOOL)verbose
{   
	int i;
    if(verbose){
        NSLog(@"Reading Thresholds:\n");
        NSLog(@"Chan Enabled HESupp CFD Threshold \n");
    }
    for(i =0; i < kNumSIS3316Channels; i++) {
		
		unsigned long aValue;
		[[self adapter] readLongBlock: &aValue
							atAddress: [self baseAddress] + thresholdRegs[i]
							numToRead: 1
						   withAddMod: [self addressModifier]
						usingAddSpace: 0x01];
		
		if(verbose){
            unsigned short thres  = (aValue & 0x0FFFFFFF);
            unsigned short cfdCnt = ((aValue>>28) & 0x3);
            unsigned short heSup  = ((aValue>>30) & 0x1);
            unsigned short enabl  = ((aValue>>31) & 0x1);
			NSLog(@"%2d: %@ %@ %@ 0x%08x\n",i, enabl?@"YES":@" NO",heSup?@"YES":@" NO",cfdCntrlString[cfdCnt],thres);
		}
	}
}


- (void) writeHeTrigThresholds
{
    int i;
    for(i = 0; i < kNumSIS3316Channels; i++) {
        unsigned long valueToWrite =    (((trigBothEdgesMask>>i)        & 0x1) << 31)  |
                                        (((intHeTrigOutPulseMask>>i)    & 0x1) << 30)  |
                                        (([self intTrigOutPulseBit:i]  & 0x3) <<28)   |
                                        ([self heTrigThreshold:i]       & 0xffffffff);
        
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + heThresholdRegs[i]
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
    }
  
}

- (void) writeActiveTrigeGateWindowLens
{
    int i;
    for(i = 0; i < kNumSIS3316Groups; i++) {
        unsigned long valueToWrite = [self activeTrigGateWindowLen:i];
        
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kActTriggerGateWindowLenReg + (0x1000 * i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
    }
    
}

- (void) writePreTriggerDelays
{
    int i;
    for(i = 0; i < kNumSIS3316Groups; i++) {
        unsigned long valueToWrite = [self preTriggerDelay:i];
        
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kPreTriggerDelayReg + (0x1000 * i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
    }
    
}

- (void) writeRawDataBufferConfig
{
    int i;
    
    for(i = 0; i < kNumSIS3316Groups; i++) {
        unsigned long valueToWrite = ([self rawDataBufferLen:i]<<16) | ([self rawDataBufferStart:i]);
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kRawDataBufferConfigReg + (0x1000 * i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
    }
    
}


- (void) readHeTrigThresholds:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading High Energty Thresholds:\n");
        NSLog(@"Chan BothEdges IntHETrigOut IntTrigOut HEThreshold \n");
    }
    for(i =0; i < kNumSIS3316Channels; i++) {
        
        unsigned long aValue;
        [[self adapter] readLongBlock: &aValue
                            atAddress: [self baseAddress] + heThresholdRegs[i]
                            numToRead: 1
                           withAddMod: [self addressModifier]
                        usingAddSpace: 0x01];
        
        if(verbose){
            unsigned short heThres  = (aValue & 0x0FFFFFFF);
            unsigned short intTrigOut = ((aValue>>28) & 0x3);
            unsigned short intHETrigOut  = ((aValue>>30) & 0x1);
            unsigned short both  = ((aValue>>31) & 0x1);
            NSLog(@"%2d: %@ %@ %@ 0x%08x\n",i, both?@"YES":@" NO",intHETrigOut?@"YES":@" NO",intTrigOutPulseString[intTrigOut],heThres);
        }
    }
}
- (void) writeAccumulatorGates
{
    int i;
    unsigned long valueToWrite;
    for(i = 0; i < kNumSIS3316Groups; i++) {
        valueToWrite =  ([self accGate1Len:i] << 16) | [self accGate1Start:i];
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kAccGate1ConfigReg + (0x1000 * i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
        
        valueToWrite =  ([self accGate2Len:i] << 16) | [self accGate2Start:i];
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kAccGate2ConfigReg + (0x1000 * i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];

        valueToWrite =  ([self accGate3Len:i] << 16) | [self accGate3Start:i];
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kAccGate3ConfigReg + (0x1000 * i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];

        valueToWrite =  ([self accGate4Len:i] << 16) | [self accGate4Start:i];
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kAccGate4ConfigReg + (0x1000 * i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];

        valueToWrite =  ([self accGate5Len:i] << 16) | [self accGate5Start:i];
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kAccGate5ConfigReg + (0x1000 * i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];

        valueToWrite =  ([self accGate6Len:i] << 16) | [self accGate6Start:i];
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kAccGate6ConfigReg + (0x1000 * i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];

        valueToWrite =  ([self accGate7Len:i] << 16) | [self accGate7Start:i];
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kAccGate7ConfigReg + (0x1000 * i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];

        valueToWrite =  ([self accGate8Len:i] << 16) | [self accGate8Start:i];
        [[self adapter] writeLongBlock:&valueToWrite
                             atAddress:[self baseAddress] + kAccGate8ConfigReg + (0x1000 * i)
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
    }
}

- (void) writeHistogramConfiguration
{
    int i;
    for(i=0;i<16;i++){
        unsigned long aValue = 0x0;
        if([self histogramsEnabled:i])      aValue |= 0x1<<0;
        if([self pileupEnabled:i])          aValue |= 0x1<<1;
        if([self clrHistogramsWithTS:i])    aValue |= 0x1<<30;
        if([self writeHitsToEventMemory:i]) aValue |= 0x1<<31;
        
        aValue |= ([self energyDivider:i]&0xfff)  << 16;
        aValue |= ([self energySubtractor:i]&0xfff)<< 8;

        [[self adapter] writeLongBlock: &aValue
                            atAddress: [self baseAddress] + energyHistogramConfigRegs[i]
                            numToWrite: 1
                           withAddMod: [self addressModifier]
                        usingAddSpace: 0x01];
    }
}
- (void) writeDataFormat
{
    int i;
    for(i=0;i<kNumSIS3316Groups;i++){
        unsigned long aValue = 0x05050505;//<<<<<<<---------hard coded for now---------------
        [[self adapter] writeLongBlock: &aValue
                             atAddress: [self baseAddress] + kDataFormatConfigReg * (0x1000*i)
                            numToWrite: 1
                            withAddMod: [self addressModifier]
                         usingAddSpace: 0x01];
    }
}
- (void) writeConfigurationReg
{
    int i;
    for(i=0;i<kNumSIS3316Groups;i++){
        unsigned long aValue = 0x4;//<<<<<<<---------hard coded for now (Internal Trigger)---------------
        [[self adapter] writeLongBlock: &aValue
                             atAddress: [self baseAddress] + kEventConfigReg * (0x1000*i)
                            numToWrite: 1
                            withAddMod: [self addressModifier]
                         usingAddSpace: 0x01];
    }
}

- (void) writeEndThresholds
{
    int i;
    for(i=0;i<kNumSIS3316Groups;i++){
        unsigned long aValue = 0x1024;//<<<<<<<---------hard coded for now ---------------
        [[self adapter] writeLongBlock: &aValue
                             atAddress: [self baseAddress] + kEndAddressThresholdReg * (0x1000*i)
                            numToWrite: 1
                            withAddMod: [self addressModifier]
                         usingAddSpace: 0x01];
    }
}
- (void) writeAcquistionRegister
{
unsigned long aValue=0; //<<<<<<<---------hard coded for now ---------------
[[self adapter] readLongBlock:&aValue
                    atAddress:[self baseAddress] + kAcqControlStatusReg
                    numToRead:1
                   withAddMod:[self addressModifier]
                usingAddSpace:0x01];
}
- (unsigned long) readTriggerTime:(int)bank index:(int)index
{   		
	unsigned long aValue;
	[[self adapter] readLongBlock: &aValue
						atAddress: [self baseAddress] + (bank?kTriggerTime2Offset:kTriggerTime1Offset) + index*sizeof(long)
						numToRead: 1
					   withAddMod: [self addressModifier]
					usingAddSpace: 0x01];
		
	return aValue;
}

- (unsigned long) readTriggerEventBank:(int)bank index:(int)index
{   		
	unsigned long aValue;
	[[self adapter] readLongBlock: &aValue
						atAddress: [self baseAddress] + (bank?kTriggerEvent2DirOffset:kTriggerEvent1DirOffset) + index*sizeof(long)
						numToRead: 1
					   withAddMod: [self addressModifier]
					usingAddSpace: 0x01];
	
	return aValue;
}

//- (void) configureEventRegisters
//{
//    
//    
//    unsigned int internalGateConfig_register_addresses[SIS3316_ADCGROUP_PER_CARD] = { SIS3316_ADC_CH1_4_INTERNAL_GATE_LENGTH_CONFIG_REG, SIS3316_ADC_CH5_8_INTERNAL_GATE_LENGTH_CONFIG_REG, SIS3316_ADC_CH9_12_INTERNAL_GATE_LENGTH_CONFIG_REG, SIS3316_ADC_CH13_16_INTERNAL_GATE_LENGTH_CONFIG_REG };
//    for( int groupNumber = 0; groupNumber < SIS3316_ADCGROUP_PER_CARD; groupNumber++ ) {
//        data = (0xF & internalGate2_block_channelEnableMask[groupNumber]) << 20 | (0xF & internalGate1_block_channelEnableMask[groupNumber] ) << 16 | (0xFF & internalGate_block_length[groupNumber] ) << 8 | (0xFF & internalCoincidence_block_width[groupNumber] );
//        return_code = vmei->vme_A32D32_write(baseaddress + internalGateConfig_register_addresses[groupNumber], data );
//    }
//    
//    
//    unsigned int internalTriggerDelay_register_addresses[SIS3316_ADCGROUP_PER_CARD] = { SIS3316_ADC_CH1_4_INTERNAL_TRIGGER_DELAY_CONFIG_REG, SIS3316_ADC_CH5_8_INTERNAL_TRIGGER_DELAY_CONFIG_REG,
//        SIS3316_ADC_CH9_12_INTERNAL_TRIGGER_DELAY_CONFIG_REG, SIS3316_ADC_CH13_16_INTERNAL_TRIGGER_DELAY_CONFIG_REG };
//    for( int groupNumber = 0; groupNumber < SIS3316_ADCGROUP_PER_CARD; groupNumber++ ) {
//        data = 0xFFFFFFFF & internalTriggerDelay_block[groupNumber];
//        return_code = vmei->vme_A32D32_write(baseaddress + internalTriggerDelay_register_addresses[groupNumber], data );
//    }
//    
//    
//    
//}


- (void) initBoard
{
    [self reset];
    [self writeClockSource];
    [self writeThresholds];
    [self resetADCClockDCM];
    [self setClockChoice:0];
    
//    vslot->sample_length_block[iadc]=200;
//    vslot->sample_start_block[iadc]=0;
//    vslot->pretriggerdelaypg_block[iadc]=0;
//    for(int igate=0;igate<MAX_NOF_SIS3316_QDCS;igate++){
//        vslot->qdcstart[iadc][igate]=80;
//        vslot->qdclength[iadc][igate]=10;
//    }
//    vslot->qdcstart[iadc][0]=0;
//    vslot->qdclength[iadc][0]=60;
//    vslot->qdcstart[iadc][1]=180;
//    vslot->qdclength[iadc][1]=1;
//    vslot->qdcstart[iadc][2]=74;
//    vslot->qdclength[iadc][2]=1;
//    vslot->addressthreshold[iadc]=0x100;
    [self configureAnalogRegisters];
    
    [self writeActiveTrigeGateWindowLens];
    [self writePreTriggerDelays];
    [self writeRawDataBufferConfig];
    [self writeDataFormat];
    [self writeAccumulatorGates];
    [self writeConfigurationReg];
    [self writeEndThresholds];
    [self writeAcquistionRegister];			//set up the Acquisition Register

    [self writeFirTriggerSetup];
    [self writeFirEnergySetup];
    
//    [self writeHeTrigThresholds];
//    [self writeHistogramConfiguration];
    
	
}
- (void) configureAnalogRegisters
{
    
    //temp ---- fix gains and termination values 0x1
    unsigned long adata = 0;
    int iadc;
    for( iadc = 0; iadc<kNumSIS3316Groups; iadc++){
        adata = 0;
        for(int ic = 0; ic<kNumSIS3316ChansPerGroup; ic++){
            //unsigned int tdata = 0x3 & gain[iadc*kNumSIS3316ChansPerGroup+ic];
            unsigned int tdata = 0x1;
            //if(termination[iadc*kNumSIS3316ChansPerGroup+ic] == 0) tdata = tdata | 0x4;
            adata = adata | (tdata<<(ic*8));
        }
        [[self adapter] writeLongBlock: &adata
                             atAddress: [self baseAddress] + 0x1000*iadc + kAdcGainTermCntrlReg
                            numToWrite: 1
                            withAddMod: [self addressModifier]
                         usingAddSpace: 0x01];

    }
    
    // set ADC chips via SPI
    for (int iadc=0;iadc<kNumSIS3316Groups;iadc++) {
        unsigned long aValue = 0x81001404; // SPI (OE)  set binary
        [[self adapter] writeLongBlock: &aValue
                             atAddress: [self baseAddress] + 0x1000*iadc + kAdcSpiControlReg
                            numToWrite: 1
                            withAddMod: [self addressModifier]
                         usingAddSpace: 0x01];
        
        usleep(1);
        aValue = 0x81401404; // SPI (OE)  set binary
        [[self adapter] writeLongBlock: &aValue
                             atAddress: [self baseAddress] + 0x1000*iadc + kAdcSpiControlReg
                            numToWrite: 1
                            withAddMod: [self addressModifier]
                         usingAddSpace: 0x01];
    
        usleep(1);
        aValue = 0x8100ff01; // SPI (OE)  update
        [[self adapter] writeLongBlock: &aValue
                             atAddress: [self baseAddress] + 0x1000*iadc + kAdcSpiControlReg
                            numToWrite: 1
                            withAddMod: [self addressModifier]
                         usingAddSpace: 0x01];
      
        usleep(1);
        aValue = 0x8140ff01; // SPI (OE)  update
        [[self adapter] writeLongBlock: &aValue
                             atAddress: [self baseAddress] + 0x1000*iadc + kAdcSpiControlReg
                            numToWrite: 1
                            withAddMod: [self addressModifier]
                         usingAddSpace: 0x01];
        usleep(1);
    }
    
    //  set ADC offsets (DAC)
    //dacoffset[iadc] = 0x8000; //2V Range: -1 to 1V 0x8000, -2V to 0V 13000
    unsigned long dacOffset = 0x8000;
    for (iadc=0;iadc<kNumSIS3316Groups;iadc++) {
        unsigned long aValue = 0x80000000 + 0x08000000 +  0x00f00000 + 0x1; // set internal Reference
        [[self adapter] writeLongBlock: &aValue
                             atAddress: [self baseAddress] + 0x1000*iadc + kAdcOffsetDacCntrlReg
                            numToWrite: 1
                            withAddMod: [self addressModifier]
                         usingAddSpace: 0x01];
        usleep(1);
        aValue = 0x80000000 + 0x02000000 +  0x00f00000 + ((dacOffset & 0xffff) << 4);  // clear error Latch bits
        [[self adapter] writeLongBlock: &aValue
                             atAddress: [self baseAddress] + 0x1000*iadc + kAdcOffsetDacCntrlReg
                            numToWrite: 1
                            withAddMod: [self addressModifier]
                         usingAddSpace: 0x01];

        usleep(1);
        aValue = 0xC0000000;  // clear error Latch bits
        [[self adapter] writeLongBlock: &aValue
                             atAddress: [self baseAddress] + 0x1000*iadc + kAdcOffsetDacCntrlReg
                            numToWrite: 1
                            withAddMod: [self addressModifier]
                         usingAddSpace: 0x01];
        usleep(1);
    }
}

- (void) testMemory
{
	long i;
	for(i=0;i<1024;i++){
		unsigned long aValue = i;
		[[self adapter] writeLongBlock: &aValue
							atAddress: [self baseAddress] + 0x00400000+i*4
							numToWrite: 1
						   withAddMod: [self addressModifier]
						usingAddSpace: 0x01];
	}
	long errorCount =0;
	for(i=0;i<1024;i++){
		unsigned long aValue;
		[[self adapter] readLongBlock: &aValue
							atAddress: [self baseAddress] + 0x00400000+i*4
							numToRead: 1
						   withAddMod: [self addressModifier]
						usingAddSpace: 0x01];
		if(aValue!=i)errorCount++;
	}
	if(errorCount)NSLog(@"Error R/W Bank memory: %d errors\n",errorCount);
	else NSLog(@"Memory Bank Test Passed\n");
}


#pragma mark •••Data Taker
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORSIS3316WaveformDecoder",            @"decoder",
								 [NSNumber numberWithLong:dataId],       @"dataId",
								 [NSNumber numberWithBool:YES],          @"variable",
								 [NSNumber numberWithLong:-1],			 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
    
    return dataDictionary;
}

#pragma mark •••HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (int) numberOfChannels
{
    return kNumSIS3316Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Page Size"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPageSize:) getMethod:@selector(pageSize)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Start Delay"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setStartDelay:) getMethod:@selector(startDelay)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Stop Delay"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setStopDelay:) getMethod:@selector(stopDelay)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
    [a addObject:[ORHWWizParam boolParamWithName:@"PageWrap" setter:@selector(setPageWrap:) getter:@selector(pageWrap)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"StopTrigger" setter:@selector(setStopTrigger:) getter:@selector(stopTrigger)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"P2StartStop" setter:@selector(setP2StartStop:) getter:@selector(p2StartStop)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"LemoStartStop" setter:@selector(setLemoStartStop:) getter:@selector(lemoStartStop)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"RandomClock" setter:@selector(setRandomClock:) getter:@selector(randomClock)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"GateMode" setter:@selector(setGateMode:) getter:@selector(gateMode)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"StartDelayEnabled" setter:@selector(setStartDelayEnabled:) getter:@selector(startDelayEnabled)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"StopDelayEnabled" setter:@selector(setStopDelayEnabled:) getter:@selector(stopDelayEnabled)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"MultiEvent" setter:@selector(setMultiEventMode:) getter:@selector(multiEventMode)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"AutoStart" setter:@selector(setAutoStart:) getter:@selector(autoStart)]];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0x7fff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}


- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel  name:@"Crate"   className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel     name:@"Card"    className:@"ORSIS3316Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel    name:@"Channel" className:@"ORSIS3316Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:@"Threshold"])return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Enabled"]) return [cardDictionary objectForKey:@"enabledMask"];
    else if([param isEqualToString:@"Page Size"]) return [cardDictionary objectForKey:@"pageSize"];
    else if([param isEqualToString:@"Start Delay"]) return [cardDictionary objectForKey:@"startDelay"];
    else if([param isEqualToString:@"Stop Delay"]) return [cardDictionary objectForKey:@"stopDelay"];
    else if([param isEqualToString:@"Clock Source"]) return [cardDictionary objectForKey:@"clockSource"];
    else if([param isEqualToString:@"PageWrap"]) return [cardDictionary objectForKey:@"pageWrap"];
    else if([param isEqualToString:@"StopTrigger"]) return [cardDictionary objectForKey:@"stopTrigger"];
    else if([param isEqualToString:@"P2StartStop"]) return [cardDictionary objectForKey:@"p2StartStop"];
    else if([param isEqualToString:@"LemoStartStop"]) return [cardDictionary objectForKey:@"lemoStartStop"];
    else if([param isEqualToString:@"RandomClock"]) return [cardDictionary objectForKey:@"randomClock"];
    else if([param isEqualToString:@"GateMode"]) return [cardDictionary objectForKey:@"gateMode"];
    else if([param isEqualToString:@"MultiEvent"]) return [cardDictionary objectForKey:@"multiEventMode"];
    else if([param isEqualToString:@"StartDelayEnabled"]) return [cardDictionary objectForKey:@"sartDelayEnabled"];
    else if([param isEqualToString:@"StopDelayEnabled"]) return [cardDictionary objectForKey:@"stopDelayEnabled"];
    else return nil;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3316Model"];    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
    
    [self startRates];
    [self initBoard];
	
	if(!moduleID)[self readModuleID:NO];
			
	[self armBank2];
	[self setLed:YES];
	isRunning = NO;
	count=0;
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    @try {
		isRunning = YES;
		if([self addressThresholdFlag]){
			int prevRunningBank = currentBank;
            [self switchBanks];
			
            // Verify that the previous bank address is valid
            unsigned long prevBankEndingAddress = 0;
            int max_poll_counter = 1000;
            int chan = 0;
            BOOL timeout = NO;
            do {
                [[self adapter] readLongBlock: &prevBankEndingAddress
                                    atAddress: [self baseAddress] + prevBankSampleRegs[chan]
                                    numToRead: 1
                                    withAddMod: [self addressModifier]
                                usingAddSpace: 0x01];

                max_poll_counter--;
                if (max_poll_counter == 0) {
                    timeout = YES;
                    break;
                }
            } while (((prevBankEndingAddress>>24) & 0x1)  != (prevRunningBank-1)) ; // previous Bank sample address is valid if bit 24 is equal bank2_read_flag

            if(!timeout){
                unsigned long data[10];
                [[self adapter] readLongBlock: data
                                    atAddress: [self baseAddress] + 0x00100000
                                    numToRead: 10
                                   withAddMod: [self addressModifier]
                                usingAddSpace: 0x01];
                int i;
                for(i=0;i<10;i++){
                    NSLog(@"%d : 0x%08x\n",i,data[i]);
                }
                NSLog(@"-------------------------------\n");
//                prevBankReadBeginAddress = (prevBankEndingAddress & 0x03000000) + 0x10000000*((ichan/2)%2);
//                expectedNumberOfWords = prevBankEndingAddress & 0x00FFFFFF;
//                
//                //databufferread[ichan] = 0;
//                
//                 // Start FPGA Transfer Logic
//                addr = baseaddress
//                                + SIS3316_DATA_TRANSFER_CH1_4_CTRL_REG
//                                + i_adc*0x4;
//                return_code = vmei->vme_A32D32_write ( addr , 0x80000000 + prevBankReadBeginAddress);
//                if(return_code < 0) {
//                    printf("vme_A32D32_write: %d Address: %08x %08x %d\n",ichan, addr, 0x80000000 + prevBankReadBeginAddress, prevRunningBank-1);
//                    return return_code;
//                }
//                
//                // Start the DMA Fifo Transfer
//                addr = baseaddress
//                + SIS3316_FPGA_ADC1_MEM_BASE
//                +i_adc*SIS3316_FPGA_ADC_MEM_OFFSET;
//
//                return_code = vmei->vme_A32_FastestFIFO_read( addr , databuffer[ichan], ((expectedNumberOfWords + 1) & 0xfffffE), &got_nof_32bit_words);
//                
//                //printf("Chan %d Received %d words\n",ichan,got_nof_32bit_words);
//                if(return_code < 0) {
//                    printf("vme_A32MBLT64FIFO_read: %d Address: 0x%08x %d %d\n",ichan, addr, expectedNumberOfWords, prevRunningBank-1);
//                    return return_code;
//                }
//                
//                if((got_nof_32bit_words)!=((expectedNumberOfWords + 1) & 0xfffffE))
//                    //if( got_nof_32bit_words!=expectedNumberOfWords )
//                {
//                    databufferread[ichan] = 0;
//                    std::cerr<<" Channel " <<(adcheaderid[0]>>24)<<":"<< ichan << " did not receive the expected number of words "
//                    <<got_nof_32bit_words<<"("<<((expectedNumberOfWords + 1) & 0xfffffE)<<std::endl;
//                    return 1;
//                }else{
//                    databufferread[ichan] = expectedNumberOfWords;
//                }
//                
//                if(got_nof_32bit_words!=expectedNumberOfWords) return 1;
            }
            
        }
        
	}
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
	[self setLed:NO];
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kSIS3316; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId; //better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= [self addressModifier];
	configStruct->card_info[index].base_add					= [self baseAddress];
    configStruct->card_info[index].deviceSpecificData[0]	= bankSwitchMode;
    configStruct->card_info[index].deviceSpecificData[1]	= [self numberOfSamples];
	configStruct->card_info[index].deviceSpecificData[2]	= moduleID;
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (void) reset
{
 	unsigned long aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kKeyResetReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(isRunning)return NO;
    
    ++waveFormCount[channel];
    return YES;
}

- (unsigned long) waveFormCount:(int)aChannel
{
    return waveFormCount[aChannel];
}

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumSIS3316Channels;i++){
        waveFormCount[i]=0;
    }
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setEnabledMask:               [decoder decodeInt32ForKey: @"enabledMask"]];
    [self setHistogramsEnabledMask:     [decoder decodeInt32ForKey: @"histogramsEnabledMask"]];
    [self setHeSuppressTriggerMask:     [decoder decodeInt32ForKey: @"heSuppressTriggerMask"]];
    
    int i;
    for(i=0;i<kNumSIS3316Channels;i++){
        [self setCfdControlBits:i   withValue:[decoder decodeInt32ForKey:[NSString stringWithFormat:@"cfdControlBits%d",i]]];
        [self setThreshold:i        withValue:[decoder decodeInt32ForKey:[NSString stringWithFormat:@"threshold%d",i]]];
        [self setPeakingTime:i      withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"peakingTime%d",i]]];
        [self setGapTime:i          withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"gapTime%d",i]]];
        [self setTauFactor:i        withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"tauFactor%d",i]]];
        [self setIntTrigOutPulseBit:i  withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"intTrigOutPulseBit%d",i]]];
        [self setHeTrigThreshold:i  withValue:[decoder decodeInt32ForKey:[NSString stringWithFormat:@"heTrigThreshold%d",i]]];
        [self setEnergySubtractor:i  withValue:[decoder decodeInt32ForKey:[NSString stringWithFormat:@"energySubtractors%d",i]]];
        [self setEnergyDivider:i  withValue:[decoder decodeInt32ForKey:[NSString stringWithFormat:@"energyDividers%d",i]]];
    }
    
    for(i=0;i<kNumSIS3316Groups;i++){
        [self setActiveTrigGateWindowLen:i  withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"activeTrigGateWindowLen%d",i]]];
        [self setPreTriggerDelay:i      withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"preTriggerDelay%d",i]]];
        [self setRawDataBufferLen:i     withValue:[decoder decodeInt32ForKey:[NSString stringWithFormat:@"rawDataBufferLen%d",i]]];
        [self setRawDataBufferStart:i   withValue:[decoder decodeInt32ForKey:[NSString stringWithFormat:@"rawDataBufferStart%d",i]]];
        [self setAccGate1Start:i        withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate1Start%d",i]]];
        [self setAccGate2Start:i        withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate2Start%d",i]]];
        [self setAccGate3Start:i        withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate3Start%d",i]]];
        [self setAccGate4Start:i        withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate4Start%d",i]]];
        [self setAccGate5Start:i        withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate5Start%d",i]]];
        [self setAccGate6Start:i        withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate6Start%d",i]]];
        [self setAccGate7Start:i        withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate7Start%d",i]]];
        [self setAccGate8Start:i        withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate8Start%d",i]]];
        
        [self setAccGate1Len:i          withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate1Len%d",i]]];
        [self setAccGate2Len:i          withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate2Len%d",i]]];
        [self setAccGate3Len:i          withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate3Len%d",i]]];
        [self setAccGate4Len:i          withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate4Len%d",i]]];
        [self setAccGate5Len:i          withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate5Len%d",i]]];
        [self setAccGate6Len:i          withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate6Len%d",i]]];
        [self setAccGate7Len:i          withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate7Len%d",i]]];
        [self setAccGate8Len:i          withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"accGate8Len%d",i]]];
    }
    
    [self setTrigBothEdgesMask:         [decoder decodeInt32ForKey: @"trigBothEdgesMask"]];
    [self setIntHeTrigOutPulseMask:     [decoder decodeInt32ForKey: @"intHeTrigOutPulseMask"]];
    

    //csr
	[self setBankFullTo3:			[decoder decodeBoolForKey:@"bankFullTo3"]];
    [self setBankFullTo2:			[decoder decodeBoolForKey:@"bankFullTo2"]];
    [self setBankFullTo1:			[decoder decodeBoolForKey:@"bankFullTo1"]];
	[self setEnableInternalRouting:	[decoder decodeBoolForKey:@"enableInternalRouting"]];
    [self setActivateTriggerOnArmed:[decoder decodeBoolForKey:@"activateTriggerOnArmed"]];
    [self setInvertTrigger:			[decoder decodeBoolForKey:@"invertTrigger"]];
    [self setEnableTriggerOutput:	[decoder decodeBoolForKey:@"enableTriggerOutput"]];
	
	//acq
    [self setBankSwitchMode:		[decoder decodeBoolForKey:@"bankSwitchMode"]];
    [self setAutoStart:				[decoder decodeBoolForKey:@"autoStart"]];
    [self setMultiEventMode:		[decoder decodeBoolForKey:@"multiEventMode"]];
    [self setMultiplexerMode:		[decoder decodeBoolForKey:@"multiplexerMode"]];
    [self setLemoStartStop:			[decoder decodeBoolForKey:@"lemoStartStop"]];
    [self setP2StartStop:			[decoder decodeBoolForKey:@"p2StartStop"]];
    [self setGateMode:				[decoder decodeBoolForKey:@"gateMode"]];
	
	//clocks
    [self setRandomClock:			[decoder decodeBoolForKey:@"randomClock"]];
    [self setStartDelayEnabled:		[decoder decodeBoolForKey:@"startDelayEnabled"]];
    [self setStopDelayEnabled:		[decoder decodeBoolForKey:@"stopDelayEnabled"]];
    [self setStopDelay:				[decoder decodeIntForKey:@"stopDelay"]];
    [self setStartDelay:			[decoder decodeIntForKey:@"startDelay"]];
    [self setClockSource:			[decoder decodeIntForKey:@"clockSource"]];
    [self setStopDelay:				[decoder decodeIntForKey:@"stopDelay"]];
	
    [self setPageWrap:				[decoder decodeBoolForKey:@"pageWrap"]];
    [self setStopTrigger:			[decoder decodeBoolForKey:@"stopTrigger"]];
    [self setPageSize:				[decoder decodeIntForKey:@"pageSize"]];
		
    [self setWaveFormRateGroup:     [decoder decodeObjectForKey:@"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3316Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];


    [[self undoManager] enableUndoRegistration];
    
    return self;
}


- (void) setUpEmptyArray:(SEL)aSetter numItems:(int)n
{
    NSMutableArray* anArray = [NSMutableArray arrayWithCapacity:n];
    int i;
    for(i=0;i<n;i++)[anArray addObject:[NSNumber numberWithInt:0]];
    NSMethodSignature* signature = [[self class] instanceMethodSignatureForSelector:aSetter];
    NSInvocation* invocation     = [NSInvocation invocationWithMethodSignature: signature];
    [invocation setTarget:   self];
    [invocation setSelector: aSetter];
    [invocation setArgument: &anArray atIndex: 2];
    [invocation invoke];

}

- (void) setUpArray:(SEL)aSetter intValue:(int)aValue numItems:(int)n
{
    NSMutableArray* anArray = [NSMutableArray arrayWithCapacity:n];
    int i;
    for(i=0;i<n;i++)[anArray addObject:[NSNumber numberWithInt:aValue]];
    NSMethodSignature* signature = [[self class] instanceMethodSignatureForSelector:aSetter];
    NSInvocation* invocation     = [NSInvocation invocationWithMethodSignature: signature];
    [invocation setTarget:   self];
    [invocation setSelector: aSetter];
    [invocation setArgument: &anArray atIndex: 2];
    [invocation invoke];
    
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];

    [encoder encodeInt32: enabledMask               forKey:@"enabledMask"];
    [encoder encodeInt32: histogramsEnabledMask     forKey:@"histogramsEnabledMask"];
    [encoder encodeInt32: pileupEnabledMask         forKey:@"pileupEnabledMask"];
    [encoder encodeInt32: clrHistogramsWithTSMask   forKey:@"clrHistogramsWithTSMask"];
    [encoder encodeInt32: writeHitsToEventMemoryMask forKey:@"writeHitsToEventMemoryMask"];
    [encoder encodeInt32: heSuppressTriggerMask     forKey:@"heSuppressTriggerMask"];
    int i;
    for(i=0;i<kNumSIS3316Channels;i++){
        [encoder encodeInt32:cfdControlBits         forKey:[NSString stringWithFormat:@"cfdControlBits%d",i]];
        [encoder encodeInt32:threshold[i]           forKey:[NSString stringWithFormat:@"threshold%d",i]];
        [encoder encodeInt:peakingTime[i]           forKey:[NSString stringWithFormat:@"peakingTime%d",i]];
        [encoder encodeInt:gapTime[i]               forKey:[NSString stringWithFormat:@"gapTime%d",i]];
        [encoder encodeInt:tauFactor[i]             forKey:[NSString stringWithFormat:@"tauFactor%d",i]];
        [encoder encodeInt:heTrigThreshold[i]       forKey:[NSString stringWithFormat:@"heTrigThreshold%d",i]];
        [encoder encodeInt32:energySubtractor[i]      forKey:[NSString stringWithFormat:@"energySubtractor%d",i]];
        [encoder encodeInt32:energyDivider[i]         forKey:[NSString stringWithFormat:@"energyDivider%d",i]];
    }
    
    for(i=0;i<kNumSIS3316Groups;i++){
        [encoder encodeInt:activeTrigGateWindowLen[i]     forKey:[NSString stringWithFormat:@"activeTrigGateWindowLen%d",i]];
        [encoder encodeInt:preTriggerDelay[i]             forKey:[NSString stringWithFormat:@"preTriggerDelay%d",i]];
        [encoder encodeInt:rawDataBufferLen[i]            forKey:[NSString stringWithFormat:@"rawDataBufferLen%d",i]];
        [encoder encodeInt:rawDataBufferStart[i]          forKey:[NSString stringWithFormat:@"rawDataBufferStart%d",i]];
        [encoder encodeInt:accGate1Len[i]                 forKey:[NSString stringWithFormat:@"accGate1Len%d",i]];
        [encoder encodeInt:accGate2Len[i]                 forKey:[NSString stringWithFormat:@"accGate2Len%d",i]];
        [encoder encodeInt:accGate3Len[i]                 forKey:[NSString stringWithFormat:@"accGate3Len%d",i]];
        [encoder encodeInt:accGate4Len[i]                 forKey:[NSString stringWithFormat:@"accGate4Len%d",i]];
        [encoder encodeInt:accGate5Len[i]                 forKey:[NSString stringWithFormat:@"accGate5Len%d",i]];
        [encoder encodeInt:accGate6Len[i]                 forKey:[NSString stringWithFormat:@"accGate6Len%d",i]];
        [encoder encodeInt:accGate7Len[i]                 forKey:[NSString stringWithFormat:@"accGate7Len%d",i]];
        [encoder encodeInt:accGate8Len[i]                 forKey:[NSString stringWithFormat:@"accGate8Len%d",i]];
        [encoder encodeInt:accGate1Start[i]               forKey:[NSString stringWithFormat:@"accGate1Start%d",i]];
        [encoder encodeInt:accGate2Start[i]               forKey:[NSString stringWithFormat:@"accGate2Start%d",i]];
        [encoder encodeInt:accGate3Start[i]               forKey:[NSString stringWithFormat:@"accGate3Start%d",i]];
        [encoder encodeInt:accGate4Start[i]               forKey:[NSString stringWithFormat:@"accGate4Start%d",i]];
        [encoder encodeInt:accGate5Start[i]               forKey:[NSString stringWithFormat:@"accGate5Start%d",i]];
        [encoder encodeInt:accGate6Start[i]               forKey:[NSString stringWithFormat:@"accGate6Start%d",i]];
        [encoder encodeInt:accGate7Start[i]               forKey:[NSString stringWithFormat:@"accGate7Start%d",i]];
        [encoder encodeInt:accGate8Start[i]               forKey:[NSString stringWithFormat:@"accGate8Start%d",i]];

    }
    [encoder encodeInt32:trigBothEdgesMask          forKey:@"trigBothEdgesMask"];
    [encoder encodeInt32:intHeTrigOutPulseMask      forKey:@"intHeTrigOutPulseMask"];
    

    //csr
    [encoder encodeBool:bankFullTo3				forKey:@"bankFullTo3"];
    [encoder encodeBool:bankFullTo2				forKey:@"bankFullTo2"];
    [encoder encodeBool:bankFullTo1				forKey:@"bankFullTo1"];
    [encoder encodeBool:enableInternalRouting	forKey:@"enableInternalRouting"];
    [encoder encodeBool:activateTriggerOnArmed	forKey:@"activateTriggerOnArmed"];
    [encoder encodeBool:invertTrigger			forKey:@"invertTrigger"];
    [encoder encodeBool:enableTriggerOutput		forKey:@"enableTriggerOutput"];

	//acq
    [encoder encodeBool:bankSwitchMode			forKey:@"bankSwitchMode"];
    [encoder encodeBool:autoStart				forKey:@"autoStart"];
    [encoder encodeBool:multiEventMode			forKey:@"multiEventMode"];
	[encoder encodeBool:multiplexerMode			forKey:@"multiplexerMode"];
    [encoder encodeBool:lemoStartStop			forKey:@"lemoStartStop"];
    [encoder encodeBool:p2StartStop				forKey:@"p2StartStop"];
    [encoder encodeBool:gateMode				forKey:@"gateMode"];
	
 	//clocks
    [encoder encodeBool:randomClock				forKey:@"randomClock"];
    [encoder encodeBool:startDelayEnabled		forKey:@"startDelayEnabled"];
    [encoder encodeBool:stopDelayEnabled		forKey:@"stopDelayEnabled"];
    [encoder encodeInt:stopDelay				forKey:@"stopDelay"];
    [encoder encodeInt:startDelay				forKey:@"startDelay"];
    [encoder encodeInt:clockSource				forKey:@"clockSource"];
	
    [encoder encodeBool:pageWrap				forKey:@"pageWrap"];
    [encoder encodeBool:stopTrigger				forKey:@"stopTrigger"];

    [encoder encodeInt:pageSize					forKey:@"pageSize"];
 	
    [encoder encodeObject:waveFormRateGroup     forKey:@"waveFormRateGroup"];
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];

    [objDictionary setObject: [NSNumber numberWithLong:enabledMask]                 forKey:@"enabledMask"];
    [objDictionary setObject: [NSNumber numberWithLong:histogramsEnabledMask]       forKey:@"histogramsEnabledMask"];
    [objDictionary setObject: [NSNumber numberWithLong:pileupEnabledMask    ]       forKey:@"pileupEnabledMask"];
    [objDictionary setObject: [NSNumber numberWithLong:clrHistogramsWithTSMask]     forKey:@"clrHistogramsWithTSMask"];
    [objDictionary setObject: [NSNumber numberWithLong:writeHitsToEventMemoryMask]  forKey:@"writeHitsToEventMemoryMask"];
    [objDictionary setObject: [NSNumber numberWithLong:heSuppressTriggerMask]       forKey:@"heSuppressTriggerMask"];
    [objDictionary setObject: [NSNumber numberWithLong:trigBothEdgesMask]           forKey:@"trigBothEdgesMask"];
    [objDictionary setObject: [NSNumber numberWithLong:intHeTrigOutPulseMask]       forKey:@"intHeTrigOutPulseMask"];
    

    [self addCurrentState:objDictionary unsignedLongArray:cfdControlBits  size:kNumSIS3316Channels  forKey:@"cfdControlBits"];
    [self addCurrentState:objDictionary unsignedLongArray:threshold       size:kNumSIS3316Channels forKey:@"threshold"];
    [self addCurrentState:objDictionary unsignedShortArray:peakingTime    size:kNumSIS3316Channels forKey:@"peakingTime"];
    [self addCurrentState:objDictionary unsignedShortArray:gapTime        size:kNumSIS3316Channels  forKey:@"gapTime"];
    [self addCurrentState:objDictionary unsignedShortArray:tauFactor      size:kNumSIS3316Channels  forKey:@"tauFactor"];
    [self addCurrentState:objDictionary unsignedShortArray:intTrigOutPulseBit      size:kNumSIS3316Channels  forKey:@"intTrigOutPulseBit"];
    [self addCurrentState:objDictionary unsignedLongArray:heTrigThreshold size:kNumSIS3316Channels forKey:@"heTrigThreshold"];
    [self addCurrentState:objDictionary unsignedShortArray:energyDivider size:kNumSIS3316Channels forKey:@"energyDivider"];
    [self addCurrentState:objDictionary unsignedShortArray:energySubtractor size:kNumSIS3316Channels forKey:@"energySubtractor"];

    [self addCurrentState:objDictionary unsignedShortArray:activeTrigGateWindowLen  size:kNumSIS3316Groups forKey:@"activeTrigGateWindowLen" ];
    [self addCurrentState:objDictionary unsignedShortArray:preTriggerDelay          size:kNumSIS3316Groups forKey:@"preTriggerDelay"];
    [self addCurrentState:objDictionary unsignedLongArray:rawDataBufferLen          size:kNumSIS3316Groups forKey:@"rawDataBufferLen"];
    [self addCurrentState:objDictionary unsignedLongArray:rawDataBufferStart        size:kNumSIS3316Groups forKey:@"rawDataBufferStart"];

    [self addCurrentState:objDictionary unsignedShortArray:accGate1Start            size:kNumSIS3316Groups forKey:@"accGate1Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate2Start            size:kNumSIS3316Groups forKey:@"accGate2Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate3Start            size:kNumSIS3316Groups forKey:@"accGate3Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate4Start            size:kNumSIS3316Groups forKey:@"accGate4Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate5Start            size:kNumSIS3316Groups forKey:@"accGate5Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate6Start            size:kNumSIS3316Groups forKey:@"accGate6Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate7Start            size:kNumSIS3316Groups forKey:@"accGate7Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate8Start            size:kNumSIS3316Groups forKey:@"accGate8Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate1Len              size:kNumSIS3316Groups forKey:@"accGate1Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate2Len              size:kNumSIS3316Groups forKey:@"accGate2Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate3Len              size:kNumSIS3316Groups forKey:@"accGate3Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate4Len              size:kNumSIS3316Groups forKey:@"accGate4Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate5Len              size:kNumSIS3316Groups forKey:@"accGate5Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate6Len              size:kNumSIS3316Groups forKey:@"accGate6Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate7Len              size:kNumSIS3316Groups forKey:@"accGate7Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate8Len              size:kNumSIS3316Groups forKey:@"accGate8Len"];

 
    //csr
	[objDictionary setObject: [NSNumber numberWithBool:bankFullTo3]			  forKey:@"bankFullTo3"];
	[objDictionary setObject: [NSNumber numberWithBool:bankFullTo2]			  forKey:@"bankFullTo2"];
	[objDictionary setObject: [NSNumber numberWithBool:bankFullTo1]			  forKey:@"bankFullTo1"];
	[objDictionary setObject: [NSNumber numberWithBool:enableInternalRouting] forKey:@"enableInternalRouting"];
	[objDictionary setObject: [NSNumber numberWithBool:activateTriggerOnArmed] forKey:@"activateTriggerOnArmed"];
	[objDictionary setObject: [NSNumber numberWithBool:invertTrigger]		forKey:@"invertTrigger"];
	[objDictionary setObject: [NSNumber numberWithBool:enableTriggerOutput] forKey:@"enableTriggerOutput"];
	
	//acq
	[objDictionary setObject: [NSNumber numberWithBool:bankSwitchMode]		forKey:@"bankSwitchMode"];
	[objDictionary setObject: [NSNumber numberWithBool:autoStart]			forKey:@"autoStart"];
	[objDictionary setObject: [NSNumber numberWithBool:multiEventMode]		forKey:@"multiEventMode"];
	[objDictionary setObject: [NSNumber numberWithBool:multiplexerMode]		forKey:@"multiplexerMode"];
	[objDictionary setObject: [NSNumber numberWithBool:lemoStartStop]		forKey:@"lemoStartStop"];
	[objDictionary setObject: [NSNumber numberWithBool:p2StartStop]			forKey:@"p2StartStop"];
	[objDictionary setObject: [NSNumber numberWithBool:gateMode]			forKey:@"gateMode"];

 	//clocks
	[objDictionary setObject: [NSNumber numberWithBool:randomClock]			forKey:@"randomClock"];
	[objDictionary setObject: [NSNumber numberWithInt:clockSource]			forKey:@"clockSource"];
	[objDictionary setObject: [NSNumber numberWithInt:stopDelay]			forKey:@"stopDelay"];
	[objDictionary setObject: [NSNumber numberWithInt:startDelay]			forKey:@"startDelay"];
	[objDictionary setObject: [NSNumber numberWithBool:startDelayEnabled]	forKey:@"startDelayEnabled"];
	[objDictionary setObject: [NSNumber numberWithBool:stopDelayEnabled]	forKey:@"stopDelayEnabled"];

	[objDictionary setObject: [NSNumber numberWithInt:pageSize]				forKey:@"pageSize"];
	[objDictionary setObject: [NSNumber numberWithBool:pageWrap]			forKey:@"pageWrap"];
	[objDictionary setObject: [NSNumber numberWithBool:stopTrigger]			forKey:@"stopTrigger"];
	
    return objDictionary;
}

- (NSArray*) autoTests
{
	NSMutableArray* myTests = [NSMutableArray array];
//	[myTests addObject:[ORVmeReadOnlyTest test:kControlStatus wordSize:4 name:@"Control Status"]];
//	[myTests addObject:[ORVmeReadOnlyTest test:kModuleIDReg wordSize:4 name:@"Module ID"]];
//	[myTests addObject:[ORVmeReadOnlyTest test:kAcquisitionControlReg wordSize:4 name:@"Acquistion Reg"]];
//	[myTests addObject:[ORVmeReadWriteTest test:kStartDelay wordSize:4 validMask:0x000000ff name:@"Start Delay"]];
//	[myTests addObject:[ORVmeReadWriteTest test:kStopDelay wordSize:4 validMask:0x000000ff name:@"Stop Delay"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kGeneralReset wordSize:4 name:@"Reset"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kStartSampling wordSize:4 name:@"Start Sampling"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kStopSampling wordSize:4 name:@"Stop Sampling"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kStartAutoBankSwitch wordSize:4 name:@"Stop Auto Bank Switch"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kStopAutoBankSwitch wordSize:4 name:@"Start Auto Bank Switch"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kClearBank1FullFlag wordSize:4 name:@"Clear Bank1 Full"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kClearBank2FullFlag wordSize:4 name:@"Clear Bank2 Full"]];
//	
//	int i;
//	for(i=0;i<4;i++){
//		[myTests addObject:[ORVmeReadWriteTest test:thresholdRegOffsets[i] wordSize:4 validMask:0xffffffff name:@"Threshold"]];
//		int j;
//		for(j=0;j<2;j++){
//			[myTests addObject:[ORVmeReadOnlyTest test:bankMemory[i][j] length:64*1024 wordSize:4 name:@"Adc Memory"]];
//		}
//	}
	return myTests;
}
@end

@implementation ORSIS3316Model (private)
- (int) si570FreezeDCO:(int) osc
{
    char ack;
    
    // start
    int rc = [self i2cStart:osc];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    // address
    rc = [self i2cWriteByte:osc data:OSC_ADR<<1 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // register offset
    rc = [self i2cWriteByte:osc data:0x89 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // write data
    rc = [self i2cWriteByte:osc data:0x10 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // stop
    rc = [self i2cStop:osc];
    return rc;
}

- (int) si570Divider:(int) osc values:(unsigned char*)data
{
    int rc;
    char ack;
    int i;
    
    // start
    rc = [self i2cStart:osc];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    // address
    rc = [self i2cWriteByte:osc data:OSC_ADR<<1 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // register offset
    rc = [self i2cWriteByte:osc data:0x0D ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // write data
    for(i = 0;i < 2;i++){
        rc = [self i2cWriteByte:osc data:data[i] ack:&ack];
        if(rc){
            [self i2cStop:osc];
            return rc;
        }
        
        if(!ack){
            [self i2cStop:osc];
            return -101;
        }
    }
    
    // stop
    rc = [self i2cStop:osc];
    return rc;
}

- (int) si570UnfreezeDCO:(int)osc {
    int rc;
    char ack;
    
    // start
    rc = [self i2cStart:osc];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    // address
    rc = [self i2cWriteByte:osc data:OSC_ADR<<1 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // register offset
    
    rc = [self i2cWriteByte:osc data:0x89 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // write data
    rc = [self i2cWriteByte:osc data:0x00 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // stop
    rc = [self i2cStop:osc];
    return rc;
}

- (int) si570NewFreq:(int) osc {
    
    // start
    int rc = [self i2cStart:osc];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    // address
    char ack;
    rc = [self i2cWriteByte:osc data:OSC_ADR<<1 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // register offset
    rc = [self i2cWriteByte:osc data:0x87 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // write data
    rc = [self i2cWriteByte:osc data:0x40 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // stop
    
    rc = [self i2cStop:osc];
    return rc;
}

- (int) i2cStart:(int) osc
{
    if(osc > 3)return -101;
    // start
    unsigned long aValue = 1<<I2C_START;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kAdcClockI2CReg +  (4 * osc)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    
    int i = 0;
    aValue = 0;
    do{
        // poll i2c fsm busy
        [[self adapter] readLongBlock:&aValue
                            atAddress:[self baseAddress] + kAdcClockI2CReg +  (4 * osc)
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        
        i++;
    }while((aValue & (1<<I2C_BUSY)) && (i < 1000));
    
    // register access problem
    if(i == 1000){
        printf("i2cStart3 too many tries \n");
        return -100;
    }
    
    return 0;
}


- (int) i2cStop:(int) osc
{
    if(osc > 3)return -101;
    
    // stop
    usleep(20000);
    unsigned long aValue = 1<<I2C_STOP;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kAdcClockI2CReg +  (4 * osc)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    int i = 0;
    aValue = 0;
    do{
        // poll i2c fsm busy
        usleep(20000);
        [[self adapter] readLongBlock:&aValue
                            atAddress:[self baseAddress] + kAdcClockI2CReg +  (4 * osc)
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        i++;
    }while((aValue & (1<<I2C_BUSY)) && (i < 1000));
    
    // register access problem
    if(i == 1000)return -100;
    
    return 0;
}
- (int) i2cWriteByte:(int)osc data:(unsigned char) data ack:(char*)ack
{
    int i;
    
    if(osc > 3)return -101;
    
    // write byte, receive ack
    unsigned long aValue = 1<<I2C_WRITE ^ data;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kAdcClockI2CReg +  (4 * osc)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    i = 0;
    unsigned long tmp = 0;
    do{
        // poll i2c fsm busy
        [[self adapter] readLongBlock:&tmp
                            atAddress:[self baseAddress] + kAdcClockI2CReg +  (4 * osc)
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        
        i++;
    }while((tmp & (1<<I2C_BUSY)) && (i < 1000));
    
    // register access problem
    if(i == 1000)return -100;
    
    // return ack value?
    if(ack){
        // yup
        *ack = tmp & 1<<I2C_ACK ? 1 : 0;
    }
    
    return 0;
}

- (int) i2cReadByte:(int) osc data:(unsigned char*) data ack:(char)ack
{
    if(osc > 3)return -101;
    
    // read byte, put ack
    unsigned long aValue;
    aValue = 1<<I2C_READ;
    aValue |= ack ? 1<<I2C_ACK : 0;
    usleep(20000);
    
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kAdcClockI2CReg +  (4 * osc)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    
    int i = 0;
    do{
        // poll i2c fsm busy
        usleep(20000);
        [[self adapter] readLongBlock:&aValue
                            atAddress:[self baseAddress] + kAdcClockI2CReg +  (4 * osc)
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        
        i++;
    }while((aValue & (1<<I2C_BUSY)) && (i < 1000));
    
    // register access problem
    if(i == 1000)return -100;
    
    return 0;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary unsignedLongArray:(unsigned long*)anArray size:(long)numItems forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<numItems;i++){
        [ar addObject:[NSNumber numberWithLong:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary unsignedShortArray:(unsigned short*)anArray size:(long)numItems forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<numItems;i++){
        [ar addObject:[NSNumber numberWithUnsignedShort:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray size:(long)numItems forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<numItems;i++){
        [ar addObject:[NSNumber numberWithBool:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

@end
