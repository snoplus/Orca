//
//  ResistorDBViewController.m
//  Orca
//
//  Created by Chris Jones on 28/04/2014.
//
//

#import "ResistorDBViewController.h"

@interface ResistorDBViewController ()

@end

@implementation ResistorDBViewController

-(id)init
{
    self = [super initWithWindowNibName:@"ResistorDBWindow"];
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void) updateWindow
{
	[super updateWindow];
    
}

- (void) registerNotificationObservers
{
	//NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];
}

@end
