//--------------------------------------------------------
// ORMJDBiasWatcherModel
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

#pragma mark •••Imported Files
#import "ORMJDBiasWatcherModel.h"
#import "MajoranaModel.h"
#import "ORMJDSegmentGroup.h"
#import "ORiSegHVCard.h"
#import "ORMJDPreAmpModel.h"
#import "ORiSegHVCard.h"
#import "ORTimeRate.h"

#pragma mark •••External Strings
NSString* ORMJDBiasWatcherModelWatchChanged     = @"ORMJDBiasWatcherModelWatchChanged";
NSString* ORMJDBiasWatcherForceUpdate			= @"ORMJDBiasWatcherForceUpdate";

@interface ORMJDBiasWatcherModel (private)
- (void) collectAllObjects;
- (void) collectHvObjs;
- (void) collectPreAmpObjs;
@end

@implementation ORMJDBiasWatcherModel
- (id) init
{
	self = [super init];
	return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [mjd release];
    [hvObjs release];
    [preAmpObjs release];
	[super dealloc];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) wakeUp
{
    [self registerNotificationObservers];
    [self collectAllObjects];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"MJDBiasWatcher.tif"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORMJDBiasWatcherController"];
}

//- (NSString*) helpURL
//{
	//return @"RS232/MJDBiasWatcher.html";
//}

- (void) awakeAfterDocumentLoaded
{
    docReady = YES;
    [self collectAllObjects];
    [self registerNotificationObservers];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDBiasWatcherForceUpdate object:self];

}
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORSegmentGroupConfiguationChanged
                       object : nil];
   
}

- (void) objectsChanged:(NSNotification*)aNote
{
    if(docReady)[self collectAllObjects];
}


#pragma mark •••Accessors
- (BOOL) watch:(int)index
{
    if(index>=0 && index<kMaxDetectors){
        return watch[index];
    }
    else return NO;
}

- (void) setWatch:(int)index value:(BOOL)aFlag;
{
    if(index>=0 && index<kMaxDetectors){
        [[[self undoManager] prepareWithInvocationTarget:self] setWatch:index value:watch[index]];
        watch[index] = aFlag;
        
        int i;
        int ii = 0;
        for(i=0;i<kMaxDetectors;i++){
            watchLookup[ii++] = -1;
        }
        ii =0;
        for(i=0;i<kMaxDetectors;i++){
            if(watch[i]) watchLookup[ii++] = i;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDBiasWatcherModelWatchChanged object:self];

    }
}
- (int) watchLookup:(int)index
{
    if(index>=0 && index < kMaxDetectors)return watchLookup[index];
    else return -1;
}

- (NSString*) detectorName:(int)index { return [self detectorName:index useLookUp:NO]; }
- (NSString*) detectorName:(int)index useLookUp:(BOOL)useLookUp
{
    if(useLookUp)index = watchLookup[index];
    if(index<0)return @"";
    
    NSString* detName = [[mjd segmentGroup:0] segment:index*2 objectForKey:@"kDetectorName"];
    if([detName length]>0 && ![detName hasPrefix:@"-"]){
        return detName;
    }
    else return @"";

}

- (int) numberWatched
{    
    int num = 0;
    int i;
    for(i=0;i<kMaxDetectors;i++){
        if(watch[i])num++;
    }
    return num;
}

- (NSString*) hvId:(int)index { return [self hvId:index useLookUp:NO]; }
- (NSString*) hvId:(int)index useLookUp:(BOOL)useLookUp
{
    if(useLookUp)index = watchLookup[index];
    if(index<0)return @"";

    NSString* detName = [self detectorName:index];
    if([detName length]>0 && ![detName hasPrefix:@"-"]){
        NSString* crate =[[mjd segmentGroup:0] segment:index*2 objectForKey:@"kHVCrate"];
        NSString* card  = [[mjd segmentGroup:0] segment:index*2 objectForKey:@"kHVCard"];
        NSString* chan  = [[mjd segmentGroup:0] segment:index*2 objectForKey:@"kHVChan"];
        return [NSString stringWithFormat:@"%@,%@,%@",crate,card,chan];
    }
    else return @"";
}

