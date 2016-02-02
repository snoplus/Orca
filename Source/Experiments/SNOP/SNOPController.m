//
//  SNOPController.m
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
#import "SNOPController.h"
#import "SNOPModel.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORDetectorSegment.h"
#import "ORXL3Model.h"
#import "ORSNOCrateModel.h"
#import "ELLIEModel.h"
#import "ORCouchDB.h"
#import "ORRunModel.h"
#import "ORRunController.h"
#import "ORMTC_Constants.h"
#import "ORMTCModel.h"
#import "SNOP_Run_Constants.h"


NSString* ORSNOPRequestHVStatus = @"ORSNOPRequestHVStatus";

@implementation SNOPController

@synthesize
runStopImg = _runStopImg,
runTypeMask,
smellieRunFileList,
snopRunTypeMaskDic,
smellieRunFile;

#pragma mark ���Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"SNOP"];
    return self;
}

-(void)windowDidLoad
{
    
    /*if([[globalRunTypesMatrix cellAtRow:i column:0] intValue] == 1){
        maskValue |= (0x1UL << i);
    }*/
    
    //build run type dictionary from the runTypes in the GUI
    self.snopRunTypeMaskDic = nil; //reset the current GUI information
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] initWithCapacity:20];
    int i;
    for(i=0;i<31;i++){
        NSButtonCell* test = [globalRunTypesMatrix cellAtRow:i column:0];
        [temp setObject:[NSString stringWithFormat:@"empty"] forKey:[test title]];
    }
    
    self.snopRunTypeMaskDic = temp;
}


- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/SNOP";
}

-(void) awakeFromNib
{
	detectorSize		= NSMakeSize(1200,700);
	detailsSize		= NSMakeSize(1200,700);//NSMakeSize(450,589);
	focalPlaneSize		= NSMakeSize(1200,700);//NSMakeSize(450,589);
	couchDBSize		= NSMakeSize(1200,700);//(620,595);//NSMakeSize(450,480);
	hvMasterSize		= NSMakeSize(1200,700);
	runsSize		= NSMakeSize(1200,700);
	
	blankView = [[NSView alloc] init];
//  [tabView setFocusRingType:NSFocusRingTypeNone];
//	[self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
    
    //pull the information from the SMELLIE DB
    [model getSmellieRunListInfo];
	[super awakeFromNib];
    [self performSelector:@selector(updateWindow)withObject:self afterDelay:0.1];
}


#pragma mark ���Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* theRunControl = [objs objectAtIndex:0];
    
    [super registerNotificationObservers];

    [notifyCenter addObserver : self
                     selector : @selector(viewTypeChanged:)
                         name : ORSNOPModelViewTypeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(dbOrcaDBIPChanged:)
                         name : ORSNOPModelOrcaDBIPAddressChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dbDebugDBIPChanged:)
                         name : ORSNOPModelDebugDBIPAddressChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(hvStatusChanged:)
                         name : ORXL3ModelHvStatusChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(hvStatusChanged:)
                         name : ORXL3ModelHVNominalVoltageChanged
                        object: nil];
    
    [notifyCenter addObserver :self
                     selector : @selector(stopSmellieRunAction:)
                         name : ORELLIERunFinished
                        object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStatusChanged:)
                         name: ORRunStatusChangedNotification
                       object: theRunControl];
    
    [notifyCenter addObserver:self
                     selector:@selector(runTypeChanged:)
                         name:SNOPRunTypeChangedNotification
                       object:self];
    
    [notifyCenter addObserver:self
                     selector:@selector(runTypeMaskChanged:)
                         name:ORRunTypeChangedNotification
                       object:theRunControl];
    
    [notifyCenter addObserver : self
                     selector : @selector(runsLockChanged:)
                         name : ORSNOPRunsLockNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];

    
    [notifyCenter addObserver : self
                     selector : @selector(runsECAChanged:)
                         name : ORSNOPModelRunsECAChangedNotification
                        object: model];
    
    //TODO: add the notification for changedRunType on SNO+
    /*[notifyCenter addObserver:self
                     selector:@selector(runTypesChanged:)
                         name:nil
                       object:nil];*/
    
    
}

- (void) updateWindow
{
    [super updateWindow];
	[self viewTypeChanged:nil];
    [self hvStatusChanged:nil];
    [self dbOrcaDBIPChanged:nil];
    [self dbDebugDBIPChanged:nil];
    [self fetchNhitSettings];
    [self fetchRunMaskSettings];
    [self runStatusChanged:nil]; //update the run status
    [model setIsEmergencyStopEnabled:TRUE]; //enable the emergency stop
    [self runsLockChanged:nil];
    [self runsECAChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSNOPRunsLockNotification to:secure];
    [runsLockButton setEnabled:secure];
}

