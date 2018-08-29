//--------------------------------------------------------
// ORMet237Model
// Created by Mark  A. Howe on Fri Jul 22 2005
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files

#import "ORMet237Model.h"
#import "ORSerialPortAdditions.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORTimeRate.h"
#import "ORAlarm.h"

#pragma mark ***External Strings
NSString* ORMet237ModelCountAlarmLimitChanged = @"ORMet237ModelCountAlarmLimitChanged";
NSString* ORMet237ModelMaxCountsChanged = @"ORMet237ModelMaxCountsChanged";
NSString* ORMet237ModelCycleNumberChanged	= @"ORMet237ModelCycleNumberChanged";
NSString* ORMet237ModelCycleWillEndChanged	= @"ORMet237ModelCycleWillEndChanged";
NSString* ORMet237ModelCycleStartedChanged	= @"ORMet237ModelCycleStartedChanged";
NSString* ORMet237ModelRunningChanged		= @"ORMet237ModelRunningChanged";
NSString* ORMet237ModelCycleDurationChanged = @"ORMet237ModelCycleDurationChanged";
NSString* ORMet237ModelCountingModeChanged	= @"ORMet237ModelCountingModeChanged";
NSString* ORMet237ModelCount2Changed		= @"ORMet237ModelCount2Changed";
NSString* ORMet237ModelCount1Changed		= @"ORMet237ModelCount1Changed";
NSString* ORMet237ModelSize2Changed			= @"ORMet237ModelSize2Changed";
NSString* ORMet237ModelSize1Changed			= @"ORMet237ModelSize1Changed";
NSString* ORMet237ModelMeasurementDateChanged = @"ORMet237ModelMeasurementDateChanged";
NSString* ORMet237ModelMissedCountChanged	= @"ORMet237ModelMissedCountChanged";

NSString* ORMet237Lock = @"ORMet237Lock";

@interface ORMet237Model (private)
- (void) timeout;
- (void) processOneCommandFromQueue;
- (void) process_response:(NSString*)theResponse;
- (void) goToNextCommand;
- (void) startTimeOut;
- (void) checkCycle;
- (void) processStatus:(NSString*)aString;
- (void) clearDelay;
- (void) startDataArrivalTimeout;
- (void) cancelDataArrivalTimeout;
- (void) doCycleKick;
- (void) postCouchDBRecord;
@end

@implementation ORMet237Model

#define kMet237CmdTimeout  10

- (id) init
{
	self = [super init];
	[self setMaxCounts:1000];
	[self setCountAlarmLimit:800];
	return self;
}

- (void) dealloc
{
    [cycleWillEnd release];
    [cycleStarted release];
    [measurementDate release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [buffer release];
    [missingCyclesAlarm clearAlarm];
	[missingCyclesAlarm release];
	
	int i;
	for(i=0;i<2;i++){
		[timeRates[i] release];
	}	
	[super dealloc];
}

- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super sleep];
}

- (void) wakeUp
{
	[super wakeUp];
}
- (NSString*) helpURL
{
	return @"RS232/Met237.html";
}
- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"Met237.tif"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORMet237Controller"];
}

- (void) dataReceived:(NSNotification*)note
{
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		
        
        NSString* theString = [[[[NSString alloc] initWithData:[[note userInfo] objectForKey:@"data"] 
												      encoding:NSASCIIStringEncoding] autorelease] uppercaseString];
		
		[self process_response:theString];
	}
}

#pragma mark ***Accessors
- (int) missedCycleCount
{
    return missedCycleCount;
}

- (void) setMissedCycleCount:(int)aValue
{
    missedCycleCount = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelMissedCountChanged object:self];
    
	if((missedCycleCount >= 3) && (countingMode == kMet237Counting)){
		if(!missingCyclesAlarm){
			NSString* s = [NSString stringWithFormat:@"Met637 (Unit %u) Missing Cycles",[self uniqueIdNumber]];
			missingCyclesAlarm = [[ORAlarm alloc] initWithName:s severity:kHardwareAlarm];
			[missingCyclesAlarm setSticky:YES];
            [missingCyclesAlarm setHelpString:@"The particle counter is not reporting counts at the end of its cycle. ORCA tried to kick start it at least three times.\n\nThis alarm will not go away until the problem is cleared. Acknowledging the alarm will silence it."];
			[missingCyclesAlarm postAlarm];
		}
	}
	else {
		[missingCyclesAlarm clearAlarm];
		[missingCyclesAlarm release];
		missingCyclesAlarm = nil;
	}
    
}
- (BOOL) dataForChannelValid:(int)aChannel
{
    return dataValid && [serialPort isOpen];
}

