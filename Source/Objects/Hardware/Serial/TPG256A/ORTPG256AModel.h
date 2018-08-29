//--------------------------------------------------------
// ORTPG256AModel
//  Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
//  Created by Mark Howe on Mon Apr 16 2012.
//  Copyright 2012  University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORAdcProcessing.h"
#import "ORSerialPortWithQueueModel.h"

@class ORTimeRate;

#define kTPG256AMeasurementOK				0
#define kTPG256AMeasurementUnderRange		1
#define kTPG256AMeasurementOverRange		2
#define kTPG256AMeasurementSensorError		3
#define kTPG256AMeasurementSensorOff		4
#define kTPG256AMeasurementNoSensor			5
#define kTPG256AMeasurementIDError			6

#define kTPG256ARecordLength				14

@interface ORTPG256AModel : ORSerialPortWithQueueModel <ORAdcProcessing>
{
    @private
        uint32_t	dataId;
		float		    pressure[6];
		uint32_t	timeMeasured[6];
		ORTimeRate*		timeRates[6];
		double			lowLimit[6];
		double			lowAlarm[6];
		double			highLimit[6];
		double			highAlarm[6];
		int				measurementState[6];
		int				pollTime;
        NSMutableString* buffer;
		BOOL			shipPressures;
		int				pressureScale;
		float			pressureScaleValue;
		int				portDataState;
		int				units;
}

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;

- (void) dataReceived:(NSNotification*)note;

#pragma mark •••Accessors
- (int) units;
- (void) setUnits:(int)aUnits;
- (int) measurementState:(int)index;
- (void) setMeasurementState:(int)index value:(int)aMeasurementState;
- (float) pressureScaleValue;
- (int) pressureScale;
- (void) setPressureScale:(int)aPressureScale;
- (ORTimeRate*)timeRate:(int)index;
- (BOOL) shipPressures;
- (void) setShipPressures:(BOOL)aShipPressures;
- (int)  pollTime;
- (void) setPollTime:(int)aPollTime;
- (float) pressure:(int)index;
- (uint32_t) timeMeasured:(int)index;
- (void) setPressure:(int)index value:(float)aValue;
- (double) lowLimit:(int)aChan;
- (void) setLowLimit:(int)aChan value:(double)aValue;
- (double) highLimit:(int)aChan;
- (void) setHighLimit:(int)aChan value:(double)aValue;
- (double) highAlarm:(int)aChan;
- (void) setHighAlarm:(int)aChan value:(double)aValue;
- (double) lowAlarm:(int)aChan;
- (void) setLowAlarm:(int)aChan value:(double)aValue;

#pragma mark •••Data Records
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSDictionary*) dataRecordDescription;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherTPG256A;
- (void) shipPressureValues;

#pragma mark •••Commands
- (void) addCmdToQueue:(NSString*)aCmd;
- (void) readPressures;
- (void) sendUnits;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Adc Processing Protocol
- (void) processIsStarting;
- (void) processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (NSString*) identifier;
- (NSString*) processingTitle;
- (double) convertedValue:(int)aChan;
- (double) maxValueForChan:(int)aChan;
- (double) minValueForChan:(int)aChan;
- (void) getAlarmRangeLow:(double*)theLoAlarm high:(double*)theHighAlarm channel:(int)aChan;
- (BOOL) processValue:(int)aChan;
- (void) setProcessOutput:(int)channel value:(int)value;
@end

extern NSString* ORTPG256AModelUnitsChanged;
extern NSString* ORTPG256AModelLowLimitChanged;
extern NSString* ORTPG256AModelLowAlarmChanged;
extern NSString* ORTPG256AModelHighLimitChanged;
extern NSString* ORTPG256AModelHighAlarmChanged;
extern NSString* ORTPG256AModelPressureScaleChanged;
extern NSString* ORTPG256AModelShipPressuresChanged;
extern NSString* ORTPG256AModelPollTimeChanged;
extern NSString* ORTPG256ALock;
extern NSString* ORTPG256APressureChanged;
