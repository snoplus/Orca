//--------------------------------------------------------
// ORCMC203Controller
// Created by Mark  A. Howe on Tue Aug 02 2005
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

#import "ORCMC203Controller.h"
#import "ORCMC203Model.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORValueBar.h"
#import "ORTimeAxis.h"
#import "ORPlotView.h"
#import "OR1DHistoPlot.h"
#import "ORTimeLinePlot.h"
#import "ORTimeRate.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"

@interface ORCMC203Controller (private)
- (void) updateButtons;
@end

@implementation ORCMC203Controller

#pragma mark ***Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"CMC203"];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
	[[totalRate xAxis] setRngLimitsLow:0 withHigh:100E6 withMinRng:10000];
	
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];

	OR1DHistoPlot* aPlot1 = [[OR1DHistoPlot alloc] initWithTag:1 andDataSource:self];
	[histoPlot addPlot: aPlot1];
	[aPlot1 release];
	
	[super awakeFromNib];
}

#pragma mark ***Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];

    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORCamacCardSlotChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORCMC203SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(histogramStartChanged:)
                         name : ORCMC203ModelHistogramStartChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histogramLengthChanged:)
                         name : ORCMC203ModelHistogramLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(wordSizeChanged:)
                         name : ORCMC203ModelWordSizeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histogramModeChanged:)
                         name : ORCMC203ModelHistogramModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(adcBitsChanged:)
                         name : ORCMC203ModelAdcBitsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(operationModeChanged:)
                         name : ORCMC203ModelOperationModeChanged
						object: model];

	[notifyCenter addObserver : self
					 selector : @selector(integrationChanged:)
						 name : ORRateGroupIntegrationChangedNotification
					   object : nil];
	
//    [notifyCenter addObserver : self
//					 selector : @selector(rateGroupChanged:)
//						 name : ORCMC203RateGroupChangedNotification
//					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
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
					   object : [[model fifoRateGroup]timeRate]];
	
    [notifyCenter addObserver : self
					 selector : @selector(updateHistoPlot:)
						 name : ORCMC203HistoDataChangedNotification
					   object : model];
	

}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
 	[self histogramStartChanged:nil];
	[self histogramLengthChanged:nil];
	[self wordSizeChanged:nil];
	[self histogramModeChanged:nil];
	[self adcBitsChanged:nil];
	[self operationModeChanged:nil];
    [self totalRateChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self updateTimePlot:nil];
}


- (void) operationModeChanged:(NSNotification*)aNote
{
	int mode = [model operationMode];
	[operationModeMatrix  selectCellWithTag:mode];
	[dataTabView selectTabViewItemAtIndex:mode];
	[self updateButtons];
}

- (void) adcBitsChanged:(NSNotification*)aNote
{
	[adcBitsTextField setIntValue: [model adcBits]];
}

- (void) histogramModeChanged:(NSNotification*)aNote
{
	[histogramModePU selectItemAtIndex: [model histogramMode]];
}

- (void) wordSizeChanged:(NSNotification*)aNote
{
	[wordSizeField setIntValue: [model wordSize]];
}

- (void) histogramLengthChanged:(NSNotification*)aNote
{
	[histogramLengthTextField setIntegerValue: [model histogramLength]];
}

- (void) histogramStartChanged:(NSNotification*)aNote
{
	[histogramStartTextField setIntegerValue: [model histogramStart]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORCMC203SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    [self updateButtons];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"CMC203 (Station %u)",(int)[model stationNumber]]];
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
	ORRateGroup* theRateObj = [aNotification object];
	if(aNotification == nil || [model fifoRateGroup] == theRateObj){
		
		[totalRateText setFloatValue: [theRateObj totalRate]];
		[totalRate setNeedsDisplay:YES];
	}
}

- (void) integrationChanged:(NSNotification*)aNotification
{
	ORRateGroup* theRateGroup = [aNotification object];
	if(aNotification == nil || [model fifoRateGroup] == theRateGroup || [aNotification object] == model){
		double dValue = [[model fifoRateGroup] integrationTime];
		[integrationStepper setDoubleValue:dValue];
		[integrationText setDoubleValue: dValue];
	}
}

- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [[model fifoRateGroup]timeRate])){
		[timeRatePlot setNeedsDisplay:YES];
	}
}
	
- (void) updateHistoPlot:(NSNotification*)aNote
{
	[histoPlot setNeedsDisplay:YES];
}

