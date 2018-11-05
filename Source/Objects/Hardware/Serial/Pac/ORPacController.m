//--------------------------------------------------------
// ORPacController
// Created by Mark  A. Howe on Tue Jan 6, 2009
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

#pragma mark •••Imported Files

#import "ORPacController.h"
#import "ORPacModel.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORTimeRate.h"
#import "OHexFormatter.h"
#import "ORValueBarGroupView.h"

@interface ORPacController (private)
- (void) populatePortListPopup;
@end

@implementation ORPacController

#pragma mark •••Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"Pac"];
	return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    
    [self populatePortListPopup];
	
	[[plotter0 yAxis] setRngLow:0.0 withHigh:6.];
	[[plotter0 yAxis] setRngLimitsLow:0.0 withHigh:6. withMinRng:1];
    [[plotter1 yAxis] setRngLow:0.0 withHigh:6.];
	[[plotter1 yAxis] setRngLimitsLow:0.0 withHigh:6. withMinRng:1];
	[[plotter0 yAxis] setInteger:NO];
	[[plotter1 yAxis] setInteger:NO];
	
    [[plotter0 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter0 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:50];
    [[plotter1 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter1 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:50];
    
	NSColor* color[4] = {
		[NSColor redColor],
		[NSColor greenColor],
		[NSColor blueColor],
		[NSColor brownColor],
	};
    int i;
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
		[plotter0 addPlot: aPlot];
		[aPlot setLineColor:color[i]];
		[aPlot setName:[model adcName:i]];
		[(ORTimeAxis*)[plotter0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i+4 andDataSource:self];
		[plotter1 addPlot: aPlot];
		[aPlot setName:[model adcName:i+4]];
		[aPlot setLineColor:color[i]];
		[(ORTimeAxis*)[plotter1 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
	[plotter0 setShowLegend:YES];
	[plotter1 setShowLegend:YES];
	
    [[queueValueBar xAxis] setRngLimitsLow:0 withHigh:300 withMinRng:10];
    [[queueValueBar xAxis] setRngDefaultsLow:0 withHigh:300];
    
    blankView = [[NSView alloc] init];
    setUpSize			= NSMakeSize(540,515);
    normalSize			= NSMakeSize(400,515);
    gainSize			= NSMakeSize(695,515);
    processLimitsSize	= NSMakeSize(470,515);
    trendSize           = NSMakeSize(555,515);
    
    NSString* key = [NSString stringWithFormat: @"orca.Pac%u.selectedtab",[model uniqueIdNumber]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
    
	[super awakeFromNib];
}

#pragma mark •••Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollingStateChanged:)
                         name : ORPacModelPollingStateChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORPacLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORPacModelPortNameChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(adcChanged:)
                         name : ORPacModelAdcChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(gainValueChanged:)
                         name : ORPacModelGainValueChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(moduleChanged:)
                         name : ORPacModelModuleChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(preAmpChanged:)
                         name : ORPacModelPreAmpChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lcmEnabledChanged:)
                         name : ORPacModelLcmEnabledChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(gainChannelChanged:)
                         name : ORPacModelGainChannelChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(setAllGainsChanged:)
                         name : ORPacModelSetAllGainsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(gainsChanged:)
                         name : ORPacModelGainsChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(gainsReadBackChanged:)
                         name : ORPacModelGainsReadBackChanged
						object: model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(logToFileChanged:)
                         name : ORPacModelLogToFileChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(logFileChanged:)
                         name : ORPacModelLogFileChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(updateTimePlot:)
						 name : ORRateAverageChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(queCountChanged:)
						 name : ORPacModelQueCountChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(gainDisplayTypeChanged:)
                         name : ORPacModelGainDisplayTypeChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(processLimitsChanged:)
                         name : ORPacModelProcessLimitsChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lcmChanged:)
                         name : ORPacModelLcmChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(adcChannelChanged:)
                         name : ORPacModelAdcChannelChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lastGainReadChanged:)
                         name : ORPacModelLastGainReadChanged
						object: model];
    [notifyCenter addObserver : self
                     selector : @selector(vetoConditionChanged:)
                         name : ORPacModelVetoChanged
						object: model];
    
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Power and Control (Unit %u)",[model uniqueIdNumber]]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
    [self portStateChanged:nil];
    [self portNameChanged:nil];
	[self gainValueChanged:nil];
	[self moduleChanged:nil];
	[self preAmpChanged:nil];
	[self lcmEnabledChanged:nil];
	[self gainChannelChanged:nil];
	[self setAllGainsChanged:nil];
	[self gainsChanged:nil];
	[self gainsReadBackChanged:nil];
    [self pollingStateChanged:nil];
	[self logToFileChanged:nil];
	[self logFileChanged:nil];
    [self pollingStateChanged:nil];
    [self miscAttributesChanged:nil];
	[self queCountChanged:nil];
	[self gainDisplayTypeChanged:nil];
	[self processLimitsChanged:nil];
	[self adcChanged:nil];
	[self lcmChanged:nil];
	[self adcChannelChanged:nil];
	[self lastGainReadChanged:nil];
	[self vetoConditionChanged:nil];
}