- (NSString*) preAmpId:(int)index { return [self preAmpId:index useLookUp:NO]; }
- (NSString*) preAmpId:(int)index useLookUp:(BOOL)useLookUp
{
    if(useLookUp)index = watchLookup[index];
    if(index<0)return @"";

    NSString* detName = [self detectorName:index];
    if([detName length]>0 && ![detName hasPrefix:@"-"]){
        NSString* crate =[[mjd segmentGroup:0] segment:index*2 objectForKey:@"kVME"];
        NSString* card =[[mjd segmentGroup:0] segment:index*2 objectForKey:@"kPreAmpDigitizer"];
        NSString* chan  = [[mjd segmentGroup:0] segment:index*2 objectForKey:@"kPreAmpChan"];
        return [NSString stringWithFormat:@"%@,%@,%@",crate,card,chan];
    }
    else return @"";
}

- (int) numberDetectors
{
    return [[mjd segmentGroup:0] numSegments]/2;
}

- (uint32_t) numberPointsInHVPlot:(int)index
{
     //index is detector segment number
    return [self numberPointsInHvPlot: [self hvObj:index] channel:[self hvChannel:index]];
}

- (uint32_t) numberPointsInPreAmpPlot:(int)index
{
     //index is detector segment number
    uint32_t n =  [self numberPointsInPreAmpPlot: [self preAmpObj:index] channel:[self preAmpChannel:index]];
    return n;
}

- (uint32_t) numberPointsInHvPlot:(ORiSegHVCard*)anHVCard channel:(int)aChan
{
   return (uint32_t)[[anHVCard currentHistory:aChan] count];
}

- (uint32_t) numberPointsInPreAmpPlot:(ORMJDPreAmpModel*)aPreAmpCard channel:(int)aChan
{
    return (uint32_t)[[aPreAmpCard adcHistory:aChan] count];
}

//scripting method for testing
- (void) addValueToHV:(int)index value:(float)aValue
{
     ORiSegHVCard* theHvCard = [self hvObj:index];
    int hvChan = [self hvChannel:index];
    [theHvCard makeCurrentHistory:hvChan];
    ORTimeRate* theHistory = [theHvCard currentHistory:hvChan];
    [theHistory addDataToTimeAverage:aValue];
}

- (void) addValueToPreAmp:(int)index value:(float)aValue
{
    ORMJDPreAmpModel* thePreAmp = [self preAmpObj:index];
    int chan = [self preAmpChannel:index];
    ORTimeRate* theHistory = [thePreAmp adcHistory:chan];
    [theHistory addDataToTimeAverage:aValue];
}

- (void) hvPlot:(int)index dataIndex:(int)dataIndex x:(double*)xValue y:(double*)yValue
{
    ORiSegHVCard* theHvCard = [self hvObj:index];
    int hvChan = [self hvChannel:index];
    ORTimeRate* theHistory = [theHvCard currentHistory:hvChan];
    [theHistory setSampleTime:1];
    *xValue = [theHistory timeSampledAtIndex:dataIndex];
    *yValue = [theHistory valueAtIndex:dataIndex];
}

- (void) preAmpPlot:(int)index dataIndex:(int)dataIndex x:(double*)xValue y:(double*)yValue
{
    ORMJDPreAmpModel* thePreAmpCard = [self preAmpObj:index];
    int chan = [self preAmpChannel:index];
    ORTimeRate* theHistory = [thePreAmpCard adcHistory:chan];
    [theHistory setSampleTime:1];
    *xValue = [theHistory timeSampledAtIndex:dataIndex];
    *yValue = [theHistory valueAtIndex:dataIndex];
}

- (int) hvChannel:(int)index
{
    index = watchLookup[index];
    if(index<0)return 0;
    NSString* key = [self hvId:index];
    //this will include crate,card,chan. We have to strip off the chan part
    NSUInteger lastCommaPosition = [key rangeOfString:@"," options:NSBackwardsSearch].location;
    if(lastCommaPosition == NSNotFound)return 0;
    else {
        return [[key substringFromIndex:lastCommaPosition+1] intValue];
    }
}

