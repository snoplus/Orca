//
//  SNOPModel.m
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
#import "SNOPModel.h"
#import "SNOPController.h"
#import "ORSegmentGroup.h"
#import "ORTaskSequence.h"
#import "ORCouchDB.h"
#import "ORXL3Model.h"
#import "ORDataTaker.h"
#import "ORDataTypeAssigner.h"
#import "ORRunModel.h"
#import "ORMTCModel.h"
#import "ORMTCController.h"
#import "ORMTC_Constants.h"
#import "ORFecDaughterCardModel.h"
#import "ORFec32Model.h"
#import "OROrderedObjManager.h"
#import "ORSNOConstants.h"
#import "ORCaen1720Model.h"
#import "ELLIEModel.h"
#import "SNOP_Run_Constants.h"
#import "SBC_Link.h"
#import "SNOCmds.h"

NSString* ORSNOPModelViewTypeChanged	= @"ORSNOPModelViewTypeChanged";
static NSString* SNOPDbConnector	= @"SNOPDbConnector";
NSString* ORSNOPModelOrcaDBIPAddressChanged = @"ORSNOPModelOrcaDBIPAddressChanged";
NSString* ORSNOPModelDebugDBIPAddressChanged = @"ORSNOPModelDebugDBIPAddressChanged";
NSString* SNOPRunTypeChangedNotification = @"SNOPRunTypeChangedNotification";
NSString* SNOPRunsLockNotification = @"SNOPRunsLockNotification";

#define kOrcaRunDocumentAdded   @"kOrcaRunDocumentAdded"
#define kOrcaRunDocumentUpdated @"kOrcaRunDocumentUpdated"
#define kOrcaConfigDocumentAdded @"kOrcaConfigDocumentAdded"
#define kOrcaConfigDocumentUpdated @"kOrcaConfigDocumentUpdated"
#define kMtcRunDocumentAdded @"kMtcRunDocumentAdded"
#define kNumChanConfigBits 5 //used for the CAEN values 

#define kMorcaCompactDB         @"kMorcaCompactDB"

@interface SNOPModel (private)
- (void) morcaUpdateDBDict;
- (void) morcaUpdatePushDocs:(unsigned int) crate;
- (NSString*) stringDateFromDate:(NSDate*)aDate;
- (void) _runDocumentWorker;
- (void) _runEndDocumentWorker:(NSDictionary*)runDoc;
@end

@implementation SNOPModel

@synthesize
orcaDBUserName = _orcaDBUserName,
smellieRunNameLabel = _smellieRunNameLabel,
orcaDBPassword = _orcaDBPassword,
orcaDBName = _orcaDBName,
orcaDBPort = _orcaDBPort,
orcaDBConnectionHistory = _orcaDBConnectionHistory,
orcaDBIPNumberIndex = _orcaDBIPNumberIndex,
orcaDBPingTask = _orcaDBPingTask,
debugDBUserName = _debugDBUserName,
debugDBPassword = _debugDBPassword,
debugDBName = _debugDBName,
debugDBPort = _debugDBPort,
debugDBConnectionHistory = _debugDBConnectionHistory,
debugDBIPNumberIndex = _debugDBIPNumberIndex,
debugDBPingTask = _debugDBPingTask,
epedDataId = _epedDataId,
rhdrDataId = _rhdrDataId,
runDocument = _runDocument,
smellieDBReadInProgress = _smellieDBReadInProgress,
smellieDocUploaded = _smellieDocUploaded,
configDocument  = _configDocument,
snopRunTypeMask = snopRunTypeMask,
runTypeMask= runTypeMask,
isEStopPolling = isEStopPolling,
isEmergencyStopEnabled = isEmergencyStopEnabled,
mtcConfigDoc = _mtcConfigDoc;

@synthesize smellieRunHeaderDocList;

//Standard Runs
//ECA
@synthesize
ECA_pattern_number = _ECA_pattern_number,
ECA_type = _ECA_type,
ECA_tslope_pattern = _ECA_tslope_pattern,
ECA_subrun_time = _ECA_subrun_time;

#pragma mark ���Initialization

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SNOP"]];
}

- (NSMutableDictionary*) getSnopRunTypeMask
{
    return snopRunTypeMask;
}

- (void) setSnopRunTypeMask:(NSMutableDictionary*)aSnopRunTypeMask
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SNOPRunTypeChangedNotification object:self];
    snopRunTypeMask = aSnopRunTypeMask;
}

//check to see if the current SNO+ runType mask has the correct settings
-(BOOL)isRunTypeMaskedIn:(NSString*)aRunType
{
    bool runTypeMaskedIn;
    runTypeMaskedIn = [[self.snopRunTypeMask objectForKey:aRunType] boolValue];
    return runTypeMaskedIn;
}

- (void) makeMainController
{
    [self linkToController:@"SNOPController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:SNOPDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB O' ];
	[ aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB outputs
    [aConnector release];
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (void) sleep
{
    [super sleep];
    //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(morcaUpdateDB) object:nil];
}


- (void) initSmellieRunDocsDic
{
    [self setSmellieDBReadInProgress:NO];
    
    if(!self.smellieRunHeaderDocList) {
        self.smellieRunHeaderDocList = nil;//[[NSMutableDictionary alloc] init];
    }
}

-(void) initRunMaskHistory
{
    
}

- (void) initOrcaDBConnectionHistory
{
	self.orcaDBIPNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.orcaDBIPNumberIndex",[self className]]];
	if(!self.orcaDBConnectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey:
                        [NSString stringWithFormat:@"orca.%@.orcaDBConnectionHistory",[self className]]];

        self.orcaDBConnectionHistory = [[his mutableCopy] autorelease];
	}
	if(!self.orcaDBConnectionHistory) {
        self.orcaDBConnectionHistory = [NSMutableArray array];
    }
}

- (void) initDebugDBConnectionHistory
{
	self.debugDBIPNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.debugDBIPNumberIndex",[self className]]];
	if(!self.debugDBConnectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey:
                        [NSString stringWithFormat:@"orca.%@.debugDBConnectionHistory",[self className]]];
        
		self.debugDBConnectionHistory = [[his mutableCopy] autorelease];
	}
	if(!self.debugDBConnectionHistory) {
        self.debugDBConnectionHistory = [NSMutableArray array];
    }
}

//- (NSString*) helpURL
//{
//	return @"SNO/Index.html";
//}

#pragma mark ���Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStateChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];    

    [notifyCenter addObserver : self
                     selector : @selector(subRunStarted:)
                         name : ORRunStartSubRunNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(subRunEnded:)
                         name : ORRunBetweenSubRunsNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runStarted:)
                         name : ORRunStartedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runStopped:)
                         name : ORRunStoppedNotification
                       object : nil];
}

- (void) runStateChanged:(NSNotification*)aNote
{
    int running = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
    if(running == eRunStopped){
    }
    else if(running == eRunStarting) {
    }
}

- (void) subRunStarted:(NSNotification*)aNote
{
    //EPED record
    //TRIG record?
    //update orcadb run document
}

- (void) subRunEnded:(NSNotification*)aNote
{
    //update calibration documents (TELLIE temp)
}

- (void) runStarted:(NSNotification*)aNote
{
    //initilise the run document
    self.runDocument = nil;
    //intialise the configuation document
    self.configDocument = nil;
    //initilise the run document
    self.mtcConfigDoc = nil;
    
    [NSThread detachNewThreadSelector:@selector(_runDocumentWorker) toTarget:self withObject:nil];

    [self updateRHDRSruct];
    [self shipRHDRRecord];
}

- (void) runStopped:(NSNotification*)aNote
{
    [NSThread detachNewThreadSelector:@selector(_runEndDocumentWorker:)
                             toTarget:self
                           withObject:[[self.runDocument copy] autorelease]];
    self.runDocument = nil;
    self.configDocument = nil;
}

// orca script helper (will come from DB)
- (void) updateEPEDStructWithCoarseDelay: (unsigned long) coarseDelay
                               fineDelay: (unsigned long) fineDelay
                          chargePulseAmp: (unsigned long) chargePulseAmp
                           pedestalWidth: (unsigned long) pedestalWidth
                                 calType: (unsigned long) calType
{
    _epedStruct.coarseDelay = coarseDelay; // nsec
    _epedStruct.fineDelay = fineDelay; // clicks
    _epedStruct.chargePulseAmp = chargePulseAmp; // clicks
    _epedStruct.pedestalWidth = pedestalWidth; // nsec
    _epedStruct.calType = calType; // nsec
}

- (void) updateEPEDStructWithStepNumber: (unsigned long) stepNumber
{
    _epedStruct.stepNumber = stepNumber;
    
}

- (void) updateEPEDStructWithNSlopePoint: (unsigned long) nTSlopePoints
{
    _epedStruct.nTSlopePoints = nTSlopePoints;
}


// orca script helper
- (void) shipEPEDRecord
{
    if ([[ORGlobal sharedGlobal] runInProgress]) {
        const unsigned char eped_rec_length = 10;
        unsigned long data[eped_rec_length];
        data[0] = [self epedDataId] | eped_rec_length;
        data[1] = 0;

        data[2] = _epedStruct.pedestalWidth;
        data[3] = _epedStruct.coarseDelay;
        data[4] = _epedStruct.fineDelay;
        data[5] = _epedStruct.chargePulseAmp;
        data[6] = _epedStruct.stepNumber;
        data[7] = _epedStruct.calType;
        data[8] = 0;//_epedStruct.nTSlopePoints;
        data[9] = 0;
        
        NSData* pdata = [[NSData alloc] initWithBytes:data length:sizeof(long)*(eped_rec_length)];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification object:pdata];
        [pdata release];
        pdata = nil;
    }
}


- (void) updateRHDRSruct
{
    //form run info
    NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
	if([runObjects count]){
		ORRunModel* rc = [runObjects objectAtIndex:0];
        _rhdrStruct.runNumber = [rc runNumber];
        NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
        NSDateComponents *cmpStartTime = [gregorian components:
                                                 (NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay |
                                                  NSCalendarUnitHour | NSCalendarUnitMinute |NSCalendarUnitSecond)
                                                      fromDate:[NSDate date]];
        _rhdrStruct.date = [cmpStartTime day] + [cmpStartTime month] * 100 + [cmpStartTime year] * 10000;
        _rhdrStruct.time = [cmpStartTime second] * 100 + [cmpStartTime minute] * 10000 + [cmpStartTime hour] * 1000000;
	}

    //svn revision
    if (_rhdrStruct.daqCodeVersion == 0) {
        NSFileManager* fm = [NSFileManager defaultManager];
		NSString* svnVersionPath = [[NSBundle mainBundle] pathForResource:@"svnversion"ofType:nil];
		NSMutableString* svnVersion = [NSMutableString stringWithString:@""];
		if([fm fileExistsAtPath:svnVersionPath])svnVersion = [NSMutableString stringWithContentsOfFile:svnVersionPath encoding:NSASCIIStringEncoding error:nil];
		if([svnVersion hasSuffix:@"\n"]){
			[svnVersion replaceCharactersInRange:NSMakeRange([svnVersion length]-1, 1) withString:@""];
		}
        NSLog(svnVersion);
        NSLog(svnVersionPath);
        _rhdrStruct.daqCodeVersion = [svnVersion integerValue]; //8045:8046M -> 8045 which is desired
    }
    
    _rhdrStruct.calibrationTrialNumber = 0;
    _rhdrStruct.sourceMask = 0; // from run type document
    _rhdrStruct.runMask = 0; // from run type document
    _rhdrStruct.gtCrateMask = 0; // from run type document
}