-(void) fetchRunMaskSettings
{
    int i;
    for(i=0;i<31;i++){
        unsigned long mask = 0;
        mask = [[model runTypeMask] unsignedLongValue];
        //read the bitmask from the run mask
        int valueToSetInMatrix = (int) ((mask >> i) & 0x1UL);
        [[globalRunTypesMatrix cellAtRow:i column:0] setIntValue:valueToSetInMatrix];
        
    }
    //[globalRunTypesMatrix
}

-(IBAction)setTellie:(id)sender
{
    //Collect a series of objects from the ELLIEModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];
    NSArray * setSafeStates = @[@"0",@"0",@"0"]; //30 is the flag for setting smellie to its safe states
    [theELLIEModel callPythonScript:@"/Users/snotdaq/Desktop/orca-python/tellie/tellie_orca_script.py" withCmdLineArgs:setSafeStates];
}

-(IBAction)fireTellie:(id)sender
{

}

-(void)fetchNhitSettings
{
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    if([objs count]){
        ORMTCModel* theMtcModel = [objs objectAtIndex:0];
        int col,row;
        for(col=0;col<4;col++){
            for(row=0;row<6;row++){
                int index = kNHit100HiThreshold + row + (col * 6);
                int mtcaIndex = kESumLowThreshold + row + (col * 4);
                if((col == 0) && (row==0)){
                    [n100Hi setIntValue:[theMtcModel dbFloatByIndex: index]];
                    [esumhi setIntValue:[theMtcModel dbFloatByIndex:mtcaIndex]];
                }
                else if((col == 0) && (row==1)){
                    [n100med setIntValue:[theMtcModel dbFloatByIndex: index]];
                }
                else if((col == 0) && (row==3)){
                    [n20hi setIntValue:[theMtcModel dbFloatByIndex: index]];
                }
                else if((col == 0) && (row==5)){
                    [owln setIntValue:[theMtcModel dbFloatByIndex: index]];
                }
                else if((col == 0) && (row==2)){
                    [n100Lo setIntValue:[theMtcModel dbFloatByIndex: index]]; 
                }
                else{
                    //do nothing
                }
            }
        }
    }
    else {
        NSLogColor([NSColor redColor],@"Must have an MTC in the configuration\n");
    }
}

-(void) runTypeChanged:(NSNotification*)aNote
{
    [lastRunType setIntValue:[[model runTypeMask] intValue]]; //update the old run types
    //[currentRunType setIntValue:[aNote intValue]]; //update the current Run Type
    
}

-(void) runTypeMaskChanged:(NSNotification*)aNote
{
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* mainRunControl = [objs objectAtIndex:0];

    [maintenanceRunBox setState:[mainRunControl runType] & 1];
}


- (IBAction)maintenanceBoxAction:(id)sender {

    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* mainRunControl = [objs objectAtIndex:0];
    if([maintenanceRunBox state]){
        [runControl setRunType:[mainRunControl runType] | (eMaintenanceRunType)];
    }
    else if(![maintenanceRunBox state]){
        [runControl setRunType:[mainRunControl runType] & ~(eMaintenanceRunType)];
    }
    
}


//- (IBAction) startRunAction:(id)sender
//{
//    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
//    ORRunModel* theRunControl = [objs objectAtIndex:0];
//	if([[theRunControl document] isDocumentEdited]){
//		[[theRunControl document] afterSaveDo:@selector(startRun) withTarget:self];
//        [[theRunControl document] saveDocument:nil];
//    }
//	else [self startRun];
////    [currentStatus setStringValue:[self getStartingString]];
//    
//    NSLog(@"Sender: %@",[sender title]);
//    
//    //decide whether to issue a standard Physics run or a maintainence run
//    if([[sender title] isEqualToString:@"Start Physics Run"]){
//        //[model setRunType:kRunStandardPhysicsRun];
//    }
//    else if ([[sender title] isEqualToString:@"Start Run"]){
//        //[model setRunType:kRunMaintainence];
//        NSLog(@"Starting a run from SNOP");
//    }
//    else{
//        NSLog(@"SNOP_CONTROL:Run isn't correctly defined. Please check NSButton titles");
//        //[model setRunType:kRunUndefined];
//    }
//    
//    
//}

- (IBAction)newRunAction:(id)sender {
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* theRunControl = [objs objectAtIndex:0];
    [theRunControl setForceRestart:YES];
    [theRunControl performSelector:@selector(stopRun) withObject:nil afterDelay:0];
    [runStatusField setStringValue:[self getRestartingString]];
    
    NSLog(@"Sender: %@",[sender title]);
    
    if([[sender title] isEqualToString:@"New Physics Run"]){
        //[model setRunType:kRunStandardPhysicsRun];
    }
    else if ([[sender title] isEqualToString:@"New Maint. Run"]){
        //[model setRunType:kRunMaintainence];
    }
    else{
        NSLog(@"SNOP_CONTROL:Run isn't correctly defined. Please check NSButton titles");
        //[model setRunType:kRunUndefined];
    }
    
}