- (ORiSegHVCard*) hvObj:(int)index
{
    index = watchLookup[index];
    if(index<0)return nil;

    NSString* key = [self hvId:index];
    //this will include crate,card,chan. We have to strip off the chan part
    int lastCommaPosition = (int)[key rangeOfString:@"," options:NSBackwardsSearch].location;
    if(lastCommaPosition == NSNotFound)return nil;
    else {
        key = [key substringWithRange:NSMakeRange(0,lastCommaPosition)];
        return [hvObjs objectForKey:key];
    }
}

- (int) preAmpChannel:(int)index
{
    index = watchLookup[index];
    if(index<0)return 0;
    NSString* key = [self preAmpId:index];
    //this will include crate,card,chan. We have to strip off the chan part
    NSUInteger lastCommaPosition = [key rangeOfString:@"," options:NSBackwardsSearch].location;
    if(lastCommaPosition == NSNotFound)return 0;
    else {
        return [[key substringFromIndex:lastCommaPosition+1] intValue];
    }
}

- (ORMJDPreAmpModel*) preAmpObj:(int)index
{
    index = watchLookup[index];
    if(index<0)return nil;
    NSString* key = [self preAmpId:index];
    //this will include crate,card,chan. We have to strip off the chan part
    int lastCommaPosition = (int)[key rangeOfString:@"," options:NSBackwardsSearch].location;
    if(lastCommaPosition == NSNotFound)return nil;
    else {
        key = [key substringWithRange:NSMakeRange(0,lastCommaPosition)];
        return [preAmpObjs objectForKey:key];
    }
}


#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];

    [[self undoManager] disableUndoRegistration];
    int i;
    for(i=0;i<kMaxDetectors;i++){
        [self setWatch:i value:[decoder decodeBoolForKey:[@"watch" stringByAppendingFormat:@"%d",i]]];
    }
	[[self undoManager] enableUndoRegistration];
    

	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    int i;
    for(i=0;i<kMaxDetectors;i++){
        [encoder encodeBool:watch[i] forKey:[@"watch" stringByAppendingFormat:@"%d",i]];
    }
}

- (NSString*) identifier
{
	NSString* s;
 	@synchronized(self){
		s= [NSString stringWithFormat:@"MJDBiasWatcher,%u",[self uniqueIdNumber]];
	}
	return s;
}
- (void) pollNow
{
    //collect the watched preAmps
    NSMutableSet* watchedPreAmps = [NSMutableSet set];
    int i;
    for(i=0;i<kMaxDetectors;i++){
        ORMJDPreAmpModel* aPreAmpObj = [self preAmpObj:i];
        if(aPreAmpObj){
            [watchedPreAmps addObject:aPreAmpObj];
        }
        
    }
    [watchedPreAmps makeObjectsPerformSelector:@selector(pollValues)];
}
@end

@implementation ORMJDBiasWatcherModel (private)

- (void) collectAllObjects
{
    [mjd release];
    mjd = nil;
    NSArray* mjdObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"MajoranaModel")];
    if([mjdObjects count])mjd = [[mjdObjects objectAtIndex:0] retain];
    
    [self collectPreAmpObjs];
    [self collectHvObjs];
}

- (void) collectHvObjs
{
    [hvObjs release];
    hvObjs = nil;
    hvObjs = [[NSMutableDictionary dictionary] retain];
    NSArray* hvObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORiSegHVCard")];
    for(ORiSegHVCard* anHVObj in hvObjects){
        NSString* aKey = [NSString stringWithFormat:@"%d,%d",[anHVObj crateNumber],[anHVObj slot]];
        [hvObjs setObject:anHVObj forKey:aKey];
    }
}

- (void) collectPreAmpObjs
{
    [preAmpObjs release];
    preAmpObjs = nil;
    preAmpObjs = [[NSMutableDictionary dictionary] retain];
    NSArray* preAmpObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMJDPreAmpModel")];
    for(ORMJDPreAmpModel* aPreAmp in preAmpObjects){
        NSString* aKey = [NSString stringWithFormat:@"%d,%d",[aPreAmp connectedGretinaCrate],[aPreAmp connectedGretinaSlot]];
        [preAmpObjs setObject:aPreAmp forKey:aKey];
    }
}

@end
