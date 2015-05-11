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

NSString* ORSNOPModelViewTypeChanged	= @"ORSNOPModelViewTypeChanged";
static NSString* SNOPDbConnector	= @"SNOPDbConnector";
NSString* ORSNOPModelOrcaDBIPAddressChanged = @"ORSNOPModelOrcaDBIPAddressChanged";
NSString* ORSNOPModelDebugDBIPAddressChanged = @"ORSNOPModelDebugDBIPAddressChanged";


#define kOrcaRunDocumentAdded   @"kOrcaRunDocumentAdded"
#define kOrcaRunDocumentUpdated @"kOrcaRunDocumentUpdated"
#define kOrcaConfigDocumentAdded @"kOrcaConfigDocumentAdded"
#define kOrcaConfigDocumentUpdated @"kOrcaConfigDocumentUpdated"
#define kMtcRunDocumentAdded @"kMtcRunDocumentAdded"

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
configDocument  = _configDocument,
mtcConfigDoc = _mtcConfigDoc;

#pragma mark ���Initialization

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SNOP"]];
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
        data[8] = 0;
        data[9] = 0;
        
        NSData* pdata = [[NSData alloc] initWithBytes:data length:sizeof(long)*(eped_rec_length)];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification object:pdata];
        [pdata release];
        pdata = nil;
    }
}