- (IBAction)changedRunTypeMatrixAction:(id)sender
{    
    //write in the new runType mask
    unsigned long maskValue = 0;
    int i;
    //only goes up to 31 because there is some strange problem with objective c recasting implictly an unsigned long as a long
    for(i=0;i<31;i++){
        if([[globalRunTypesMatrix cellAtRow:i column:0] intValue] == 1){
            NSButtonCell* test = [globalRunTypesMatrix cellAtRow:i column:0];
            [snopRunTypeMaskDic setObject:[NSNumber numberWithInt:[[globalRunTypesMatrix cellAtRow:i column:0] intValue]] forKey:[test title]];
            //set the actual bit mask
            maskValue |= (0x1UL << i);
        }
    }
    
    //self.runTypeMask = nil;
    NSNumber* maskValueForStore = [NSNumber numberWithUnsignedLong:maskValue];
    self.runTypeMask = maskValueForStore;
    
    [model setRunTypeMask:maskValueForStore];
    
    //A bit of test code to see a 32-bit word
    /*NSMutableString *str = [NSMutableString stringWithFormat:@""];
    for(NSInteger numberCopy = maskValue; numberCopy > 0; numberCopy >>= 1)
    {
        // Prepend "0" or "1", depending on the bit
        [str insertString:((numberCopy & 1) ? @"1" : @"0") atIndex:0];
    }*/
}


//- (IBAction)stopRunAction:(id)sender {
//    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
//    ORRunModel* theRunControl = [objs objectAtIndex:0];
//    [theRunControl performSelector:@selector(haltRun)withObject:nil afterDelay:.1];
//    [currentStatus setStringValue:[self getStoppingString]];
//    
//    //reset the run Type to be undefined
//    //[model setRunType:kRunUndefined];
//}

//- (void) startRun
//{
//    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
//    ORRunModel* theRunControl = [objs objectAtIndex:0];
//	[theRunControl performSelector:@selector(startRun)withObject:nil afterDelay:.1];
//}

- (void) runStatusChanged:(NSNotification*)aNotification{
    
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* theRunControl = [objs objectAtIndex:0];
    if([theRunControl runningState] == eRunInProgress){
		if(![theRunControl runPaused])[runStatusField setStringValue:[[ORGlobal sharedGlobal] runModeString]];
		else [runStatusField setStringValue:@"Paused"];
        [lightBoardView setState:kGoLight];
	}
	else if([theRunControl runningState] == eRunStopped){
		[runStatusField setStringValue:@"Stopped"];
        [lightBoardView setState:kStoppedLight];
	}
	else if([theRunControl runningState] == eRunStarting || [theRunControl runningState] == eRunStopping || [theRunControl runningState] == eRunBetweenSubRuns){
		if([theRunControl runningState] == eRunStarting)[runStatusField setStringValue:[self getStartingString]];
		else {
			if([theRunControl runningState] == eRunBetweenSubRuns)	[runStatusField setStringValue:[self getBetweenSubrunsString]];
			else                                                    [runStatusField setStringValue:[self getStoppingString]];
		}
        [lightBoardView setState:kCautionLight];
	}
}

- (NSString*) getStartingString
{
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* theRunControl = [objs objectAtIndex:0];
    NSString* s;
    if([theRunControl waitRequestersCount]==0)s = @"Starting...";
    else s = @"Starting (Waiting)";
    return s;
}

- (NSString*) getRestartingString
{
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* theRunControl = [objs objectAtIndex:0];
    NSString* s;
    if([theRunControl waitRequestersCount]==0)s = @"Restart...";
    else s = @"Restarting (Waiting)";
    return s;
}
- (NSString*) getStoppingString
{
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* theRunControl = [objs objectAtIndex:0];
    NSString* s;
    if([theRunControl waitRequestersCount]==0)s = @"Stopping...";
    else s = @"Stopping (Waiting)";
    return s;
}
- (NSString*) getBetweenSubrunsString
{
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* theRunControl = [objs objectAtIndex:0];
    NSString* s;
    if([theRunControl waitRequestersCount]==0)s = @"Between Sub Runs..";
    else s = @"'TweenSubRuns (Waiting)";
    return s;
}

- (void) viewTypeChanged:(NSNotification*)aNote
{
	[viewTypePU selectItemAtIndex:[model viewType]];
	[detectorView setViewType:[model viewType]];
	[detectorView makeAllSegments];	
}

- (void) dbOrcaDBIPChanged:(NSNotification*)aNote
{
    [orcaDBIPAddressPU setStringValue:[model orcaDBIPAddress]];
}

- (void) dbDebugDBIPChanged:(NSNotification*)aNote
{
    [debugDBIPAddressPU setStringValue:[model debugDBIPAddress]];
}

