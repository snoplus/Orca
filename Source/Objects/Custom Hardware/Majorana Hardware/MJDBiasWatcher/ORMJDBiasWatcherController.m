//--------------------------------------------------------
// ORMJDBiasWatcherController
// Created by Mark  A. Howe on Thursday, Aug 11, 2016
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2016 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina  sponsored in part by the United States
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

#import "ORMJDBiasWatcherController.h"
#import "ORMJDBiasWatcherModel.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"
#import "ORMJDSegmentGroup.h"

@implementation ORMJDBiasWatcherController

#pragma mark ***Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"MJDBiasWatcher"];
	return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
	
    [self performSelector:@selector(setUpPlots) withObject:nil afterDelay:.1];
}

- (void) setUpPlots
{
    [[hvPlotter yAxis] setRngLimitsLow:0.0 withHigh:100 withMinRng:2];
    [[baselinePlotter yAxis] setRngLimitsLow:-11.0 withHigh:11.0 withMinRng:3];
    
    [hvPlotter removeAllPlots];
    int n = [model numberWatched];
    //make tag for each plot so we can tell which to update.
    //
    int i;
    for(i=0;i<n;i++){
        ORTimeLinePlot* aPlot= [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
        [hvPlotter addPlot: aPlot];
        [aPlot setLineColor:[self colorForDataSet:[model watchLookup:i]]];
        [aPlot setName:[model detectorName:i useLookUp:YES]];


        [(ORTimeAxis*)[hvPlotter xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
        [aPlot release];
    }
    
    [baselinePlotter removeAllPlots];
    for(i=0;i<n;i++){
        ORTimeLinePlot* aPlot= [[ORTimeLinePlot alloc] initWithTag:i+kMaxDetectors andDataSource:self];
        [baselinePlotter addPlot: aPlot];
        [aPlot setLineColor:[self colorForDataSet:[model watchLookup:i]]];
        [aPlot setName:[model detectorName:i useLookUp:YES]];
        
        
        [(ORTimeAxis*)[baselinePlotter xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
        [aPlot release];
    }
    [hvPlotter       setShowLegend:YES];
    [baselinePlotter setShowLegend:YES];
    
}

#pragma mark ***Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
		
     [notifyCenter addObserver : self
                     selector : @selector(watchChanged:)
                         name : ORMJDBiasWatcherModelWatchChanged
						object: model];
  
    [notifyCenter addObserver : self
                     selector : @selector(updateTable:)
                         name : ORMJDBiasWatcherForceUpdate
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updatePlots:)
                         name : ORRateAverageChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateTable:)
                         name : ORSegmentGroupConfiguationChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(setUpPlots)
                         name : ORSegmentGroupConfiguationChanged
                       object : nil];

}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"MJD Bias Watcher (Unit %u)",[model uniqueIdNumber]]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self watchChanged:nil];
    [self updatePlots       :nil];
}
- (void) updatePlots:(NSNotification*)aNote
{
    if(!scheduledToUpdatePlot){
        scheduledToUpdatePlot=YES;
        [self performSelector:@selector(deferredPlotUpdate) withObject:nil afterDelay:1];
    }
}

- (void) deferredPlotUpdate
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(deferredPlotUpdate) object:nil];
    scheduledToUpdatePlot = NO;
    [hvPlotter       setNeedsDisplay:YES];
    [baselinePlotter setNeedsDisplay:YES];
}

- (void) updateTable:(NSNotification*)aNote
{
    [detectorTableView reloadData];
}
     