- (float) countAlarmLimit
{
    return countAlarmLimit;
}

- (void) setCountAlarmLimit:(float)aCountAlarmLimit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCountAlarmLimit:countAlarmLimit];
    countAlarmLimit = aCountAlarmLimit;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelCountAlarmLimitChanged object:self];
}

- (float) maxCounts
{
    return maxCounts;
}

- (void) setMaxCounts:(float)aMaxCounts
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxCounts:maxCounts];
    
    maxCounts = aMaxCounts;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelMaxCountsChanged object:self];
}

- (ORTimeRate*)timeRate:(int)index
{
	return timeRates[index];
}

- (int) cycleNumber
{
    return cycleNumber;
}

- (void) setCycleNumber:(int)aCycleNumber
{
    cycleNumber = aCycleNumber;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelCycleNumberChanged object:self];
}

- (NSDate*) cycleWillEnd
{
    return cycleWillEnd;
}

- (void) setCycleWillEnd:(NSDate*)aCycleWillEnd
{
    [aCycleWillEnd retain];
    [cycleWillEnd release];
    cycleWillEnd = aCycleWillEnd;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelCycleWillEndChanged object:self];
}

- (NSDate*) cycleStarted
{
    return cycleStarted;
}

- (void) setCycleStarted:(NSDate*)aCycleStarted
{
    [aCycleStarted retain];
    [cycleStarted release];
    cycleStarted = aCycleStarted;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelCycleStartedChanged object:self];
}

- (BOOL) running
{
    return running;
}

- (void) setRunning:(BOOL)aRunning
{
    running = aRunning;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelRunningChanged object:self];
}

- (int) cycleDuration
{
    return cycleDuration;
}

- (void) setCycleDuration:(int)aCycleDuration
{
	if(aCycleDuration == 0) aCycleDuration = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setCycleDuration:cycleDuration];
    
    cycleDuration = aCycleDuration;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelCycleDurationChanged object:self];
}

- (int) countingMode
{
    return countingMode;
}

- (void) setCountingMode:(int)aCountingMode
{
    countingMode = aCountingMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelCountingModeChanged object:self];
}

- (NSString*) countingModeString
{
	switch ([self countingMode]) {
		case kMet237Counting: return @"Counting";
		case kMet237Holding:  return @"Holding";
		case kMet237Stopped:  return @"Stopped";
		default: return @"--";
	}
}

- (int) count2
{
    return count2;
}

- (void) setCount2:(int)aCount2
{
	//normalize to counts/ft^3
	//flow for this model is .1 ft^3/min
    count2 = aCount2*10/(float)cycleDuration;;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelCount2Changed object:self];
	if(timeRates[1] == nil) timeRates[1] = [[ORTimeRate alloc] init];
	[timeRates[1] addDataToTimeAverage:count2];
}

- (int) count1
{
    return count1;
}

- (void) setCount1:(int)aCount1
{
	//normalize to counts/ft^3
	//flow for this model is .1 ft^3/min
    count1 = aCount1*10/(float)cycleDuration;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelCount1Changed object:self];
	if(timeRates[0] == nil) timeRates[0] = [[ORTimeRate alloc] init];
	[timeRates[0] addDataToTimeAverage:count1];
}

- (float) size2
{
    return size2;
}

- (void) setSize2:(float)aSize2
{
    size2 = aSize2;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelSize2Changed object:self];
}

- (float) size1
{
    return size1;
}

- (void) setSize1:(float)aSize1
{
    size1 = aSize1;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelSize1Changed object:self];
}

- (NSString*) measurementDate
{
	if(!measurementDate)return @"";
    else return measurementDate;
}

- (void) setMeasurementDate:(NSString*)aMeasurementDate
{
    [measurementDate autorelease];
    measurementDate = [aMeasurementDate copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelMeasurementDateChanged object:self];
}

- (uint32_t) timeMeasured
{
	return timeMeasured;
}

