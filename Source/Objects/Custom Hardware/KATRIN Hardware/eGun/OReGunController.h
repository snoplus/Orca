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

@class ORCompositePlotView;

@interface OReGunController : OrcaObjectController
{
	IBOutlet NSPopUpButton* interfaceObjPUx;
	IBOutlet NSTextField* stepTimeTextField;
	IBOutlet NSTextField* overshootTextField;
	IBOutlet NSTextField* stateStringTextField;
	IBOutlet NSTextField*	decayTimeTextField;
	IBOutlet NSTextField*	decayRateTextField;
	IBOutlet NSTextField*	excursionTextField;
	IBOutlet NSMatrix*		viewTypeMatrix;
	IBOutlet NSTextField*	millimetersPerVoltTextField;
    IBOutlet NSPopUpButton* interfaceObjPUy;
	IBOutlet NSMatrix*		channelMatrix;
	IBOutlet ORCompositePlotView*    xyPlot;
    IBOutlet NSButton*      lockButton;
    IBOutlet NSButton*      getPositionButton;
    IBOutlet NSTextField*   xPositionField;
    IBOutlet NSTextField*   yPositionField;
    IBOutlet NSMatrix*		cmdMatrix;
    IBOutlet NSMatrix*      absMatrix;
    IBOutlet NSButton*      goButton;
    IBOutlet NSButton*      stopButton;
    IBOutlet NSTextField*   moveStatusField;
    IBOutlet NSTextField*   moveLabelField;
    IBOutlet NSButton*      degaussButton;
}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) stepTimeChanged:(NSNotification*)aNote;
- (void) overshootChanged:(NSNotification*)aNote;
- (void) stateStringChanged:(NSNotification*)aNote;
- (void) decayTimeChanged:(NSNotification*)aNote;
- (void) decayRateChanged:(NSNotification*)aNote;
- (void) excursionChanged:(NSNotification*)aNote;
- (void) viewTypeChanged:(NSNotification*)aNote;
- (void) millimetersPerVoltChanged:(NSNotification*)aNote;
- (void) chanChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) positionChanged:(NSNotification*)aNote;
- (void) cmdPositionChanged:(NSNotification*)aNote;
- (void) absMotionChanged:(NSNotification*)aNote;
- (void) proxyChanged:(NSNotification*) aNote;
- (void) movingChanged:(NSNotification*)aNote;

#pragma mark ***Actions
- (IBAction) stepTimeTextFieldAction:(id)sender;
- (IBAction) overshootTextFieldAction:(id)sender;
- (IBAction) degaussAction:(id)sender;
- (IBAction) decayTimeTextFieldAction:(id)sender;
- (IBAction) decayRateTextFieldAction:(id)sender;
- (IBAction) excursionTextFieldAction:(id)sender;
- (IBAction) viewTypeAction:(id)sender;
- (IBAction) millimetersPerVoltTextFieldAction:(id)sender;
- (IBAction) getPositionAction:(id)sender;
- (IBAction) chanMatrixAction:(id)sender;
- (IBAction) interfaceObjPUAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) getPositionAction:(id)sender;
- (IBAction) cmdPositionAction:(id)sender;
- (IBAction) absMotionAction:(id)sender;
- (IBAction) goAction:(id)sender;
- (IBAction) stopAction:(id)sender;

#pragma mark ***Data Source
- (int)	numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(uint32_t)index x:(double*)xValue y:(double*)yValue;
- (BOOL) plotter:(id)aPlotter crossHairX:(double*)xValue crossHairY:(double*)yValue;

@end


