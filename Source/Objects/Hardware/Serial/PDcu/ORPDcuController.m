//--------------------------------------------------------
// ORPDcuController
// Created by Mark  A. Howe on Wed 4/15/2009
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

#import "ORPDcuController.h"
#import "ORPDcuModel.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORSerialPort.h"
#import "ORTimeRate.h"
#import "OHexFormatter.h"
#import "StopLightView.h"
#import "ORSerialPortController.h"

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
@interface ORPDcuController (private)
- (void) _turnOffSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
@end
#endif
@implementation ORPDcuController

#pragma mark •••Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"PDcu"];
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{	
    [[plotter yAxis] setRngLow:0.0 withHigh:1000.];
	[[plotter yAxis] setRngLimitsLow:0.0 withHigh:1000000000 withMinRng:10];
	[plotter setUseGradient:YES];
	
    [[plotter xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];

	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[plotter addPlot: aPlot];
	[(ORTimeAxis*)[plotter xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	
	[super awakeFromNib];	
	//[model getPressure];
}

#pragma mark •••Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORPDcuModelPollTimeChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORPDcuLock
                        object: nil];

     [notifyCenter addObserver : self
                     selector : @selector(deviceAddressChanged:)
                         name : ORPDcuModelDeviceAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(turboAcceleratingChanged:)
                         name : ORPDcuTurboAcceleratingChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(speedAttainedChanged:)
                         name : ORPDcuTurboSpeedAttainedChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(turboOverTempChanged:)
                         name : ORPDcuTurboOverTempChanged
						object: model];
		
	[notifyCenter addObserver : self
                     selector : @selector(oilDeficiencyChanged:)
                         name : ORPDcuOilDeficiencyChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(setRotorSpeedChanged:)
                         name : ORPDcuModelSetRotorSpeedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(actualRotorSpeedChanged:)
                         name : ORPDcuModelActualRotorSpeedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(motorCurrentChanged:)
                         name : ORPDcuModelMotorCurrentChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(motorCurrentChanged:)
                         name : ORPDcuModelMotorCurrentChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pressureChanged:)
                         name : ORPDcuModelPressureChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(motorPowerChanged:)
                         name : ORPDcuModelMotorPowerChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(stationPowerChanged:)
                         name : ORPDcuModelStationPowerChanged
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
                     selector : @selector(pressureScaleChanged:)
                         name : ORPDcuModelPressureScaleChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(tmpRotSetChanged:)
                         name : ORPDcuModelTmpRotSetChanged
						object: model];
	
	[serialPortController registerNotificationObservers];


}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"DCU (%u)",[model uniqueIdNumber]]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
	[self deviceAddressChanged:nil];
	[self setRotorSpeedChanged:nil];
	[self actualRotorSpeedChanged:nil];
	[self motorCurrentChanged:nil];
	[self turboAcceleratingChanged:nil];
	[self speedAttainedChanged:nil];
	[self turboOverTempChanged:nil];
	[self unitOverTempChanged:nil];
	[self oilDeficiencyChanged:nil];
	[self pressureChanged:nil];
	[self motorPowerChanged:nil];
	[self stationPowerChanged:nil];
	[self updateTimePlot:nil];
    [self miscAttributesChanged:nil];
	[self pressureScaleChanged:nil];
	[self pollTimeChanged:nil];
	[self tmpRotSetChanged:nil];
	[serialPortController updateWindow];
}

- (void) tmpRotSetChanged:(NSNotification*)aNote
{
	[tmpRotSetField setIntValue: [model tmpRotSet]];
}

- (void) pressureScaleChanged:(NSNotification*)aNote
{
	[pressureScalePU selectItemAtIndex: [model pressureScale]];
	[plotter setNeedsDisplay:YES];
	if([model pressureScale]>0){
		[[plotter yAxis] setLabel:[NSString stringWithFormat:@"xE-%02d mbar",[model pressureScale]]];
	}
	else {
		[[plotter yAxis] setLabel:@"mbar"];
	}
}
- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter xAxis]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter yAxis]attributes] forKey:@"YAttributes0"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter xAxis] setAttributes:attrib];
			[plotter setNeedsDisplay:YES];
			[[plotter xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter yAxis] setAttributes:attrib];
			[plotter setNeedsDisplay:YES];
			[[plotter yAxis] setNeedsDisplay:YES];
		}
	}
	
}

- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [model timeRate])){
		[plotter setNeedsDisplay:YES];
	}
}

- (void) motorCurrentChanged:(NSNotification*)aNote		{ [motorCurrentField		setFloatValue:	[model motorCurrent]]; }
- (void) actualRotorSpeedChanged:(NSNotification*)aNote	{ [actualRotorSpeedField	setIntValue:	[model actualRotorSpeed]]; }
- (void) setRotorSpeedChanged:(NSNotification*)aNote	{ [setRotorSpeedField		setIntValue:	[model setRotorSpeed]]; }
- (void) deviceAddressChanged:(NSNotification*)aNote	{ [deviceAddressField		setIntValue:	[model deviceAddress]]; }

