//
//  ORRunModel.h
//  Orca
//
//  Created by Mark Howe on Tue Dec 24 2002.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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



#import "ORBaseDecoder.h"
#import "ORDataChainObject.h"
#import "ORBitProcessing.h"

#pragma mark ���Forward Declarations
@class ORDataPacket;
@class ORDataSet;
@class ORRunScript;
@class ORDataTypeAssigner;
@class ORRunScriptModel;

@interface ORRunModel :  ORDataChainObjectWithGroup <ORBitProcessing>{
    @private
        unsigned long 	runNumber;

        NSDate* startTime;
		NSDate* subRunStartTime;
		NSDate* subRunEndTime;
        NSTimer* 		timer;
        NSTimer* 		heartBeatTimer;

		NSTimeInterval  elapsedRunTime;
		NSTimeInterval  elapsedSubRunTime;
		NSTimeInterval	elapsedBetweenSubRunTime;
        NSTimeInterval  timeToGo;
        NSTimeInterval  timeLimit;
        BOOL            timedRun;
        BOOL            repeatRun;
        BOOL            quickStart;
        ORDataPacket*	dataPacket;
		NSMutableDictionary* runInfo;
        BOOL            ignoreRepeat;
        unsigned long	runType;
        unsigned long	savedRunType;
        BOOL            remoteControl;
        unsigned long   dataId;
       
        NSString*		definitionsFilePath;
        NSString* 		dirName;
        id              client;
        unsigned long	exceptionCount;

        BOOL			forceFullInit;
		BOOL			_forceRestart;
		BOOL			_ignoreMode;
		BOOL			_wasQuickStart;
		BOOL			_nextRunWillQuickStart;
		BOOL			_ignoreRunTimeout;
		unsigned long	_currentRun;
        int				runningState;
        ORDataTypeAssigner* dataTypeAssigner;
		unsigned long lastRunNumberShipped;
        NSMutableArray* runTypeNames;
        BOOL        remoteInterface;
		BOOL		runPaused;
		
		//thread control variables
		BOOL		timeToStopTakingData;
		BOOL		dataTakingThreadRunning;
		float		totalWaitTime;

		ORAlarm*    runFailedAlarm;
		ORAlarm*    runStoppedByVetoAlarm;
	
		ORRunScriptModel* startScript;
		ORRunScriptModel* shutDownScript;
		BOOL skipShutDownScript;
	
		NSString* startScriptState;
		NSString* shutDownScriptState;
		int subRunNumber;
		BOOL runModeCache;
		NSThread* readoutThread;
    
        NSMutableArray* objectsRequestingStateChangeWait;
        NSMutableArray* objectsRequestingRunStartAbort;
        int selectedRunTypeScript;
        int savedSelectedRunTypeScript;
}


#pragma mark ���Initialization
- (void) makeConnectors;
- (void) registerNotificationObservers;

#pragma mark ���Accessors
- (int) selectedRunTypeScript;
- (void) setSelectedRunTypeScript:(int)aSelectedRunTypeScript;
- (NSDictionary*)runInfo;
- (NSDictionary*) fullRunInfo;