- (void) vetoConditionChanged:(NSNotification*)aNote
{
    if([model vetoInPlace])[ lcmRunVetoWarning setStringValue:@"Run is Vetoed because of the LCM setting!"];
	else					[lcmRunVetoWarning setStringValue:@""];
}

- (void) lastGainReadChanged:(NSNotification*)aNote
{
    NSDate* theLastRead = [model lastGainRead];
    if(!theLastRead) [lastGainReadField setObjectValue: @"Gains not read since ORCA start"];
    else             [lastGainReadField setObjectValue: [NSString stringWithFormat:@"Gains last read: %@",theLastRead]];
}

- (void) processLimitsChanged:(NSNotification*)aNote
{
    [processLimitsTableView reloadData];
}

- (void) gainDisplayTypeChanged:(NSNotification*)aNote
{
	[gainDisplayTypeMatrix selectCellWithTag : [model gainDisplayType]];
	NSFormatter* aFormatter = nil;
	if([model gainDisplayType] == 0){
		aFormatter = [[OHexFormatter alloc] init];
	}
    
	[[[gainTableView tableColumnWithIdentifier:@"Board0"] dataCell] setFormatter:aFormatter];
	[[[gainTableView tableColumnWithIdentifier:@"Board1"] dataCell] setFormatter:aFormatter];
	[[[gainTableView tableColumnWithIdentifier:@"Board2"] dataCell] setFormatter:aFormatter];
	[[[gainTableView tableColumnWithIdentifier:@"Board3"] dataCell] setFormatter:aFormatter];
    
    [[[gainReadBackTableView tableColumnWithIdentifier:@"Board0"] dataCell] setFormatter:aFormatter];
	[[[gainReadBackTableView tableColumnWithIdentifier:@"Board1"] dataCell] setFormatter:aFormatter];
	[[[gainReadBackTableView tableColumnWithIdentifier:@"Board2"] dataCell] setFormatter:aFormatter];
	[[[gainReadBackTableView tableColumnWithIdentifier:@"Board3"] dataCell] setFormatter:aFormatter];
    
	[aFormatter release];
	[gainTableView reloadData];
	[gainReadBackTableView reloadData];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter0 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 xAxis]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter0 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 yAxis]attributes] forKey:@"YAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter1 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter1 xAxis]attributes] forKey:@"XAttributes1"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter1 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter1 yAxis]attributes] forKey:@"YAttributes1"];
	};
}
- (void) miscAttributesChanged:(NSNotification*)aNote
{
	
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 xAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 yAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 yAxis] setNeedsDisplay:YES];
		}
	}
	
	if(aNote == nil || [key isEqualToString:@"XAttributes1"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes1"];
		if(attrib){
			[(ORAxis*)[plotter1 xAxis] setAttributes:attrib];
			[plotter1 setNeedsDisplay:YES];
			[[plotter1 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes1"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes1"];
		if(attrib){
			[(ORAxis*)[plotter1 yAxis] setAttributes:attrib];
			[plotter1 setNeedsDisplay:YES];
			[[plotter1 yAxis] setNeedsDisplay:YES];
		}
	}
}
- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [model timeRate:0])){
		[plotter0 setNeedsDisplay:YES];
	}
	else if(!aNote || ([aNote object] == [model timeRate:1])){
		[plotter1 setNeedsDisplay:YES];
	}
}
- (void) pollingStateChanged:(NSNotification*)aNotification
{
	[pollingButton selectItemAtIndex:[pollingButton indexOfItemWithTag:[model pollingState]]];
}

- (void) queCountChanged:(NSNotification*)aNotification
{
	[cmdQueCountField setIntegerValue:[model queCount]];
    [queueValueBar setNeedsDisplay:YES];
}

- (void) logFileChanged:(NSNotification*)aNote
{
	if([model logFile])[logFileTextField setStringValue: [model logFile]];
	else [logFileTextField setStringValue: @"---"];
}

- (void) logToFileChanged:(NSNotification*)aNote
{
	[logToFileButton setIntValue: [model logToFile]];
}