- (void) watchChanged:(NSNotification*)aNote
{
    [detectorTableView reloadData];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [hvPlotter xAxis]){
		[model setMiscAttributes:[(ORAxis*)[hvPlotter xAxis]attributes] forKey:@"XAttributesHv"];
	}
	
	if(aNotification == nil || [aNotification object] == [hvPlotter yAxis]){
		[model setMiscAttributes:[(ORAxis*)[hvPlotter yAxis]attributes] forKey:@"YAttributesHv"];
	}
    
    
    if(aNotification == nil || [aNotification object] == [baselinePlotter xAxis]){
        [model setMiscAttributes:[(ORAxis*)[baselinePlotter xAxis]attributes] forKey:@"XAttributesBaseLine"];
    }
    
    if(aNotification == nil || [aNotification object] == [baselinePlotter yAxis]){
        [model setMiscAttributes:[(ORAxis*)[baselinePlotter yAxis]attributes] forKey:@"YAttributesBaseLine"];
    }
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
    if(aNote == nil || [key isEqualToString:@"XAttributesHv"]){
        if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributesHv"];
        if(attrib){
            [(ORAxis*)[hvPlotter xAxis] setAttributes:attrib];
            [hvPlotter setNeedsDisplay:YES];
            [[hvPlotter xAxis] setNeedsDisplay:YES];
        }
    }
    if(aNote == nil || [key isEqualToString:@"YAttributesHv"]){
        if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributesHv"];
        if(attrib){
            [(ORAxis*)[hvPlotter yAxis] setAttributes:attrib];
            [hvPlotter setNeedsDisplay:YES];
            [[hvPlotter yAxis] setNeedsDisplay:YES];
        }
    }
    
    if(aNote == nil || [key isEqualToString:@"XAttributesBaseLine"]){
        if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributesBaseLine"];
        if(attrib){
            [(ORAxis*)[baselinePlotter xAxis] setAttributes:attrib];
            [baselinePlotter setNeedsDisplay:YES];
            [[baselinePlotter xAxis] setNeedsDisplay:YES];
        }
    }
    if(aNote == nil || [key isEqualToString:@"YAttributesBaseLine"]){
        if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributesBaseLine"];
        if(attrib){
            [(ORAxis*)[baselinePlotter yAxis] setAttributes:attrib];
            [baselinePlotter setNeedsDisplay:YES];
            [[baselinePlotter yAxis] setNeedsDisplay:YES];
        }
    }
}

#pragma mark ***Actions
- (IBAction) pollNowAction:(id)sender
{
	[model pollNow];
}

#pragma mark •••Data Source
- (NSColor*) colorForDataSet:(int)set
{
    switch(set%10){
        case 0:  return [NSColor blackColor];
        case 1:  return [NSColor redColor];
        case 2:  return [NSColor blueColor];
        case 3:  return [NSColor greenColor];
        case 4:  return [NSColor cyanColor];
        case 5:  return [NSColor cyanColor];
        case 6:  return [NSColor magentaColor];
        case 7:  return [NSColor orangeColor];
        case 8:  return [NSColor purpleColor];
        case 9:  return [NSColor brownColor];
        default: return [NSColor redColor];
    }
    return [NSColor redColor];;
}

- (int)	numberPointsInPlot:(id)aPlotter
{
    int theTag = (int)[aPlotter tag];

    if(theTag<kMaxDetectors){
        //hv plot
        return (int)[model numberPointsInHVPlot:theTag];
    }
    else if(theTag >= kMaxDetectors){
        theTag -= kMaxDetectors;
        return (int)[model numberPointsInPreAmpPlot:theTag];
    }
    else return 0;
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
    int theTag = (int)[aPlotter tag];
    if(theTag<kMaxDetectors){
        //hv plot
        int count = (int)[model numberPointsInHVPlot:theTag];
        int index = count-i-1;
        [model hvPlot:theTag dataIndex:index x:xValue y:yValue];
     }
    else {
        theTag -= kMaxDetectors;
        NSUInteger count = [model numberPointsInPreAmpPlot:theTag];
        NSUInteger index = count-i-1;
        [model preAmpPlot:theTag dataIndex:(int)index x:xValue y:yValue];
       
    }
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    if(aTableView == detectorTableView){
        if([[aTableColumn identifier] isEqualToString:@"kDetectorName"]){
            return [model detectorName:rowIndex useLookUp:NO];
        }
        else if([[aTableColumn identifier] isEqualToString:@"kHV"]){
            return [model hvId:rowIndex useLookUp:NO];
        }
        else if([[aTableColumn identifier] isEqualToString:@"kPreAmp"]){
            return [model preAmpId:rowIndex useLookUp:NO];
        }
        else if([[aTableColumn identifier] isEqualToString:@"kWatch"]){
            return [NSNumber numberWithBool:[model watch:rowIndex]];
        }
    }
    return nil;
}


- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if(aTableView == detectorTableView){
        if([[aTableColumn identifier] isEqualToString:@"kWatch"]){
            [model setWatch:rowIndex value:[anObject intValue]];
            [self setUpPlots];
        }
    }
}

// just returns the number of items we have.
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == detectorTableView){
        return [model numberDetectors];
    }
    else return 0;
}



@end