- (void) hvStatusChanged:(NSNotification*)aNote
{
    if (!aNote) {
        //collect all instances of xl3 objects in Orca
        NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
        
        // bit wise mask of xl3s
        unsigned long xl3Mask = 0x7ffff;
        
        //loop through all xl3 instances in Orca
        for (id xl3 in xl3s) {
            
            xl3Mask ^= 1 << [xl3 crateNumber];
            int mRow;
            int mColumn;
            bool found;
            bool globalHVON = false;
            
            found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:[xl3 crateNumber]]];
            if (found) {
                //Individual HV status
                [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[xl3 hvASwitch]?@"ON":@"OFF"];
                if ([xl3 hvASwitch]) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
                    globalHVON = true;
                }
                else {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
                }
                [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvNominalVoltageA]]];
                [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvAVoltageReadValue]]];
                [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:
                 [NSString stringWithFormat:@"%3.1f mA",[xl3 hvACurrentReadValue]]];
            }
            //Detector worldwide HV status
            if(globalHVON){
                [detectorHVStatus setStringValue:@"PMTs HV is ON"];
                [detectorHVStatus setBackgroundColor:[NSColor colorWithSRGBRed:255./255. green:102./255. blue:102./255. alpha:1]];
                [panicDownButton setEnabled:1];
            }
            else{
                [detectorHVStatus setStringValue:@"PMTs HV is OFF"];
                [detectorHVStatus setBackgroundColor:[NSColor colorWithSRGBRed:153./255. green:204./255. blue:255./255. alpha:1]];
                [panicDownButton setEnabled:0];
            }
            if ([xl3 crateNumber] == 16) {//16B
                int mRow;
                int mColumn;
                bool found;
                found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:19]];
                if (found) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[xl3 hvBSwitch]?@"ON":@"OFF"];
                    if ([xl3 hvBSwitch]) {
                        [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
                    }
                    else {
                        [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
                    }
                    [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:
                     [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvNominalVoltageB]]];
                    [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
                     [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvBVoltageReadValue]]];
                    [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:
                     [NSString stringWithFormat:@"%3.1f mA",[xl3 hvBCurrentReadValue]]];
                }
            }
        }
        unsigned short crate_num;
        if (xl3Mask & 1 << 16) {//16B needs an extra care
            xl3Mask |= 1 << 19;
        }
        for (crate_num=0; crate_num<20; crate_num++) {
            if (xl3Mask & 1 << crate_num) {
                int mRow;
                int mColumn;
                bool found;
                found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:crate_num]];
                if (found) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:@"???"];
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
                    [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:@"??? V"];
                    [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:@"??? V"];
                    [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:@"??? mA"];
                }
            }
        }
    }
    else { //update from a notification
        int mRow;
        int mColumn;
        bool found;
        found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:
                 [hvStatusMatrix cellWithTag:[[aNote object] crateNumber]]];

        if (found) {
            [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[[aNote object] hvASwitch]?@"ON":@"OFF"];
            if ([[aNote object] hvASwitch]) {
                [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
            }
            else {
                [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
            }
            [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:
             [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvNominalVoltageA]]];
            [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
             [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvAVoltageReadValue]]];
            [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:
             [NSString stringWithFormat:@"%3.1f mA",[[aNote object] hvACurrentReadValue]]];
        }
        if ([[aNote object] crateNumber] == 16) {//16B
            int mRow;
            int mColumn;
            bool found;
            found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:19]];
            if (found) {
                [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[[aNote object] hvBSwitch]?@"ON":@"OFF"];
                if ([[aNote object] hvBSwitch]) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
                }
                else {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
                }
                [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvNominalVoltageB]]];
                [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvBVoltageReadValue]]];
                [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:
                 [NSString stringWithFormat:@"%3.1f mA",[[aNote object] hvBCurrentReadValue]]];
            }
        }
    }
}

#pragma mark ���Interface Management
- (IBAction) viewTypeAction:(id)sender
{
	[model setViewType:[sender indexOfSelectedItem]];
}

- (IBAction) orcaDBIPAddressAction:(id)sender {
    [model setOrcaDBIPAddress:[sender stringValue]];
}

- (IBAction) debugDBIPAddressAction:(id)sender {
    [model setDebugDBIPAddress:[sender stringValue]];
}

- (IBAction) orcaDBClearHistoryAction:(id)sender
{
    [model clearOrcaDBConnectionHistory];
}

- (IBAction) debugDBClearHistoryAction:(id)sender
{
    [model clearDebugDBConnectionHistory];
}

- (IBAction) orcaDBFutonAction:(id)sender {

    NSString *url = [NSString stringWithFormat:@"http://%@:%@@%@:%d/_utils/database.html?%@",[model orcaDBUserName],[model orcaDBPassword],[model orcaDBIPAddress],[model orcaDBPort],[model orcaDBName]];
    NSString* urlScaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlScaped]];
}

- (IBAction) debugDBFutonAction:(id)sender {

    NSString *url = [NSString stringWithFormat:@"http://%@:%@@%@:%d/_utils/database.html?%@", [model debugDBUserName], [model debugDBPassword],[model debugDBIPAddress],[model debugDBPort], [model debugDBName]];
    NSString* urlScaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlScaped]];
}

- (IBAction) orcaDBTestAction:(id)sender {
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@:%d",
                                   [model orcaDBUserName], [model orcaDBPassword],
                                   [model orcaDBIPAddress], [model orcaDBPort]]]];
}