- (void) shipRHDRRecord
{
    const unsigned char rhdr_rec_length = 20;
    unsigned long data[rhdr_rec_length];
    data[0] = [self rhdrDataId] | rhdr_rec_length;
    data[1] = 0;
    
    data[2] = _rhdrStruct.date;
    data[3] = _rhdrStruct.time;
    data[4] = _rhdrStruct.daqCodeVersion;
    data[5] = _rhdrStruct.runNumber;
    data[6] = _rhdrStruct.calibrationTrialNumber;
    data[7] = _rhdrStruct.sourceMask;
    data[8] = _rhdrStruct.runMask & 0xffffffffULL;
    data[9] = _rhdrStruct.gtCrateMask;
    data[10] = 0;
    data[11] = 0;
    data[12] = _rhdrStruct.runMask >> 32;
    data[13] = 0;
    data[14] = 0;
    data[15] = 0;
    data[16] = 0;
    data[17] = 0;
    data[18] = 0;
    data[19] = 0;
    
    NSData* pdata = [[NSData alloc] initWithBytes:data length:sizeof(long)*(rhdr_rec_length)];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification object:pdata];
    [pdata release];
    pdata = nil;
}

#pragma mark ���Accessors

- (void) clearOrcaDBConnectionHistory
{
	self.orcaDBConnectionHistory = nil;
    [self setOrcaDBIPAddress:[self orcaDBIPAddress]];
}

- (void) clearDebugDBConnectionHistory
{
	self.debugDBConnectionHistory = nil;
	[self setDebugDBIPAddress:[self debugDBIPAddress]];
}

- (id) orcaDBConnectionHistoryItem:(unsigned int)index
{
	if(self.orcaDBConnectionHistory && index < [self.orcaDBConnectionHistory count]) {
        return [self.orcaDBConnectionHistory objectAtIndex:index];
    }
	else return nil;
}

- (id) debugDBConnectionHistoryItem:(unsigned int)index
{
	if(self.debugDBConnectionHistory && index < [self.debugDBConnectionHistory count]) {
        return [self.debugDBConnectionHistory objectAtIndex:index];
    }
	else return nil;
}

- (NSString*) orcaDBIPAddress
{
    if (!_orcaDBIPAddress) {
        return @"";
    }
    id result;
    result = [_orcaDBIPAddress retain];
    return [result autorelease];
}

- (void) setOrcaDBIPAddress:(NSString*)orcaIPAddress
{
	if([orcaIPAddress length] && orcaIPAddress != self.orcaDBIPAddress) {
		[[[self undoManager] prepareWithInvocationTarget:self] setOrcaDBIPAddress:self.orcaDBIPAddress];
		
		if (self.orcaDBIPAddress) [_orcaDBIPAddress autorelease];
		if (orcaIPAddress) _orcaDBIPAddress = [orcaIPAddress copy];
		
		if(!self.orcaDBConnectionHistory) self.orcaDBConnectionHistory = [NSMutableArray arrayWithCapacity:4];
		if(![self.orcaDBConnectionHistory containsObject:self.orcaDBIPAddress]){
			[self.orcaDBConnectionHistory addObject:self.orcaDBIPAddress];
		}
		self.orcaDBIPNumberIndex = [self.orcaDBConnectionHistory indexOfObject:self.orcaDBIPAddress];
		
		[[NSUserDefaults standardUserDefaults] setObject:self.orcaDBConnectionHistory forKey:[NSString stringWithFormat:@"orca.%@.orcaDBConnectionHistory",[self className]]];
		[[NSUserDefaults standardUserDefaults] setInteger:self.orcaDBIPNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.orcaDBIPNumberIndex",[self className]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelOrcaDBIPAddressChanged object:self];
	}
}

- (NSString*) debugDBIPAddress
{
    if (!_debugDBIPAddress) {
        return @"";
    }
    id result;
    result = [_debugDBIPAddress retain];
    return [result autorelease];
}

- (void) setDebugDBIPAddress:(NSString*)debugIPAddress
{
	if([debugIPAddress length] && debugIPAddress != self.debugDBIPAddress) {
		[[[self undoManager] prepareWithInvocationTarget:self] setDebugDBIPAddress:self.debugDBIPAddress];

        if (self.debugDBIPAddress) [_debugDBIPAddress autorelease];
		if (debugIPAddress) _debugDBIPAddress = [debugIPAddress copy];

		if(!self.debugDBConnectionHistory) self.debugDBConnectionHistory = [NSMutableArray arrayWithCapacity:4];
		if(![self.debugDBConnectionHistory containsObject:self.debugDBIPAddress]){
			[self.debugDBConnectionHistory addObject:self.debugDBIPAddress];
		}
		self.debugDBIPNumberIndex = [self.debugDBConnectionHistory indexOfObject:self.debugDBIPAddress];
		
		[[NSUserDefaults standardUserDefaults] setObject:self.debugDBConnectionHistory forKey:[NSString stringWithFormat:@"orca.%@.debugDBConnectionHistory",[self className]]];
		[[NSUserDefaults standardUserDefaults] setInteger:self.debugDBIPNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.debugDBIPNumberIndex",[self className]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelDebugDBIPAddressChanged object:self];
	}
}

- (void) orcaDBPing
{
    if(!self.orcaDBPingTask){
		ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		self.orcaDBPingTask = [[[NSTask alloc] init] autorelease];
		
		[self.orcaDBPingTask setLaunchPath:@"/sbin/ping"];
		[self.orcaDBPingTask setArguments: [NSArray arrayWithObjects:@"-c",@"2",@"-t",@"5",@"-q",self.orcaDBIPAddress,nil]];
		
		[aSequence addTaskObj:self.orcaDBPingTask];
		[aSequence setVerbose:YES];
		[aSequence setTextToDelegate:YES];
		[aSequence launch];
	}
	else {
		[self.orcaDBPingTask terminate];
	}
}

- (void) debugDBPing
{
    if(!self.debugDBPingTask){
		ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		self.debugDBPingTask = [[[NSTask alloc] init] autorelease];
		
		[self.debugDBPingTask setLaunchPath:@"/sbin/ping"];
		[self.debugDBPingTask setArguments: [NSArray arrayWithObjects:@"-c",@"2",@"-t",@"5",@"-q",self.debugDBIPAddress,nil]];
		
		[aSequence addTaskObj:self.debugDBPingTask];
		[aSequence setVerbose:YES];
		[aSequence setTextToDelegate:YES];
		[aSequence launch];
	}
	else {
		[self.debugDBPingTask terminate];
	}
}

- (void) taskFinished:(NSTask*)aTask
{
	if(aTask == self.orcaDBPingTask){
		self.orcaDBPingTask = nil;
	}
	else if(aTask == self.debugDBPingTask){
		self.debugDBPingTask = nil;
	}
}

- (void) orcaUpdateDB {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(orcaUpdateDB) object:nil];
    //[self orcaUpdateDBDict];
    //[self performSelector:@selector(morcaUpdatePushDocs) withObject:nil afterDelay:0.2];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
	@synchronized(self) {
        if ([aResult isKindOfClass:[NSDictionary class]]) {
            NSString* message = [aResult objectForKey:@"Message"];
            if (message) {
                /*
                if([aTag isEqualToString:kMorcaCrateDocGot]){
                    NSLog(@"CouchDB Message getting a crate doc:");
                }
                 */
                [aResult prettyPrint:@"CouchDB Message:"];
                return;
            }

            if ([aTag isEqualToString:kOrcaRunDocumentAdded]) {
                NSMutableDictionary* runDoc = [[[self runDocument] mutableCopy] autorelease];
                [runDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                //[runDoc setObject:[aResult objectForKey:@"rev"] forKey:@"_rev"];
                //[runDoc setObject:[aResult objectForKey:@"ok"] forKey:@"ok"];
                self.runDocument = runDoc;
                //[aResult prettyPrint:@"CouchDB Ack Doc:"];
            }
            
            //This is called when smellie run header is queried from CouchDB
            else if ([aTag isEqualToString:@"kSmellieRunHeaderRetrieved"])
            {
                //NSLog(@"here\n");
                //NSLog(@"Object: %@\n",aResult);
                //NSLog(@"result1: %@\n",[aResult objectForKey:@"rows"]);
                //NSLog(@"result2: %@\n",[[aResult objectForKey:@"rows"] objectAtIndexedSubscript:0]);
                [self parseSmellieRunHeaderDoc:aResult];
            }
            else if ([aTag isEqualToString:kOrcaRunDocumentUpdated]) {
                //there was error
                //[aResult prettyPrint:@"couchdb update doc:"];
            }
            else if([aTag isEqualToString:kMtcRunDocumentAdded]){
                NSMutableDictionary* mtcConfigDoc = [[[self mtcConfigDoc] mutableCopy] autorelease];
                [mtcConfigDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                self.mtcConfigDoc = mtcConfigDoc;
            }
            //Look for the configuration document tag
            else if ([aTag isEqualToString:kOrcaConfigDocumentAdded]) {
                NSMutableDictionary* configDoc = [[[self configDocument] mutableCopy] autorelease];
                [configDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                //[runDoc setObject:[aResult objectForKey:@"rev"] forKey:@"_rev"];
                //[runDoc setObject:[aResult objectForKey:@"ok"] forKey:@"ok"];
                self.configDocument = configDoc;
                //[aResult prettyPrint:@"CouchDB Ack Doc:"];
            }
            //look for the configuation docuemnt updated tag
            else if ([aTag isEqualToString:kOrcaConfigDocumentUpdated]) {
                //there was error
                //[aResult prettyPrint:@"couchdb update doc:"];
            }
            /*
            else if([aTag rangeOfString:kMorcaCrateDocGot].location != NSNotFound){
                //int key = [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"key"];
                if ([[aResult objectForKey:@"rows"] count] && [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"key"]){
                    [morcaDBDict setObject:[[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"doc"]
                        forKey:[[[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"key"] stringValue]];
                }
                else {
                    [morcaDBDict removeObjectForKey:[[aTag componentsSeparatedByString:@"."] objectAtIndex:1]];
                }
                if ([self morcaIsVerbose]) {
                    [aResult prettyPrint:@"CouchDB pull doc from DB"];
                }
                [self morcaUpdatePushDocs:[[[aTag componentsSeparatedByString:@"."] objectAtIndex:1] intValue]];
            }
             */
            else if ([aTag isEqualToString:@"Message"]) {
                [aResult prettyPrint:@"CouchDB Message:"];
            }
            else {
                [aResult prettyPrint:@"CouchDB"];
            }
        }
        else if ([aResult isKindOfClass:[NSArray class]]) {
            /*
            if([aTag isEqualToString:kListDB]){
                [aResult prettyPrint:@"CouchDB List:"];
            else [aResult prettyPrint:@"CouchDB"];
             */
            [aResult prettyPrint:@"CouchDB"];
        }
        else {
            NSLog(@"%@\n",aResult);
        }

	} // synchronized
}


#pragma mark ���Segment Group Methods
- (void) makeSegmentGroups
{
    ORSegmentGroup* group = [[ORSegmentGroup alloc] initWithName:@"SNO+ Detector" numSegments:kNumTubes mapEntries:[self setupMapEntries:0]];
	[self addGroup:group];
	[group release];
}

- (int)  maxNumSegments
{
	return kNumTubes;
}

- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		NSString* cardName = [aGroup segment:index objectForKey:@"kCardSlot"];
		NSString* chanName = [aGroup segment:index objectForKey:@"kChannel"];
		if(cardName && chanName && ![cardName hasPrefix:@"-"] && ![chanName hasPrefix:@"-"]){
			ORDataSet* aDataSet = nil;
			[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
			NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
			if([objs count]){
				NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				if([arrayOfHistos count]){
					id histoObj = [arrayOfHistos objectAtIndex:0];
					aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:@"SIS3302", @"Crate  0",
															[NSString stringWithFormat:@"Card %2d",[cardName intValue]], 
															[NSString stringWithFormat:@"Channel %2d",[chanName intValue]],
															nil]];
					
					[aDataSet doDoubleClick:nil];
				}
			}
		}
	}
}
- (NSString*) dataSetNameGroup:(int)aGroup segment:(int)index
{
	ORSegmentGroup* theGroup = [segmentGroups objectAtIndex:aGroup];
	
	NSString* crateName = [theGroup segment:index objectForKey:@"kCrate"];
	NSString* cardName  = [theGroup segment:index objectForKey:@"kCardSlot"];
	NSString* chanName  = [theGroup segment:index objectForKey:@"kChannel"];
	
	return [NSString stringWithFormat:@"SIS3302,Energy,Crate %2d,Card %2d,Channel %2d",[crateName intValue],[cardName intValue],[chanName intValue]];
}
#pragma mark ���Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"SNOPMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"SNOPDetectorLock";
}

