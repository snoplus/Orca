//
//  ORAugerFireWireCard.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24, 2006.
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



#pragma mark ���imports
#import "ORAugerFireWireCard.h"
#import "ORAugerCrateModel.h"
#import "ORFireWireInterface.h"
#import "ORAlarm.h"

#import <IOKit/IOKitLib.h>

NSString* ORAugerInterfaceChanged	= @"ORAugerInterfaceChanged";
NSString* ORAugerPBusSimChanged		= @"ORAugerPBusSimChanged";

@implementation ORAugerFireWireCard

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(attemptConnection) object:nil];
    [fireWireInterface release];
	[simulationAlarm clearAlarm];
	[simulationAlarm release];
    [super dealloc];
}

- (void) sleep
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(attemptConnection) object:nil];
	[super sleep];
}

- (void) awakeAfterDocumentLoaded
{
	NS_DURING
		[self findInterface];	
	NS_HANDLER
	NS_ENDHANDLER
}

- (NSDictionary*) matchingDictionary
{
	return nil;
}


#pragma mark ���Accessors
- (ORFireWireInterface*) fireWireInterface
{
    return fireWireInterface;
}

- (void) setFireWireInterface:(ORFireWireInterface*)aFwInterface
{
    [aFwInterface retain];
    [fireWireInterface release];
    fireWireInterface = aFwInterface;

	[fireWireInterface open];
	
	if(!fireWireInterface){
		[self startConnectionAttempts];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(attemptConnection) object:nil];
	}
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAugerInterfaceChanged object:self];

}

- (void) setGuardian:(id)aGuardian
{
    if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self];			
		}
	}
    else [[self guardian] setAdapter:nil];

    [super setGuardian:aGuardian];
}

- (BOOL) pBusSim
{
	return pBusSim;
}

- (void) setPBusSim:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPBusSim:pBusSim];	
	pBusSim = flag;
	[self checkSimulationAlarm];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAugerPBusSimChanged object:self];
}


- (void) checkSimulationAlarm
{
	if(pBusSim){
		NSLogColor([NSColor redColor],@"========================================\n");
		NSLogColor([NSColor redColor],@"Warning: Running in simulation mode - no real access to the Firewire interface\n");
		NSLogColor([NSColor redColor],@"========================================\n");
		
		if(!simulationAlarm){
			simulationAlarm = [[ORAlarm alloc] initWithName:@"Running in simulation mode" severity:kSetupAlarm];
			[simulationAlarm setSticky:YES];
			[simulationAlarm setAcknowledged:NO];	
		}
		[simulationAlarm postAlarm];
	}
	else {
		[simulationAlarm clearAlarm];
	}
}

- (id) controller
{
	//there is no controller in this case. The connection is via FireWire.
	//so just return nil so no one can use it by mistake.
    return nil;
}

- (BOOL) serviceIsOpen
{
	if(!pBusSim)return [fireWireInterface isOpen];
	else return YES;
}

- (BOOL) serviceIsAlive
{
	if(!pBusSim){
		if(!fireWireInterface)[self findInterface];
		return [fireWireInterface serviceAlive];
	}
	else return YES;
}

- (void) startConnectionAttempts
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(attemptConnection) object:nil];
	[self performSelector:@selector(attemptConnection) withObject:nil afterDelay:15];
}

- (void) attemptConnection
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(attemptConnection) object:nil];

	[self findInterface];
	if(!fireWireInterface)[self performSelector:@selector(attemptConnection) withObject:nil afterDelay:15];
}

#pragma mark ���Notifications
- (void) registerNotificationObservers
{	
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
			   
    [notifyCenter addObserver : self
                     selector : @selector(serviceChanged:)
                         name : ORFireWireInterfaceServiceAliveChanged
                       object : fireWireInterface];
    

    [notifyCenter addObserver : self
                     selector : @selector(serviceChanged:)
                         name : ORFireWireInterfaceIsOpenChanged
                       object : fireWireInterface];

}

- (void) serviceChanged:(NSNotification*)aNote
{
	//re-post to the crate with this object as the sender
	if([aNote object] != guardian){
		[[NSNotificationCenter defaultCenter] postNotificationName:[aNote name] object:guardian userInfo:[aNote userInfo]];
	}
	if([aNote object] == fireWireInterface){
		if(![fireWireInterface isOpen]){
			//[self startConnectionAttempts]; //TDB MAH 10/03/05
		}
	}
}

#pragma mark ���HW Access
- (void) findInterface
{
	//subclass responsiblity
}


- (void) dumpROM
{
	if(fireWireInterface){	
		NSLog(@"AugerSLT (station %d)\n",[self stationNumber]);
		[fireWireInterface printConfigROM];
	}
	else if(!pBusSim){
		NSLogColor([NSColor redColor],@"No Firewire Service: check cables and power!\n");
		[NSException raise:@"ORFireWireInterface" format:@"No Firewire Service: check cables and power"];
	}
}

- (uint32_t) read:(uint32_t) address
{
	if(fireWireInterface) return [fireWireInterface read_raw:address];
	else {
		if(!pBusSim){
			NSLogColor([NSColor redColor],@"No Firewire Service: check cables and power!\n");
			[NSException raise:@"ORFireWireInterface" format:@"No Firewire Service: check cables and power"];
		}
		else return 0;
	}
	return 0;
}