- (void) gainsChanged:(NSNotification*)aNote
{
	[gainTableView reloadData];
}

- (void) gainsReadBackChanged:(NSNotification*)aNote
{
	[gainReadBackTableView reloadData];
}


- (void) setAllGainsChanged:(NSNotification*)aNote
{
	[setAllGainsButton setIntValue: [model setAllGains]];
    if([model setAllGains]) [writeGainButton setTitle:@"Write To ALL"];
    else [writeGainButton setTitle:@"Write To One"];
}

- (void) gainChannelChanged:(NSNotification*)aNote
{
	[gainChannelTextField setIntValue: [model gainChannel]];
}

- (void) lcmEnabledChanged:(NSNotification*)aNote
{
    BOOL state = [model lcmEnabled];
	[lcmEnabledMatrix selectCellWithTag: state];
    [adc0Line0 setHidden:state];
    [adc0Line1 setHidden:state];
    [adc0Line2 setHidden:!state];
    
    NSColor* enabledColor = [NSColor blackColor];
    NSColor* disabledColor = [NSColor grayColor];
    
    [[channelMatrix cellAtRow:0 column:0] setTextColor:!state?enabledColor:disabledColor];
    [[adcNameMatrix cellAtRow:0 column:0] setTextColor:!state?enabledColor:disabledColor];
    [[adcMatrix cellAtRow:0 column:0] setTextColor:!state?enabledColor:disabledColor];
    [[timeMatrix cellAtRow:0 column:0] setTextColor:!state?enabledColor:disabledColor];
    
    
    [[channelMatrix cellAtRow:1 column:0] setTextColor:state?enabledColor:disabledColor];
    [[adcNameMatrix cellAtRow:1 column:0] setTextColor:state?enabledColor:disabledColor];
    [[adcMatrix cellAtRow:1 column:0] setTextColor:state?enabledColor:disabledColor];
    [[timeMatrix cellAtRow:1 column:0] setTextColor:state?enabledColor:disabledColor];
}

- (void) adcChannelChanged:(NSNotification*)aNote
{
	[adcChannelField setIntValue: [model adcChannel]];
	[preAmpTextField setIntValue: [model preAmp]];
	[moduleTextField setIntValue: [model module]];
}

- (void) preAmpChanged:(NSNotification*)aNote
{
	[preAmpTextField setIntValue: [model preAmp]];
	[adcChannelField setIntValue: [model adcChannel]];
}

- (void) moduleChanged:(NSNotification*)aNote
{
	[moduleTextField setIntValue: [model module]];
	[adcChannelField setIntValue: [model adcChannel]];
}

- (void) gainValueChanged:(NSNotification*)aNote
{
	[gainValueField setIntValue: [model gainValue]];
}

- (void) lcmChanged:(NSNotification*)aNote
{
    [self loadLcmTimeValues];
}

- (void) loadLcmTimeValues
{
	[[adcMatrix cellWithTag:0] setFloatValue:[model convertedLcm]];
	uint32_t t = [model lcmTimeMeasured];
	if(t){
		NSDate* theDate = [NSDate dateWithTimeIntervalSince1970:t];
		[[timeMatrix cellWithTag:0] setObjectValue:[theDate descriptionFromTemplate:@"MM/dd HH:mm:SS"]];
	}
	else [[timeMatrix cellWithTag:0] setObjectValue:@"--"];
}

- (void) adcChanged:(NSNotification*)aNote
{
	if(aNote){
		int index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
		[self loadAdcTimeValuesForIndex:index];
	}
	else {
		int i;
		for(i=0;i<8;i++){
			[self loadAdcTimeValuesForIndex:i];
		}
	}
}

- (void) loadAdcTimeValuesForIndex:(int)index
{
	[[adcMatrix cellWithTag:index+1] setFloatValue:[model convertedAdc:index]];
	uint32_t t = [model timeMeasured:index];
	if(t){
		NSDate* theDate = [NSDate dateWithTimeIntervalSince1970:t];
		[[timeMatrix cellWithTag:index+1] setObjectValue:[theDate stdDescription]];
	}
	else [[timeMatrix cellWithTag:index+1] setObjectValue:@"--"];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORPacLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORPacLock];
    BOOL locked = [gSecurity isLocked:ORPacLock];
    
    [lockButton setState: locked];
    
    [portListPopup setEnabled:!locked];
    [openPortButton setEnabled:!locked];
    [gainValueField setEnabled:!locked];
    [gainChannelTextField setEnabled:!locked && ![model setAllGains]];
    [readGainButton setEnabled:!locked];
    [writeGainButton setEnabled:!locked];
    [readGainButton setEnabled:!locked && ![model setAllGains]];
    [readAdcsButton setEnabled:!locked];
    [selectModuleButton setEnabled:!locked];
    [gainTableView setEnabled:!locked];
    [writeGainButton setEnabled:!lockedOrRunningMaintenance];
    [loadButton0 setEnabled:!lockedOrRunningMaintenance];
    [loadButton1 setEnabled:!lockedOrRunningMaintenance];
    [loadButton2 setEnabled:!lockedOrRunningMaintenance];
    [loadButton3 setEnabled:!lockedOrRunningMaintenance];
    //[loadButtonAll setEnabled:!lockedOrRunningMaintenance];//as per Florian's request 3/19/2013
    
    [lcmEnabledMatrix setEnabled:!locked && !runInProgress];
    
}