- (void) updateRHDRSruct
{
    //from run info
    NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
	if([runObjects count]){
		ORRunModel* rc = [runObjects objectAtIndex:0];
        _rhdrStruct.runNumber = [rc runNumber];
        NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        NSDateComponents *cmpStartTime = [gregorian components:
                                                 (NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit |
                                                  NSHourCalendarUnit | NSMinuteCalendarUnit |NSSecondCalendarUnit)
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

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	[self initOrcaDBConnectionHistory];
	[self initDebugDBConnectionHistory];
    
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

- (ORCouchDB*) debugDbRef:(id)aCouchDelegate
{
    return nil;
}


#pragma mark ���OrcaScript helpers


- (void) zeroPedestalMasks
{
    [[[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")]
     makeObjectsPerformSelector:@selector(zeroPedestalMasks)];
}

- (void) updatePedestalMasks:(unsigned int)pattern
{
    
    unsigned int** pt_step = (unsigned int**) pattern;
    NSLog(@"aaa 0x%08x\n", pt_step);
    
    //unsigned int* pt_step_crate = pt_step[0];
    
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
    if (!aDate)
        strDate = [NSDate date];
    else
        strDate = aDate;
    NSString* result = [snotDateFormatter stringFromDate:strDate];
    [snotDateFormatter release];
    strDate = nil;
    return [[result retain] autorelease];
}

- (void) _runDocumentWorker
{
    NSAutoreleasePool* runDocPool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:100];
    
    unsigned int run_number = 0;
    NSMutableString* runStartString = [NSMutableString string];
    NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* rc = nil;
	if([runObjects count]){
        rc = [runObjects objectAtIndex:0];
        run_number = [rc runNumber];
    }
    
    NSNumber* runNumber = [NSNumber numberWithUnsignedInt:run_number];

    [runDocDict setObject:@"run" forKey:@"doc_type"];
    [runDocDict setObject:@"physics" forKey:@"run_type"];
    [runDocDict setObject:[NSNumber numberWithUnsignedInt:0] forKey:@"version"];
    [runDocDict setObject:[self stringUnixFromDate:nil] forKey:@"time_stamp_start"];
    [runDocDict setObject:[self rfc2822StringDateFromDate:nil] forKey:@"sudbury_time_start"];
    [runDocDict setObject:runNumber forKey:@"run"];
    [runDocDict setObject:@"starting" forKey:@"run_status"];
    
    //[runDocDict setObject:runStartString forKey:@"run_start"];
    [runDocDict setObject:@"" forKey:@"time_stamp_end"];
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
    
    //Collect a series of objects from the ORMTCModel
    NSArray*  objs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];

    //Initialise the MTCModal
    ORMTCModel* aMTCcard = [objs objectAtIndex:0];
    
    NSMutableDictionary* configDocDict = [NSMutableDictionary dictionaryWithCapacity:1000];
    
    //Pulling all the MTC Values
    NSNumber * mtcFineDelay = [NSNumber numberWithUnsignedLong:[aMTCcard getMTC_FineDelay]];
    NSNumber * mtcPedWidth = [NSNumber numberWithUnsignedLong:[aMTCcard getMTC_PedWidth]];
    NSNumber * mtcGTWordMask = [NSNumber numberWithUnsignedLong:[aMTCcard getMTC_GTWordMask]];
    
    NSNumber * mtcCoarseDelay = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kCoarseDelay]];
    NSNumber * mtcPedestalWidth = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kPedestalWidth]];
    NSNumber * mtcNhit100LoPrescale = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kNhit100LoPrescale]];
    NSNumber * mtcPulserPeriod = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kPulserPeriod]];
    NSNumber * mtcLow10MhzClock = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kLow10MhzClock]];
    NSNumber * mtcFineSlope = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kFineSlope]];
    NSNumber * mtcMinDelayOffset= [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kMinDelayOffset]];
    
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
            
            if(row ==0) {
                [tempArray setObject:valueToDisplay forKey:@"nhit_100_hi"];
            }
            else if(row == 1){
                [tempArray setObject:valueToDisplay forKey:@"nhit_100_med"];
            }
            else if(row == 2){
                [tempArray setObject:valueToDisplay forKey:@"nhit_100_lo"];
            }
            else if(row == 3){
                [tempArray setObject:valueToDisplay forKey:@"nhit_20"];
            }
            else if(row == 4){
                [tempArray setObject:valueToDisplay forKey:@"nhit_20_lo"];
            }
            else if(row == 5){
                [tempArray setObject:valueToDisplay forKey:@"owln"];
            }
            else{
                NSLog(@"OrcaDB::Cannot write the Mtca Nhit DAC Values to the OrcaDB");
            }
    
		}
        
        //Do I need to release the memory for the temporary Array?
        //This will reveal itself during my analysis for the new Array  
        if(col == 0){
            [nhitMtcaArray setObject:tempArray forKey:@"threshold_value"];
        }
        else if(col == 1){
            [nhitMtcaArray setObject:tempArray forKey:@"mv_per_ADC"];
        }
        else if(col == 2){
            [nhitMtcaArray setObject:tempArray forKey:@"mv_per_Nhit"];
        }
        else if(col == 3){
            [nhitMtcaArray setObject:tempArray forKey:@"dc_offset"];
        }
        else{
            NSLog(@"OrcaDB::Cannot write the Mtca Nhit DAC values to the OrcaDB");
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
             
             if(row ==0) {
                 [tempArray setObject:valueToDisplay forKey:@"ESUM_hi"];
             }
             else if(row == 1){
                 [tempArray setObject:valueToDisplay forKey:@"ESUM_lo"];
             }
             else if(row == 2){
                 [tempArray setObject:valueToDisplay forKey:@"OWLE_hi"];
             }
             else if(row == 3){
                 [tempArray setObject:valueToDisplay forKey:@"OWLE_lo"];
             }
             else{
                 NSLog(@"OrcaDB::Cannot write the Mtca Esum DAC values to the OrcaDB");
             }
             
         }
        
        //Do I need to release the memory for the temporary Array?
        //This will reveal itself during my analysis for the new Array
        if(col == 0){
            [esumArray setObject:tempArray forKey:@"threshold_value"];
        }
        else if(col == 1){
            [esumArray setObject:tempArray forKey:@"mv_per_ADC"];
        }
        else if(col == 2){
            [esumArray setObject:tempArray forKey:@"mv_per_Nhit"];
        }
        else if(col == 3){
            [esumArray setObject:tempArray forKey:@"dc_offset"];
        }
        
        
    }
        
    //Get the trigger information and place into the DB
    NSMutableDictionary * triggerMask = [NSMutableDictionary dictionaryWithCapacity:100];
    
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
    
    //Combine the mutable arrays containing all the triggers into the Dictionary;
    [triggerMask setObject:gtMask forKey:@"global_trigger_mask"];
    [triggerMask setObject:gtCrateMask forKey:@"crate_trigger_mask"];
    [triggerMask setObject:pedCrateMask forKey:@"pedestal_trigger_mask"];
    
    //Fill an array with mtc information 
    NSMutableDictionary * mtcArray = [NSMutableDictionary dictionaryWithCapacity:20];
    [mtcArray setObject:mtcCoarseDelay forKey:@"coarse_delay"];
    [mtcArray setObject:mtcFineDelay forKey:@"fine_delay"];
    [mtcArray setObject:mtcPedWidth forKey:@"ped_width"];
    [mtcArray setObject:mtcGTWordMask forKey:@"gt_word_mask"];
    [mtcArray setObject:mtcPedestalWidth forKey:@"pedestal_width"];
    [mtcArray setObject:mtcNhit100LoPrescale forKey:@"nhit100_lo_prescale"];
    [mtcArray setObject:mtcPulserPeriod forKey:@"pulsar_period"];
    [mtcArray setObject:mtcLow10MhzClock forKey:@"low_10Mhz_clock"];
    [mtcArray setObject:mtcFineSlope forKey:@"fine_slope"];
    [mtcArray setObject:mtcMinDelayOffset forKey:@"min_delay_offset"];
    [mtcArray setObject:nhitMtcaArray forKey:@"mtca_nhit_matrix"];
    [mtcArray setObject:esumArray forKey:@"mtca_esum_matrix"];
    [mtcArray setObject:triggerMask forKey:@"trigger_masks"];
    
    
    //make an MTC document
    NSMutableDictionary* mtcDocDict = [NSMutableDictionary dictionaryWithCapacity:100];
    
    [mtcDocDict setObject:@"mtc" forKey:@"doc_type"];
    [mtcDocDict setObject:[NSNumber numberWithUnsignedInt:0] forKey:@"version"];
    [mtcDocDict setObject:runNumber forKey:@"run"];
    [mtcDocDict setObject:mtcArray forKey:@"mtc_info"];
    
    self.mtcConfigDoc = mtcDocDict;
    
    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRef:self] addDocument:mtcDocDict tag:kMtcRunDocumentAdded];
    }
    
    //FILL THE DATA FROM EACH FRONT END CARD HERE !!!!!
    
    //Initialise a Dictionary to fill the Daughter Card information
    NSMutableDictionary * fecCardArray = [NSMutableDictionary dictionaryWithCapacity:200];
    
    //Loop over all the FEC cards
    NSArray * fec32ControllerObjs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];
    
    //Count all Fec32 Cards on the DAQ
    //int numberFec32Cards = 2; //PLACE THIS IN LATER: [fec32ControllerObjs count];
    int numberFec32Cards = [fec32ControllerObjs count];
    
    //Iterate through all of the Fec32 Cards
    for(i=0;i<numberFec32Cards;i++){
            
        ORFec32Model * aFec32Card = [fec32ControllerObjs objectAtIndex:i];
        
        //Fec 32 Card Iterator
        NSMutableDictionary * fec32Iterator = [NSMutableDictionary dictionaryWithCapacity:20];
        
        //Get the Mother Board Information
        [fec32Iterator setObject:[aFec32Card pullFecForOrcaDB] forKey:@"mother_board"];
        
        //Variable used to loop through all the current settings
        NSMutableDictionary * daughterCardIterator = [NSMutableDictionary dictionaryWithCapacity:20];
    
        //Get the Fec Daughter Cards associated with the actual
        int j;
        for(j=0;j<kNumSNODaughterCards;j++){
            
            //Iterate through all the daughter
			ORFecDaughterCardModel* dc = [[OROrderedObjManager for:aFec32Card] objectInSlot:j];
    
            //Fill the daughter card iterator
            //daughterCardIterator = [dc pullFecDaughterInformationForOrcaDB];
        
            //Place the information for each daughter card into the main daughter card array
            [daughterCardIterator setObject:[dc pullFecDaughterInformationForOrcaDB] forKey:[NSString stringWithFormat:@"%i",j]];
        
        }//end of looping through all the front end daughter boards
        
        //Fill the daughter card information into the mother board information
        [fec32Iterator setObject:daughterCardIterator forKey:@"daughter_board"];
        
        //[fecCardArray setObject:fec32Iterator forKey:[NSString stringWithFormat:@"%i",i]];
        [fecCardArray setObject:fec32Iterator forKey:[aFec32Card boardID]];
        
        
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
    [configDocDict setObject:@"configuration" forKey:@"doc_type"];
    [configDocDict setObject:[self stringDateFromDate:nil] forKey:@"time_stamp"];
    [configDocDict setObject:@"0" forKey:@"config_id"]; //need to add in an update for this
    
     NSNumber * runNumberForConfig = [NSNumber numberWithUnsignedLong:[rc runNumber]];
    [configDocDict setObject:runNumberForConfig forKey:@"run_number"];
    
    [configDocDict setObject:svnVersion forKey:@"daq_version_build"];
    
    [configDocDict setObject:mtcArray forKey:@"mtc_info"];
    
    //this works but I'm not sure we need to see everything right now???
    [configDocDict setObject:fecCardArray forKey:@"fec32_card_info"];
    
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
    [runDocDict setObject:[self stringUnixFromDate:nil] forKey:@"time_stamp_end"];
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
