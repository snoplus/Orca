//
//  ResistorDBViewController.m
//  Orca
//
//  Created by Chris Jones on 28/04/2014.
//
//

#import "ResistorDBViewController.h"
#import "ResistorDBModel.h"

@interface ResistorDBViewController ()
@property (assign) IBOutlet NSProgressIndicator *loadingFromDbWheel;

@end

@implementation ResistorDBViewController
@synthesize loadingFromDbWheel;

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

-(IBAction)queryResistorDB:(id)sender
{
    //check to see if actual values have been given
    if(([crateSelect stringValue] != nil) && ([cardSelect stringValue] != nil) && ([channelSelect stringValue] != nil)){
        
        int crateNumber = [[crateSelect stringValue] intValue];
        int cardNumber = [[cardSelect stringValue] intValue];
        int channelNumber = [[channelSelect stringValue] intValue];
        NSLog(@"value: %i %i %i",crateNumber,cardNumber,channelNumber);
        
        [loadingFromDbWheel setHidden:NO];
        [loadingFromDbWheel startAnimation:nil];
        [model queryResistorDb:crateNumber withCard:cardNumber withChannel:channelNumber];
    }
}

-(NSString*) parseStatusFromResistorDb:(NSString*)aKey withTrueStatement:(NSString*)aTrueStatement withFalseStatement:(NSString*)aFalseStatement
{
    if([[[model currentQueryResults] objectForKey:aKey] isEqualToString:@"0"]){
        return aFalseStatement;
    }
    else if([[[model currentQueryResults] objectForKey:aKey] isEqualToString:@"1"]){
        return aTrueStatement;
    }
    else{
        NSLog(@"ResistorDb:Setting to unknown state");
        return @"";
    }
}

-(NSString*) parseStatusToResistorDb:(NSString*)aControllerKey withTrueStatement:(NSString*)aTrueStatement withFalseStatement:(NSString*)aFalseStatement
{
    //return for YES/NO options in resistor GUI
    if([aControllerKey isEqualToString:@"NO"]){
        return aFalseStatement;
    }
    else if([aControllerKey isEqualToString:@"YES"]){
        return aTrueStatement;
    }
    //return for resistor pulled status in resistor GUI
    else if([aControllerKey isEqualToString:@"Not Pulled"]){
        return aFalseStatement;
    }
    else if([aControllerKey isEqualToString:@"Pulled"]){
        return aTrueStatement;
    }
    else{
        return @"Unknown State";
    }
}

-(void)resistorDbQueryLoaded
{
    //NSLog(@"in here");
    [loadingFromDbWheel setHidden:YES];
    [loadingFromDbWheel stopAnimation:nil];
    //NSLog(@"model value pulled Cable %@",[[model currentQueryResults] objectForKey:@"pulledCable"]);
    //NSLog(@"model results %@",[model currentQueryResults]);
    
    //Values to load
    NSString *resistorStatus;
    NSString *SNOLowOccString;
    NSString *pmtRemovedString;
    NSString *pmtReinstalledString;
    NSString *badCableString;
    NSString *pulledCableString;
    NSString *reason;
    NSString *info;
    
    @try{
        resistorStatus = [self parseStatusFromResistorDb:@"rPulled" withTrueStatement:@"Pulled" withFalseStatement:@"Not Pulled"];
        SNOLowOccString = [self parseStatusFromResistorDb:@"SnoLowOcc" withTrueStatement:@"YES" withFalseStatement:@"NO"];
        pmtRemovedString = [self parseStatusFromResistorDb:@"PmtRemoved" withTrueStatement:@"YES" withFalseStatement:@"NO"];
        pmtReinstalledString = [self parseStatusFromResistorDb:@"PmtReInstalled" withTrueStatement:@"YES" withFalseStatement:@"NO"];
        badCableString = [self parseStatusFromResistorDb:@"BadCable" withTrueStatement:@"YES" withFalseStatement:@"NO"];
        
        reason = [[model currentQueryResults] objectForKey:@"reason"];
        info = [[model currentQueryResults] objectForKey:@"info"];
        
        //pulledCable isn't a string but an integer!!!
        if([[[[model currentQueryResults] objectForKey:@"pulledCable"] stringValue] isEqualToString:@"0"]){
            pulledCableString = @"NO";
        }
        else if([[[[model currentQueryResults] objectForKey:@"pulledCable"] stringValue] isEqualToString:@"1"]){
            pulledCableString = @"YES";
        }
        else{
            pulledCableString = @"Unknown Cable State";
        }
        
        
        //load the values to the screen
        [currentResistorStatus setStringValue:resistorStatus];
        [currentSNOLowOcc setStringValue:SNOLowOccString];
        [currentPulledCable setStringValue:pulledCableString];
        [currentPMTReinstallled setStringValue:pmtReinstalledString];
        [currentPMTRemoved setStringValue:pmtRemovedString];
        [currentBadCable setStringValue:badCableString];
        [currentReason setStringValue:reason];
        [currentInfo setStringValue:info];
        
        
        [updateResistorStatus setStringValue:resistorStatus];
        [updateSnoLowOcc setStringValue:SNOLowOccString];
        [updatePulledCable setStringValue:pulledCableString];
        [updatePmtReinstalled setStringValue:pmtReinstalledString];
        [updatePmtRemoved setStringValue:pmtRemovedString];
        [updateBadCable setStringValue:badCableString];
        
        
    
        //reasonbox
        NSString *reasonString = [[model currentQueryResults] objectForKey:@"reason"];
        if([reasonString isEqualToString:NULL]){
            reasonString = @"";
        }
        [updateReasonBox setStringValue:reasonString];
        
        //infoBox
        NSString *infoString = [[model currentQueryResults] objectForKey:@"info"];
        if([infoString isEqualToString:NULL]){
            infoString = @"";
        }
        [updateInfoForPull setStringValue:infoString];
        [self updateWindow];
        
        
    }
    
    @catch(NSException *e){
        NSLog(@"CouchDb Parse Error %@",e);
    }
    
}