- (IBAction) debugDBTestAction:(id)sender {
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@:%d",
                                   [model debugDBUserName], [model debugDBPassword],
                                   [model debugDBIPAddress], [model debugDBPort]]]];
}

- (IBAction) orcaDBPingAction:(id)sender {
    [model orcaDBPing];
}

- (IBAction) debugDBPingAction:(id)sender {
    [model debugDBPing];
}

- (IBAction)hvMasterPanicAction:(id)sender
{
    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(hvPanicDown)];
    NSLog(@"Detector wide panic down started\n");
}

- (IBAction)updatexl3Mode:(id)sender{
    
    int i =0;
    NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    for (id xl3 in xl3s) {
        ORXL3Model * anXl3 = xl3;
        //[xl3 xl3Mode];
        NSString *xl3ModeDescription;
        if([anXl3 xl3Mode] == 1)        xl3ModeDescription = [NSString stringWithFormat:@"init"];
        else if ([anXl3 xl3Mode] == 2)  xl3ModeDescription = [NSString stringWithFormat:@"normal"];
        else if ([anXl3 xl3Mode] == 3)  xl3ModeDescription = [NSString stringWithFormat:@"CGT"];
        else                            xl3ModeDescription = [NSString stringWithFormat:@"unknown"];
        
        if([anXl3 crateNumber] == 16){
            i++;
        [[globalxl3Mode cellAtRow:16 column:0] setStringValue:xl3ModeDescription];
            if(i>0){
                [[globalxl3Mode cellAtRow:17 column:0] setStringValue:xl3ModeDescription];
            }
        }
        else if ([anXl3 crateNumber] > 16){
            [[globalxl3Mode cellAtRow:([anXl3 crateNumber]+1) column:0] setStringValue:xl3ModeDescription];
        }
        else{
            [[globalxl3Mode cellAtRow:[anXl3 crateNumber] column:0] setStringValue:xl3ModeDescription];
        }
        //setStringValue:[xl3 xl3Mode] stringValue]];
        /*if([anXl3 crateNumber] >= 16); //skip for 16B
        {
            [[globalxl3Mode cellAtRow:[anXl3 crateNumber] column:0] setStringValue:xl3ModeDescription];
        }*/
    }
    
}

- (IBAction)initCratesWithXilinx:(id)sender {
    
    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORSNOCrateModel")] makeObjectsPerformSelector:@selector(setAutoInit:) withObject:NO];
    
    NSArray *crates = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass: NSClassFromString(@"ORSNOCrateModel")];
    for (id crate in crates) {
        [crate performSelector:@selector(initCrate:phase:) withObject:NO withObject:0];
    }
    
}

- (IBAction)initCratesWithOutXilinx:(id)sender {
    
    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORSNOCrateModel")] makeObjectsPerformSelector:@selector(setAutoInit:) withObject:NO];
    
    NSArray *crates = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass: NSClassFromString(@"ORSNOCrateModel")];
    for (id crate in crates) {
        [crate performSelector:@selector(initCrate:phase:) withObject:YES withObject:0];
    }
    
}



- (IBAction)hvMasterTriggersON:(id)sender
{
    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(hvTriggersON)];
}

- (IBAction)hvMasterTriggersOFF:(id)sender
{
    [model hvMasterTriggersOFF];
}

- (IBAction)hvMasterStatus:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPRequestHVStatus object:self];
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[detectorView makeAllSegments];
}

- (void) setDetectorTitle
{	
	switch([model displayType]){
		case kDisplayRates:		[detectorTitle setStringValue:@"Detector Rate"];	break;
		case kDisplayThresholds:	[detectorTitle setStringValue:@"Thresholds"];		break;
		case kDisplayTotalCounts:	[detectorTitle setStringValue:@"Total Counts"];		break;
		default: break;
	}
}

#pragma mark ���Details Interface Management
- (void) detailsLockChanged:(NSNotification*)aNotification
{
	[super detailsLockChanged:aNotification];
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetailsLock]];
	BOOL locked = [gSecurity isLocked:[model experimentDetailsLock]];

	[detailsLockButton setState: locked];
	[initButton setEnabled: !lockedOrRunningMaintenance];
}

#pragma mark ���Table Data Source

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detectorSize];
		[[self window] setContentView:snopView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 5){
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:runsSize];
        [[self window] setContentView:snopView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detailsSize];
		[[self window] setContentView:snopView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:focalPlaneSize];
		[[self window] setContentView:snopView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 4){
	    [[self window] setContentView:blankView];
	    [self resizeWindowToSize:couchDBSize];
	    [[self window] setContentView:snopView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 5){
	    [[self window] setContentView:blankView];
	    [self resizeWindowToSize:hvMasterSize];
	    [[self window] setContentView:snopView];
    }

	int index = [tabView indexOfTabViewItem:tabViewItem];
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.SNOPController.selectedtab"];
}

