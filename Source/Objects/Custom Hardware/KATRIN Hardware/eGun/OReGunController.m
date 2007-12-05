//--------------------------------------------------------
// OReGunController
// Created by Mark  A. Howe on Wed Nov 28, 2007
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

#import "OReGunController.h"
#import "OReGunModel.h"
#import "ORPlotter2D.h"
#import "ORAxis.h"
#import "ORIP220Model.h"
#import "ORObjectProxy.h"
#define __CARBONSOUND__ //temp until undated to >10.3
#import <Carbon/Carbon.h>

@implementation OReGunController

#pragma mark ***Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"eGun"];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    [xyPlot setVectorMode:YES];
    [xyPlot setDrawWithGradient:YES];
	[[xyPlot xScale] setInteger:YES];
    [xyPlot setBackgroundColor:[NSColor colorWithCalibratedRed:.9 green:1.0 blue:.9 alpha:1.0]];
	[super awakeFromNib];
}


#pragma mark ***Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
	[notifyCenter addObserver: self
					 selector: @selector( proxyChanged: )
						 name: ORObjectProxyChanged
					   object: nil];
	
	[notifyCenter addObserver: self
					 selector: @selector( proxyChanged: )
						 name: ORObjectProxyNumberChanged
					   object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(proxyChanged:)
                         name : ORDocumentLoadedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : OReGunLock
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(positionChanged:)
                         name : OReGunModelPositionChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(absMotionChanged:)
                         name : OReGunModelAbsMotionChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(mousePositionReported:)
                         name : ORPlotter2DMousePosition
                       object : xyPlot];
	
    [notifyCenter addObserver : self
                     selector : @selector(chanChanged:)
                         name : OReGunModelChanXChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(chanChanged:)
                         name : OReGunModelChanYChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(cmdPositionChanged:)
                         name : OReGunModelCmdPositionChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(voltsPerMillimeterChanged:)
                         name : OReGunModelVoltsPerMillimeterChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(movingChanged:)
                         name : OReGunModelMovingChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(noHysteresisChanged:)
                         name : OReGunModelNoHysteresisChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(viewTypeChanged:)
                         name : OReGunModelViewTypeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(excursionChanged:)
                         name : OReGunModelExcursionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(decayRateChanged:)
                         name : OReGunModelDecayRateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(decayTimeChanged:)
                         name : OReGunModelDecayTimeChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
    [self cmdPositionChanged:nil];
    [self absMotionChanged:nil];
	[self chanChanged:nil];
	[self movingChanged:nil];
	[self voltsPerMillimeterChanged:nil];
	[self noHysteresisChanged:nil];
	[self proxyChanged:nil];
	[self viewTypeChanged:nil];
	[self excursionChanged:nil];
	[self decayRateChanged:nil];
	[self decayTimeChanged:nil];
}

- (void) decayTimeChanged:(NSNotification*)aNote
{
	[decayTimeTextField setFloatValue: [model decayTime]];
}

- (void) decayRateChanged:(NSNotification*)aNote
{
	[decayRateTextField setFloatValue: [model decayRate]];
}

- (void) excursionChanged:(NSNotification*)aNote
{
	[excursionTextField setFloatValue: [model excursion]];
}

- (void) viewTypeChanged:(NSNotification*)aNote
{
    [viewTypeMatrix selectCellWithTag:[model viewType]];

	float r;
	if(![model viewType]){
		[xyPlot setBackgroundImage:[NSImage imageNamed:@"mainFocalPlanedetector"]];
		r = 47;
	}
	else {
		[xyPlot setBackgroundImage:nil];
		r = 200;
	}
	[[xyPlot xScale] setRngDefaultsLow:-r withHigh:r];
    [[xyPlot xScale] setRngLimitsLow:-r withHigh:r withMinRng:2*r];
	[[xyPlot yScale] setRngDefaultsLow:-r withHigh:r];
    [[xyPlot yScale] setRngLimitsLow:-r withHigh:r withMinRng:2*r];
	[xyPlot setNeedsDisplay:YES];
	
}

- (void) noHysteresisChanged:(NSNotification*)aNote
{
	[noHysteresisButton setIntValue: [model noHysteresis]];
	[decayTimeTextField setEnabled: ![model noHysteresis]];
	[decayRateTextField setEnabled: ![model noHysteresis]];
	[excursionTextField setEnabled: ![model noHysteresis]];
}

- (void) voltsPerMillimeterChanged:(NSNotification*)aNote
{
	[voltsPerMillimeterTextField setFloatValue: [model voltsPerMillimeter]];
}

- (void) movingChanged:(NSNotification*)aNote
{
	[goButton setEnabled:![model moving]];
	[stopButton setEnabled:[model moving]];
	[moveStatusField setStringValue:[model moving]?@"Moving":@""];
	[xyPlot setNeedsDisplay:YES];
}

- (void) chanChanged:(NSNotification*)aNote
{
	[[channelMatrix cellWithTag:0] setIntValue:[model chanX]];
	[[channelMatrix cellWithTag:1] setIntValue:[model chanY]];
}

- (void) proxyChanged:(NSNotification*) aNote
{
	if([aNote object] == [model x220Object] || !aNote){
		[[model x220Object] populatePU:interfaceObjPUx];
		[[model x220Object] selectItemForPU:interfaceObjPUx];
	}
	if([aNote object] == [model y220Object] || !aNote){
		[[model y220Object] populatePU:interfaceObjPUy];
		[[model y220Object] selectItemForPU:interfaceObjPUy];
	}
	[self positionChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:OReGunLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:OReGunLock];

    [lockButton setState: locked];

    [getPositionButton setEnabled:!locked];
    [cmdMatrix setEnabled:!locked];
    [channelMatrix setEnabled:!locked];
    [absMatrix setEnabled:!locked];
    [goButton setEnabled:!locked];

}