-(IBAction)updatePmtDatabase:(id)sender
{
    //fetch the values from the database
    NSMutableDictionary *resistorDocDic = [[NSMutableDictionary alloc] initWithCapacity:10];
    int crateNumber = [[crateSelect stringValue] intValue];
    int cardNumber = [[cardSelect stringValue] intValue];
    int channelNumber = [[channelSelect stringValue] intValue];
    NSString *resistorStatus = [self parseStatusToResistorDb:[updateResistorStatus stringValue] withTrueStatement:@"1" withFalseStatement:@"0"];
    NSString *SNOLowOccString = [self parseStatusToResistorDb:[updateSnoLowOcc stringValue] withTrueStatement:@"1" withFalseStatement:@"0"];
    NSString *pmtRemovedString = [self parseStatusToResistorDb:[updatePmtRemoved stringValue] withTrueStatement:@"1" withFalseStatement:@"0"];
    NSString *pmtReinstalledString = [self parseStatusToResistorDb:[updatePmtReinstalled stringValue] withTrueStatement:@"1" withFalseStatement:@"0"];
    NSString *badCableString = [self parseStatusToResistorDb:[updateBadCable stringValue] withTrueStatement:@"1" withFalseStatement:@"0"];
    NSString *pulledCableString = [self parseStatusToResistorDb:[updatePulledCable stringValue] withTrueStatement:@"1" withFalseStatement:@"0"];
    
    NSString *reasonString;
    //if another reason is given then place this in the database otherwise use one of the default values
    if([[updateReasonBox stringValue] isEqualToString:@"OTHER"]){
        reasonString = [updateReasonOther stringValue]; //update from the other reason box
    }
    else{
        reasonString = [updateReasonBox stringValue];   //update from the reason string 
    }
    
    NSString *infoString = [updateInfoForPull stringValue];
    [resistorDocDic setObject:[NSNumber numberWithInt:cardNumber] forKey:@"slot"];
    [resistorDocDic setObject:infoString forKey:@"info"];
    [resistorDocDic setObject:pmtRemovedString forKey:@"PmtRemoved"];
    [resistorDocDic setObject:SNOLowOccString forKey:@"SnoLowOcc"];
    [resistorDocDic setObject:[[model currentQueryResults] objectForKey:@"SnoPmt"] forKey:@"SnoPmt"];
    [resistorDocDic setObject:[NSNumber numberWithInt:crateNumber] forKey:@"crate"];
    [resistorDocDic setObject:badCableString forKey:@"BadCable"];
    [resistorDocDic setObject:reasonString forKey:@"reason"];
    [resistorDocDic setObject:resistorStatus forKey:@"rPulled"];
    [resistorDocDic setObject:@"" forKey:@"NewPmt"];
    [resistorDocDic setObject:@"" forKey:@"date"];
    [resistorDocDic setObject:[NSNumber numberWithInt:[pulledCableString intValue]] forKey:@"pulledCable"];
    [resistorDocDic setObject:pmtReinstalledString forKey:@"PmtReInstalled"];
    [resistorDocDic setObject:[NSNumber numberWithInt:channelNumber] forKey:@"channel"];
    
    [model updateResistorDb:resistorDocDic];
    [resistorDocDic release];
    
    //update the current query value
    NSLog(@"value: %i %i %i",crateNumber,cardNumber,channelNumber);
    [loadingFromDbWheel setHidden:NO];
    [loadingFromDbWheel startAnimation:nil];
    [model queryResistorDb:crateNumber withCard:cardNumber withChannel:channelNumber];

}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];
    
	[notifyCenter addObserver : self
                     selector : @selector(resistorDbQueryLoaded)
                         name : resistorDBQueryLoaded
                        object: model];
}

@end
