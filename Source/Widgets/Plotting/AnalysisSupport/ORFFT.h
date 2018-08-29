//
//  ORFFT.h
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
@interface NSObject (ORFFTDataSourceMethods)
- (int)   numberPointsInPlot:(id)aPlot;
- (void)  plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y;
- (BOOL)  plotterShouldShowRoi:(id)aPlot;
- (id)    plotView;
- (id)    topPlot;
- (id)    roi;
- (id)    xScale;
- (id)    yScale;
@end


@interface ORFFT : NSObject {
    id				dataSource;
	BOOL			serviceAvailable;
	int32_t				maxChannel;
	int32_t				minChannel;
	int32_t				fftOption;
	int32_t             fftWindow;

}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;

#pragma mark ***Accessors
- (void)	setDataSource:(id)ds;
- (id)		dataSource ;
- (BOOL) serviceAvailable;
- (int32_t) minChannel;
- (void) setMinChannel:(int32_t)aChannel;
- (int32_t) maxChannel;
- (void) setMaxChannel:(int32_t)aChannel;
- (int32_t) fftOption;
- (void) setFftOption:(int32_t)aValue;
- (int32_t) fftWindow;
- (void) setFftWindow:(int32_t)aValue;

#pragma mark ***FFT Handling
- (void) doFFT;
- (void) processResponse:(NSDictionary*)aResponse;

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORFFTOptionChanged;
extern NSString* ORFFTWindowChanged;
