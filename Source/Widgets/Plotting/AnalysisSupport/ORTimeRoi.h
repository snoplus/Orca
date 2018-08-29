//
//  ORTimeRoi.h
//  Orca
//
//  Created by Mark Howe on 2/13/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
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
@class ORPlot;
@class ORPlotView;

@interface NSObject (ORTimeRoiDataSourceMethods)
- (int)   numberPointsInPlot:(id)aPlot;
- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y;
- (id)    plotView;
- (id)    topPlot;
@end

enum {
    kInitialDrag,
    kMinDrag,
    kMaxDrag,
    kCenterDrag,
    kNoDrag
};

@interface ORTimeRoi : NSObject {
    id			dataSource;
	int32_t		minChannel;
	int32_t		maxChannel;
	double		average;
	double		minValue;
	double		maxValue;
	double      standardDeviation;
	
	double			startChan;
	BOOL			dragInProgress;
	int				dragType;
	int             gate1,gate2;
	NSString*		label;
}

#pragma mark ***Initialization
- (id) initWithMin:(int32_t)aMin max:(int32_t)aMax;
- (void) dealloc;

#pragma mark ***Accessors
- (void)	setDataSource:(id)ds;
- (void)	setLabel:(NSString*)aLabel;
- (NSString*) label;
- (id)		dataSource ;
- (int32_t)	minChannel;
- (void)	setMinChannel:(int32_t)aChannel;
- (int32_t)	maxChannel;
- (void)	setMaxChannel:(int32_t)aChannel;
- (void)	setDefaultMin:(int32_t)aMinChannel max:(int32_t)aMaxChannel;
- (double)	average;	
- (double)	standardDeviation;	
- (double)   minValue;	
- (double)   maxValue;	

#pragma mark ***Analysis
- (void) analyzeData;

#pragma mark ***Event Handling
- (void) flagsChanged:(NSEvent *)theEvent;
- (BOOL) mouseDown:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotView;
- (void) mouseDragged:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotView;
- (void) mouseUp:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotter;
- (void) shiftRight;
- (void) shiftLeft;

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORTimeRoiMinChanged;
extern NSString* ORTimeRoiMaxChanged;
extern NSString* ORTimeRoiAnalysisChanged;
