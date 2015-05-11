//-------------------------------------------------------------------------
//  ORSciptTaskModel.m
//
//  Created by Mark A. Howe on Tuesday 12/26/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORScriptTaskModel.h"
#import "ORScriptInterface.h"
#import "ORScriptRunner.h"
#import "ORMailer.h"
#import "ORStatusController.h"

NSString*  ORScriptTaskInConnector			= @"ORScriptTaskInConnector";
NSString*  ORScriptTaskOutConnector			= @"ORScriptTaskOutConnector";

@implementation ORScriptTaskModel

#pragma mark ***Initialization

- (void) dealloc 
{
    [task setDelegate:nil];
    [task release];
    task = nil;
	[externVariablePool release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize-4,[self frame].size.height-kConnectorSize) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORScriptTaskInConnector];
	[aConnector setOffColor:[NSColor brownColor]];
	[aConnector setConnectorType: 'SCRI'];
	[aConnector addRestrictedConnectionType: 'SCRO']; //can only connect to Script Outputs
    [aConnector release];
 
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize-4,0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORScriptTaskOutConnector];
	[aConnector setOffColor:[NSColor brownColor]];
	[aConnector setConnectorType: 'SCRO'];
	[aConnector addRestrictedConnectionType: 'SCRI']; //can only connect to Script Inputs
    [aConnector release];
    
}

- (void) connectionChanged
{
	[self setUpImage];
}

- (void) doShiftCmdClick:(id)sender atPoint:(NSPoint)aPoint
{
    if(enableIconControls){
        if(NSPointInRect(aPoint,[self frame])){
            if([self running]) [self stopScript];
            else [self runScript];
        }
    }
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"ScriptTask"];
	    
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
	[self decorateIcon:i];
    
    
	if([self breakChain] && [self objectConnectedTo: ORScriptTaskOutConnector]){
        NSImage* theImage = [NSImage imageNamed:@"chainBroken"];
        [theImage drawAtPoint:NSZeroPoint fromRect:[theImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
	}	
    if([self running]){
        NSImage* theImage = [NSImage imageNamed:@"ScriptRunning"];
        [theImage drawAtPoint:NSZeroPoint fromRect:[theImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    }
    
	if(enableIconControls){
        NSImage* theImage;
        if([self running])theImage = [NSImage imageNamed:@"Stop"];
        else              theImage = [NSImage imageNamed:@"Play"];
         [theImage drawInRect:NSMakeRect(3,3,25,25) fromRect:[theImage imageRect] operation:NSCompositeSourceOver fraction:1];
    }
	
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORForceRedraw
                      object: self];

}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    
    [task wakeUp];
}
- (void) sleep
{
    [super sleep];    
    [task sleep];
}

- (void) installTasks:(NSNotification*)aNote
{
    if(!task){
        task = [[ORScriptInterface alloc] init];
    }
    [task setDelegate:self];
    [task wakeUp];
}

#pragma mark ���Notifications
- (void) registerNotificationObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(runningChanged:)
                         name : ORScriptRunnerRunningChanged
						object: nil];	
}

- (void) runningChanged:(NSNotification*)aNote
{
	[self setUpImage];
}

#pragma mark ***Script Methods
- (id) nextScriptConnector
{
	return ORScriptTaskOutConnector;
}

- (void) setMessage:(NSString*)aMessage
{
	[task setMessage:aMessage];
}

- (void) sendStatusLogTo:(NSString*)receipients cc:(NSString*)cc subject:(NSString*)subject
{
	[self sendMailTo:receipients cc:cc subject:subject content:[[ORStatusController sharedStatusController] contents]];
}

- (void) sendStatusLogTo:(NSString*)receipients cc:(NSString*)cc subject:(NSString*)subject lastSeconds:(unsigned long)aDuration
{
	[self sendMailTo:receipients cc:cc subject:subject content:[[ORStatusController sharedStatusController] contentsTail:aDuration]];
}

- (void) sendMailTo:(NSString*)receipients cc:(NSString*)cc subject:(NSString*)subject content:(NSString*)theContent
{
	@synchronized([NSApp delegate]){
		ORMailer* mailer = [ORMailer mailer];
		[mailer setTo:receipients];
		[mailer setSubject:subject];
        
        NSArray* parts = [theContent componentsSeparatedByString:@"\\n"];
        NSString* escapedString = [parts componentsJoinedByString:@"\n"];

		NSAttributedString* s = [[NSAttributedString alloc] initWithString:escapedString];
		[mailer setBody:s];
		[mailer send:self];
		[s release];
	}
}

- (void) mailSent:(NSString*)to
{
	NSLog(@"Script sent mail to: %@\n",to);
}

- (void) setExternalVariable:(id)aKey to:(id)aValue
{
	@synchronized(self){
		if(!externVariablePool)externVariablePool = [[NSMutableDictionary dictionary] retain];
		if(aKey!=nil){
			[externVariablePool setObject:aValue forKey:aKey]; 
		}
		else {
			NSException* e =  [NSException exceptionWithName:@"illegal variables" reason:@"The script external pool can not hold nil keys" userInfo:nil];
			@throw(e);
		}
	}
}

- (id) externalVariable:(id)aKey
{
	id result = nil;
	@synchronized(self){
		result = [externVariablePool objectForKey:aKey];
		if(!result)result = [NSDecimalNumber numberWithInt:0];
	}
	return result;
}

#pragma mark ���Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
		
    task = [[decoder decodeObjectForKey:@"task"] retain];
    [self installTasks:nil];
	[task setTitle:scriptName];
    [[self undoManager] enableUndoRegistration];
	[self registerNotificationObservers];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:task forKey:@"task"];
}


- (void) taskDidStart:(NSNotification*)aNote
{
	//this really means a task is about to start....
	id reportingTask = [aNote object];

	if(reportingTask != task){
		if([task taskState] == eTaskRunning || [task taskState] == eTaskWaiting){
			[task stopTask];
		}
	}


  //  [self shipTaskRecord:[aNote object] running:YES];
}

- (void) taskDidFinish:(NSNotification*)aNote
{
   // [self shipTaskRecord:[aNote object] running:NO];
}



@end
