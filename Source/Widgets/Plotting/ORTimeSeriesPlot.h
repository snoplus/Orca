//
//  ORTimeSeries.h
//  Orca
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of  
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the progrzam should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORPlotWithROI.h"

@interface NSObject (ORORTimeSeriesPlotDataSourceMethods)
- (void) plotter:(id)aPlot index:(int)index time:(uint32_t*)xValue y:(float*)yValue;
- (NSTimeInterval) plotterStartTime:(id)aPlot;
@end

@interface ORTimeSeriesPlot : ORPlotWithROI {
}

#pragma mark ***Data Source Setup
- (void) setDataSource:(id)ds;

#pragma mark ***Drawing
- (void) drawData;
- (void) drawExtras;

@end