- (void) stationPowerChanged:(NSNotification*)aNote		
{ 
	[stationPowerField	setStringValue:	[model stationPower]? @"ON":@"OFF"];
	[self updateStopLight];
	[self updateButtons];
}

- (void) speedAttainedChanged:(NSNotification*)aNote	
{ 
	[speedAttainedField setStringValue:	[model speedAttained] ? @"YES":@"NO"];
	[self updateStopLight];
}

- (void) turboAcceleratingChanged:(NSNotification*)aNote
{ 
	[turboAcceleratingField	setStringValue:	[model turboAccelerating] ? @"YES":@"NO"];
	[self updateStopLight];
}

- (void) updateStopLight
{
	if([model motorPower]){
		if([model speedAttained])[lightBoardView setState:kGoLight];
		else [lightBoardView setState:kCautionLight];
	}
	else [lightBoardView setState:kStoppedLight];
}

- (void) pressureChanged:(NSNotification*)aNote
{
	float pressure = [model pressure];
	[pressureField setStringValue: pressure == 0?@"--":[NSString stringWithFormat:@"%7.1E mbar",[model pressure]]];
}

- (void) motorPowerChanged:(NSNotification*)aNote		
{ 
	[motorPowerField setStringValue: [model motorPower] ? @"ON":@"OFF"];
	[self updateStopLight];
	[self updateButtons];
}

- (void) turboOverTempChanged:(NSNotification*)aNote
{	
	[turboPumpOverTempField setStringValue: [model turboPumpOverTemp]?@"HOT":@"OK"];
	[turboPumpOverTempField setTextColor:	[model turboPumpOverTemp]?[NSColor redColor]:[NSColor blackColor]];
}

- (void) unitOverTempChanged:(NSNotification*)aNote
{
	[driveUnitOverTempField setStringValue: [model driveUnitOverTemp]?@"HOT":@"OK"];
	[driveUnitOverTempField setTextColor:	[model driveUnitOverTemp]?[NSColor redColor]:[NSColor blackColor]];
}

- (void) oilDeficiencyChanged:(NSNotification*)aNote
{
	[oilDeficiencyField setStringValue: [model oilDeficiency]?@"LOW":@"OK"];
	[oilDeficiencyField setTextColor:	[model oilDeficiency]?[NSColor redColor]:[NSColor blackColor]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORPDcuLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (BOOL) portLocked
{
	return [gSecurity isLocked:ORPDcuLock];;
}

- (void) updateButtons
{
    BOOL locked = [gSecurity isLocked:ORPDcuLock];
	BOOL portOpen = [[model serialPort] isOpen];
	BOOL stationOn = [model stationPower] && [model motorPower];
    [lockButton setState: locked];
	
	[serialPortController updateButtons:locked];
	
    [stationOnButton setEnabled:!locked && portOpen && !stationOn];
    [stationOffButton setEnabled:!locked && portOpen && stationOn];
	[tmpRotSetField setEnabled:!locked && portOpen];
    [updateButton setEnabled:portOpen];

    [pollTimePopup setEnabled:!locked && portOpen];
	//[initButton  setEnabled:!locked && portOpen && stationOn];
}

- (void) pollTimeChanged:(NSNotification*)aNotification
{
	[pollTimePopup selectItemWithTag:[model pollTime]];
}

#pragma mark •••Actions
- (IBAction) tmpRotSetAction:(id)sender
{
	[model setTmpRotSet:[sender intValue]];	
}

- (IBAction) pressureScaleAction:(id)sender
{
	[model setPressureScale:(int)[sender indexOfSelectedItem]];
}

- (IBAction) turnOnAction:(id)sender
{
	[model turnStationOn];
}

- (IBAction) turnOffAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Turning Off Pumping Station!"];
    [alert setInformativeText:@"Is this really what you want?"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Yes, Turn it OFF"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertSecondButtonReturn){
            [model turnStationOff];
        }
    }];
#else
    NSBeginAlertSheet(@"Turning Off Pumping Station!",
                      @"Cancel",
                      @"Yes, Turn it OFF",
                      nil,[self window],
                      self,
                      @selector(_turnOffSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Is this really what you want?");
#endif
}

- (IBAction) deviceAddressAction:(id)sender
{
	[model setDeviceAddress:[sender intValue]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORPDcuLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) updateAllAction:(id)sender
{
	[model updateAll];
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:(int)[[sender selectedItem] tag]];
}

- (IBAction) initAction:(id)sender
{
	[self endEditing];
	[model initUnit];
}

#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
	return (int)[[model timeRate] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int count = (int)[[model timeRate] count];
	int index = count-i-1;
	*xValue = [[model timeRate] timeSampledAtIndex:index];
	*yValue = [[model timeRate] valueAtIndex:index] * [model pressureScaleValue];
}

@end

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
@implementation ORPDcuController (private)
- (void) _turnOffSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
		[model turnStationOff];
    }    
}
@end
#endif