- (NSString*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(NSString*)aRequest
{
	[lastRequest autorelease];
	lastRequest = [aRequest copy];    
}


- (void) setUpPort
{
	[serialPort setSpeed:9600];
	[serialPort setParityNone];
	[serialPort setStopBits2:NO];
	[serialPort setDataBits:8];
}

- (void) firstActionAfterOpeningPort
{
	[self universalSelect];
	if(wasRunning)[self startCycle];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	wasRunning = [decoder decodeBoolForKey:@"wasRunning"];
	[self setCycleDuration:		[decoder decodeIntForKey:@"cycleDuration"]];
	[self setCountAlarmLimit:	[decoder decodeFloatForKey:@"countAlarmLimit"]];
	[self setMaxCounts:			[decoder decodeFloatForKey:@"maxCounts"]];
	[[self undoManager] enableUndoRegistration];

	int i; 
	for(i=0;i<2;i++){
		timeRates[i] = [[ORTimeRate alloc] init];
	}
	
	
	return self;
}
- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:	countAlarmLimit forKey:@"countAlarmLimit"];
    [encoder encodeFloat:	maxCounts		forKey:@"maxCounts"];
    [encoder encodeInteger:		cycleDuration	forKey:@"cycleDuration"];
    [encoder encodeBool:	wasRunning		forKey:	@"wasRunning"];
}

#pragma mark *** Commands
- (void) addCmdToQueue:(NSString*)aCmd
{
   if([serialPort isOpen]){ 
	   [self enqueueCmd:aCmd];
	   [self enqueueCmd:@"++Delay"];
		if(!lastRequest){
			[self processOneCommandFromQueue];
		}
	}
}

- (void) initHardware
{
}

- (void) sendAuto					{ [self addCmdToQueue:@"a"]; }
- (void) sendManual					{ [self addCmdToQueue:@"b"]; }
- (void) startCountingByComputer	{ [self addCmdToQueue:@"c"]; }
- (void) startCountingByCounter		{ [self addCmdToQueue:@"d"]; }
- (void) stopCounting				{ [self addCmdToQueue:@"e"]; }
- (void) clearBuffer				{ [self addCmdToQueue:@"C"]; }
- (void) getNumberRecords			{ [self addCmdToQueue:@"D"]; }
- (void) getRevision				{ [self addCmdToQueue:@"E"]; }
- (void) getMode					{ [self addCmdToQueue:@"M"]; }
- (void) getModel					{ [self addCmdToQueue:@"T"]; }
- (void) getRecord					{ [self addCmdToQueue:@"A"]; }
- (void) resendRecord				{ [self addCmdToQueue:@"R"]; }
- (void) goToStandbyMode			{ [self addCmdToQueue:@"h"]; }
- (void) getToActiveMode			{ [self addCmdToQueue:@"g"]; }
- (void) goToLocalMode				{ [self addCmdToQueue:@"l"]; }
- (void) universalSelect			{ [self addCmdToQueue:@"U"]; }

#pragma mark ***Polling and Cycles
- (void) startCycle
{
    [self startCycle:NO];
}
- (void) startCycle:(BOOL)force
{
	if((![self running] || force) && [serialPort isOpen]){
		[self setRunning:YES];
		[self setCycleNumber:1];
		NSDate* now = [NSDate date];
		[self setCycleStarted:now];
        NSDate* endTime = [now dateByAddingTimeInterval:[self cycleDuration]*60];
		[self setCycleWillEnd:endTime];
		[self clearBuffer];
		[self startCountingByComputer];
		[self checkCycle];
		[self getMode];
        [self startDataArrivalTimeout];
		NSLog(@"Met237(%d) Starting particle counter\n",[self uniqueIdNumber]);
	}
}

- (void) stopCycle
{
	if([self running] && [serialPort isOpen]){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkCycle) object:nil];
		[self setRunning:NO];
		[self setCycleNumber:0];
		[self stopCounting];
		[self getMode];
		[self getRecord];
        [self cancelDataArrivalTimeout];
		NSLog(@"Met637(%d) Stopping particle counter\n",[self uniqueIdNumber]);
	}
}

#pragma mark •••Bit Processing Protocol
- (void) processIsStarting
{
	if(!running){
		if(!sentStartOnce){
			sentStartOnce = YES;
			sentStopOnce = NO;
            wasRunning = NO;
			
			[self startCycle:YES];
		}
	}
    else wasRunning = YES;

}

- (void) processIsStopping
{
	if(!wasRunning){
		if(!sentStopOnce){
			sentStopOnce = YES;
			sentStartOnce = NO;
			[self stopCycle];
		}
	}
}

//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{    
	@try { 
	}
	@catch(NSException* localException) { 
		//catch this here to prevent it from falling thru, but nothing to do.
	}
}