- (id) sbcLink
{
    NSArray* theSBCs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORVmecpuModel")];
    //NSLog(@"Found %d SBCs.\n", theSBCs.count);
    for(id anSBC in theSBCs)
    {
        return [anSBC sbcLink];
    }
    return nil;
}

-(void) testerHv
{
    __block bool hvStatus =TRUE;
    
    dispatch_queue_t eStopQueue = dispatch_queue_create("eStopQueue", NULL);
    
    dispatch_async(eStopQueue, ^{
        while (hvStatus) {
            sleep(3.0); //3s
        
            if(!isEStopPolling) break;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                hvStatus = (BOOL)[self eStopPoll];
            });
        
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(isEStopPolling){
            
                if(isEmergencyStopEnabled ){
                
                    NSLog(@"PANIC DOWN\n");
                    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(hvPanicDown)];
                    [self setIsEStopPolling:NO];
                }
                else{
                    NSLog(@"Panic Down enabled but automatic shutdown is not enabled\n");
                }
            }
            else{
                NSLog(@"Emergency Stop has stopped polling");
            }
        });
    });
}

-(void) eStopPolling
{
    NSLog(@"Started Polling Emergency Stop...");
    [self testerHv];
}

-(BOOL) eStopPoll
{
   SBC_Link *sbcLink = [self sbcLink];
   long hvStatus = 1;
    if( sbcLink != nil )
    {
        //NSLog(@"Made SBC Link.\n");
        //long hvStatus = 0;
        SBC_Packet aPacket;
        aPacket.cmdHeader.destination = kSNO;
        aPacket.cmdHeader.cmdID = kSNOReadHVStop;
        aPacket.cmdHeader.numberBytesinPayload = 1 * sizeof( long );
        unsigned long* payloadPtr = (unsigned long*) aPacket.payload;
        payloadPtr[0] = 0;
        @try
        {
            [sbcLink send: &aPacket receive: &aPacket];
            unsigned long* responsePtr = (unsigned long*) aPacket.payload;
            hvStatus = responsePtr[0];
            //NSLog(@"hv_status %ld",hvStatus);
            /*if( errorCode )
            {
                @throw [NSException exceptionWithName:@"Reset All Camera error" reason:@"SBC and/or LabJack failed.\n" userInfo:nil];
            }*/
        }
        @catch( NSException* e )
        {
            NSLog( @"SBC failed pol hv\n" );
            NSLog( @"Error: %@ with reason: %@\n", [e name], [e reason] );
            //@throw e;
        }
    
    } //end of if statement
    //return (BOOL)hvStatus ;
    //NSLog(@"status");
    return (BOOL)hvStatus;
        
}

- (NSString*) experimentDetailsLock
{
	return @"SNOPDetailsLock";
}

- (void) setViewType:(int)aViewType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setViewType:aViewType];
	viewType = aViewType;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelViewTypeChanged object:self userInfo:nil];
}

- (int) viewType
{
	return viewType;
}

//undefined run type
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	[self initOrcaDBConnectionHistory];
	[self initDebugDBConnectionHistory];
    [self initSmellieRunDocsDic];


    
    [self setViewType:[decoder decodeIntForKey:@"viewType"]];

    self.orcaDBUserName = [decoder decodeObjectForKey:@"ORSNOPModelOrcaDBUserName"];
    self.orcaDBPassword = [decoder decodeObjectForKey:@"ORSNOPModelOrcaDBPassword"];
    self.orcaDBName = [decoder decodeObjectForKey:@"ORSNOPModelOrcaDBName"];
    self.orcaDBPort = [decoder decodeInt32ForKey:@"ORSNOPModelOrcaDBPort"];
    self.orcaDBIPAddress = [decoder decodeObjectForKey:@"ORSNOPModelOrcaDBIPAddress"];
    self.debugDBUserName = [decoder decodeObjectForKey:@"ORSNOPModelDebugDBUserName"];
    self.debugDBPassword = [decoder decodeObjectForKey:@"ORSNOPModelDebugDBPassword"];
    self.debugDBName = [decoder decodeObjectForKey:@"ORSNOPModelDebugDBName"];
    self.debugDBPort = [decoder decodeInt32ForKey:@"ORSNOPModelDebugDBPort"];
    self.debugDBIPAddress = [decoder decodeObjectForKey:@"ORSNOPModelDebugDBIPAddress"];
    
    self.runTypeMask = [decoder decodeObjectForKey:@"SNOPRunTypeMask"];
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:viewType forKey:@"viewType"];

    [encoder encodeObject:self.orcaDBUserName forKey:@"ORSNOPModelOrcaDBUserName"];
    [encoder encodeObject:self.orcaDBPassword forKey:@"ORSNOPModelOrcaDBPassword"];
    [encoder encodeObject:self.orcaDBName forKey:@"ORSNOPModelOrcaDBName"];
    [encoder encodeInt32:self.orcaDBPort forKey:@"ORSNOPModelOrcaDBPort"];
    [encoder encodeObject:self.orcaDBIPAddress forKey:@"ORSNOPModelOrcaDBIPAddress"];
    [encoder encodeObject:self.debugDBUserName forKey:@"ORSNOPModelDebugDBUserName"];
    [encoder encodeObject:self.debugDBPassword forKey:@"ORSNOPModelDebugDBPassword"];
    [encoder encodeObject:self.debugDBName forKey:@"ORSNOPModelDebugDBName"];
    [encoder encodeInt32:self.debugDBPort forKey:@"ORSNOPModelDebugDBPort"];
    [encoder encodeObject:self.debugDBIPAddress forKey:@"ORSNOPModelDebugDBIPAddress"];
    [encoder encodeObject:self.runTypeMask forKey:@"SNOPRunTypeMask"];
}

- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	if([aString length] == 0)return @"Not Mapped";
	
	NSString* finalString = @"";
	NSArray* parts = [aString componentsSeparatedByString:@"\n"];
	finalString = [finalString stringByAppendingString:@"\n-----------------------\n"];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Detector" parts:parts]];
	finalString = [finalString stringByAppendingString:@"-----------------------\n"];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" CardSlot" parts:parts]];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Channel" parts:parts]];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Threshold" parts:parts]];
	finalString = [finalString stringByAppendingString:@"-----------------------\n"];
	return finalString;
}

- (NSString*) getPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound) return aLine;
	}
	return @"";
}

#pragma mark ���DataTaker
- (void) setDataIds:(id)assigner
{
    [self setRhdrDataId:[assigner assignDataIds:kLongForm]];
    [self setEpedDataId:[assigner assignDataIds:kLongForm]];
}

- (void) syncDataIdsWith:(id)anotherObj
{
	[self setRhdrDataId:[anotherObj rhdrDataId]];
	[self setEpedDataId:[anotherObj epedDataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"SNOPModel"];
}

- (NSDictionary*) dataRecordDescription
{
	NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"SNOPDecoderForRHDR", @"decoder",
                                 [NSNumber numberWithLong:[self rhdrDataId]], @"dataId",
                                 [NSNumber numberWithBool:NO],	@"variable",
                                 [NSNumber numberWithLong:20], @"length",
                                 nil];
	[dataDictionary setObject:aDictionary forKey:@"snopRhdrBundle"];
    
	NSDictionary* bDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"SNOPDecoderForEPED", @"decoder",
                                 [NSNumber numberWithLong:[self epedDataId]], @"dataId",
                                 [NSNumber numberWithBool:NO], @"variable",
                                 [NSNumber numberWithLong:11], @"length",
                                 nil];
	[dataDictionary setObject:bDictionary forKey:@"snopEpedBundle"];
    
	return dataDictionary;
}


#pragma mark ���SnotDbDelegate

- (ORCouchDB*) orcaDbRef:(id)aCouchDelegate
{
    ORCouchDB* result = [ORCouchDB couchHost:self.orcaDBIPAddress
                                        port:self.orcaDBPort
                                    username:self.orcaDBUserName
                                         pwd:self.orcaDBPassword
                                    database:self.orcaDBName
                                    delegate:self];

    if (aCouchDelegate)
        [result setDelegate:aCouchDelegate];
    
    return [[result retain] autorelease];
}

- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;
 {
 
     ORCouchDB* result = [ORCouchDB couchHost:self.orcaDBIPAddress
                                         port:self.orcaDBPort
                                     username:self.orcaDBUserName
                                          pwd:self.orcaDBPassword
                                     database:entryDB
                                     delegate:self];
 
     if (aCouchDelegate)
         [result setDelegate:aCouchDelegate];
 
     return [[result retain] autorelease];
 }

- (ORCouchDB*) debugDbRef:(id)aCouchDelegate
{
    return nil;
}


#pragma mark ���OrcaScript helpers


- (void) zeroPedestalMasks
{
    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")]
     makeObjectsPerformSelector:@selector(zeroPedestalMasks)];
}

- (void) updatePedestalMasks:(unsigned int)pattern
{
    
    unsigned int** pt_step = (unsigned int**) pattern;
    NSLog(@"aaa 0x%08x\n", pt_step);
    
    //unsigned int* pt_step_crate = pt_step[0];
    
}


- (void)hvMasterTriggersOFF
{
    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(setIsPollingXl3:) withObject:NO];
    
    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(hvTriggersOFF)];
}

- (void) getSmellieRunListInfo
{
    //Collect a series of objects from the ORMTCModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if([objs count]){
        //Initialise the MTCModal
        ELLIEModel* anELLIEModel = [objs objectAtIndex:0];
        
        //NSMutableDictionary *state = [[NSMutableDictionary alloc] initWithDictionary:[anELLIEModel pullEllieCustomRunFromDB:@"smellie"]];
        
        NSString *requestString = [NSString stringWithFormat:@"_design/smellieMainQuery/_view/pullEllieRunHeaders"];
        
        [[anELLIEModel generalDBRef:@"smellie"] getDocumentId:requestString tag:@"kSmellieRunHeaderRetrieved"];
        
        [self setSmellieDBReadInProgress:YES];
        [self performSelector:@selector(smellieDocumentsRecieved) withObject:nil afterDelay:10.0];
    }
    else {
        NSLogColor([NSColor redColor], @"Must have an ELLIE object in the configuration\n");
    }
    
}

