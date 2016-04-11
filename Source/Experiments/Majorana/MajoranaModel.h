//
//  MajoranaModel.h
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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
#import "ORExperimentModel.h"
#import "OROrderedObjHolding.h"

#define kUseDetectorView    0
#define kUseCrateView       1
#define kNumDetectors       2*35*2 //2 cryostats of 35 detectors * 2 (low and hi channels)
#define kNumVetoSegments    32
#define kMaxNumStrings      14
#define kNumSpecialChannels      24

//component tag numbers
#define kVacAComponent			0
#define kVacBComponent			1

@class ORRemoteSocketModel;
@class ORAlarm;
@class ORMJDInterlocks;
@class ORMJDSource;

@interface MajoranaModel :  ORExperimentModel <OROrderedObjHolding>
{
	int             viewType;
    int             pollTime;
    NSDate*         lastConstraintCheck;
    NSMutableArray* stringMap;
    NSMutableArray* specialMap;
    ORAlarm*        rampHVAlarm[2];
    BOOL            ignorePanicOnA;
    BOOL            ignorePanicOnB;
    
    ORMJDInterlocks*    mjdInterlocks[2];
    ORMJDSource*        mjdSource[2];
}

#pragma mark ���Accessors
- (NSDate*) lastConstraintCheck;
- (void) setLastConstraintCheck:(NSDate*)aDate;
- (BOOL) ignorePanicOnB;
- (void) setIgnorePanicOnB:(BOOL)aIgnorePanicOnB;
- (BOOL) ignorePanicOnA;
- (void) setIgnorePanicOnA:(BOOL)aIgnorePanicOnA;
- (int)  pollTime;
- (void) setPollTime:(int)aPollTime;
- (void) setViewType:(int)aViewType;
- (int) viewType;
- (ORRemoteSocketModel*) remoteSocket:(int)aVMECrate;
- (BOOL) anyHvOnVMECrate:(int)aVMECrate;
- (void) setVmeCrateHVConstraint:(int)aCrate state:(BOOL)aState;
- (void) rampDownHV:(int)aCrate vac:(int)aVacSystem;
- (id) mjdInterlocks:(int)index;
- (void) hvInfoRequest:(NSNotification*)aNote;
- (void) customInfoRequest:(NSNotification*)aNote;
- (void) setDetectorStringPositions;
- (NSString*) detectorLocation:(int)index;
- (NSString*) objectNameForCrate:(NSString*)aCrateName andCard:(NSString*)aCardName;

#pragma mark ���Segment Group Methods
- (void) makeSegmentGroups;
- (NSString*) getValueForPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts;
- (id)   stringMap:(int)i objectForKey:(id)aKey;
- (void) stringMap:(int)i setObject:(id)anObject forKey:(id)aKey;
- (NSString*) stringMapFileAsString;
- (NSString*) specialMapFileAsString;
- (BOOL) validateDetector:(int)aDetectorIndex;
- (id)   specialMap:(int)i objectForKey:(id)aKey;
- (void) specialMap:(int)i setObject:(id)anObject forKey:(id)aKey;
- (void) initDigitizers;
- (void) initVeto;

#pragma mark ���Specific Dialog Lock Methods
- (NSString*) experimentMapLock;
- (NSString*) vetoMapLock;
- (NSString*) experimentDetectorLock;
- (NSString*) experimentDetailsLock;
- (NSString*) calibrationLock;

#pragma mark ���OROrderedObjHolding Protocol
- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) groupSeparation;
- (NSString*) nameForSlot:(int)aSlot;
- (NSRange) legalSlotsForObj:(id)anObj;
- (int) slotAtPoint:(NSPoint)aPoint;
- (NSPoint) pointForSlot:(int)aSlot;
- (void) place:(id)anObj intoSlot:(int)aSlot;
- (int) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;

#pragma mark ���Source
- (id)   mjdSource:(int)index;
- (void) deploySource:(int)index;
- (void) retractSource:(int)index;
- (void) stopSource:(int)index;
- (void) checkSourceGateValve:(int)index;

#pragma mark ���Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* MajoranaModelIgnorePanicOnBChanged;
extern NSString* MajoranaModelIgnorePanicOnAChanged;
extern NSString* ORMajoranaModelViewTypeChanged;
extern NSString* ORMajoranaModelPollTimeChanged;
extern NSString* ORMJDAuxTablesChanged;
extern NSString* ORMajoranaModelLastConstraintCheckChanged;
