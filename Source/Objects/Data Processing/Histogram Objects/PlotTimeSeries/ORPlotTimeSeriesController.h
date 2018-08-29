//
//  ORPlotTimeSeriesController.h
//  Orca
//
//  Created by Mark Howe on Mon Jan 06 2003.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORDataController.h"
@interface ORPlotTimeSeriesController : ORDataController {
}
- (id)   init;
- (void) awakeFromNib;

#pragma mark ���DataSource
- (NSTimeInterval) plotterStartTime:(id)aPlotter;
- (int)	numberPointsInPlot:(id)aPlotter;
- (float)  plotter:(id) aPlotter dataValue:(int)i;
- (void)  plotter:(id) aPlotter index:(int)i x:(double*)x y:(double*)y;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
@end