- (NSString*) elapsedRunTimeString;
- (int) subRunNumber;
- (void) setSubRunNumber:(int)aSubRunNumber;
- (NSString*) shutDownScriptState;
- (void) setShutDownScriptState:(NSString*)aShutDownScriptState;
- (NSString*) startScriptState;
- (void) setStartScriptState:(NSString*)aStartScriptState;
- (ORRunScriptModel*) shutDownScript;
- (void) setShutDownScript:(ORRunScriptModel*)aShutDownScript;
- (ORRunScriptModel*) startScript;
- (void) setStartScript:(ORRunScriptModel*)aStartScript;
- (BOOL) isRunning;
- (BOOL) runPaused;
- (void) setRunPaused:(BOOL)aFlag;
- (BOOL) remoteInterface;
- (void) setRemoteInterface:(BOOL)aRemoteInterface;
- (NSArray*) runTypeNames;
- (void) setRunTypeNames:(NSMutableArray*)aRunTypeNames;
- (unsigned long)   getCurrentRunNumber; //file access
- (unsigned long)   runNumber;
- (void)	    setRunNumber:(unsigned long)aRunNumber;
- (NSString*) startTimeAsString;
- (NSDate*) subRunStartTime;
- (void)	setSubRunStartTime:(NSDate*) aDate;
- (NSDate*) subRunEndTime;
- (void)	setSubRunEndTime:(NSDate*) aDate;
- (NSString*) elapsedTimeString:(NSTimeInterval) aTimeInterval;
- (NSDate*) startTime;
- (void)	setStartTime:(NSDate*) aDate;
- (NSTimeInterval)  elapsedRunTime;
- (void)	setElapsedRunTime:(NSTimeInterval) aValue;
- (NSTimeInterval)  elapsedSubRunTime;
- (void)	setElapsedSubRunTime:(NSTimeInterval) aValue;
- (NSTimeInterval)  elapsedBetweenSubRunTime;
- (void)	setElapsedBetweenSubRunTime:(NSTimeInterval) aValue;

- (NSTimeInterval)  timeToGo;
- (void)	setTimeToGo:(NSTimeInterval) aValue;
- (BOOL)	timedRun;
- (void)	setTimedRun:(BOOL) aValue;
- (BOOL)	repeatRun;
- (void)	setRepeatRun:(BOOL) aValue;
- (NSTimeInterval)timeLimit;
- (void)	setTimeLimit:(NSTimeInterval) aValue;
- (ORDataPacket*)dataPacket;
- (void)	setDataPacket:(ORDataPacket*)aDataPacket;
- (void)	setDirName:(NSString*)aFileName;
- (NSString*)   dirName;
- (unsigned long)exceptionCount;
- (void)	incExceptionCount;
- (void)	clearExceptionCount;
- (unsigned long)runType;
- (void)	setRunType:(unsigned long)aMask;
- (BOOL)	remoteControl;
- (void)	setRemoteControl:(BOOL)aState;
- (NSString*)   commandID;
- (BOOL)        nextRunWillQuickStart;
- (void)        setNextRunWillQuickStart:(BOOL)state;
- (int)		runningState;
- (void)	setRunningState:(int)aRunningState;
- (void)	setForceRestart:(BOOL)aState;
- (BOOL)	quickStart;
- (void)	setQuickStart:(BOOL)flag;
- (NSString *)  definitionsFilePath;
- (void)	setDefinitionsFilePath:(NSString *)aDefinitionsFilePath;
- (ORDataTypeAssigner *) dataTypeAssigner;
- (void) setDataTypeAssigner: (ORDataTypeAssigner *) DataTypeAssigner;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setOfflineRun:(BOOL)flag;
- (BOOL) offlineRun;
- (void) setMaintenanceRuns:(BOOL)aState;

#pragma mark ���Run Modifiers
- (void) remoteStartRun:(unsigned long)aRunNumber;
- (void) remoteRestartRun:(unsigned long)aRunNumber;
- (void) remoteHaltRun;
- (void) remoteStopRun:(BOOL)nextRunState;
- (void) forceHalt;
- (void) runAbortFromScript;

- (void) startRun;
- (void) restartRun;
- (void) stopRun;
- (void) haltRun;

- (void) prepareForNewSubRun;
- (void) startNewSubRun;

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (NSDictionary*) dataRecordDescription;
- (void) takeData;
- (void) runStarted:(BOOL)doInit;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

- (void) incrementTime:(NSTimer*)aTimer;
- (void) sendHeartBeat:(NSTimer*)aTimer;