- (void) portStateChanged:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [model serialPort]){
        if([model serialPort]){
            [openPortButton setEnabled:YES];
            
            if([[model serialPort] isOpen]){
                [openPortButton setTitle:@"Close"];
                [portStateField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:.8 blue:0.0 alpha:1.0]];
                [portStateField setStringValue:@"Open"];
            }
            else {
                [openPortButton setTitle:@"Open"];
                [portStateField setStringValue:@"Closed"];
                [portStateField setTextColor:[NSColor redColor]];
            }
        }
        else {
            [openPortButton setEnabled:NO];
            [portStateField setTextColor:[NSColor blackColor]];
            [portStateField setStringValue:@"---"];
            [openPortButton setTitle:@"---"];
        }
    }
}

- (void) portNameChanged:(NSNotification*)aNotification
{
    NSString* portName = [model portName];
    
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
    
    [portListPopup selectItemAtIndex:0]; //the default
    while (aPort = [enumerator nextObject]) {
        if([portName isEqualToString:[aPort name]]){
            [portListPopup selectItemWithTitle:portName];
            break;
        }
	}
    [self portStateChanged:nil];
}

#pragma mark •••Actions

- (void) adcChannelAction:(id)sender
{
	[model setAdcChannel:[sender intValue]];
}

- (IBAction) gainDisplayTypeAction:(id)sender
{
	[model setGainDisplayType:(int)[[sender selectedCell] tag]];
}

- (IBAction) setAllGainsAction:(id)sender
{
	[model setSetAllGains:[sender intValue]];
	[self lockChanged:nil];
}

- (IBAction) gainChannelAction:(id)sender
{
	[model setGainChannel:[sender intValue]];
	[model setGainValue: [model gain:[sender intValue]]];
}

- (IBAction) gainValueAction:(id)sender
{
	[model setGainValue:[sender intValue]];
	[model setGain:[model gainChannel] withValue:[sender intValue]];
}

- (IBAction) writeLcmEnabledAction:(id)sender
{
	[model writeLcmEnable];
}

- (IBAction) lcmEnabledAction:(id)sender
{
	[model setLcmEnabled:[[sender selectedCell]tag]];
}

- (IBAction) preAmpAction:(id)sender
{
	[model setPreAmp:[sender intValue]];
}

- (IBAction) moduleAction:(id)sender
{
	[model setModule:[sender intValue]];
}

- (IBAction) writeGainAction:(id)sender
{
	[self endEditing];
	[model writeGain];
}

- (IBAction) readGainAction:(id)sender
{
	[self endEditing];
	[model readGain];
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORPacLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) readAdcsAction:(id)sender
{
	[self endEditing];
	[model readAdcs];
}

- (IBAction) selectModuleAction:(id)sender
{
	[self endEditing];
	[model selectModule];
}

- (IBAction) loadGainAction:(id)sender
{
    [self endEditing];
    int start,end;
	int board = (int)[sender tag];
	if(board == 4){ //all
		start = 0;
		end = 148;
	}
	else {
		start = board + board*36;
		end = start + 37;
	}
    
	int i;
	for(i=start;i<end;i++){
		[model writeOneGain:i];
	}
}

- (IBAction) readBackAllGains:(id)sender
{
    if([sender tag] == 4){
        [model readAllGains];
    }
}

- (IBAction) selectFileAction:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Log To File"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[model logFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"OrcaScript";
    }
    
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setLogFile:[[[savePanel URL] path] stringByAbbreviatingWithTildeInPath]];
        }
    }];
}

- (IBAction) logToFileAction:(id)sender
{
	[model setLogToFile:[sender intValue]];
}
- (IBAction) setPollingAction:(id)sender
{
    [model setPollingState:(NSTimeInterval)[[sender selectedItem] tag]];
}

