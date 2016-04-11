//
//  MajoranaController.h
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

#import "ORExperimentController.h"
#import "MajoranaDetectorView.h"

@class ORColorScale;
@class ORSegmentGroup;

@interface MajoranaController : ORExperimentController {
 
    IBOutlet NSTextField*	detectorTitle;
	IBOutlet NSButton*      ignorePanicOnBCB;
	IBOutlet NSButton*      ignorePanicOnACB;
    IBOutlet NSPopUpButton*	viewTypePU;
    IBOutlet ORColorScale*	secondaryColorScale;
    IBOutlet NSButton*		secondaryColorAxisLogCB;
    IBOutlet NSTextField*	secondaryRateField;

    //items in the  HW map tab view
	IBOutlet NSPopUpButton* secondaryAdcClassNamePopup;
	IBOutlet NSTextField*	secondaryMapFileTextField;
    IBOutlet NSButton*		readSecondaryMapFileButton;
    IBOutlet NSButton*		saveSecondaryMapFileButton;
    IBOutlet NSTableView*	secondaryTableView;
	IBOutlet NSButton*		vetoMapLockButton;
    IBOutlet NSTableView*	stringMapTableView;
    IBOutlet NSTableView*	specialChannelsTableView;

    //items in the  details tab view
    IBOutlet NSTableView*	secondaryValuesView;
    IBOutlet NSTabView*     viewTabView;
    IBOutlet NSButton*		initVetoButton;

    //items in the  subComponet tab view
    IBOutlet ORGroupView*   subComponentsView;
    IBOutlet NSPopUpButton* pollTimePopup;

    IBOutlet NSTextField*   lastTimeCheckedField;
    IBOutlet NSTableView*   module1InterlockTable;
    IBOutlet NSTableView*   module2InterlockTable;
    IBOutlet NSTextField*   ignore1Field;
    IBOutlet NSTextField*   ignore2Field;
    
    //items in the Calibration tab view
    IBOutlet NSButton*      checkSourceGateValveButton0;
    IBOutlet NSButton*      deploySourceButton0;
    IBOutlet NSButton*      retractSourceButton0;
    IBOutlet NSButton*      stopSourceButton0;
    IBOutlet NSButton*      closeGVButton0;
    IBOutlet NSTextField*	sourceStateField0;
    IBOutlet NSTextField*   isMovingField0;
    IBOutlet NSTextField*   isConnectedField0;
    IBOutlet NSTextField*   modeField0;
    IBOutlet NSTextField*   patternField0;
    IBOutlet NSProgressIndicator*    progress0;
    IBOutlet NSTextField*   gateValveStateField0;
    IBOutlet NSTextField*   sourceIsInField0;
    
    IBOutlet NSButton*      checkSourceGateValveButton1;
    IBOutlet NSButton*      deploySourceButton1;
    IBOutlet NSButton*      retractSourceButton1;
    IBOutlet NSButton*      stopSourceButton1;
    IBOutlet NSButton*      closeGVButton1;
    IBOutlet NSTextField*	sourceStateField1;
    IBOutlet NSTextField*   isMovingField1;
    IBOutlet NSTextField*   isConnectedField1;
    IBOutlet NSTextField*   modeField1;
    IBOutlet NSTextField*   patternField1;
    IBOutlet NSProgressIndicator*    progress1;
    IBOutlet NSTextField*   gateValveStateField1;
    IBOutlet NSTextField*   sourceIsInField1;

    IBOutlet NSButton*      calibrationLockButton;
    
	NSView *blankView;
    NSSize detectorSize;
    NSSize subComponentViewSize;
    NSSize detailsSize;
    NSSize detectorMapViewSize;
    NSSize vetoMapViewSize;
    NSSize calibrationViewSize;
}

#pragma mark ���Initialization
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) updateLastConstraintCheck:(NSNotification*)aNote;
- (void) secondaryColorAxisAttributesChanged:(NSNotification*)aNote;
- (void) secondaryAdcClassNameChanged:(NSNotification*)aNote;
- (void) secondaryMapFileChanged:(NSNotification*)aNote;
- (void) vetoMapLockChanged:(NSNotification*)aNote;
- (void) groupChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) auxTablesChanged:(NSNotification*)aNote;
- (void) forceHVUpdate:(int)segIndex;
- (void) ignorePanicOnBChanged:(NSNotification*)aNote;
- (void) ignorePanicOnAChanged:(NSNotification*)aNote;
- (void) setDetectorTitle;
- (void) viewTypeChanged:(NSNotification*)aNote;
- (void) sourceStateChanged:(NSNotification*)aNote;
- (void) sourceIsMovingChanged:(NSNotification*)aNote;
- (void) sourceModeChanged:(NSNotification*)aNote;
- (void) sourcePatternChanged:(NSNotification*)aNote;
- (void) sourceGatevalveChanged:(NSNotification*)aNote;
- (void) sourceIsInChanged:(NSNotification*)aNote;
- (void) calibrationLockChanged:(NSNotification*)aNote;
- (NSString*) order:(int)index;
- (NSString*) sourceGateValveState:(int)index;
- (NSString*) sourceIsInState:(int)index;


#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) confirmDidFinish:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
#endif

#pragma mark ���Calibration Interface Management
- (void) updateCalibrationButtons;

#pragma mark ***Actions
- (IBAction) initDigitizerAction:(id)sender;
- (IBAction) initVetoAction:(id)sender;
- (IBAction) ignorePanicOnBAction:(id)sender;
- (IBAction) ignorePanicOnAAction:(id)sender;
- (IBAction) viewTypeAction:(id)sender;
- (IBAction) vetoMapLockAction:(id)sender;
- (IBAction) secondaryAdcClassNameAction:(id)sender;
- (IBAction) saveSecondaryMapFileAction:(id)sender;
- (IBAction) readSecondaryMapFileAction:(id)sender;
- (IBAction) autoscaleSecondayColorScale:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) resetInterLocksOnModule0:(id)sender;
- (IBAction) resetInterLocksOnModule1:(id)sender;

- (IBAction) deploySourceAction0:(id)sender;
- (IBAction) retractSourceAction0:(id)sender;
- (IBAction) stopSourceAction0:(id)sender;
- (IBAction) checkSourceGateValve0:(id)sender;
- (IBAction) closeGateValve0:(id)sender;

- (IBAction) deploySourceAction1:(id)sender;
- (IBAction) retractSourceAction1:(id)sender;
- (IBAction) stopSourceAction1:(id)sender;
- (IBAction) checkSourceGateValve1:(id)sender;
- (IBAction) closeGateValve1:(id)sender;

- (IBAction) calibrationLockAction:(id)sender;
- (void)     confirmCloseGateValve:(int)index;

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem;

@end

@interface ORDetectorView (Majorana)
- (void) setViewType:(int)aState;
@end