#pragma mark ���ComboBox Data Source
- (NSInteger) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    if (aComboBox == orcaDBIPAddressPU) {
        return [[model orcaDBConnectionHistory] count];
    }
    else if (aComboBox == debugDBIPAddressPU) {
        return [[model debugDBConnectionHistory] count];
    }

    return 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    if (aComboBox == orcaDBIPAddressPU) {
        return [model orcaDBConnectionHistoryItem:index];
    }
    else if (aComboBox == debugDBIPAddressPU) {
        return [model debugDBConnectionHistoryItem:index];
    }
    
    return nil;
}

//smellie functions ----------------------------------------------

//this fetches the smellie run file information 
- (IBAction) callSmellieSettings:(id)sender
{	
    //remove any old smellie file values 
    self.smellieRunFileList = nil;
    NSMutableDictionary *tmp = [[NSMutableDictionary alloc] initWithDictionary:[model smellieTestFct]];
    
    //remove all the old items 
    [smellieRunFileNameField removeAllItems];
    
    //Fill lthe combo box with information 
    for(id key in tmp){
        id loopValue = [tmp objectForKey:key];
        [smellieRunFileNameField addItemWithObjectValue:[NSString stringWithFormat:@"%@",[loopValue objectForKey:@"run_name"]]];
    }

    [smellieRunFileNameField setEnabled:YES];
    [smellieLoadRunFile setEnabled:YES];

    self.smellieRunFileList = tmp;
    [tmp release];

}

-(IBAction)loadSmellieRunAction:(id)sender
{
    if([smellieRunFileNameField objectValueOfSelectedItem]!= nil)
    {
        [smellieStartRunButton setEnabled:YES];
        [smellieStopRunButton setEnabled:YES];
        [smellieEmergencyStop setEnabled:YES];
        
        //Loop through all the smellie files in the run list 
        for(id key in self.smellieRunFileList){
            
            id loopValue = [self.smellieRunFileList objectForKey:key];
            
            NSString *string1 = [loopValue objectForKey:@"run_name"];
            NSString *string2 = [smellieRunFileNameField objectValueOfSelectedItem];
            
            if( [string1 isEqualToString:string2]){
                self.smellieRunFile = loopValue;
                
                [loadedSmellieRunNameLabel setStringValue:[smellieRunFile objectForKey:@"run_name"]];
                [model setSmellieRunNameLabel:[NSString stringWithFormat:@"%@",[smellieRunFile objectForKey:@"run_name"]]];
                [loadedSmellieTriggerFrequencyLabel setStringValue:[smellieRunFile objectForKey:@"trigger_frequency"]];
                [loadedSmellieOperationModeLabel setStringValue:[smellieRunFile objectForKey:@"operation_mode"]];
                [loadedSmellieMaxIntensityLaser setStringValue:[smellieRunFile objectForKey:@"max_laser_intensity"]];
                [loadedSmellieMinIntensityLaser setStringValue:[smellieRunFile objectForKey:@"min_laser_intensity"]];
                
                //counters of fibres and Lasers
                int fibreCounter=  0;
                int laserCounter = 0;
                
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS007"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS107"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS207"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS025"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS125"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS225"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS037"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS137"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS237"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS055"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS155"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS255"] intValue];
                
                laserCounter = laserCounter + [[self.smellieRunFile objectForKey:@"375nm_laser_on"] intValue];
                laserCounter = laserCounter + [[self.smellieRunFile objectForKey:@"405nm_laser_on"] intValue];
                laserCounter = laserCounter + [[self.smellieRunFile objectForKey:@"440nm_laser_on"] intValue];
                laserCounter = laserCounter + [[self.smellieRunFile objectForKey:@"500nm_laser_on"] intValue];
                
                [loadedSmellieFibresLabel setStringValue:[NSString stringWithFormat:@"%i",fibreCounter]];
                
                //Concatenate the laser string
                NSMutableString * smellieLaserString = [[NSMutableString alloc] init];
                
                //see if the 375nm laser is on 
                if([[self.smellieRunFile objectForKey:@"375nm_laser_on"] intValue] == 1){
                    [smellieLaserString appendString:@" 375nm "];
                }
                
                //see if the 405nm laser is on
                if([[self.smellieRunFile objectForKey:@"405nm_laser_on"] intValue] == 1){
                    [smellieLaserString appendString:@" 405nm "];
                }
                
                //see if the 440nm laser is on
                if([[self.smellieRunFile objectForKey:@"440nm_laser_on"] intValue] == 1){
                    [smellieLaserString appendString:@" 440nm "];
                }
                
                //see if the 500nm laser is on
                if([[self.smellieRunFile objectForKey:@"500nm_laser_on"] intValue] == 1){
                    [smellieLaserString appendString:@" 500nm "];
                }
                
                //Calculate the approximate time of the run
                float triggerFrequency = [[smellieRunFile objectForKey:@"trigger_frequency"] floatValue];
                float numberTriggersPerLoop = [[smellieRunFile objectForKey:@"triggers_per_loop"] floatValue];
                float timePerLaserPerFibrePerIntensity = (1.0/triggerFrequency)*numberTriggersPerLoop + 1.0; //13.0seconds forthe sub run incrementations
                float numberOfIntensities = [[smellieRunFile objectForKey:@"num_intensity_steps"] floatValue];
                float timePerLaserPerFibre = timePerLaserPerFibrePerIntensity*numberOfIntensities;
                float timePerLaser = timePerLaserPerFibre*(1.0*fibreCounter);
                
                //final approx time plus the laser switchover time
                float totalTime = timePerLaser*(1.0*laserCounter) + (30*laserCounter);
                
                //return total approx time in minutes
                totalTime = totalTime/60.0; 
                
                [loadedSmellieApproxTimeLabel setStringValue:[NSString stringWithFormat:@"%0.1f",totalTime]];
                [loadedSmellieLasersLabel setStringValue:smellieLaserString];
                
                //unlock the control buttons
                //[smellieCheckInterlock setEnabled:YES];
                [smellieLaserString release];
                
            }
        }
    }
    else{
        //[smellieCheckInterlock setEnabled:NO];
        NSLog(@"Main SNO+ Control:Please choose a Smellie Run File from selection\n");
    }
}

