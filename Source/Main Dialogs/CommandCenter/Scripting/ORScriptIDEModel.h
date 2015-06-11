//-------------------------------------------------------------------------
//  ORScriptIDEModel.m
//
//  Created by Mark A. Howe on Tuesday 12/26/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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
#import "OrcaObject.h"
#import "ORBaseDecoder.h"

@class ORScriptRunner;
@class ORDataPacket;
@class ORDataSet;

@interface ORScriptIDEModel : OrcaObject
{
	unsigned long		    dataId;
	unsigned long			recordDataId;
	NSString*				script;
	ORScriptRunner*			scriptRunner;
	NSString*				scriptName;
	BOOL					parsedOK;
	BOOL					scriptExists;
	NSString*				lastFile;
	id						inputValue;
	NSMutableArray*			inputValues;
    NSString*				comments;
	BOOL					debugging;
	NSDictionary*			breakpoints;
	BOOL					breakChain;
    BOOL					autoStartWithDocument;
    BOOL					autoStartWithRun;
    BOOL					autoStopWithRun;
    BOOL					showSuperClass;
    BOOL					showCommonOnly;
    BOOL                    autoRunAtQuit;
    BOOL					runPeriodically;
    int						periodicRunInterval;
    NSDate*					nextPeriodicRun;
	NSMutableDictionary*    persistantStore;
}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) decorateIcon:(NSImage*)anImage;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) runAboutToStart:(NSNotification*)aNote;
- (void) runStarted:(NSNotification*)aNote;
- (void) runEnded:(NSNotification*)aNote;
- (void) aboutToQuit:(NSNotification*)aNote;
- (void) finalQuitNotice:(NSNotification*)aNote;

#pragma mark ***Accessors
- (id)   storedObjectWithKey:(id)aKey;
- (void) setStoredObject:(id)anObj forKey:(id)aKey;
- (void) clearStoredObjects;
- (BOOL) suppressStartStopMessage;
- (void) setSuppressStartStopMessage:(BOOL)aState;
- (NSString*) runStatusString;
- (NSDate*) nextPeriodicRun;
- (void) setNextPeriodicRun:(NSDate*)aNextPeriodicRun;
- (int)  periodicRunInterval;
- (void) setPeriodicRunInterval:(int)aPeriodicRunInterval;
- (BOOL) runPeriodically;
- (void) setRunPeriodically:(BOOL)aRunPeriodically;
- (BOOL) autoRunAtQuit;
- (void) setAutoRunAtQuit:(BOOL)aAutoRunAtQuit;
- (BOOL) showCommonOnly;
- (void) setShowCommonOnly:(BOOL)aShowCommonOnly;
- (BOOL) autoStopWithRun;
- (void) setAutoStopWithRun:(BOOL)aAutoStopWithRun;
- (BOOL) autoStartWithRun;
- (void) setAutoStartWithRun:(BOOL)aAutoStartWithRun;
- (BOOL) autoStartWithDocument;
- (void) setAutoStartWithDocument:(BOOL)aAutoStartWithDocument;

- (BOOL)	breakChain;
- (void)	setBreakChain:(BOOL)aState;
- (id)		inputValue;
- (void)	setInputValue:(id)aValue;
- (NSDictionary*)		breakpoints;
- (NSMutableIndexSet*)	breakpointSet;
- (void)		setBreakpoints:(NSDictionary*) someBreakpoints;
- (NSString*)	comments;
- (void)		setComments:(NSString*)aComments;
- (void)		setCommentsNoNote:(NSString*)aString;
- (BOOL)		showSuperClass;
- (void)		setShowSuperClass:(BOOL)aShowSuperClass;
- (NSString*)	lastFile;
- (void)		setLastFile:(NSString*)aFile;
- (NSString*)	script;
- (void)		setScript:(NSString*)aString;
- (void)		setScriptNoNote:(NSString*)aString;
- (NSString*)	scriptName;
- (void)		setScriptName:(NSString*)aString;
- (BOOL)		parsedOK;
- (BOOL)		scriptExists;
- (ORScriptRunner*)	scriptRunner;
- (NSMutableArray*) inputValues;
- (void)		addInputValue;
- (void)		removeInputValue:(int)i;
- (NSString*)	identifier;

#pragma mark ***Script Methods
- (id) nextScriptConnector;
- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue;
- (void) parseScript;
- (BOOL) runScript;
- (BOOL) runScriptWithMessage:(NSString*) startMessage;
- (BOOL) running;
- (void) stopScript;
- (void) saveFile;
- (void) loadScriptFromFile:(NSString*)aFilePath;
- (void) saveScriptToFile:(NSString*)aFilePath;
- (id) evaluator;


//functions for testing script objC calls
- (float) testNoArgFunc;
- (float) testOneArgFunc:(float)aValue;
- (float) testTwoArgFunc:(float)aValue argTwo:(float)aValue2;
- (NSString*) testFuncStringReturn;
- (NSPoint) testFuncPointReturn:(NSPoint)aPoint;
- (NSRect) testFuncRectReturn:(NSRect)aRect;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (void) postCouchDBRecord:(NSDictionary*)aRecord;

#pragma mark ***Data ID
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) aDataId;
- (unsigned long) recordDataId;
- (void) setRecordDataId: (unsigned long) aDataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
- (NSDictionary*) dataRecordDescription;
- (void) shipTaskRecord:(id)aTask running:(BOOL)aState;
- (void) shipDataRecord:(id)someData tag:(unsigned long)anID;
- (int) scriptType;
- (unsigned long) currentTime;

@end

extern NSString* ORScriptIDEModelNextPeriodicRunChanged;
extern NSString* ORScriptIDEModelPeriodicRunIntervalChanged;
extern NSString* ORScriptIDEModelRunPeriodicallyChanged;
extern NSString* ORScriptIDEModelAutoRunAtQuitChanged;
extern NSString* ORScriptIDEModelShowCommonOnlyChanged;
extern NSString* ORScriptIDEModelAutoStopWithRunChanged;
extern NSString* ORScriptIDEModelAutoStartWithRunChanged;
extern NSString* ORScriptIDEModelAutoStartWithDocumentChanged;
extern NSString* ORScriptIDEModelCommentsChanged;
extern NSString* ORScriptIDEModelLock;
extern NSString* ORScriptIDEModelShowSuperClassChanged;
extern NSString* ORScriptIDEModelScriptChanged;
extern NSString* ORScriptIDEModelNameChanged;
extern NSString* ORScriptIDEModelLastFileChangedChanged;
extern NSString* ORScriptIDEModelBreakpointsChanged;
extern NSString* ORScriptIDEModelBreakChainChanged;
extern NSString* ORScriptIDEModelGlobalsChanged;

@interface ORScriptDecoderForState : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

@interface ORScriptDecoderForRecord : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

