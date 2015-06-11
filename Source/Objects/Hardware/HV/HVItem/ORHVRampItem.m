//
//  ORHVRampItem.m
//  test
//
//  Created by Mark Howe on 3/29/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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
#import "ORHVRampItem.h"

@implementation ORHVRampItem
- (NSString*) itemName
{
	return [NSString stringWithFormat:@"Voltage Channel %d",channelNumber];
}
- (void) loadTargetObject
{
	[self setTargetObject:owner];
}

- (void) loadParameterObject
{
	//fake out...
	[self setParameterObject:owner];
}
- (void) loadProxyObjects
{
}

- (void) loadHardware
{
	//load to hardware
	@try {
		if([owner respondsToSelector:@selector(loadDac:)]){
			[owner loadDac:[self channelNumber]];
		}
	}
	@catch(NSException* localException) {
		[self stopRamper];
		ORRunAlertPanel([localException name], @"%@\n\nRamp Stopped for %@", @"OK", nil, nil,
						localException,[self itemName]);
	}
}


@end