//complete this after the smellie documents have been recieved 
-(void)smellieDocumentsRecieved
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(smellieDocumentsRecieved) object:nil];
    if (![self smellieDBReadInProgress]) { //killed already
        return;
    }
    
    [self setSmellieDBReadInProgress:NO];
    
}

-(void) parseSmellieRunHeaderDoc:(id)aResult
{
    unsigned int i,cnt = [[aResult objectForKey:@"rows"] count];
    
    NSMutableDictionary *tmp = [[NSMutableDictionary alloc] init];
    
    for(i=0;i<cnt;i++){
        NSMutableDictionary* smellieRunHeaderDocIterator = [[[aResult objectForKey:@"rows"] objectAtIndex:i] objectForKey:@"value"];
        NSString *keyForSmellieDocs = [NSString stringWithFormat:@"%u",i];
        [tmp setObject:smellieRunHeaderDocIterator forKey:keyForSmellieDocs];
    }

    [self setSmellieRunHeaderDocList:tmp];
    [tmp release];
    
    [self setSmellieDocUploaded:YES];
}

/*-(void)setSmellieRunNameLabel:(NSString*)aRunNameLabel
{
    [self setSmellieRunNameLabel:aRunNameLabel];
}*/


- (NSMutableDictionary*)smellieTestFct
{
    if([self smellieDocUploaded] == YES){
        return smellieRunHeaderDocList;
    }
    else{
        NSLog(@"Document no loaded yet\n");
        return nil;
    }
}

- (void) loadVariablesInScript:(NSString*)userscriptname
{
    
    //Collect ALL the RunScripts & ORCAScripts in an array
    NSArray* runscripts = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunScriptModel")];
    NSArray* orcascripts = [[self document] collectObjectsOfClass:NSClassFromString(@"ORScriptTaskModel")];
    
    //Look for the requested runscript by looping through the script names
    for (int i=0; i<[runscripts count]; i++) {
        //NSLog(@"%d: %@ \n", i, [runscripts[i] scriptName]);
        if([[runscripts[i] scriptName] isEqualToString:userscriptname])
        {
            //This is the one we are looking for so get the script and exit
            SR_script = [runscripts objectAtIndex:i];
            break;
        }
    }
    
    //Look for the requested orcascript by looping through the script names
    for (int i=0; i<[orcascripts count]; i++) {
        //NSLog(@"%d: %@ \n", i, [orcascripts[i] scriptName]);
        if([[orcascripts[i] scriptName] isEqualToString:userscriptname])
        {
            //This is the one we are looking for so get the script and exit
            SR_script = [orcascripts objectAtIndex:i];
            break;
        }
    }
    
    if(!SR_script){  //It didn't found the script
        NSLog(@"ORCA script %@ not found. \n", userscriptname);
    }
    else if([[SR_script scriptName] isEqualToString:@"ECA_singleRun"]){
        //Set global variables
        NSLog(@"Set values in %@ ORCA script. \n",userscriptname);
        [self addGlobalVariable:@0 withName:@"pattern_number" withValue:[self ECA_pattern_number]];
        [self addGlobalVariable:@1 withName:@"eca_type" withValue:[self ECA_type]];
        [self addGlobalVariable:@2 withName:@"tslope_pattern" withValue:[self ECA_tslope_pattern]];
        [self addGlobalVariable:@3 withName:@"sub_run_time" withValue:[self ECA_subrun_time]];
    }
    
    //Clean script pointer
    SR_script = nil;
    
}

- (void) addGlobalVariable:(NSNumber*)varindex withName:(NSString*)varname withValue:(NSNumber*)varvalue
{
    
    NSLog(@"Adding new global variable: %@ = %@ \n",varname, varvalue);
    //Add new global variable in case it doesn't already exist
    if([varindex integerValue] + 1 > [[SR_script inputValues] count]){
        [SR_script addInputValue];
    }
    
    //Copy the value
    [[SR_script inputValues] replaceObjectAtIndex:[varindex intValue] withObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:varname,@"name",[NSDecimalNumber numberWithUnsignedLong:[varvalue intValue]],@"iValue",nil]];
    
}