- (IBAction) startSmellieRunAction:(id)sender
{
    [smellieLoadRunFile setEnabled:NO];
    [smellieRunFileNameField setEnabled:NO];
    [smellieStopRunButton setEnabled:YES];
    [smellieStartRunButton setEnabled:NO];
    
    //assign the run type as a SMELLIE run
    //[model setRunType:kRunSmellie];

    //start different sub runs as the laser runs through
    //communicate with smellie model
    
    //Collect a series of objects from the ELLIEModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    
    //get the ELLIE Model object
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];
    
    //Method for completing this without a new thread 
    //[theELLIEModel startSmellieRun:smellieRunFile];
    
    //if([model isRunTypeMaskedIn:@"Smellie"]){

    smellieThread = [[NSThread alloc] initWithTarget:theELLIEModel selector:@selector(startSmellieRun:) object:smellieRunFile];
    [smellieThread start];
    //}
    //else{
    //    NSLog(@"Smellie Run Type is not masked in. Please mask this in and try again \n");
    //}
    
    //[NSThread detachNewThreadSelector:@selector(startSmellieRun:) toTarget:theELLIEModel withObject:smellieRunFile];
    
    //[theELLIEModel release];
    
}

- (IBAction) enmergencyStopToggle:(id)sender
{
    /*if([emergyencyStopEnabled state] == 1){
        [model setIsEmergencyStopEnabled:true];
    }
    else{
        [model setIsEmergencyStopEnabled:false];
    }*/
    [model setIsEmergencyStopEnabled:(bool)[sender state]];
}

-(IBAction)eStop:(id)sender
{
    if([model isEStopPolling]){
        //cancel the E stop polling and change button
        [eStopButton setTitle:@"Start Polling"];
        [pollingStatus setStringValue:@"Not Polling"];
        [model setIsEStopPolling:NO];
    }
    else{
        [eStopButton setTitle:@"Stop Polling"];
        [pollingStatus setStringValue:@"Polling"];
        [model setIsEStopPolling:YES];
        [model eStopPolling];
    }

}

- (IBAction) stopSmellieRunAction:(id)sender
{
    [smellieLoadRunFile setEnabled:YES];
    [smellieRunFileNameField setEnabled:YES];
    [smellieStartRunButton setEnabled:YES];
    [smellieStopRunButton setEnabled:NO];
    //[smellieCheckInterlock setEnabled:YES];
    
    
    //unassign the run type as a SMELLIE run
    //[model setRunType:kRunUndefined];
   
    //Collect a series of objects from the ELLIEModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    
    //get the ELLIE Model object
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];
    
    /*[NSThread detachNewThreadSelector:@selector(startSmellieRun:)
                             toTarget:theELLIEModel
                           withObject:[smellieRunFile autorelease]];*/
    
    /*[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startSmellieRun:) object:smellieRunFile];*/
    //cancel the smellie thread
    [smellieThread cancel];
    [smellieThread release];
    smellieThread = nil;
    
    //Method for completing this without a new thread
    [theELLIEModel stopSmellieRun];
    
    
    //[theELLIEModel release];
    
    //wait for the current loop to finish
    //move straight to a maintainence run
    //communicate with smellie model
    //TODO:Make a note in the datastream that this happened
}

- (IBAction) emergencySmellieStopAction:(id)sender
{
    [smellieLoadRunFile setEnabled:YES];
    [smellieRunFileNameField setEnabled:YES];
    [smellieStartRunButton setEnabled:NO];
    [smellieStopRunButton setEnabled:NO];
    
    //unassign the run type as a SMELLIE run
    //[model setRunType:kRunUndefined];
    //[smellieCheckInterlock setEnabled:NO];
    //turn the interlock off
    //(if a smellie run is currently operating) start a maintainence run
    //reset the smellie laser system
    //TODO:Make a note in the datastream that this happened 
}

