//-------------------------------------------------------------------------
//  ORSIS3316Controller.h
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2015 CENPA. University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolinaponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORSIS3316Model.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORSIS3316Controller : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
    IBOutlet NSTextField*   moduleIDField;
	
	//base address
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;

    //thresholds
    IBOutlet NSMatrix*		enabledMatrix;
    IBOutlet NSMatrix*		heSuppressTrigModeMatrix;
    IBOutlet NSMatrix*		cfdControlMatrix;
    IBOutlet NSMatrix*		thresholdMatrix;
    IBOutlet NSMatrix*		energyDividerMatrix;
    IBOutlet NSMatrix*		energySubtractorMatrix;
    IBOutlet NSMatrix*		tauFactorMatrix;
    IBOutlet NSMatrix*		gapTimeMatrix;
    IBOutlet NSMatrix*		peakingTimeMatrix;
    
    IBOutlet NSMatrix*		heTrigThresholdMatrix;
    IBOutlet NSMatrix*		trigBothEdgesMatrix;
    IBOutlet NSMatrix*		intHeTrigOutPulseMatrix;
    IBOutlet NSMatrix*		intTrigOutPulseBitsMatrix;
    IBOutlet NSMatrix*      activeTrigGateWindowLenMatrix;
    IBOutlet NSMatrix*      preTriggerDelayMatrix;
    IBOutlet NSMatrix*      accGate1LenMatrix;
    IBOutlet NSMatrix*      accGate1StartMatrix;
    IBOutlet NSMatrix*      accGate2LenMatrix;
    IBOutlet NSMatrix*      accGate2StartMatrix;
    IBOutlet NSMatrix*      accGate3LenMatrix;
    IBOutlet NSMatrix*      accGate3StartMatrix;
    IBOutlet NSMatrix*      accGate4LenMatrix;
    IBOutlet NSMatrix*      accGate4StartMatrix;
    IBOutlet NSMatrix*      accGate5LenMatrix;
    IBOutlet NSMatrix*      accGate5StartMatrix;
    IBOutlet NSMatrix*      accGate6LenMatrix;
    IBOutlet NSMatrix*      accGate6StartMatrix;
    IBOutlet NSMatrix*      accGate7LenMatrix;
    IBOutlet NSMatrix*      accGate7StartMatrix;
    IBOutlet NSMatrix*      accGate8LenMatrix;
    IBOutlet NSMatrix*      accGate8StartMatrix;
 
    
    IBOutlet NSMatrix*		histogramsEnabledMatrix;
    IBOutlet NSMatrix*		pileupEnabledMatrix;
    IBOutlet NSMatrix*		clrHistogramWithTSMatrix;
    IBOutlet NSMatrix*		writeHitsIntoEventMemoryMatrix;

    IBOutlet NSMatrix*      rawDataBufferLenMatrix;
    IBOutlet NSMatrix*      rawDataBufferStartMatrix;


    //----------------------^^^^^^^^
    //------------------------------
	//CSR
	IBOutlet NSMatrix*		csrMatrix;
	IBOutlet NSMatrix*		acqMatrix;
	IBOutlet NSMatrix*		eventConfigMatrix;
	
	IBOutlet NSButton*		stopTriggerButton;
	IBOutlet NSButton*		randomClockButton;
	IBOutlet NSButton*		startDelayEnabledButton;
	IBOutlet NSButton*		stopDelayEnabledButton;
	IBOutlet NSButton*		writeThresholdButton;
	IBOutlet NSButton*		readThresholdButton;
	IBOutlet NSTextField*	startDelayField;
	IBOutlet NSPopUpButton* clockSourcePU;
	IBOutlet NSTextField*	stopDelayField;
	IBOutlet NSPopUpButton* pageSizePU;


    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
    IBOutlet NSButton*      statusButton;
	IBOutlet NSButton*		checkEventButton;
	IBOutlet NSButton*		testMemoryButton;

    //rate page
    IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;

    IBOutlet ORValueBarGroupView*     rate0;
    IBOutlet ORValueBarGroupView*     totalRate;
    IBOutlet NSButton*		 		  rateLogCB;
    IBOutlet NSButton*				  totalRateLogCB;
    IBOutlet ORCompositeTimeLineView* timeRatePlot;
    IBOutlet NSButton*				  timeRateLogCB;
	
    NSView* blankView;
    NSSize  settingSize;
    NSSize  rateSize;
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) enabledChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) energyDividerChanged:(NSNotification*)aNote;
- (void) energySubtractorChanged:(NSNotification*)aNote;
- (void) histogramsEnabledChanged:(NSNotification*)aNote;
- (void) pileupEnabledChanged:(NSNotification*)aNote;
- (void) clrHistogramWithTSChanged:(NSNotification*)aNote;
- (void) writeHitsIntoEventMemoryChanged:(NSNotification*)aNote;