- (void) read:(uint64_t) address data:(uint32_t*)theData size:(uint32_t)len;
{ 
	if(fireWireInterface) {
	    [fireWireInterface read_raw:address data:theData size:len];
	} 
	else {
		if(!pBusSim){
			NSLogColor([NSColor redColor],@"No Firewire Service: check cables and power!\n");
			[NSException raise:@"ORFireWireInterface" format:@"No Firewire Service: check cables and power"];
		}
		else {
			int i;
			for (i=0;i<len/sizeof(uint32_t);i++){
			  theData[i] = ((2*i+1) << 16) + (2*i);
			}
			//NSLog(@"Simulated data: %08x %08x %08x\n", theData[0], theData[1], theData[2]);
		}
	}
	return;
}


- (void) write:(uint32_t) address value:(uint32_t) aValue
{
	if(fireWireInterface)[fireWireInterface write_raw:address value:aValue];
	else if(!pBusSim){
		NSLogColor([NSColor redColor],@"No Firewire Service: check cables and power!\n");
		[NSException raise:@"ORFireWireInterface" format:@"No Firewire Service: check cables and power"];
	}
}


- (void) writeBitsAtAddress:(uint32_t)address 
					   value:(uint32_t)dataWord 
					   mask:(uint32_t)aMask 
					shifted:(int)shiftAmount
{
	if(fireWireInterface){
		uint32_t buffer = [fireWireInterface read_raw:address];
		buffer =(buffer & ~(aMask<<shiftAmount) ) | (dataWord << shiftAmount);
		[fireWireInterface write_raw:address value:buffer];
	}
	else if(!pBusSim){
		NSLogColor([NSColor redColor],@"No Firewire Service: check cables and power!\n");
		[NSException raise:@"ORFireWireInterface" format:@"No Firewire Service: check cables and power"];
	}
}

- (void) setBitsLowAtAddress:(uint32_t)address 
						mask:(uint32_t)aMask
{
	if(fireWireInterface){
		uint32_t buffer = [fireWireInterface read_raw:address];
		buffer = (buffer & ~aMask );
		[fireWireInterface write_raw:address value:buffer];
	}
	else if(!pBusSim){
		NSLogColor([NSColor redColor],@"No Firewire Service: check cables and power!\n");
		[NSException raise:@"ORFireWireInterface" format:@"No Firewire Service: check cables and power"];
	}
}
						
- (void) setBitsHighAtAddress:(uint32_t)address 
						 mask:(uint32_t)aMask
{
	if(fireWireInterface){
		uint32_t buffer = [fireWireInterface read_raw:address];
		buffer = (buffer | aMask );
		[fireWireInterface write_raw:address value:buffer];
	}
	else if(!pBusSim){
		NSLogColor([NSColor redColor],@"No Firewire Service: check cables and power!\n");
		[NSException raise:@"ORFireWireInterface" format:@"No Firewire Service: check cables and power"];
	}
}

- (void) readRegisterBlock:(uint32_t)  anAddress 
				dataBuffer:(uint32_t*) aDataBuffer
					length:(uint32_t)  length 
				 increment:(uint32_t)  incr
			   numberSlots:(uint32_t)  nSlots 
			 slotIncrement:(uint32_t)  incrSlots
{
	if(fireWireInterface){
		int i,j;
		for(i=0;i<nSlots;i++) {
			for(j=0;j<length;j++) {
				aDataBuffer[i*length + j] = [fireWireInterface read_raw:(anAddress + i*incrSlots + j*incr)]; // Slots start with id 1 !!!
			}
		}

	}
	else if(!pBusSim){
		NSLogColor([NSColor redColor],@"No Firewire Service: check cables and power!\n");
		[NSException raise:@"ORFireWireInterface" format:@"No Firewire Service: check cables and power"];
	}
}

- (void) readBlock:(uint32_t)  anAddress 
		dataBuffer:(uint32_t*) aDataBuffer
			length:(uint32_t)  length 
		 increment:(uint32_t)  incr
{
	if(fireWireInterface){
		int i;
		for(i=0;i<length;i++) {
			aDataBuffer[i] = [fireWireInterface read_raw:anAddress + i*incr];
		}
	}
	else if(!pBusSim){
		NSLogColor([NSColor redColor],@"No Firewire Service: check cables and power!\n");
		[NSException raise:@"ORFireWireInterface" format:@"No Firewire Service: check cables and power"];
	}
}

- (void) writeBlock:(uint32_t)  anAddress 
		 dataBuffer:(uint32_t*) aDataBuffer
			 length:(uint32_t)  length 
		  increment:(uint32_t)  incr
{
	if(fireWireInterface){
		int i;
		for(i=0;i<length;i++) {
			[fireWireInterface write_raw:anAddress + i*incr value:aDataBuffer[i]];
		}
	}
	else if(!pBusSim){
		NSLogColor([NSColor redColor],@"No Firewire Service: check cables and power!\n");
		[NSException raise:@"ORFireWireInterface" format:@"No Firewire Service: check cables and power"];
	}
	
}

- (void) clearBlock:(uint32_t)  anAddress 
		 pattern:(uint32_t) aPattern
			 length:(uint32_t)  length 
		  increment:(uint32_t)  incr
{
	if(fireWireInterface){
		int i;
		for(i=0;i<length;i++) {
			[fireWireInterface write_raw:anAddress + i*incr value:aPattern];
		}
	}
	else if(!pBusSim){
		NSLogColor([NSColor redColor],@"No Firewire Service: check cables and power!\n");
		[NSException raise:@"ORFireWireInterface" format:@"No Firewire Service: check cables and power"];
	}
	
}


#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	[self setPBusSim:[decoder decodeBoolForKey:@"pBusSim"]];
	[[self undoManager] enableUndoRegistration];

	[self registerNotificationObservers];

	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeBool:pBusSim forKey:@"pBusSim"];
	[super encodeWithCoder:encoder];
}


@end
