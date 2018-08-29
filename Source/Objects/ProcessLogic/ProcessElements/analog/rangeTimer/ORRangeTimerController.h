//
//  ORRangeTimerController.h
//  Orca
//
//  Created by Mark Howe on Fri Sept 8, 2006.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORProcessHwAccessorController.h"

@interface ORRangeTimerController : ORProcessHwAccessorController {
	IBOutlet NSTextField*	deadBandTextField;
	IBOutlet NSButton*		enableMailButton;
	IBOutlet NSTextField*	limitTextField;
	IBOutlet NSPopUpButton* directionPU;
	IBOutlet NSTableView*	addressList;
	IBOutlet NSButton* 		removeAddressButton;
	IBOutlet NSButton* 		addAddressButton;
}

#pragma mark ���Initialization
-(id)init;

#pragma mark ���Interface Management
- (void) enableMailChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) directionChanged:(NSNotification*)aNote;
- (void) limitChanged:(NSNotification*)aNote;
- (void) deadBandChanged:(NSNotification*)aNote;
- (void) addressesChanged:(NSNotification*)aNote;
- (void)setButtonStates;
- (void) selectionChanged:(NSNotification*)aNote;


#pragma mark ���Actions
- (IBAction) enableMailAction:(id)sender;
- (IBAction) deadBandAction:(id)sender;
- (IBAction) limitAction:(id)sender;
- (IBAction) directionAction:(id)sender;
- (IBAction) addAddressAction:(id)sender;
- (IBAction) removeAddressAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;

#pragma mark ���DataSource
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

@end