#pragma mark •••Table Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    if(gainTableView == aTableView){
        if([[aTableColumn identifier] isEqualToString:@"Channel"]) return [NSNumber numberWithInt:rowIndex];
        else {
            int board;
            if([[aTableColumn identifier] isEqualToString:@"Board0"])board = 0;
            else if([[aTableColumn identifier] isEqualToString:@"Board1"])board = 1;
            else if([[aTableColumn identifier] isEqualToString:@"Board2"])board = 2;
            else board = 3;
            return [NSNumber numberWithInt:[model gain:rowIndex + board*37]];
        }
    }
    else if(gainReadBackTableView == aTableView){
        if([[aTableColumn identifier] isEqualToString:@"Channel"]) return [NSNumber numberWithInt:rowIndex];
        else {
            int board;
            if([[aTableColumn identifier] isEqualToString:@"Board0"])board = 0;
            else if([[aTableColumn identifier] isEqualToString:@"Board1"])board = 1;
            else if([[aTableColumn identifier] isEqualToString:@"Board2"])board = 2;
            else board = 3;
            return [NSNumber numberWithInt:[model gainReadBack:rowIndex + board*37]];
        }
    }
    
    else if(processLimitsTableView == aTableView){
        id columnId = [aTableColumn identifier];
        if([columnId isEqualToString:@"Name"])return [model processName:rowIndex];
        else if([columnId isEqualToString:@"ChannelNumber"])return [NSNumber numberWithInt:rowIndex];
        else if([columnId isEqualToString:@"AdcNumber"])return [NSNumber numberWithInt:rowIndex];
        else {
            id obj = [[model processLimits] objectAtIndex:rowIndex];
            return [obj objectForKey:columnId];
        }
    }
    else return nil;
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(gainTableView == aTableView)return 37;
	else if(gainReadBackTableView == aTableView)return 37;
    else if(processLimitsTableView == aTableView)return 8;
	else return 0;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(anObject == nil)return;
    
    if(gainTableView == aTableView){
        if([[aTableColumn identifier] isEqualToString:@"Channel"]) return;
        int board;
        if([[aTableColumn identifier] isEqualToString:@"Board0"])board = 0;
        else if([[aTableColumn identifier] isEqualToString:@"Board1"])board = 1;
        else if([[aTableColumn identifier] isEqualToString:@"Board2"])board = 2;
        else board = 3;
        [model setGain:(int)rowIndex+(board*37) withValue:[anObject intValue]];
        if(rowIndex+(board*37) == [model gainChannel]){
            [model setGainValue:[anObject intValue]];
        }
        [model writeGain:(int)rowIndex+(board*37) value:[anObject intValue]];
        [model readAllGains];
        
    }
    else if(processLimitsTableView == aTableView){
        id obj = [[model processLimits] objectAtIndex:rowIndex];
		[[[self undoManager] prepareWithInvocationTarget:self] tableView:aTableView setObjectValue:[obj objectForKey:[aTableColumn identifier]] forTableColumn:aTableColumn row:rowIndex];
		[obj setObject:anObject forKey:[aTableColumn identifier]];
		[aTableView reloadData];
        
    }
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:item]){
		case  0: [self resizeWindowToSize:setUpSize];	    break;
		case  1: [self resizeWindowToSize:gainSize];	    break;
		case  2: [self resizeWindowToSize:trendSize];	    break;
		case  3: [self resizeWindowToSize:processLimitsSize];	    break;
            
		default: [self resizeWindowToSize:normalSize];	    break;
    }
    
    NSInteger index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:[NSString stringWithFormat:@"orca.Pac%u.selectedtab",[model uniqueIdNumber]]];
    [[self window] setContentView:totalView];
}

#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
	return (int)[[model timeRate:(int)[aPlotter tag]]   count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int set = (int)[aPlotter tag];
	int count = (int)[[model timeRate:set] count];
	int index = count-i-1;
	*yValue = [[model timeRate:set] valueAtIndex:index];
	*xValue = [[model timeRate:set] timeSampledAtIndex:index];
}

- (IBAction) readGainFileAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[model lastGainFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
    }
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model readGainFile:[[openPanel URL] path]];
        }
    }];
}

- (IBAction) saveGainFileAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[model lastGainFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = [model lastGainFile];
        
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model saveGainFile:[[savePanel URL]path]];
        }
    }];
}

#pragma  mark •••Delegate Responsiblities
- (BOOL) outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}

- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	return YES;
}
@end

@implementation ORPacController (private)
- (void) populatePortListPopup
{
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
    [portListPopup removeAllItems];
    [portListPopup addItemWithTitle:@"--"];
    
	while (aPort = [enumerator nextObject]) {
        [portListPopup addItemWithTitle:[aPort name]];
	}
}
@end