//a fake action from the scale object
- (void) scaleAction:(NSNotification*)aNotification
{
	
	if(aNotification == nil || [aNotification object] == [totalRate xAxis]){
		[model setMiscAttributes:[[totalRate xAxis]attributes] forKey:@"TotalRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot xAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot xAxis]attributes] forKey:@"TimeRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot yAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot yAxis]attributes] forKey:@"TimeRateYAttributes"];
	};

	if(aNotification == nil || [aNotification object] == [histoPlot yAxis]){
		[model setMiscAttributes:[(ORAxis*)[histoPlot yAxis]attributes] forKey:@"histoYAttributes"];
	};
	if(aNotification == nil || [aNotification object] == [histoPlot xAxis]){
		[model setMiscAttributes:[(ORAxis*)[histoPlot xAxis]attributes] forKey:@"histoXAttributes"];
	};
	
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"TotalRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TotalRateXAttributes"];
		if(attrib){
			[[totalRate xAxis] setAttributes:attrib];
			[totalRate setNeedsDisplay:YES];
			[[totalRate xAxis] setNeedsDisplay:YES];
			[totalRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateXAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot xAxis] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot yAxis] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot yAxis] setNeedsDisplay:YES];
			[timeRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	
	if(aNote == nil || [key isEqualToString:@"HistoYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"HistoYAttributes"];
		if(attrib){
			[(ORAxis*)[histoPlot yAxis] setAttributes:attrib];
			[histoPlot setNeedsDisplay:YES];
			[[histoPlot yAxis] setNeedsDisplay:YES];
		}
	}
	
	if(aNote == nil || [key isEqualToString:@"HistoXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"HistoXAttributes"];
		if(attrib){
			[(ORAxis*)[histoPlot xAxis] setAttributes:attrib];
			[histoPlot setNeedsDisplay:YES];
			[[histoPlot xAxis] setNeedsDisplay:YES];
		}
	}
}

#pragma mark ***Actions


- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
	if([sender doubleValue] != [[model fifoRateGroup]integrationTime]){
		[[self undoManager] setActionName: @"Set Integration Time"];
		[model setIntegrationTime:[sender doubleValue]];		
	}
	
}

- (IBAction) operationModeAction:(id)sender
{
	[model setOperationMode:(int)[[sender selectedCell]tag]];
}

- (IBAction) adcBitsAction:(id)sender
{
	[model setAdcBits:[sender intValue]];	
}

- (IBAction) histogramModeAction:(id)sender
{
	[model setHistogramMode:(int)[sender indexOfSelectedItem]];
}

- (IBAction) wordSizeAction:(id)sender
{
	[model setWordSize:[sender intValue]];	
}

- (IBAction) histogramLengthTextFieldAction:(id)sender
{
	[model setHistogramLength:[sender intValue]];	
}

- (IBAction) histogramStartTextFieldAction:(id)sender
{
	[model setHistogramStart:[sender intValue]];	
}

- (IBAction) sampleAction:(id)sender
{
	@try {
		[model sample];
	}
	@catch(NSException* localException) {
		NSLog(@"Histogram sample of CMC203 (%d,%d) Failed\n",[model crateNumber],[model stationNumber]);
		@throw;
	}
}

- (IBAction) initAction:(id)sender
{
	@try {
		[model initBoard];
	}
	@catch(NSException* localException) {
		NSLog(@"InitBoard of CMC203 (%d,%d) Failed\n",[model crateNumber],[model stationNumber]);
		@throw;
	}
}

- (IBAction) loadFPGAAction:(id)sender;
{
	@try {
		[model forceFPGALoad];
	}
	@catch(NSException* localException) {
		NSLog(@"FPGA load of CMC203 (%d,%d) Failed\n",[model crateNumber],[model stationNumber]);
		@throw;
	}
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORCMC203SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) forceFPGALoad:(id)sender
{
	@try {
		[model forceFPGALoad];
	}
	@catch (NSException* localException){
		NSLog(@"Forced reload of CMC203 (%d,%d) Failed\n",[model crateNumber],[model stationNumber]);
	}
}

- (double) getBarValue:(int)tag
{
	
	return [[[[model fifoRateGroup]rates] objectAtIndex:tag] rate];
}


- (int) numberPointsInPlot:(id)aPlotter
{
	int tag = (int)[aPlotter tag];
	if(tag == 0) return (int)[[[model fifoRateGroup]timeRate]count];
	else		 return [model histogramCount];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int tag = (int)[aPlotter tag];
	if(tag == 0){
		int count = (int)[[[model fifoRateGroup]timeRate] count];
		int index = count-i-1;
		*yValue =  [[[model fifoRateGroup] timeRate] valueAtIndex:index];
		*xValue =  [[[model fifoRateGroup] timeRate] timeSampledAtIndex:index];
	}
	else if(tag == 1){
		*yValue =   [model histoDataValueAtIndex:i];
		*xValue = i;
	}
	else {
		*yValue = 0;
		*xValue = i;
	}
}


@end

@implementation ORCMC203Controller (private)
- (void) updateButtons
{
	int  operationMode = [model operationMode];
	BOOL runInProgress = [gOrcaGlobals runInProgress];
	BOOL locked = [gSecurity isLocked:ORCMC203SettingsLock];
    [settingLockButton setState: locked];
    [operationModeMatrix setEnabled:!runInProgress && !locked];
	[adcBitsTextField setEnabled: !runInProgress & (operationMode == kCMC203HistogramMode) && !locked];
	[histogramModePU setEnabled: !runInProgress & (operationMode == kCMC203HistogramMode) && !locked];
	[wordSizeField setEnabled: !runInProgress & (operationMode == kCMC203HistogramMode) && !locked];
	[histogramLengthTextField setEnabled: !runInProgress & (operationMode == kCMC203HistogramMode) && !locked];
	[histogramStartTextField setEnabled: !runInProgress & (operationMode == kCMC203HistogramMode) && !locked];
	[histogramModePU setEnabled: !runInProgress & (operationMode == kCMC203HistogramMode) && !locked];
	[histogramMaxCountsPU setEnabled: !runInProgress & (operationMode == kCMC203HistogramMode) && !locked];
	[sampleButton setEnabled: (operationMode == kCMC203HistogramMode) && !locked];
	[initButton setEnabled: !runInProgress && !locked];
    [loadButton setEnabled:!runInProgress && !locked];
}
@end

