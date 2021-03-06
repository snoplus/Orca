//--------------------------------------------------------
// ORLakeShore210Model
// Created by Mark  A. Howe on Fri Jul 22 2005
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORAdcProcessing.h"
#import "ORSerialPortWithQueueModel.h"

@class ORTimeRate;

#define kLakeShore210Kelvin		0
#define kLakeShore210Centigrade 1
#define kLakeShore210Raw		2


@interface ORLakeShore210Model : ORSerialPortWithQueueModel <ORAdcProcessing>
{
    @private
        uint32_t	dataId;
		float		    temp[8];
		uint32_t	timeMeasured[8];
		int				pollTime;
		int				unitsType;
        NSMutableString*       buffer;
		BOOL			shipTemperatures;
		ORTimeRate*		timeRates[8];
        double			lowLimit[8];
        double			lowAlarm[8];
        double			highLimit[8];
        double			highAlarm[8];
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

- (void) registerNotificationObservers;
- (void) dataReceived:(NSNotification*)note;

#pragma mark ***Accessors
- (int) unitsType;
- (void) setUnitsType:(int)aType;
- (ORTimeRate*)timeRate:(int)index;
- (BOOL) shipTemperatures;
- (void) setShipTemperatures:(BOOL)aShipTemperatures;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (float) temp:(int)index;
- (uint32_t) timeMeasured:(int)index;
- (void) setTemp:(int)index value:(float)aValue;
- (double) lowLimit:(int)aChan;
- (void) setLowLimit:(int)aChan value:(double)aValue;
- (double) highLimit:(int)aChan;
- (void) setHighLimit:(int)aChan value:(double)aValue;
- (double) highAlarm:(int)aChan;
- (void) setHighAlarm:(int)aChan value:(double)aValue;
- (double) lowAlarm:(int)aChan;
- (void) setLowAlarm:(int)aChan value:(double)aValue;


#pragma mark ***Data Records
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSDictionary*) dataRecordDescription;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherLakeShore210;

- (void) shipTemps;

#pragma mark ***Commands
- (void) addCmdToQueue:(NSString*)aCmd;
- (void) readTemps;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Adc Processing Protocol
- (double) lowLimit:(int)aChan;
- (void) setLowLimit:(int)aChan value:(double)aValue;
- (double) highLimit:(int)aChan;
- (void) setHighLimit:(int)aChan value:(double)aValue;
- (double) highAlarm:(int)aChan;
- (void) setHighAlarm:(int)aChan value:(double)aValue;
- (double) lowAlarm:(int)aChan;
- (void) setLowAlarm:(int)aChan value:(double)aValue;

@end

extern NSString* ORLakeShore210ModelLowLimitChanged;
extern NSString* ORLakeShore210ModelLowAlarmChanged;
extern NSString* ORLakeShore210ModelHighLimitChanged;
extern NSString* ORLakeShore210ModelHighAlarmChanged;
extern NSString* ORLakeShore210ModelShipTemperaturesChanged;
extern NSString* ORLakeShore210ModelUnitsTypeChanged;
extern NSString* ORLakeShore210ModelPollTimeChanged;
extern NSString* ORLakeShore210ModelSerialPortChanged;
extern NSString* ORLakeShore210Lock;
extern NSString* ORLakeShore210ModelPortNameChanged;
extern NSString* ORLakeShore210ModelPortStateChanged;
extern NSString* ORLakeShore210TempArrayChanged;
extern NSString* ORLakeShore210TempChanged;