// Load last MTC values (saved with 'saveStandardRun') from the DB for the selected Standard Run
-(void) loadStandardRun:(NSString*)runTypeName
{

    
    NSArray* paramNames = [NSArray arrayWithObjects:

                               @"LockOutWidth",
                               @"PedestalWidth",
                               @"Nhit100LoPrescale",
                               @"PulserPeriod",
                               @"Low10MhzClock",
                               @"High10MhzClock",
                               @"FineSlope",
                               @"MinDelayOffset",
                               @"CoarseDelay",
                               @"FineDelay",
                           
                               @"GTMask",
                               @"GTCrateMask",
                               @"PEDCrateMask",
                               @"ControlMask",
                           
                               @"NHit100HiThreshold",
                               @"NHit100MedThreshold",
                               @"NHit100LoThreshold",
                               @"NHit20Threshold",
                               @"NHit20LBThreshold",
                               @"OWLNThreshold",
                               
                               @"NHit100HimVperAdc",
                               @"NHit100MedmVperVAdc",
                               @"NHit100LomVperAdc",
                               @"NHit20mVperAdc",
                               @"NHit20LBmVperAdc",
                               @"OWLNmVperAdc",
                               
                               @"NHit100HimVperNHit",
                               @"NHit100MedmVperNHit",
                               @"NHit100LomVperNHit",
                               @"NHit20mVperNHit",
                               @"NHit20LBmVperNHit",
                               @"OWLNmVperNHit",
                               
                               @"NHit100HidcOffset",
                               @"NHit100MeddcOffset",
                               @"NHit100LodcOffset",
                               @"NHit20dcOffset",
                               @"NHit20LBdcOffset",
                               @"OWLNdcOffset",
                               
                               @"ESumLowThreshold",
                               @"ESumHiThreshold",
                               @"OWLELoThreshold",
                               @"OWLEHiThreshold",
                               
                               @"ESumLowmVperAdc",
                               @"ESumHimVperAdc",
                               @"OWLELomVperAdc",
                               @"OWLEHimVperAdc",
                               
                               @"ESumLowmVperpC",
                               @"ESumHimVperpC",
                               @"OWLELomVperpC",
                               @"OWLEHimVperpC",
                               
                               @"ESumLowdcOffset",
                               @"ESumHidcOffset",
                               @"OWLELodcOffset",
                               @"OWLEHidcOffset",
                               
                               nil];
    
    
    //Get MTC model
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtcModel = [objs objectAtIndex:0];

    //Query the OrcaDB and get a dictionary with the parameters
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%u/orca/_design/standardRuns/_view/getRuns?startkey=[\"%@\",{}]&endkey=[\"%@\",0]&descending=True&include_docs=True",[self orcaDBIPAddress],[self orcaDBPort],runTypeName,runTypeName];

    NSString* urlStringScaped = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlStringScaped];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error =  nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];

    if(error) NSLog(@"Error querying couchDB, please check the connection is correct %@",error);

    //Load values
    @try{

        //Set pedestal mode if ECA
        if([runTypeName isEqualToString:@"ECA"]){
            [mtcModel setIsPedestalEnabledInCSR:1];
        }
        else{
            [mtcModel setIsPedestalEnabledInCSR:0];
        }
        
        //Load MTC/D parameters, trigger masks and MTC/A+ thresholds
        for (int iparam=0; iparam<50; iparam++) {
            [mtcModel setDbObject:[[[[json valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[paramNames objectAtIndex:iparam]] forIndex:iparam];
        }
        
    }
    @catch (NSException *e) {
        NSLog(@"Error ",e);
    }
    
}

//Save MTC settings in a Standard Run table in CouchDB for later use by the Run Scripts or the user
-(void) saveStandardRun:(NSString*)runTypeName
{

    NSArray* paramNames = [NSArray arrayWithObjects:
                           
                           @"LockOutWidth",
                           @"PedestalWidth",
                           @"Nhit100LoPrescale",
                           @"PulserPeriod",
                           @"Low10MhzClock",
                           @"High10MhzClock",
                           @"FineSlope",
                           @"MinDelayOffset",
                           @"CoarseDelay",
                           @"FineDelay",
                           
                           @"GTMask",
                           @"GTCrateMask",
                           @"PEDCrateMask",
                           @"ControlMask",
                           
                           @"NHit100HiThreshold",
                           @"NHit100MedThreshold",
                           @"NHit100LoThreshold",
                           @"NHit20Threshold",
                           @"NHit20LBThreshold",
                           @"OWLNThreshold",
                           
                           @"NHit100HimVperAdc",
                           @"NHit100MedmVperVAdc",
                           @"NHit100LomVperAdc",
                           @"NHit20mVperAdc",
                           @"NHit20LBmVperAdc",
                           @"OWLNmVperAdc",
                           
                           @"NHit100HimVperNHit",
                           @"NHit100MedmVperNHit",
                           @"NHit100LomVperNHit",
                           @"NHit20mVperNHit",
                           @"NHit20LBmVperNHit",
                           @"OWLNmVperNHit",
                           
                           @"NHit100HidcOffset",
                           @"NHit100MeddcOffset",
                           @"NHit100LodcOffset",
                           @"NHit20dcOffset",
                           @"NHit20LBdcOffset",
                           @"OWLNdcOffset",
                           
                           @"ESumLowThreshold",
                           @"ESumHiThreshold",
                           @"OWLELoThreshold",
                           @"OWLEHiThreshold",
                           
                           @"ESumLowmVperAdc",
                           @"ESumHimVperAdc",
                           @"OWLELomVperAdc",
                           @"OWLEHimVperAdc",
                           
                           @"ESumLowmVperpC",
                           @"ESumHimVperpC",
                           @"OWLELomVperpC",
                           @"OWLEHimVperpC",
                           
                           @"ESumLowdcOffset",
                           @"ESumHidcOffset",
                           @"OWLELodcOffset",
                           @"OWLEHidcOffset",
                           
                           nil];
    
    
    //Get MTC model
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtcModel = [objs objectAtIndex:0];

    //Build run table
    NSMutableDictionary *thresholdsFromMTC = [NSMutableDictionary dictionaryWithCapacity:100];
    
    [thresholdsFromMTC setObject:@"standard_run" forKey:@"type"];
    [thresholdsFromMTC setObject:runTypeName forKey:@"run_type"];
    NSNumber *date = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    [thresholdsFromMTC setObject:date forKey:@"time_stamp"];

    //Save MTC/D parameters, trigger masks and MTC/A+ thresholds
    for (int iparam=0; iparam<50; iparam++) {
//        NSLog(@" Writting %@ to %@ \n", [mtcModel dbObjectByIndex:ithres+kNHit100HiThreshold], [thresholdNames objectAtIndex:ithres]);
        [thresholdsFromMTC setObject:[mtcModel dbObjectByIndex:iparam] forKey:[paramNames objectAtIndex:iparam]];
    }
    
    //    NSLog(@" Writting to ORCADB \n");

    [[self orcaDbRefWithEntryDB:self withDB:@"orca"] addDocument:thresholdsFromMTC tag:@"kStandardRunDocumentAdded"];
}


@end


@implementation SNOPModel (private)

- (NSString*) stringDateFromDate:(NSDate*)aDate
{
    NSDateFormatter* snotDateFormatter = [[NSDateFormatter alloc] init];
    [snotDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SS'Z'"];
    snotDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate* strDate;
    if (!aDate)
        strDate = [NSDate date];
    else
        strDate = aDate;
    NSString* result = [snotDateFormatter stringFromDate:strDate];
    [snotDateFormatter release];
    strDate = nil;
    return [[result retain] autorelease];
}

//iso formatted string from date
- (NSString*) stringUnixFromDate:(NSDate*)aDate
{
    //NSDateFormatter* snotDateFormatter = [[NSDateFormatter alloc] init];
    //[snotDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SS'Z'"];
    //snotDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate* strDate;
    if (!aDate)
        strDate = [NSDate date];
    else
        strDate = aDate;
    //strDate.date.timeIntervalSince1970
    NSString* result = [NSString stringWithFormat:@"%f",[strDate timeIntervalSince1970]];
    //[snotDateFormatter release];
    strDate = nil;
    return [[result retain] autorelease];
}


//rfc2822 formatted string from date
- (NSString*) rfc2822StringDateFromDate:(NSDate*)aDate
{
    NSDateFormatter* snotDateFormatter = [[NSDateFormatter alloc] init];
    [snotDateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
    snotDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate* strDate;
    if (!aDate) strDate = [NSDate date];
    else        strDate = aDate;
    NSString* result = [snotDateFormatter stringFromDate:strDate];
    [snotDateFormatter release];
    return [[result retain] autorelease];
}

- (void) _runDocumentWorker
{
    NSAutoreleasePool* runDocPool   = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:100];
    
    unsigned int run_number = 0;
    NSMutableString* runStartString = [NSMutableString string];
    NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* rc = nil;
	if([runObjects count]){
        rc = [runObjects objectAtIndex:0];
        run_number = [rc runNumber];
    }
    
    //Collect a series of objects from the ORMTCModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    
    //Initialise the MTCModal
    ORMTCModel* aMTCcard = [objs objectAtIndex:0];
    
    NSNumber* runNumber = [NSNumber numberWithUnsignedInt:run_number];

    [runDocDict setObject:@"run" forKey:@"type"];
    //[runDocDict setObject:[self getRunType] forKey:@"run_type"];
    [runDocDict setObject:[NSNumber numberWithUnsignedLong:[aMTCcard mtcStatusGTID]] forKey:@"start_gtid"];
    [runDocDict setObject:[NSNumber numberWithUnsignedLong:[[self runTypeMask] unsignedLongValue]] forKey:@"run_type"];
    [runDocDict setObject:[NSNumber numberWithUnsignedInt:0] forKey:@"version"];
    [runDocDict setObject:[NSNumber numberWithDouble:[[self stringUnixFromDate:nil] doubleValue]] forKey:@"timestamp_start"];
    [runDocDict setObject:[self rfc2822StringDateFromDate:nil] forKey:@"sudbury_time_start"];
    [runDocDict setObject:runNumber forKey:@"run"];
    [runDocDict setObject:@"starting" forKey:@"run_status"];
    
    //[runDocDict setObject:runStartString forKey:@"run_start"];
    [runDocDict setObject:@"" forKey:@"timestamp_end"];
    [runDocDict setObject:@"" forKey:@"sudbury_time_end"];
    //[runDocDict setObject:@"" forKey:@"run_stop"];

    self.runDocument = runDocDict;
    
    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRef:self] addDocument:runDocDict tag:kOrcaRunDocumentAdded];
    }
    
    //wait for main thread to receive acknowledgement from couchdb
    NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow:2.0];
    while ([timeout timeIntervalSinceNow] > 0 && ![self.runDocument objectForKey:@"_id"]) {
        [NSThread sleepForTimeInterval:0.1];
    }
    
    //if failed emit alarm and give up
    runDocDict = [[[self runDocument] mutableCopy] autorelease];
    if (rc) {
        NSDate* runStart = [[[rc startTime] copy] autorelease];
        [runStartString setString:[self stringDateFromDate:runStart]];
    }
    [runDocDict setObject:@"in progress" forKey:@"run_status"];
        

    //self.runDocument = runDocDict;
    
    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRef:self] updateDocument:runDocDict documentId:[runDocDict objectForKey:@"_id"] tag:kOrcaRunDocumentUpdated];
    }
    
    NSMutableDictionary* configDocDict = [NSMutableDictionary dictionaryWithCapacity:1000];
    
    //Pulling all the MTC Values
    NSNumber * mtcFineDelay         = [NSNumber numberWithUnsignedLong:[aMTCcard getMTC_FineDelay]];
    NSNumber * mtcPedWidth          = [NSNumber numberWithUnsignedLong:[aMTCcard getMTC_PedWidth]];
    NSNumber * mtcGTWordMask        = [NSNumber numberWithUnsignedLong:[aMTCcard getMTC_GTWordMask]];
    
    NSNumber * mtcCoarseDelay       = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kCoarseDelay]];
    NSNumber * mtcPedestalWidth     = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kPedestalWidth]];
    NSNumber * mtcNhit100LoPrescale = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kNhit100LoPrescale]];
    NSNumber * mtcPulserPeriod      = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kPulserPeriod]];
    NSNumber * mtcLow10MhzClock     = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kLow10MhzClock]];
    NSNumber * mtcFineSlope         = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kFineSlope]];
    NSNumber * mtcMinDelayOffset    = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kMinDelayOffset]];
    
    //Important not to help complete this work
    //dbFloatByIndex - this function will get the value on the screen (at least for the mtc and
    //read this from what is placed into the GUI (I think)
    //An example:
	//[pedestalWidthField		setFloatValue:	[model dbFloatByIndex: kPedestalWidth]];

    //The above example actually set the values in the GUI. But for loading into the database
    //it is more important to think about the [modeal dbFloatByIndex: kPedestalWidth] information
    //this is actualy looking up the model information and using it.
    
    //Extra values to load into the DB
    //load the nhit values
    //NSMatrix * nhitMatrix = nil;
    NSMutableDictionary *nhitMtcaArray = [NSMutableDictionary dictionaryWithCapacity:100];

	int col,row;
	float displayValue=0;
	for(col=0;col<4;col++){
        
        NSMutableDictionary * tempArray = [NSMutableDictionary dictionaryWithCapacity:100];
        
		for(row=0;row<6;row++){
            
			int index = kNHit100HiThreshold + row + (col * 6);
            
			if(col == 0){
	 			int type = [aMTCcard nHitViewType];
				
                if(type == kNHitsViewRaw) {
					displayValue = [aMTCcard dbFloatByIndex: index];
				}
				
                else if(type == kNHitsViewmVolts) {
					float rawValue = [aMTCcard dbFloatByIndex: index];
					displayValue = [aMTCcard rawTomVolts:rawValue];
				}
				
                else if(type == kNHitsViewNHits) {
					int rawValue    = [aMTCcard dbFloatByIndex: index];
					float mVolts    = [aMTCcard rawTomVolts:rawValue];
					float dcOffset  = [aMTCcard dbFloatByIndex:index + kNHitDcOffset_Offset];
					float mVperNHit = [aMTCcard dbFloatByIndex:index + kmVoltPerNHit_Offset];
					displayValue    = [aMTCcard mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
				}
			}
			else displayValue = [aMTCcard dbFloatByIndex: index];
            
            NSNumber * valueToDisplay = [NSNumber numberWithFloat:displayValue];
            switch (row){
                case 0: [tempArray setObject:valueToDisplay forKey:@"nhit_100_hi"];  break;
                case 1: [tempArray setObject:valueToDisplay forKey:@"nhit_100_med"]; break;
                case 2: [tempArray setObject:valueToDisplay forKey:@"nhit_100_lo"];  break;
                case 3: [tempArray setObject:valueToDisplay forKey:@"nhit_20"];      break;
                case 4: [tempArray setObject:valueToDisplay forKey:@"nhit_20_lo"];   break;
                case 5: [tempArray setObject:valueToDisplay forKey:@"owln"];         break;
                default: NSLog(@"OrcaDB::Cannot write the Mtca Nhit DAC Values to the OrcaDB"); break;
            }
    
		}
        
        //Do I need to release the memory for the temporary Array?
        //This will reveal itself during my analysis for the new Array
        switch(col){
            case 0: [nhitMtcaArray setObject:tempArray forKey:@"threshold_value"];  break;
            case 1: [nhitMtcaArray setObject:tempArray forKey:@"mv_per_adc"];       break;
            case 2: [nhitMtcaArray setObject:tempArray forKey:@"mv_per_nhit"];      break;
            case 3: [nhitMtcaArray setObject:tempArray forKey:@"dc_offset"];        break;
            default:  NSLog(@"OrcaDB::Cannot write the Mtca Nhit DAC values to the OrcaDB"); break;
        }
	}
    
     //now the esum values
    NSMutableDictionary *esumArray = [NSMutableDictionary dictionaryWithCapacity:100];
    
    for(col=0;col<4;col++){
         
        NSMutableDictionary * tempArray = [NSMutableDictionary dictionaryWithCapacity:100];
         
         for(row=0;row<4;row++){
            int index = kESumLowThreshold + row + (col * 4);
             if(col == 0){
                 int type = [aMTCcard eSumViewType];
                 if(type == kESumViewRaw) {
                     displayValue = [aMTCcard dbFloatByIndex: index];
                 }
                 else if(type == kESumViewmVolts) {
                     float rawValue = [aMTCcard dbFloatByIndex: index];
                     displayValue = [aMTCcard rawTomVolts:rawValue];
                 }
                 else if(type == kESumVieweSumRel) {
                     float dcOffset = [aMTCcard dbFloatByIndex:index + kESumDcOffset_Offset];
                     displayValue = dcOffset - [aMTCcard dbFloatByIndex: index];
                 }
                 else if(type == kESumViewpC) {
                     int rawValue   = [aMTCcard dbFloatByIndex: index];
                     float mVolts   = [aMTCcard rawTomVolts:rawValue];
                     float dcOffset = [aMTCcard dbFloatByIndex:index + kESumDcOffset_Offset];
                     float mVperpC  = [aMTCcard dbFloatByIndex:index + kmVoltPerpC_Offset];
                     displayValue   = [aMTCcard mVoltsTopC:mVolts dcOffset:dcOffset mVperpC:mVperpC];
                 }
             }
             
             else displayValue = [aMTCcard dbFloatByIndex: index];
             
             NSNumber * valueToDisplay = [NSNumber numberWithFloat:displayValue];
             switch (row){
                 case 0: [tempArray setObject:valueToDisplay forKey:@"esum_hi"]; break;
                 case 1: [tempArray setObject:valueToDisplay forKey:@"esum_lo"]; break;
                 case 2: [tempArray setObject:valueToDisplay forKey:@"owle_hi"]; break;
                 case 3: [tempArray setObject:valueToDisplay forKey:@"owle_lo"]; break;
                 default: NSLog(@"OrcaDB::Cannot write the Mtca Esum DAC values to the OrcaDB"); break;
             }
             
         }
        switch(col){
            case 0: [esumArray setObject:tempArray forKey:@"threshold_value"];  break;
            case 1: [esumArray setObject:tempArray forKey:@"mv_per_adc"];       break;
            case 2: [esumArray setObject:tempArray forKey:@"mv_per_nhit"];      break;
            case 3: [esumArray setObject:tempArray forKey:@"dc_offset"];        break;
            default: break;
        }
    }
        
    //Get the trigger information and place into the DB
    //NSMutableDictionary * triggerMask = [NSMutableDictionary dictionaryWithCapacity:100];
    
    //Respective arrays that will be used to fill the main array 
    NSMutableArray * gtMask = [NSMutableArray arrayWithCapacity:100];
    //NSMutableDictionary *gtMask = [NSMutableDictionary dictionaryWithCapacity:100];
    NSMutableArray * gtCrateMask = [NSMutableArray arrayWithCapacity:100];
    NSMutableArray * pedCrateMask = [NSMutableArray arrayWithCapacity:100];
    
    //Collect a series of objects from the ORMTCController
    /*NSArray*  controllerObjs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCController")];
    
    //Initialise the MTCModal
    ORMTCController* aMTCController = [controllerObjs objectAtIndex:0];
    
    NSMutableDictionary * triggerMaskMatricies = [aMTCController getMatriciesFromNib];

    //Unpack all the Matricies from the Nib
    NSMatrix * globalTriggerMaskMatrix = [triggerMaskMatricies objectForKey:@"globalTriggerMaskMatrix"];*/
        
    int i;
	int maskValue = [aMTCcard dbIntByIndex: kGtMask];
    //NSString * triggerOn = @"On";
    //NSString * triggerOff = @"Off";
    
    NSNumber *triggerOn = [NSNumber numberWithInt:1];
    NSNumber *triggerOff = [NSNumber numberWithInt:0];
    
    
    //add each mask to the main gtMask mutableArray �
	for(i=0;i<26;i++){
        NSNumber * maskValueToWrite = [NSNumber numberWithInt:maskValue & (1<<i)];
        if ([maskValueToWrite intValue] > 0){
            [gtMask insertObject:triggerOn atIndex:i];
        }
        else{
            [gtMask insertObject:triggerOff atIndex:i];
        }
        
        //Keep this idea for a future date.
        //This idea is to take the GUI binding titles and read those in as the arguments for the trigger. Perhaps
        //these would change and it would be better to force the user to use bits???? Keep the database constant?

        //Alternative method
        
        /*NSButtonCell * cell = [globalTriggerMaskMatrix cellAtRow:i column:0];
        NSString *cellTitle = [cell title];
        
        if ([maskValueToWrite intValue] > 0){
            [gtMask setObject:@"triggerOn" forKey:cellTitle];
        }
        else{
            [gtMask setObject:@"triggerOff" forKey:cellTitle];
        }*/
        
	}
    
	maskValue = [aMTCcard dbIntByIndex: kGtCrateMask];
	for(i=0;i<25;i++){
        NSNumber * maskValueToWrite = [NSNumber numberWithInt:maskValue & (1<<i)];        
        if ([maskValueToWrite intValue] > 0){
            [gtCrateMask insertObject:triggerOn atIndex:i];
        }
        else{
            [gtCrateMask insertObject:triggerOff atIndex:i];
        }
	}
    
	maskValue = [aMTCcard dbIntByIndex: kPEDCrateMask];
	for(i=0;i<25;i++){
        NSNumber * maskValueToWrite = [NSNumber numberWithInt:maskValue & (1<<i)];        
        if ([maskValueToWrite intValue] > 0){
            [pedCrateMask insertObject:triggerOn atIndex:i];
        }
        else{
            [pedCrateMask insertObject:triggerOff atIndex:i];
        }
	}
    
    
    //TODO: REMOVE THIS AND ABOVE CODE FOR READING TRIGGGER MASK
    //Combine the mutable arrays containing all the triggers into the Dictionary;
    /*[triggerMask setObject:gtMask forKey:@"global_trigger_mask"];
    [triggerMask setObject:gtCrateMask forKey:@"crate_trigger_mask"];
    [triggerMask setObject:pedCrateMask forKey:@"pedestal_trigger_mask"];*/
    
    
    //Fill an array with mtc information 
    NSMutableDictionary * mtcArray = [NSMutableDictionary dictionaryWithCapacity:20];
    [mtcArray setObject:mtcCoarseDelay       forKey:@"coarse_delay"];
    [mtcArray setObject:mtcFineDelay         forKey:@"fine_delay"];
    [mtcArray setObject:mtcPedWidth          forKey:@"ped_width"];
    [mtcArray setObject:mtcGTWordMask        forKey:@"gt_word_mask"];
    [mtcArray setObject:mtcPedestalWidth     forKey:@"pedestal_width"];
    [mtcArray setObject:mtcNhit100LoPrescale forKey:@"nhit100_lo_prescale"];
    [mtcArray setObject:mtcPulserPeriod      forKey:@"pulser_period"];
    [mtcArray setObject:mtcLow10MhzClock     forKey:@"low_10Mhz_clock"];
    [mtcArray setObject:mtcFineSlope         forKey:@"fine_slope"];
    [mtcArray setObject:mtcMinDelayOffset    forKey:@"min_delay_offset"];
    [mtcArray setObject:nhitMtcaArray        forKey:@"mtca_nhit_matrix"];
    [mtcArray setObject:[NSNumber numberWithFloat:[aMTCcard dbFloatByIndex:kLockOutWidth]] forKey:@"lockout_width"];
    [mtcArray setObject:esumArray            forKey:@"mtca_esum_matrix"];
    //[mtcArray setObject:triggerMask forKey:@"trigger_masks"];
    
    [mtcArray setObject:[NSNumber numberWithBool:[aMTCcard isPedestalEnabledInCSR]] forKey:@"is_pedestal_enabled"];
    
    //Trigger masks
    [mtcArray setObject:[NSNumber numberWithInt:[aMTCcard dbIntByIndex: kGtMask]]       forKey:@"gt_mask"];
    [mtcArray setObject:[NSNumber numberWithInt:[aMTCcard dbIntByIndex: kGtCrateMask]]  forKey:@"crate_trigger_mask"];
    [mtcArray setObject:[NSNumber numberWithInt:[aMTCcard dbIntByIndex: kPEDCrateMask]] forKey:@"pedestal_trigger_mask"];
    
    
    //make an MTC document
    NSMutableDictionary* mtcDocDict = [NSMutableDictionary dictionaryWithCapacity:100];
    
    [mtcDocDict setObject:@"mtc"    forKey:@"doc_type"];
    [mtcDocDict setObject:[NSNumber numberWithUnsignedInt:0] forKey:@"version"];
    [mtcDocDict setObject:runNumber forKey:@"run"];
    [mtcDocDict setObject:mtcArray  forKey:@"mtc"];
    
    self.mtcConfigDoc = mtcDocDict;
    
    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRef:self] addDocument:mtcDocDict tag:kMtcRunDocumentAdded];
    }
    
    //FILL information from the Caen
    NSMutableDictionary* caenArray = [NSMutableDictionary dictionaryWithCapacity:100];
    NSArray* caenObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORCaen1720Model")];
    if([caenObjects count]){
        ORCaen1720Model* theCaen        = [caenObjects objectAtIndex:0]; //there is only one Caen object
        NSMutableDictionary* ioArray    = [NSMutableDictionary dictionaryWithCapacity:20];
        [ioArray setObject:[NSNumber numberWithUnsignedLong:[theCaen frontPanelControlMask]] forKey:@"io_bit_mask"];
    
        
        //Build the components of the CAEN from the bitMask
        //These are ordered arrays so DO NOT change the ordering!!!!!!!!!
        NSArray* ioModeArray        = @[@"general_purpose",@"program",@"pattern"];
        NSArray* patternLatchArray  = @[@"internal_trigger",@"external_trigger"];
        NSArray* trigInArray        = @[@"nim",@"ttl"];
        NSArray* trigOutArray       = @[@"low_impedendce",@"high_impedence"];
        NSArray* lvdsArray          = @[@"in",@"out"];
        NSArray* trigOutModeArray   = @[@"normal",@"test_hi",@"test_low"];
        
        //deconstruct the bitMask used to describe the caen IO and recast the unsigned long variables as integer
        int ioMode, patternLatch, trigIn, trigOut, vds0, vds1, vds2, vds3, trigOutMode;
        ioMode       = (int)(([theCaen frontPanelControlMask] >> 6) & 0x3UL);
        patternLatch = (int)(([theCaen frontPanelControlMask] >> 9) & 0x1UL);
        trigIn       = (int)([theCaen frontPanelControlMask] & 0x1UL);
        trigOut      = (int)(([theCaen frontPanelControlMask] >> 1) & 0x1UL);
        trigOutMode  = (int)(([theCaen frontPanelControlMask] >> 14) & 0x3UL);
        
        //write the configuration of the lvdsArray
        vds0 = (int)(([theCaen frontPanelControlMask] >> 2) & 0x1UL);
        vds1 = (int)(([theCaen frontPanelControlMask] >> 3) & 0x1UL);
        vds2 = (int)(([theCaen frontPanelControlMask] >> 4) & 0x1UL);
        vds3 = (int)(([theCaen frontPanelControlMask] >> 5) & 0x1UL);
        
        NSMutableArray * lvdsDictionary = [NSMutableArray arrayWithCapacity:20];
        [lvdsDictionary setObject:[lvdsArray objectAtIndex:vds0] atIndexedSubscript:0];
        [lvdsDictionary setObject:[lvdsArray objectAtIndex:vds1] atIndexedSubscript:1];
        [lvdsDictionary setObject:[lvdsArray objectAtIndex:vds2] atIndexedSubscript:2];
        [lvdsDictionary setObject:[lvdsArray objectAtIndex:vds3] atIndexedSubscript:3];
        
        [ioArray setObject:lvdsDictionary                                   forKey:@"lvds_io_direction"];
        [ioArray setObject:[ioModeArray objectAtIndex:ioMode]               forKey:@"io_mode"];
        [ioArray setObject:[patternLatchArray objectAtIndex:patternLatch]   forKey:@"pattern_latch"];
        [ioArray setObject:[trigInArray objectAtIndex:trigIn]               forKey:@"trigger_clock_input_logic"];
        [ioArray setObject:[trigOutArray objectAtIndex:trigOut]             forKey:@"trigger_clock_output_logic"];
        [ioArray setObject:[trigOutModeArray objectAtIndex:trigOutMode]     forKey:@"trigger_output_mode"];
        [caenArray setObject:ioArray                                        forKey:@"io"];
        
        NSMutableDictionary* bufferInfo = [NSMutableDictionary dictionaryWithCapacity:20];
        [bufferInfo setObject:[NSNumber numberWithInt:(1024*1024./powf(2.,(float)[theCaen eventSize]) / 2)] forKey:@"event_size"];
        [bufferInfo setObject:[NSNumber numberWithUnsignedLong:([theCaen postTriggerSetting] * 4)]          forKey:@"post_trigger_size"];
        [bufferInfo setObject:[NSNumber numberWithUnsignedLong:([theCaen customSize] * 4)]                  forKey:@"custom_size"];
        [bufferInfo setObject:[NSNumber numberWithBool:[theCaen isCustomSize]]                              forKey:@"is_custom_size"];
        [bufferInfo setObject:[NSNumber numberWithBool:[theCaen isFixedSize]]                               forKey:@"fixed_event_size"];
        
        [caenArray setObject:bufferInfo forKey:@"buffer"];
        
        //Fetch the channel configuration information
        NSMutableDictionary* chanConfigInfo = [NSMutableDictionary dictionaryWithCapacity:20];
        int chanConfigToMaskBit[kNumChanConfigBits] = {1,3,4,6,11};
        [chanConfigInfo setObject:[NSNumber numberWithBool:(([theCaen channelConfigMask] >> chanConfigToMaskBit[0] ) & 0x1)] forKey:@"trigger_overlap"];
        [chanConfigInfo setObject:[NSNumber numberWithBool:(([theCaen channelConfigMask] >> chanConfigToMaskBit[1] ) & 0x1)] forKey:@"test_pattern"];
        [chanConfigInfo setObject:[NSNumber numberWithBool:(([theCaen channelConfigMask] >> chanConfigToMaskBit[2] ) & 0x1)] forKey:@"seq_memory_access"];
        [chanConfigInfo setObject:[NSNumber numberWithBool:(([theCaen channelConfigMask] >> chanConfigToMaskBit[3] ) & 0x1)] forKey:@"trig_on_under_threshold"];
        [caenArray setObject:chanConfigInfo forKey:@"channel_configuration"];
        
        //get the run mode of the CAEN ADC, there is a runMode mask which is 00, 01, 10, 11 and corresponds to the four options in the CAEN GUI
        NSArray* runModeArray = @[@"register_controlled",@"s_in_controller",@"s_in_gate",@"multi_board_sync"];
        int acquitionMode = (int)[theCaen acquisitionMode];
        [caenArray setObject:[NSString stringWithFormat:@"%@",[runModeArray objectAtIndex:acquitionMode]] forKey:@"run_mode"];
    
        NSMutableDictionary* channelInfo = [NSMutableDictionary dictionaryWithCapacity:20];
        int l;
        for(l=0;l<[theCaen numberOfChannels];l++){
            NSMutableDictionary* specificChannel = [NSMutableDictionary dictionaryWithCapacity:20];
            [specificChannel removeAllObjects];
            [specificChannel setObject:[NSNumber numberWithBool:(([theCaen enabledMask] >> l) & 0x1)]           forKey:@"enabled"];
            [specificChannel setObject:[NSNumber numberWithUnsignedShort:[theCaen threshold:l]]                 forKey:@"threshold"];
            [specificChannel setObject:[NSNumber numberWithFloat:[theCaen convertDacToVolts:[theCaen dac:l]]]   forKey:@"offset"];
            [specificChannel setObject:[NSNumber numberWithBool:(([theCaen triggerSourceMask] >> l) & 0x1UL)]   forKey:@"trigger_source"];
            [specificChannel setObject:[NSNumber numberWithBool:(([theCaen triggerOutMask] >> l) & 0x1UL)]      forKey:@"trigger_output"];
            [specificChannel setObject:[NSNumber numberWithUnsignedShort:[theCaen overUnderThreshold:l]]        forKey:@"over_under_threshold"];
            [channelInfo setObject:specificChannel                                                              forKey:[NSString stringWithFormat:@"%i",l]];
        }
        [caenArray setObject:channelInfo forKey:@"channels"];
        
        NSMutableDictionary *otherTrigInfo = [NSMutableDictionary dictionaryWithCapacity:20];
        [otherTrigInfo setObject:[NSNumber numberWithBool:(([theCaen triggerSourceMask] >> 30) & 0x1UL)]    forKey:@"external_trigger_enabled"];
        [otherTrigInfo setObject:[NSNumber numberWithBool:(([theCaen triggerSourceMask] >> 31) & 0x1UL)]    forKey:@"software_trigger_enabled"];
        [otherTrigInfo setObject:[NSNumber numberWithBool:(([theCaen triggerOutMask] >> 30) & 0x1UL)]       forKey:@"external_trigger_out"];
        [otherTrigInfo setObject:[NSNumber numberWithBool:(([theCaen triggerOutMask] >> 31) & 0x1UL)]       forKey:@"software_trigger_out"];
        [otherTrigInfo setObject:[NSNumber numberWithBool:[theCaen countAllTriggers]]                       forKey:@"count_all_triggers"];
        [otherTrigInfo setObject:[NSNumber numberWithUnsignedShort:[theCaen coincidenceLevel]]              forKey:@"nhit"];
        
        [caenArray setObject:otherTrigInfo forKey:@"extra_trigger"];

        [caenArray setObject:[NSNumber numberWithUnsignedShort:[theCaen enabledMask]]               forKey:@"enable_mask"];
        [caenArray setObject:[NSNumber numberWithUnsignedLong:[theCaen triggerSourceMask]]          forKey:@"trigger_source_mask"];
        [caenArray setObject:[NSNumber numberWithUnsignedLong:[theCaen triggerOutMask]]             forKey:@"trigger_out_mask"];
        [caenArray setObject:[NSNumber numberWithUnsignedShort:[theCaen coincidenceLevel]]          forKey:@"coincidence_level"];
        [caenArray setObject:[NSNumber numberWithUnsignedShort:[theCaen channelConfigMask]]         forKey:@"channel_config_mask"];
        [caenArray setObject:[NSNumber numberWithUnsignedLong:[theCaen numberBLTEventsToReadout]]   forKey:@"number_blt_events"];
        [caenArray setObject:[NSNumber numberWithBool:[theCaen continuousMode]]                     forKey:@"continuous_mode"];
        
        /*int l;
        for(l=0; l < [theCaen numberOfChannels]; l++){
            [caenArray setObject:[NSNumber numberWithUnsignedShort:[theCaen dac:l]] forKey:[NSString stringWithFormat:@"dac_ch_%d",l]];
            [caenArray setObject:[NSNumber numberWithUnsignedShort:[theCaen threshold:l]] forKey:[NSString stringWithFormat:@"thres_ch_%d",l]];
            [caenArray setObject:[NSNumber numberWithUnsignedShort:[theCaen overUnderThreshold:l]] forKey:[NSString stringWithFormat:@"over_thres_ch_%d",l]];
        }*/
    }
    
    //FILL THE DATA FROM EACH FRONT END CARD HERE !!!!!
    
    //Initialise a Dictionary to fill the Daughter Card information
    NSMutableDictionary * fecCardArray = [NSMutableDictionary dictionaryWithCapacity:200];
    
    //Build an empty array for all Fec32 arrays
    int c;
    for(c =0;c<kNumOfCrates;c++){
        NSMutableDictionary* boardsInSlots = [[NSMutableDictionary alloc] initWithCapacity:100];
        
        int slot;
        for(slot=0;slot<kNumSNOCrateSlots-2;slot++){
            [boardsInSlots setObject:@"" forKey:[NSString stringWithFormat:@"%i",slot]];
        }
        [fecCardArray setObject:boardsInSlots forKey:[NSString stringWithFormat:@"%i",c]];
        [boardsInSlots release];
    }
    
    //Gersende and Chris (Xl3 printing status)
    NSArray* xl3Objects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    
    NSMutableDictionary* allXl3Info = [NSMutableDictionary dictionaryWithCapacity:10];
    
    //loop through all xl3 instances in Orca
    for (id xl3 in xl3Objects) {
        
        NSMutableDictionary * crateXl3Info = [NSMutableDictionary dictionaryWithCapacity:10];
        [crateXl3Info setObject:[NSString stringWithFormat:@"%@",   [xl3 hvASwitch]?@"ON":@"OFF"]   forKey:@"hv_status_a"];
        [crateXl3Info setObject:[NSNumber numberWithUnsignedLong:   [xl3 hvNominalVoltageA]]        forKey:@"hv_nominal_a"];
        [crateXl3Info setObject:[NSNumber numberWithFloat:          [xl3 hvAVoltageReadValue]]      forKey:@"hv_voltage_read_value_a"];
        [crateXl3Info setObject:[NSNumber numberWithFloat:          [xl3 hvACurrentReadValue]]      forKey:@"hv_current_read_value_a"];
        [crateXl3Info setObject:[NSNumber numberWithInt:            [xl3 xl3Mode]]                  forKey:@"xl3_mode"];
        [crateXl3Info setObject:[NSNumber numberWithUnsignedLong:   [xl3 relayHighMask]]            forKey:@"hv_relay_high_mask"];
        [crateXl3Info setObject:[NSNumber numberWithUnsignedLong:   [xl3 relayLowMask]]             forKey:@"hv_relay_low_mask"];
        
        if([xl3 crateNumber] == 16) {
            
            [crateXl3Info setObject:[NSString stringWithFormat:@"%@",   [xl3 hvBSwitch]?@"ON":@"OFF"]   forKey:@"hv_status_b"];
            [crateXl3Info setObject:[NSNumber numberWithUnsignedLong:   [xl3 hvNominalVoltageB]]        forKey:@"hv_nominal_b"];
            [crateXl3Info setObject:[NSNumber numberWithFloat:          [xl3 hvBVoltageReadValue]]      forKey:@"hv_voltage_read_value_b"];
            [crateXl3Info setObject:[NSNumber numberWithFloat:          [xl3 hvBCurrentReadValue]]      forKey:@"hv_current_read_value_b"];
            
        }
    
        NSString * crateNumberAsString = [NSString stringWithFormat:@"%i",[xl3 crateNumber]];
        [allXl3Info setObject:crateXl3Info forKey:crateNumberAsString];
    
    }
    
    //Loop over all the FEC cards
    NSArray * fec32ControllerObjs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];
    
    //Count all Fec32 Cards on the DAQ
    //int numberFec32Cards = 2; //PLACE THIS IN LATER: [fec32ControllerObjs count];
    int numberFec32Cards = [fec32ControllerObjs count];
    
    //Iterate through all of the Fec32 Cards
    for(i=0;i<numberFec32Cards;i++){
            
        ORFec32Model * aFec32Card = [fec32ControllerObjs objectAtIndex:i];
        
        //Fec 32 Card Iterator
        NSMutableDictionary* fec32Iterator = [NSMutableDictionary dictionaryWithCapacity:20];
        
        //Get the Mother Board Information
        [fec32Iterator setObject:[aFec32Card pullFecForOrcaDB] forKey:@"mother_board"];
        
        //Variable used to loop through all the current settings
        NSMutableDictionary * daughterCardIterator = [NSMutableDictionary dictionaryWithCapacity:20];
    
        //Get the Fec Daughter Cards associated with the actual
        int j;
        for(j=0;j<kNumSNODaughterCards;j++){
			ORFecDaughterCardModel* dc = [[OROrderedObjManager for:aFec32Card] objectInSlot:j];
    
            //Fill the daughter card iterator
            //daughterCardIterator = [dc pullFecDaughterInformationForOrcaDB];
            
            //[NSString stringWithFormat:@"%i",j]
            NSString* daughterBoardSlot = [NSString stringWithFormat:@"%i",[dc slot]];
            
            //Place the information for each daughter card into the main daughter card array
            [daughterCardIterator setObject:[dc pullFecDaughterInformationForOrcaDB] forKey:daughterBoardSlot];
        }
        
        //Fill the daughter card information into the mother board information
        [fec32Iterator setObject:daughterCardIterator forKey:@"daughter_board"];
        
        //[fecCardArray setObject:fec32Iterator forKey:[NSString stringWithFormat:@"%i",i]];
        //[fecCardArray setObject:fec32Iterator forKey:[fecCardArray valueForKeyPath:crateNumberString]];
        
        //this works but only places in the first slot
        NSString *crateNumberString = [NSString stringWithFormat:@"%i",[aFec32Card crateNumber]];
        NSString *slotNumberString  = [NSString stringWithFormat:@"%i",15-([aFec32Card slot]-1)];
        //[fecCardArray setObject:fec32Iterator forKey:crateNumberString];
        
        //NSLog(@"%@",[fecCardArray objectForKey:crateNumberStringv2]);
        [[fecCardArray objectForKey:crateNumberString] setObject:fec32Iterator forKey:slotNumberString];

    }//end of looping through all the Fec32 Cards
    
    //fetching the svn version used for this DAQ build 
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* svnVersionPath = [[NSBundle mainBundle] pathForResource:@"svnversion"ofType:nil];
    NSMutableString* svnVersion = [NSMutableString stringWithString:@""];
    if([fm fileExistsAtPath:svnVersionPath])svnVersion = [NSMutableString stringWithContentsOfFile:svnVersionPath encoding:NSASCIIStringEncoding error:nil];
    if([svnVersion hasSuffix:@"\n"]){
        [svnVersion replaceCharactersInRange:NSMakeRange([svnVersion length]-1, 1) withString:@""];
    }
    
    //Fill the configuration document with information
    [configDocDict setObject:@"configuration" forKey:@"type"];
    [configDocDict setObject:[NSNumber numberWithDouble:[[self stringDateFromDate:nil] doubleValue]] forKey:@"timestamp"];
    [configDocDict setObject:@"0" forKey:@"config_version"]; //need to add in an update for this
    
     NSNumber * runNumberForConfig = [NSNumber numberWithUnsignedLong:[rc runNumber]];
    [configDocDict setObject:runNumberForConfig forKey:@"run"];
    
    [configDocDict setObject:svnVersion forKey:@"daq_version_build"];
    
    [configDocDict setObject:mtcArray forKey:@"mtc"];

    //add the xl3 information to configuration document
    [configDocDict setObject:allXl3Info forKey:@"xl3s"];

    //reorganise the Fec32 cards to make it easier for couchDB

    //Loop through all the crates in the detector
    /*int c;
    NSMutableDictionary *organisedFec32Information = [[NSMutableDictionary alloc] initWithCapacity:100];
    for(c=0;c<kNumOfCrates;c++){
        
        //String of the crate being used
        NSString * stringValueOfCrate = [NSString stringWithFormat:@"%i",c];
        
        //Loop through all the motherBoards and check to see it this motherboard id is in a given crate number
        NSMutableDictionary *motherBoardsInCrate = [[NSMutableDictionary alloc] initWithCapacity:100];

        for(id key in fecCardArray){
            
            NSNumber *currentCrateNumber = [NSNumber numberWithInt:[[fecCardArray objectForKey:@"mother_board"] objectForKey:@"crate_number"]];
            NSNumber *currentSlotNumber = [NSNumber numberWithInt:[[fecCardArray objectForKey:@"mother_board"]objectForKey:@"slot"]];
            
            NSMutableDictionary * subDictionary = [[NSMutableDictionary alloc] initWithCapacity:100];
            [subDictionary setObject:fecCardArray forKey:key];
            
            NSString *slotIDForMotherBoard = [NSString stringWithFormat:@"%@",[currentSlotNumber stringValue]];
            
            //if this particular mother board is in the current crate in the loop 
            if(c == [currentCrateNumber intValue]){
                [motherBoardsInCrate setObject:subDictionary forKey:slotIDForMotherBoard];
            }
        }
        
        [organisedFec32Information setObject:motherBoardsInCrate forKey:stringValueOfCrate];        
        
    }*/
    
    //NSLog(@"%@",organisedFec32Information);
    
    [configDocDict setObject:fecCardArray forKey:@"fec32_card"];
    [configDocDict setObject:caenArray forKey:@"caen"];
    
    //collect the objects that correspond to the CAEN
    
    //add the configuration document
    self.configDocument = configDocDict;
    
    //check to see if this is an offline run 
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRef:self] addDocument:configDocDict tag:kOrcaConfigDocumentAdded];
    }
    //NSLog(@"Adding configuation file \n");
    
    //wait for main thread to receive acknowledgement from couchdb
    /*NSDate* timeoutConfig = [NSDate dateWithTimeIntervalSinceNow:2.0];
    while ([timeoutConfig timeIntervalSinceNow] > 0 && ![self.runDocument objectForKey:@"_id"]) {
        [NSThread sleepForTimeInterval:0.1];
    }*/
    
    //Update to the Orca DB
    //[[self orcaDbRef:self] updateDocument:configDocDict documentId: [configDocDict objectForKey:@"_id"] tag:kOrcaConfigDocumentUpdated];
    

    //if ([objs count]) {
    //    aMTCcard = [objs objectAtIndex:0];
    //}
    
    // array object at 0
    //NSEnumerator* e = [listOfCards objectEnumerator];
    //ORCaen1720Model* aCard;
    //while(aCard = [e nextObject]){
    //    if([aCard crateNumber] == crate && [aCard slot] == card){
    //        [actualCards setObject:aCard forKey:aKey];
    //        obj = aCard;
    //        break;
    //    }
   // }

    
    // access to MTC/D object
    
    
    // mtcdDocDict
    
    
    // upload to DB
    
    
    // get doc id, and update run doc
    
    
    
    //crates
    //cable doc should go here...
    
    //order matters

    
    /*
     expert_flag = BooleanProperty()
     mtc_doc = StringProperty()
     hv_doc = StringProperty()
     run_type_doc = StringProperty()
     source_doc = StringProperty()
     crate = ListProperty()
     sub_run_number = IntegerProperty()?
     run_stop = DateTimeProperty()? to be updated with the run status update to "done"
     */
    
    
    // run document links to crate documents (we need doc IDs)
    
    [runDocPool release];
}


