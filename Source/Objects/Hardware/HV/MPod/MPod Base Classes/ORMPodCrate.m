//
//  ORMPodCrate.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORMPodCrate.h"
#import "ORMPodCModel.h"
#import "ORMPodCard.h"
#import "ORiSegHVCard.h"

NSString* ORMPodCrateConstraintsChanged				= @"ORMPodCrateConstraintsChanged";


@interface ORMPodCrate (private)
- (void) slowPoll;
- (void) postCouchDBRecord;
@end

@implementation ORMPodCrate
- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[hvConstraints release];
    [super dealloc];
}

- (void) wakeUp
{
	[super wakeUp];
    [self slowPoll];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) makeConnectors
{
}
- (void) connected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(connected)];
}

- (void) disconnected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(disconnected)];
}
#pragma mark •••Accessors
- (NSString*) adapterArchiveKey
{
	return @"MPod Adapter";
}

- (NSString*) crateAdapterConnectorKey
{
	return @"MPod Crate Adapter Connector";
}

- (void) setAdapter:(id)anAdapter
{
	[super setAdapter:anAdapter];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORMPodCardSlotChangedNotification
                       object : nil];
 
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORiSegHVCardConstraintsChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORMPodCrateConstraintsChanged
                       object : nil];

    
    [notifyCenter addObserver : self
                     selector : @selector(powerFailed:)
                         name : @"MPodPowerFailedNotification"
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"MPodPowerRestoredNotification"
                       object : nil];
    
    [self slowPoll];

}

- (id) controllerCard
{
	return adapter;
}


- (void) pollCratePower
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollCratePower) object:nil];
    @try {
        if(polledOnce)[[self controllerCard] checkCratePower];
		polledOnce = YES;
    }
	@catch(NSException* localException) {
    }
    [self performSelector:@selector(pollCratePower) withObject:nil afterDelay:1];
}

- (void) powerFailed:(NSNotification*)aNotification
{
    if([aNotification object] == [self controllerCard]){
        [self setPowerOff:YES];
		if(!cratePowerAlarm){
			cratePowerAlarm = [[ORAlarm alloc] initWithName:@"No MPod Communication" severity:0];
			[cratePowerAlarm setSticky:YES];
			[cratePowerAlarm setHelpStringFromFile:@"NoMPodCratePowerHelp"];
			[cratePowerAlarm postAlarm];
		}
    }
}

- (void) powerRestored:(NSNotification*)aNotification
{
    if([aNotification object] == [self controllerCard]){
        [self setPowerOff:NO];
		[cratePowerAlarm clearAlarm];
		[cratePowerAlarm release];
		cratePowerAlarm = nil;
    }
}

- (BOOL) hvOnAnyChannel
{
    for(id anObj in [self orcaObjects]){
        if([anObj isKindOfClass:NSClassFromString(@"ORiSegHVCard")]){
            if([anObj hvOnAnyChannel])return YES;
        }
    }
    return NO;
}

- (int) numberChannelsWithNonZeroVoltage
{
    int count=0;
    for(id anObj in [self orcaObjects]){
        if([anObj isKindOfClass:NSClassFromString(@"ORiSegHVCard")]){
            count += [(ORiSegHVCard*)anObj numberChannelsWithNonZeroVoltage];
        }
    }
    return count;
}

- (id) cardInSlot:(int)aSlot
{
    for(id anObj in [self orcaObjects]){
        if([(ORiSegHVCard*)anObj isKindOfClass:NSClassFromString(@"ORiSegHVCard")]){
            if([(ORiSegHVCard*)anObj slot] == aSlot)return anObj;
        }
    }
    return nil;
}

#pragma mark •••All card cmds
- (void) panicAllChannels
{
    for(id anObj in [self orcaObjects]){
        if([(ORiSegHVCard*)anObj isKindOfClass:NSClassFromString(@"ORiSegHVCard")]){
            [(ORiSegHVCard*)anObj panicAllChannels];
        }
    }
}

#pragma mark •••Constraints
- (void) addHvConstraint:(NSString*)aName reason:(NSString*)aReason
{
	if(!hvConstraints)hvConstraints = [[NSMutableDictionary dictionary] retain];
    if(![hvConstraints objectForKey:aName]){
        [hvConstraints setObject:aReason forKey:aName];
        [self setUpImage];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCrateConstraintsChanged object:self];
        NSLogColor([NSColor redColor],@"%@: HV constraint added: %@ -- %@\n",[self fullID],aName,aReason);
    }
}
- (void) removeHvConstraint:(NSString*)aName
{
    if([hvConstraints objectForKey:aName]){
        [hvConstraints removeObjectForKey:aName];
        [self setUpImage];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCrateConstraintsChanged object:self];
        NSLog(@"%@: HV constraint removed: %@\n",[self fullID],aName);
    }
}
- (NSDictionary*)hvConstraints		 { return hvConstraints;}