- (IBAction) runsLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORSNOPRunsLockNotification to:[sender intValue] forWindow:[self window]];
}

- (void) runsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:ORSNOPRunsLockNotification];
    BOOL lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSNOPRunsLockNotification];
    
    //[softwareTriggerButton setEnabled: !locked && !runInProgress];
    [runsLockButton setState: locked];
    
    //Enable or disable fields
    [ECApatternPopUpButton setEnabled:!lockedOrNotRunningMaintenance];
    [ECAtypePopUpButton setEnabled:!lockedOrNotRunningMaintenance];
    [TSlopePatternTextField setEnabled:!lockedOrNotRunningMaintenance];
    [subTimeTextField setEnabled:!lockedOrNotRunningMaintenance];
    [standardRunPopupMenu setEnabled:!lockedOrNotRunningMaintenance];
    [standardRunSaveButton setEnabled:!lockedOrNotRunningMaintenance];
    [standardRunLoadButton setEnabled:!lockedOrNotRunningMaintenance];
    [standardRunLoadToHWButton setEnabled:!lockedOrNotRunningMaintenance];
    [standardRunDeleteButton setEnabled:!lockedOrNotRunningMaintenance];
    [maintenanceRunBox setEnabled:!lockedOrNotRunningMaintenance];
    
    [runStatusTextField setStringValue:@"UNLOCKED"];
    [runStatusTextField setBackgroundColor:[NSColor colorWithSRGBRed:0 green:0 blue:1 alpha:1]];
    if(lockedOrNotRunningMaintenance){
        if(locked){
            [runStatusTextField setStringValue:@"LOCKED"];
            [runStatusTextField setBackgroundColor:[NSColor redColor]];
        }
        else{
            [runStatusTextField setStringValue:@"RUN IN PROGRESS"];
            [runStatusTextField setBackgroundColor:[NSColor redColor]];
        }
    }
    else if(runInProgress){
        [runStatusTextField setStringValue:@"MAINTENACE RUN"];
        [runStatusTextField setBackgroundColor:[NSColor orangeColor]];
    }
    
}

- (void) runsECAChanged:(NSNotification*)aNotification
{

    //Refresh values in GUI to match the model
    NSInteger* index = [model ECA_pattern] -1;
    [ECApatternPopUpButton selectItemAtIndex:index];
    index = [model ECA_type] -1;
    [ECAtypePopUpButton selectItemAtIndex:index];
    int integ = [model ECA_tslope_pattern];
    [TSlopePatternTextField setIntValue:integ];
    double doub = [model ECA_subrun_time];
    [subTimeTextField setDoubleValue:doub];
    
}

//ECA RUNS
- (IBAction)ecaPatternChangedAction:(id)sender {
    int value = (int)[ECApatternPopUpButton indexOfSelectedItem];
    [model setECA_pattern:value+1];
}

- (IBAction)ecaTypeChangedAction:(id)sender {
    int value = (int)[ECAtypePopUpButton indexOfSelectedItem];
    [model setECA_type:value+1];
}

- (IBAction)ecaTSlopePatternChangedAction:(id)sender {
    int value = [TSlopePatternTextField intValue];
    [model setECA_tslope_pattern:value];
}

- (IBAction)ecaSubrunTimeChangedAction:(id)sender {
    double value = [subTimeTextField doubleValue];
    [model setECA_subrun_time:value];
}

//STANDARD RUNS
- (IBAction)loadStandardRunFromDBAction:(id)sender {
    [model loadStandardRun:[standardRunPopupMenu objectValueOfSelectedItem]];
}

- (IBAction)loadStandardRunToHWAction:(id)sender {
    [model loadStandardRunToHW:[standardRunPopupMenu objectValueOfSelectedItem]];
}

- (IBAction)saveStandardRunToDBAction:(id)sender {
    [model saveStandardRun:[standardRunPopupMenu objectValueOfSelectedItem] withVersion:[standardRunVersionPopupMenu objectValueOfSelectedItem]];
}
- (IBAction)deleteStandardRun:(id)sender {
    [standardRunPopupMenu removeItemWithObjectValue:[standardRunPopupMenu stringValue]];
    [standardRunPopupMenu selectItemAtIndex:0];
}

- (IBAction)addNewStandardRunAction:(id)sender {
    NSString *newStandardRun = [standardRunPopupMenu stringValue];
    if ([standardRunPopupMenu indexOfItemWithObjectValue:newStandardRun] == NSNotFound && [newStandardRun isNotEqualTo:@""]){
        BOOL cancel = ORRunAlertPanel([NSString stringWithFormat:@"Creating new Standard Run: \"%@\"", newStandardRun],@"Is this really what you want?",@"Cancel",@"Yes, Make New Standard Run",nil);
        if(!cancel){
            [standardRunPopupMenu addItemWithObjectValue:newStandardRun];
            [standardRunPopupMenu selectItemWithObjectValue:newStandardRun];
        }
    }
}

@end