- (void) _runEndDocumentWorker:(NSDictionary*)runDoc
{
    NSAutoreleasePool* runDocPool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [[runDoc mutableCopy] autorelease];

    [runDocDict setObject:@"done" forKey:@"run_status"];
    //[runDocDict setObject:[self stringDateFromDate:nil] forKey:@"run_stop"];
    [runDocDict setObject:[NSNumber numberWithDouble:[[self stringUnixFromDate:nil] doubleValue]] forKey:@"timestamp_end"];
    [runDocDict setObject:[self rfc2822StringDateFromDate:nil] forKey:@"sudbury_time_end"];

    //after run stats
    //alarm logs
    //end of run xl3 logs
    //ellie

    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRef:self] updateDocument:runDocDict
                                   documentId:[runDocDict objectForKey:@"_id"]
                                          tag:kOrcaRunDocumentUpdated];
    }
    
    [runDocPool release];
}

- (void) morcaUpdateDBDict
{
    /*
    if (!morcaDBDict) morcaDBDict = [[NSMutableDictionary alloc] initWithCapacity:20];
    NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    ORXL3Model* xl3;
    for (xl3 in objs) {
        [[self morcaDBRef] getDocumentId:[NSString stringWithFormat:@"_design/xl3_status/_view/xl3_num?descending=True&start_key=%d&end_key=%d&limit=1&include_docs=True",[xl3 crateNumber], [xl3 crateNumber]]
                                     tag:[NSString stringWithFormat:@"%@.%d", kMorcaCrateDocGot, [xl3 crateNumber]]];
    }
     */
    /*
    if ([self morcaIsUpdating]) {
        if ([self morcaUpdateTime] == 0) {
            [self performSelector:@selector(morcaUpdateDB) withObject:nil afterDelay:0.1];
        }
        else {
            [self performSelector:@selector(morcaUpdateDB) withObject:nil afterDelay:[self morcaUpdateTime] - 0.2];
        }
    }
     */
}