- (void) absMotionChanged:(NSNotification*)aNote
{
    [absMatrix selectCellWithTag:[model absMotion]];
    if([model absMotion]){
        [moveLabelField setStringValue:@"Go To:"];
        [goButton setTitle:@"Go To"];
    }
    else {
        [moveLabelField setStringValue:@"Move:"];
        [goButton setTitle:@"Move"];
    }
}

- (void) cmdPositionChanged:(NSNotification*)aNote
{
	float voltsPerMillimeter = [model voltsPerMillimeter];
 	[[cmdMatrix cellWithTag:0] setFloatValue:[model cmdPosition].x/voltsPerMillimeter];
	[[cmdMatrix cellWithTag:1] setFloatValue:[model cmdPosition].y/voltsPerMillimeter];
}


- (void) positionChanged:(NSNotification*)aNote
{
	[xyPlot setNeedsDisplay:YES];
	float voltsPerMillimeter = [model voltsPerMillimeter];
	[xPositionField setFloatValue:[model xyVoltage].x/voltsPerMillimeter];
	[yPositionField setFloatValue:[model xyVoltage].y/voltsPerMillimeter];
}

- (void) mousePositionReported: (NSNotification*)aNote
{
    if((GetCurrentKeyModifiers() & shiftKey)){
		float voltsPerMillimeter = [model voltsPerMillimeter];
		float x = [[[aNote userInfo] objectForKey:@"x"]floatValue]*voltsPerMillimeter;
		float y = [[[aNote userInfo] objectForKey:@"y"]floatValue]*voltsPerMillimeter;
        [model setCmdPosition:NSMakePoint(x,y)];
    }
}

#pragma mark ***Actions

- (void) decayTimeTextFieldAction:(id)sender
{
	[model setDecayTime:[sender floatValue]];	
}

- (void) decayRateTextFieldAction:(id)sender
{
	[model setDecayRate:[sender floatValue]];	
}

- (void) excursionTextFieldAction:(id)sender
{
	[model setExcursion:[sender floatValue]];	
}

- (IBAction) viewTypeAction:(id)sender
{
    [model setViewType:[[viewTypeMatrix selectedCell] tag]];
}

- (IBAction) noHysteresisAction:(id)sender
{
	[model setNoHysteresis:[sender intValue]];	
}

- (IBAction) voltsPerMillimeterTextFieldAction:(id)sender
{
	[model setVoltsPerMillimeter:[sender floatValue]];	
}

- (IBAction) chanMatrixAction:(id)sender
{
	if([[sender selectedCell] tag]==0)[model setChanX:[sender intValue]];
	else [model setChanY:[sender intValue]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:OReGunLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) getPositionAction:(id)sender
{
	[model getPosition];
	[xyPlot setNeedsDisplay:YES];
	[xPositionField setNeedsDisplay:YES];
	[yPositionField setNeedsDisplay:YES];
}

- (IBAction) cmdPositionAction:(id)sender
{
	float voltsPerMillimeter = [model voltsPerMillimeter];
    [model setCmdPosition:NSMakePoint([[cmdMatrix cellWithTag:0] floatValue]*voltsPerMillimeter,[[cmdMatrix cellWithTag:1] floatValue]*voltsPerMillimeter)];
}

- (IBAction) absMotionAction:(id)sender
{
    [model setAbsMotion:[[absMatrix selectedCell] tag]];
}

- (IBAction) goAction:(id)sender
{
    [self endEditing];
    [model go];
	if([model absMotion])NSLog(@"XY Scanner %d sent to X: %f Y: %f\n",[model uniqueIdNumber],[[cmdMatrix cellWithTag:0] floatValue],[[cmdMatrix cellWithTag:1] floatValue]);
	else NSLog(@"XY Scanner %d moved relative amount X: %f Y: %f\n",[model uniqueIdNumber],[[cmdMatrix cellWithTag:0] floatValue],[[cmdMatrix cellWithTag:1] floatValue]);
}

- (IBAction) stopAction:(id)sender
{
    [model stopMotion];
}

- (IBAction) interfaceObjPUAction:(id)sender
{
	if(sender == interfaceObjPUx){
		[[model x220Object] useProxyObjectWithName:[sender titleOfSelectedItem]];
	}
	else if(sender == interfaceObjPUy){
		[[model y220Object] useProxyObjectWithName:[sender titleOfSelectedItem]];
	}
}

#pragma mark ***Plotter delegate methods
- (unsigned long) plotter:(id)aPlotter numPointsInSet:(int)set
{
    return [model validTrackCount];
}

- (BOOL) plotter:(id)aPlotter dataSet:(int)set index:(unsigned long)index x:(float*)xValue y:(float*)yValue
{
	float voltsPerMillimeter = [model voltsPerMillimeter];
    if(index>kNumTrackPoints){
        *xValue = 0;
        *yValue = 0;
        return NO;
    }
    NSPoint track = [model track:index];
    *xValue = track.x/voltsPerMillimeter;
    *yValue = track.y/voltsPerMillimeter;
    return YES;    
}

- (BOOL) plotter:(id)aPlotter dataSet:(int)set crossHairX:(float*)xValue crossHairY:(float*)yValue
{
	float voltsPerMillimeter = [model voltsPerMillimeter];
    *xValue = [model xyVoltage].x/voltsPerMillimeter;
    *yValue = [model xyVoltage].y/voltsPerMillimeter;
    return YES;
}

@end