- (void) endProcessCycle
{
}

- (NSString*) identifier
{
	NSString* s;
 	@synchronized(self){
		s= [NSString stringWithFormat:@"Met237,%u",[self uniqueIdNumber]];
	}
	return s;
}

- (NSString*) processingTitle
{
	NSString* s;
 	@synchronized(self){
		s= [self identifier];
	}
	return s;
}

- (double) convertedValue:(int)aChan
{
	double theValue;
	@synchronized(self){
		if(aChan==0) theValue = [self count1];
		else		 theValue = [self count2];
	}
	return theValue;
}

- (double) maxValueForChan:(int)aChan
{
	double theValue;
	@synchronized(self){
		theValue = (double)[self maxCounts]; 
	}
	return theValue;
}

- (double) minValueForChan:(int)aChan
{
	return 0;
}

- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		*theLowLimit = -.001;
		*theHighLimit =  [self countAlarmLimit]; 
	}		
}

- (BOOL) processValue:(int)channel
{
	BOOL r;
	@synchronized(self){
		r = YES;    //temp -- figure out what the process bool for this object should be.
	}
	return r;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    //nothing to do. not used in adcs. really shouldn't be in the protocol
}

@end

@implementation ORMet237Model (private)

- (void) postCouchDBRecord
{
    NSDictionary* values = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSArray arrayWithObjects:
                             [NSNumber numberWithInt:count1],
                             [NSNumber numberWithInt:count2],
                              nil], @"counts",
                            [NSNumber numberWithInt:    cycleDuration],    @"pollTime",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
}

- (void) checkCycle
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkCycle) object:nil];
	if(running){
		NSDate* now = [NSDate date];
		if([cycleWillEnd timeIntervalSinceDate:now] >= 0){
			[[NSNotificationCenter defaultCenter] postNotificationName:ORMet237ModelCycleWillEndChanged object:self];
			//[self getMode];
			[self performSelector:@selector(checkCycle) withObject:nil afterDelay:2];
		}
		else {
			//time to end this cycle
			[self stopCounting];
			[self getRecord];

			NSDate* endTime = [now dateByAddingTimeInterval:[self cycleDuration]*60];
			
			[self setCycleStarted:now];
			[self setCycleWillEnd:endTime]; 
			[self startCountingByComputer];
			int theCount = [self cycleNumber];
			[self setCycleNumber:theCount+1];
			[self performSelector:@selector(checkCycle) withObject:nil afterDelay:1];
		}
	}
}
- (void) startDataArrivalTimeout
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCycleKick) object:nil];
    [self performSelector:@selector(doCycleKick)  withObject:nil afterDelay:((cycleDuration*60)+120)];
}

- (void) cancelDataArrivalTimeout
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCycleKick) object:nil];
}

- (void) doCycleKick
{
    [self setMissedCycleCount:missedCycleCount+1];
    NSLogColor([NSColor redColor],@"%@ data did not arrive at end of cycle (missed %d)\n",[self fullID],missedCycleCount);
	NSLogColor([NSColor redColor],@"Kickstarting %@\n",[self fullID]);		
	[self stopCycle];
	[self startCycle:YES];
}

- (void) timeout
{
	recordComingIn = NO;
	statusComingIn = NO;
	[super timeout];
	//[self universalSelect];
}

- (void) recoverFromTimeout
{
}

- (void) goToNextCommand
{
	[self setLastRequest:nil];			 //clear the last request
	[self processOneCommandFromQueue];	 //do the next command in the queue
}

- (void) clearDelay
{
	delay = NO;
	[self processOneCommandFromQueue];
}

- (void) processOneCommandFromQueue
{
	if(delay)return;
	
	NSString* aCmd = [self nextCmd];
	if(aCmd){
		if([aCmd isEqualToString:@"++Delay"]){
			delay = YES;
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearDelay) object:nil];
			[self performSelector:@selector(clearDelay) withObject:nil afterDelay:kMet237DelayTime];
		}
		else {
			[self setLastRequest:aCmd];
			[self startTimeOut];
			[serialPort writeString:aCmd];
		}
	}
	if(!lastRequest){
		[self performSelector:@selector(processOneCommandFromQueue) withObject:nil afterDelay:3];
	}
}