- (void) tauFactorChanged:(NSNotification*)aNote;
- (void) gapTimeChanged:(NSNotification*)aNote;
- (void) peakingTimeChanged:(NSNotification*)aNote;
- (void) heTrigThresholdChanged:(NSNotification*)aNote;
- (void) trigBothEdgesChanged:(NSNotification*)aNote;
- (void) intHeTrigOutPulseChanged:(NSNotification*)aNote;
- (void) intTrigOutPulseBitsChanged:(NSNotification*)aNote;
- (void) activeTrigGateWindowLenChanged:(NSNotification*)aNote;
- (void) rawDataBufferLenChanged:(NSNotification*)aNote;
- (void) rawDataBufferStartChanged:(NSNotification*)aNote;
- (void) accGate1LenChanged:(NSNotification*)aNote;
- (void) accGate1StartChanged:(NSNotification*)aNote;
- (void) accGate2LenChanged:(NSNotification*)aNote;
- (void) accGate2StartChanged:(NSNotification*)aNote;
- (void) accGate3LenChanged:(NSNotification*)aNote;
- (void) accGate3StartChanged:(NSNotification*)aNote;
- (void) accGate4LenChanged:(NSNotification*)aNote;
- (void) accGate4StartChanged:(NSNotification*)aNote;
- (void) accGate5LenChanged:(NSNotification*)aNote;
- (void) accGate5StartChanged:(NSNotification*)aNote;
- (void) accGate6LenChanged:(NSNotification*)aNote;
- (void) accGate6StartChanged:(NSNotification*)aNote;
- (void) accGate7LenChanged:(NSNotification*)aNote;
- (void) accGate7StartChanged:(NSNotification*)aNote;
- (void) accGate8LenChanged:(NSNotification*)aNote;
- (void) accGate8StartChanged:(NSNotification*)aNote;

- (void) csrChanged:(NSNotification*)aNote;
- (void) acqChanged:(NSNotification*)aNote;
- (void) eventConfigChanged:(NSNotification*)aNote;

- (void) stopTriggerChanged:(NSNotification*)aNote;
- (void) randomClockChanged:(NSNotification*)aNote;
- (void) stopDelayChanged:(NSNotification*)aNote;
- (void) startDelayChanged:(NSNotification*)aNote;
- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) stopDelayChanged:(NSNotification*)aNote;
- (void) pageSizeChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) moduleIDChanged:(NSNotification*)aNote;

- (void) scaleAction:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) histogramsEnabledAction:(id)sender;
- (IBAction) pileupEnabledAction:(id)sender;
- (IBAction) clrHistogramsWithTSAction:(id)sender;
- (IBAction) writeHitsIntoEventMemoryAction:(id)sender;
- (IBAction) enabledAction:(id)sender;
- (IBAction) heSuppressTrigModeAction:(id)sender;
- (IBAction) cfdControlAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) energyDividerAction:(id)sender;
- (IBAction) energySubtractorAction:(id)sender;
- (IBAction) tauFactorAction:(id)sender;
- (IBAction) gapTimeAction:(id)sender;
- (IBAction) peakingTimeAction:(id)sender;
- (IBAction) heTrigThresholdAction:(id)sender;
- (IBAction) trigBothEdgesAction:(id)sender;
- (IBAction) intHeTrigOutPulseAction:(id)sender;
- (IBAction) intTrigOutPulseBitsAction:(id)sender;
- (IBAction) activeTrigGateWindowLenActive:(id)sender;
- (IBAction) preTriggerDelayAction:(id)sender;
- (IBAction) rawDataBufferLenAction:(id)sender;
- (IBAction) rawDataBufferStartAction:(id)sender;
- (IBAction) accGate1LenAction:(id)sender;
- (IBAction) accGate1StartAction:(id)sender;
- (IBAction) accGate2LenAction:(id)sender;
- (IBAction) accGate2StartAction:(id)sender;
- (IBAction) accGate3LenAction:(id)sender;
- (IBAction) accGate3StartAction:(id)sender;
- (IBAction) accGate4LenAction:(id)sender;
- (IBAction) accGate4StartAction:(id)sender;
- (IBAction) accGate5LenAction:(id)sender;
- (IBAction) accGate5StartAction:(id)sender;
- (IBAction) accGate6LenAction:(id)sender;
- (IBAction) accGate6StartAction:(id)sender;
- (IBAction) accGate7LenAction:(id)sender;
- (IBAction) accGate7StartAction:(id)sender;
- (IBAction) accGate8LenAction:(id)sender;
- (IBAction) accGate8StartAction:(id)sender;

- (IBAction) writeThresholdsAction:(id)sender;
- (IBAction) readThresholdsAction:(id)sender;
- (IBAction) writeHeTrigThresholdsAction:(id)sender;
- (IBAction) readHeTrigThresholdsAction:(id)sender;

- (IBAction) csrAction:(id)sender;
- (IBAction) acqAction:(id)sender;
- (IBAction) eventConfigAction:(id)sender;
- (IBAction) pageSizeAction:(id)sender;

- (IBAction) stopTriggerAction:(id)sender;
- (IBAction) randomClockAction:(id)sender;
- (IBAction) startDelayEnabledAction:(id)sender;
- (IBAction) stopDelayEnabledAction:(id)sender;
- (IBAction) stopDelayAction:(id)sender;
- (IBAction) startDelayAction:(id)sender;
- (IBAction) clockSourceAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) probeBoardAction:(id)sender;

- (IBAction) testMemoryBankAction:(id)sender;
- (IBAction) checkEvent:(id)sender;

#pragma mark •••Data Source
- (double)  getBarValue:(int)tag;
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end