- (void) morcaUpdatePushDocs:(unsigned int) crate
{
    /*
    NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    ORXL3Model* xl3;
    for (xl3 in objs) {
        if ([xl3 crateNumber] == crate) break;
    }
        
    BOOL updateDoc = NO;
    if ([[morcaDBDict objectForKey:[NSString stringWithFormat:@"%d",[xl3 crateNumber]]] objectForKey:@"_id"]){
        [[xl3 pollDict] setObject:[[morcaDBDict objectForKey:[NSString stringWithFormat:@"%d",[xl3 crateNumber]]] objectForKey:@"_id"] forKey:@"_id"];
        updateDoc = YES;
    }
    else {
        if ([[xl3 pollDict] objectForKey:@"_id"]) {
            [[xl3 pollDict] removeObjectForKey:@"_id"];
        }
        if ([[xl3 pollDict] objectForKey:@"_rev"]) {
            [[xl3 pollDict] removeObjectForKey:@"_rev"];
        }
    }
    if ([[morcaDBDict objectForKey:[NSString stringWithFormat:@"%d",[xl3 crateNumber]]] objectForKey:@"_rev"]){
        [[xl3 pollDict] setObject:[[morcaDBDict objectForKey:[NSString stringWithFormat:@"%d",[xl3 crateNumber]]] objectForKey:@"_rev"] forKey:@"_rev"];
    }
    [[xl3 pollDict] setObject:[NSNumber numberWithInt:[xl3 crateNumber]] forKey:@"xl3_num"];
    NSDateFormatter* iso = [[NSDateFormatter alloc] init];
    [iso setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    iso.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    //iso.calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    //iso.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
    NSString* str = [iso stringFromDate:[NSDate date]];
    [[xl3 pollDict] setObject:str forKey:@"time_stamp"];
    if (updateDoc) {
        [[self morcaDBRef] updateDocument:[xl3 pollDict] documentId:[[xl3 pollDict] objectForKey:@"_id"] tag:kMorcaCrateDocUpdated];
    }
    else{
        [[self morcaDBRef] addDocument:[xl3 pollDict] tag:kMorcaCrateDocUpdated];
    }
    [iso release];
    iso = nil;
    if (xl3 == [objs lastObject] && [self morcaIsUpdating]) {
        if ([self morcaUpdateTime] == 0) {
            [self performSelector:@selector(morcaUpdateDB) withObject:nil afterDelay:0.2];
        }
        else {
            [self performSelector:@selector(morcaUpdateDB) withObject:nil afterDelay:[self morcaUpdateTime] - 0.2];
        }
    }
     */
}
@end