- (void) process_response:(NSString*)theResponse
{
	//NSLog(@"response: %@\n",theResponse);
    dataValid = YES;

	if (recordComingIn){
		if([theResponse rangeOfString:@"#"].location != NSNotFound){	//no records
			recordComingIn = NO;
		}
		else {
			[buffer appendString:theResponse];
			[buffer autorelease];
			buffer = [[[buffer componentsSeparatedByString:@"  "]componentsJoinedByString:@" "] mutableCopy] ;

			NSArray* parts = [buffer componentsSeparatedByString:@" "];
			if([parts count] >= 12){
				NSString* datePart		= [parts objectAtIndex:1];
				NSString* timePart		= [parts objectAtIndex:2];
				NSString* size1Part		= [parts objectAtIndex:4];
				NSString* count1Part	= [parts objectAtIndex:5];
				NSString* size2Part		= [parts objectAtIndex:6];
				NSString* count2Part	= [parts objectAtIndex:7];
				if([datePart length] >= 6 && [timePart length] >= 6){
					[self setMeasurementDate: [NSString stringWithFormat:@"%02d/%02d/%02d %02d:%02d:%02d",
											   [[datePart substringWithRange:NSMakeRange(0,2)]intValue],
											   [[datePart substringWithRange:NSMakeRange(2,2)]intValue],
											   [[datePart substringWithRange:NSMakeRange(4,2)]intValue],
											   [[timePart substringWithRange:NSMakeRange(0,2)]intValue],
											   [[timePart substringWithRange:NSMakeRange(2,2)]intValue],
											   [[timePart substringWithRange:NSMakeRange(4,2)]intValue]
											   ]];
				}
				
				[self setSize1: [size1Part floatValue]];
				[self setCount1: [count1Part intValue]];
				[self setSize2: [size2Part floatValue]];
				[self setCount2: [count2Part intValue]];
								
				recordComingIn = NO;
				[self setMissedCycleCount:0];
				[self startDataArrivalTimeout];
                
                [self postCouchDBRecord];
			}
		}
	}
	else if(statusComingIn){
		[buffer appendString:theResponse];
		if([buffer length] == 2){
			[self processStatus:buffer];
		}
	}

	else if([theResponse hasPrefix:@"a"]){	//Auto Mode
	}
	
	else if([theResponse hasPrefix:@"b"]){	//Manual Mode
	}
	
	else if([theResponse hasPrefix:@"c"]){	//Computer Controlled Start count
	}
	
	else if([theResponse hasPrefix:@"d"]){	//Counter Controlled Start count
	}
	
	else if([theResponse hasPrefix:@"C"]){	//Clear Buffer
	}
	
	else if([theResponse hasPrefix:@"D"]){	//Number of Records
	}
	
	else if([theResponse hasPrefix:@"E"]){	//EProm Version
	}
	
	else if([theResponse hasPrefix:@"M"]){	//Mode Request
		if([theResponse length]<2){
			statusComingIn = YES;
			[buffer release];
			buffer = [[NSMutableString string] retain];
			[buffer appendString:theResponse];	
		}
		else [self processStatus:theResponse];
	}
		
	else if([theResponse hasPrefix:@"A"] | [theResponse hasPrefix:@"R"]){	//Send record
		recordComingIn = YES;
		[buffer release];
		buffer = [[NSMutableString string] retain];
		[buffer appendString:theResponse];	
	}
	
			 
	else if([theResponse hasPrefix:@"R"]){	//resend record
	}
			 
	else if([theResponse hasPrefix:@"h"]){	//standby Mode
	}
			 
	else if([theResponse hasPrefix:@"g"]){	//active Mode
	}
			 
	else if([theResponse hasPrefix:@"l"]){	//active Mode
	}
			 
	else if([theResponse hasPrefix:@"U"]){		//Universal Select
												//do nothing
	}
	
	if(!recordComingIn && !statusComingIn){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
		[self performSelector:@selector(goToNextCommand) withObject:nil afterDelay:1];
	}

	//NSLog(@"%@\n",theResponse);
}

- (void) processStatus:(NSString*)aString
{
	NSString* s = [aString substringWithRange:NSMakeRange(1,1)];
	if([s isEqualToString:@"C"])	  [self setCountingMode:kMet237Counting];
	else if([s isEqualToString:@"H"]) [self setCountingMode:kMet237Holding];
	else if([s isEqualToString:@"S"]) [self setCountingMode:kMet237Stopped];
	statusComingIn = NO;
}

- (void) startTimeOut
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:kMet237CmdTimeout];
}
@end