- (NSString*) constraintReport
{
    NSString* s = @"";
    for(id aKey in hvConstraints){
        s = [s stringByAppendingFormat:@"%@ : %@\n",aKey,[hvConstraints objectForKey:aKey]];
    }
    return s;
}

@end

@implementation ORMPodCrate (private)
- (void) slowPoll
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(slowPoll) object:nil];
    [self postCouchDBRecord];
    [self performSelector:@selector(slowPoll) withObject:nil afterDelay:30.0];
}

- (void) postCouchDBRecord
{
    NSMutableDictionary* theSupplies  = [NSMutableDictionary dictionary];
    NSDictionary* systemParams = nil;
    NSMutableDictionary* theModules = [NSMutableDictionary dictionary];
    
    int numChannelsWithVoltage = 0;
    int numChannelsRamping     = 0;
    @synchronized(adapter){
        for(id anObj in [self orcaObjects]){
            if([anObj isKindOfClass:NSClassFromString(@"ORiSegHVCard")]){
                ORiSegHVCard* anHVCard = (ORiSegHVCard*)anObj;
                NSMutableArray* theChannels = [NSMutableArray array];
                int i;
                for(i=0;i<[anHVCard numberOfChannels];i++){
                    NSMutableDictionary* params = [[anHVCard rdParams:i]mutableCopy];
                    if(params){
                        [params setObject:[NSNumber numberWithInt:[anHVCard target:i]]     forKey:@"target"];
                        [params setObject:[NSNumber numberWithFloat:[anHVCard maxCurrent:i]] forKey:@"maxCurrent"];
                        [params setObject:[NSNumber numberWithInt:i] forKey:@"Channel"];
                        [theChannels addObject:params];
                    }
                    [params release];
                }
                
                NSDictionary* modParams = [anHVCard modParams];
                if(modParams){
                    [theModules setObject:modParams forKey:[NSString stringWithFormat:@"%d",[anHVCard slot]-1] ];
                }
                
                numChannelsWithVoltage += [anHVCard numberChannelsWithNonZeroVoltage];
                numChannelsRamping     += [anHVCard numberChannelsRamping];
                if(theChannels){
                    [theSupplies setObject:theChannels forKey:[NSString stringWithFormat:@"%d",[anHVCard slot]-1]];
                }

            }
            else if(anObj == adapter){
                [systemParams release]; //make sure there is only one.
                systemParams = [[[adapter parameterDictionary] objectForKey:@"0"] copy];
                if(!systemParams)systemParams = [[NSDictionary dictionary] retain];
            }
        }
        
        NSDictionary* values = [NSDictionary dictionaryWithObjectsAndKeys:
                                systemParams, @"system",
                                theSupplies,  @"supplies",
                                theModules, @"modules",
                                [NSNumber numberWithInt:numChannelsWithVoltage],@"NumberChannelsOn",
                                [NSNumber numberWithInt:numChannelsRamping],@"NumberChannelsRamping",
                                nil];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
    }
    [systemParams release];
}

@end

@implementation ORMPodCrate (OROrderedObjHolding)
- (int) slotAtPoint:(NSPoint)aPoint
{
	//fist slot is special and half width
	if(aPoint.x<15)	return 0;
	else			return floor(((int)aPoint.x - 15)/[self objWidth]) + 1;
}

- (NSPoint) pointForSlot:(int)aSlot
{
	if(aSlot==0) return NSMakePoint(0,0);
	else		 return NSMakePoint((aSlot-1)*[self objWidth] + 15,0);
}


- (NSRange) legalSlotsForObj:(id)anObj
{
	if( [anObj isKindOfClass:NSClassFromString(@"ORMPodCModel")]){
		return NSMakeRange(0,1);
	}
	else {
		return  NSMakeRange(1,[self maxNumberOfObjects]);
	}
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj
{
	if(![anObj isKindOfClass:NSClassFromString(@"ORMPodCModel")] && (aSlot==0)){
		return YES;
	}
	else return NO;
}

- (int) maxNumberOfObjects	{ return 11; } //default to full-size crate -- subclasses can override
- (int) objWidth			{ return 30;}  //default to full-size crate -- subclasses can override
@end