@implementation SNOPDecoderForRHDR

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSMutableString* dsc = [NSMutableString stringWithFormat: @"RHDR record\n\n"];
    
    [dsc appendFormat:@"date: %ld\n", dataPtr[2]];
    [dsc appendFormat:@"time: %ld\n", dataPtr[3]];
    [dsc appendFormat:@"daq ver: %ld\n", dataPtr[4]];
    [dsc appendFormat:@"run num: %ld\n", dataPtr[5]];
    [dsc appendFormat:@"calib trial: %ld\n", dataPtr[6]];
    [dsc appendFormat:@"src msk: 0x%08lx\n", dataPtr[7]];
    [dsc appendFormat:@"run msk: 0x%016llx\n", (unsigned long long)(dataPtr[8] | (((unsigned long long)dataPtr[12]) << 32))];
    [dsc appendFormat:@"crate mask: 0x%08lx\n", dataPtr[9]];
    
    return [[dsc retain] autorelease];
}
@end

@implementation SNOPDecoderForEPED

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSMutableString* dsc = [NSMutableString stringWithFormat: @"EPED record\n\n"];

    [dsc appendFormat:@"coarse delay: %ld nsec\n", dataPtr[3]];
    [dsc appendFormat:@"fine delay: %ld clicks\n", dataPtr[4]];
    [dsc appendFormat:@"charge amp: %ld clicks\n", dataPtr[5]];
    [dsc appendFormat:@"ped width: %ld nsec\n", dataPtr[2]];
    [dsc appendFormat:@"cal type: 0x%08lx\n", dataPtr[7]];
    [dsc appendFormat:@"step num: %ld\n", dataPtr[6]];
    
    return [[dsc retain] autorelease];
}
@end
