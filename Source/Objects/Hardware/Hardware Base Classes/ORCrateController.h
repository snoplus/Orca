//
//  ORCrateController.h
//  Orca
//
//  Created by Mark Howe on 9/30/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORCardContainerView.h"

@class ORCrateLabelView;

@interface ORCrateController : OrcaObjectController {
    IBOutlet NSTextField*   lockDocField;
	IBOutlet NSButton*		showLabelsButton;
    IBOutlet NSTextField*   powerField;
    IBOutlet ORCardContainerView*   groupView;
    IBOutlet ORCrateLabelView*   labelView;
}

#pragma mark *Accessors
- (ORGroupView *)groupView;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) groupChanged:(NSNotification*)note;
- (void) documentLockChanged:(NSNotification*)aNotification;
- (void) powerFailed:(NSNotification*)aNotification;
- (void) powerRestored:(NSNotification*)aNotification;
- (void) crateNumberChanged:(NSNotification*)aNotification;
- (void) updateView:(NSNotification*)aNotification;

#pragma mark •••Interface Management
- (void) showLabelsChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) setCrateTitle;

#pragma mark •••Actions
- (IBAction) showLabelsAction:(id)sender;
@end