- (void) addRunStartupAbort:(NSNotification*)aNote;
- (void) addRunStateChangeWait:(NSNotification*)aNote;
- (void) releaseRunStateChangeWait:(NSNotification*)aNote;
- (void) needMoreTimeToStopRun:(NSNotification*)aNotification;
- (void) vetosChanged:(NSNotification*)aNotification;
- (void) runModeChanged:(NSNotification*)aNotification;
- (void) vmePowerFailed:(NSNotification*)aNotification;
- (void) gotForceRunStopNotification:(NSNotification*)aNotification;
- (void) gotRequestedRunStopNotification:(NSNotification*)aNotification;
- (void) gotRequestedRunHaltNotification:(NSNotification*)aNotification;
- (void) gotRequestedRunRestartNotification:(NSNotification*)aNotification;
- (void) requestedRunHalt:(id)userInfo;
- (void) requestedRunStop:(id)userInfo;
- (void) requestedRunRestart:(id)userInfo;
- (BOOL) readRunTypeNames;
- (NSString*) shortStatus;
- (NSString*) endOfRunState;
- (void) checkVetos;
- (NSString*) fullRunNumberString;
- (unsigned) waitRequestersCount;
- (id) waitRequesterAtIdex:(unsigned)index;
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ���Remote Run Control Helpers
- (NSArray*) runScriptList;
- (NSString*) selectedStartScriptName;
- (NSString*) selectedShutDownScriptName;
- (void) setStartScriptName:(NSString*)aName;
- (void) setShutDownScriptName:(NSString*)aName;

#pragma mark ���Script Helpers
- (void) forceClearWaits;
- (NSString*) commonScriptMethods;

#pragma mark ���Bit Processing protocol
- (void) processIsStarting;
- (void) processIsStopping; 
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;
@end

@interface ORRunModel (OROrderedObjHolding)
- (int)         maxNumberOfObjects;
- (int)         objWidth;
- (int)         groupSeparation;
- (NSString*)   nameForSlot:(int)aSlot;
- (NSRange)     legalSlotsForObj:(id)anObj;
- (int)         slotAtPoint:(NSPoint)aPoint;
- (NSPoint)     pointForSlot:(int)aSlot;
- (void)        place:(id)anObj intoSlot:(int)aSlot;
- (int)         slotForObj:(id)anObj;
- (int)         numberSlotsNeededFor:(id)anObj;
- (void)        drawSlotLabels;
- (void)        drawSlotBoundaries;
- (BOOL)        reverseDirection;
@end


@interface ORRunDecoderForRun : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

@interface NSObject (SpecialDataTakingFinishUp)
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (BOOL) doneTakingData;
- (BOOL) preRunChecks;
@end

@interface NSObject (ScriptHolding)
- (void) setSlot:(int)aSlot;
@end


extern NSString* ORRunModelSelectedRunTypeScriptChanged;
extern NSString* ORRunModelShutDownScriptStateChanged;
extern NSString* ORRunModelStartScriptStateChanged;
extern NSString* ORRunModelShutDownScriptChanged;
extern NSString* ORRunModelStartScriptChanged;
extern NSString* ORRunTimedRunChangedNotification;
extern NSString* ORRunRepeatRunChangedNotification;
extern NSString* ORRunTimeLimitChangedNotification;
extern NSString* ORRunElapsedTimesChangedNotification;
extern NSString* ORRunStartTimeChangedNotification;
extern NSString* ORRunTimeToGoChangedNotification;
extern NSString* ORRunNumberChangedNotification;
extern NSString* ORRunRemoteControlChangedNotification;
extern NSString* ORRunModelNumberOfWaitsChanged;
extern NSString* ORRunNumberDirChangedNotification;
extern NSString* ORRunModelExceptionCountChangedNotification;
extern NSString* ORRunMaskChangedNotification;
extern NSString* ORRunTypeChangedNotification;
extern NSString* ORRunQuickStartChangedNotification;
extern NSString* ORRunDefinitionsFileChangedNotification;
extern NSString* ORRunOfflineRunNotification;

extern NSString* ORRunNumberLock;
extern NSString* ORRunTypeLock;
extern NSString* ORRunRemoteInterfaceChangedNotification;
extern NSString* ORRunModelRunHalted;