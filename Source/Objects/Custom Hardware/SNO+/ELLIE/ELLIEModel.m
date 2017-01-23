//
//  ELLIEModel.m
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//  Revision history:
//  Ed Leming 30/12/2015 - Memory updates and tidy up.
//
//

/*TODO:
        - Check the standard run name doesn't already exsists in the DB
        - read from and write to the local couch DB for both smellie and tellie
        - fix the intensity steps in SMELLIE such that negative values cannot be considered
        - add the TELLIE GUI Information
        - add the sockets for TELLIE to communicate with itself
        - add the AMELLIE GUI
        - make sure old files cannot be overridden 
        - add the configuration files GUI for all the ELLIE systems (LOW PRIORITY)
        - add the Emergency stop button 
        - make the SMELLIE Control functions private (eventually)
*/

#import "ELLIEModel.h"
#import "ORTaskSequence.h"
#import "ORCouchDB.h"
#import "ORRunModel.h"
#import "SNOPModel.h"
#import "ORMTCModel.h"
#import "TUBiiModel.h"
#import "TUBiiController.h"
#import "ORRunController.h"
#import "ORMTC_Constants.h"
#import "SNOP_Run_Constants.h"
#import "SNOPGlobals.h"

//tags to define that an ELLIE run file has been updated
#define kSmellieRunDocumentAdded   @"kSmellieRunDocumentAdded"
#define kSmellieRunDocumentUpdated   @"kSmellieRunDocumentUpdated"
#define kTellieRunDocumentAdded   @"kTellieRunDocumentAdded"
#define kTellieRunDocumentUpdated   @"kTellieRunDocumentUpdated"
#define kAmellieRunDocumentAdded   @"kAmellieRunDocumentAdded"
#define kAmellieRunDocumentUpdated   @"kAmellieRunDocumentUpdated"
#define kSmellieRunHeaderRetrieved   @"kSmellieRunHeaderRetrieved"
#define kSmellieConfigHeaderRetrieved @"kSmellieConfigHeaderRetrieved"

//sub run information tags
#define kSmellieSubRunDocumentAdded @"kSmellieSubRunDocumentAdded"

NSString* ELLIEAllLasersChanged = @"ELLIEAllLasersChanged";
NSString* ELLIEAllFibresChanged = @"ELLIEAllFibresChanged";
NSString* smellieRunDocsPresent = @"smellieRunDocsPresent";
NSString* ORSMELLIERunFinished = @"ORSMELLIERunFinished";
NSString* ORTELLIERunFinished = @"ORTELLIERunFinished";



///////////////////////////////
// Define private methods
@interface ELLIEModel (private)
-(void) _pushEllieCustomRunToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile withDocType:(NSString*)aDocType;
-(void) _pushEllieConfigDocToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile withDocType:(NSString*)aDocType;
-(NSString*) stringDateFromDate:(NSDate*)aDate;
-(void) _pushSmellieRunDocument;
//-(void) _pushSmellieConfigDocument;
@end


//////////////////////////////
// Begin implementation
@implementation ELLIEModel

// Use synthesize to generate all our setters and getters.
// Be explicit about which instance variables to associate
// with each.
@synthesize tellieFireParameters = _tellieFireParameters;
@synthesize tellieFibreMapping = _tellieFibreMapping;
@synthesize tellieNodeMapping = _tellieNodeMapping;
@synthesize tellieRunDoc = _tellieRunDoc;
@synthesize tellieSubRunSettings = _tellieSubRunSettings;

@synthesize smellieRunSettings = _smellieRunSettings;
@synthesize smellieRunHeaderDocList = _smellieRunHeaderDocList;
@synthesize smellieSubRunInfo = _smellieSubRunInfo;
@synthesize smellieLaserHeadToSepiaMapping = _smellieLaserHeadToSepiaMapping;
@synthesize smellieLaserHeadToGainMapping = _smellieLaserHeadToGainMapping;
@synthesize smellieLaserToInputFibreMapping = _smellieLaserToInputFibreMapping;
@synthesize smellieFibreSwitchToFibreMapping = _smellieFibreSwitchToFibreMapping;
@synthesize smellieSlaveMode = _smellieSlaveMode;
@synthesize smellieConfigVersionNo = _smellieConfigVersionNo;
@synthesize smellieRunDoc = _smellieRunDoc;
@synthesize smellieDBReadInProgress = _smellieDBReadInProgress;

@synthesize tellieClient = _tellieClient;
@synthesize smellieClient = _smellieClient;

@synthesize ellieFireFlag = _ellieFireFlag;
@synthesize exampleTask = _exampleTask;
@synthesize pulseByPulseDelay = _pulseByPulseDelay;
@synthesize currentOrcaSettingsForSmellie = _currentOrcaSettingsForSmellie;


/*********************************************************/
/*                  Class control methods                */
/*********************************************************/
- (id) init
{
    self = [super init];
    if (self){
        XmlrpcClient* tellieCli = [[XmlrpcClient alloc] initWithHostName:@"builder1" withPort:@"5030"];
        XmlrpcClient* smellieCli = [[XmlrpcClient alloc] initWithHostName:@"snodrop" withPort:@"5020"];
        [self setTellieClient:tellieCli];
        [self setSmellieClient:smellieCli];
        [[self tellieClient] setTimeout:10];
        [[self smellieClient] setTimeout:360];
        [tellieCli release];
        [smellieCli release];
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];
    if (self){
        XmlrpcClient* tellieCli = [[XmlrpcClient alloc] initWithHostName:@"builder1" withPort:@"5030"];
        XmlrpcClient* smellieCli = [[XmlrpcClient alloc] initWithHostName:@"snodrop" withPort:@"5020"];
        [self setTellieClient:tellieCli];
        [self setSmellieClient:smellieCli];
        [[self tellieClient] setTimeout:10];
        [[self smellieClient] setTimeout:360];
        [tellieCli release];
        [smellieCli release];
    }
    return self;
}

- (void) setUpImage
{
    [self setSmellieDBReadInProgress:NO];
    [self setImage:[NSImage imageNamed:@"ellie"]];
}

- (void) makeMainController
{
    [self linkToController:@"ELLIEController"];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
}

- (void) sleep
{
	[super sleep];
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Release all NSObject member vairables
    [_smellieRunSettings release];
    [_currentOrcaSettingsForSmellie release];
    [_tellieRunDoc release];
    [_smellieRunDoc release];
    [_exampleTask release];
    [_smellieRunHeaderDocList release];
    [_smellieSubRunInfo release];
    
    //Server Clients
    [_tellieClient release];
    [_smellieClient release];
    
    //tellie settings
    [_tellieSubRunSettings release];
    [_tellieFireParameters release];
    [_tellieFibreMapping release];
    
    //smellie config mappings
    [_smellieLaserHeadToSepiaMapping release];
    [_smellieLaserHeadToGainMapping release];
    [_smellieLaserToInputFibreMapping release];
    [_smellieFibreSwitchToFibreMapping release];
    [_smellieConfigVersionNo release];
    [super dealloc];
}

- (void) registerNotificationObservers
{
     NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    //we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
}

/*********************************************************/
/*                    TELLIE Functions                   */
/*********************************************************/
-(NSArray*) pollTellieFibre:(double)timeOutSeconds
{
    /*
     Poll the TELLIE hardware using an XMLRPC server and requests the response from the
     hardware. If no response is observed the the hardware is re-polled once every second
     untill a timeout limit has been reached.

     Arguments:
       double timeOutSeconds :  How many seconds to wait before polling is considered a
                                failure and an exception thrown.

    */
    NSArray* blankResponse = [NSArray arrayWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:0], nil];
    NSArray* pollResponse = [[self tellieClient] command:@"read_pin_sequence"];
    int count = 0;
    NSLog(@"[TELLIE]: Will poll for pin response for the next %1.1f s\n", timeOutSeconds);
    while ([pollResponse isKindOfClass:[NSString class]] && count < timeOutSeconds){
        // Check the thread hasn't been cancelled
        if([[NSThread currentThread] isCancelled]){
            return blankResponse;
        }
        [NSThread sleepForTimeInterval:1.0];
        pollResponse = [[self tellieClient] command:@"read_pin_sequence"];
        count = count + 1;
    }
    
    // Some checks on the response
    if ([pollResponse isKindOfClass:[NSString class]]){
        NSLogColor([NSColor redColor], @"[TELLIE]: PIN diode poll returned %@. Likely that the sequence didn't finish before timeout.", pollResponse);
        return blankResponse;
    } else if ([pollResponse count] != 3) {
        NSLogColor([NSColor redColor], @"[TELLIE]: PIN diode poll returned array of len %i - expected 3", [pollResponse count]);
        return blankResponse;
    }
    return pollResponse;
}

-(NSMutableDictionary*) returnTellieFireCommands:(NSString*)fibre withNPhotons:(NSUInteger)photons withFireFrequency:(NSUInteger)frequency withNPulses:(NSUInteger)pulses withTriggerDelay:(NSUInteger)delay inSlave:(BOOL)mode
{
    /*
     Calculate the tellie fire commands given certain input parameters
    */
    NSNumber* tellieChannel = [self calcTellieChannelForFibre:fibre];
    if([tellieChannel intValue] < 0){
        return nil;
    }

    NSNumber* pulseWidth = [self calcTellieChannelPulseSettings:[tellieChannel integerValue] withNPhotons:photons withFireFrequency:frequency inSlave:mode];
    if([pulseWidth intValue] < 0){
        return nil;
    }
    
    NSString* modeString;
    if(mode == YES){
        modeString = @"Slave";
    } else {
        modeString = @"Master";
    }
    float pulseSeparation = 1000.*(1./frequency); // TELLIE accepts pulse rate in ms
    NSNumber* fibre_delay = [[[self tellieFireParameters] objectForKey:[NSString stringWithFormat:@"channel_%d",[tellieChannel intValue]]] objectForKey:@"fibre_delay"];
    
    NSMutableDictionary* settingsDict = [NSMutableDictionary dictionaryWithCapacity:100];
    [settingsDict setValue:fibre forKey:@"fibre"];
    [settingsDict setValue:tellieChannel forKey:@"channel"];
    [settingsDict setValue:modeString forKey:@"run_mode"];
    [settingsDict setValue:[NSNumber numberWithInteger:photons] forKey:@"photons"];
    [settingsDict setValue:pulseWidth forKey:@"pulse_width"];
    [settingsDict setValue:[NSNumber numberWithFloat:pulseSeparation] forKey:@"pulse_separation"];
    [settingsDict setValue:[NSNumber numberWithInteger:pulses] forKey:@"number_of_shots"];
    [settingsDict setValue:[NSNumber numberWithInteger:delay] forKey:@"trigger_delay"];
    [settingsDict setValue:[NSNumber numberWithFloat:[fibre_delay floatValue]] forKey:@"fibre_delay"];
    [settingsDict setValue:[NSNumber numberWithInteger:16383] forKey:@"pulse_height"];
    return settingsDict;
}

-(NSNumber*) calcTellieChannelPulseSettings:(NSUInteger)channel withNPhotons:(NSUInteger)photons withFireFrequency:(NSUInteger)frequency inSlave:(BOOL)mode
{
    /*
     Calculate the pulse width settings required to return a given intenstity from a specified channel, 
     at a specified rate.
    */
    // Check if fire parameters have been successfully loaded
    if([self tellieFireParameters] == nil){
        NSLogColor([NSColor redColor], @"[TELLIE]: TELLIE_FIRE_PARMETERS doc has not been loaded from telliedb - you need to call loadTellieStaticsFromDB");
        return 0;
    }
    
    // Run photon intensity check
    bool safety_check = [self photonIntensityCheck:photons atFrequency:frequency];
    if(safety_check == NO){
        NSLogColor([NSColor redColor], @"[TELLIE]: The requested number of photons (%lu), is not detector safe at %lu Hz. This setting will not be run.\n", photons, frequency);
        return [NSNumber numberWithInt:-1];
    }
    
    // Frequency check
    if(frequency != 1000){
        NSLogColor([NSColor orangeColor], @"[TELLIE]: CAUTION calibrations are only valid at 1kHz. Photon output may vary from requested setting\n");
    }
    
    // Used modality to define a string prefix for reading from database file
    NSString* prefix;
    if(mode == YES){
        prefix = @"slave";
    } else {
        prefix = @"master";
    }
    
    // Get Calibration parameters
    NSArray* IPW_values = [[[self tellieFireParameters] objectForKey:[NSString stringWithFormat:@"channel_%d",channel]] objectForKey:[NSString stringWithFormat:@"%@_IPW",prefix]];
    NSArray* photon_values = [[[self tellieFireParameters] objectForKey:[NSString stringWithFormat:@"channel_%d",channel]] objectForKey:[NSString stringWithFormat:@"%@_photons",prefix]];

    ////////////
    // Find minimum calibration point. If request is below minimum, estiamate the IPW
    // setting and inform the user.
    float min_photons = [[photon_values valueForKeyPath:@"@min.self"] floatValue];
    int min_x = [[IPW_values objectAtIndex:[photon_values indexOfObject:[photon_values valueForKeyPath:@"@min.self"]]] intValue];
    if(photons < min_photons){
        NSLog(@"[TELLIE]: Calibration curve for channel %lu does not go as low as %lu photons\n", channel, photons);
        NSLog(@"[TELLIE]: Using a linear interpolation of -5ph/IPW from min_photons = %.1f to estimate requested %d photon settings\n",min_photons,photons);
        float intercept = min_photons - (-5.*min_x);
        float floatPulseWidth = (photons - intercept)/(-5.);
        NSNumber* pulseWidth = [NSNumber numberWithInteger:floatPulseWidth];
        return pulseWidth;
    }
    
    /////////////
    // If requested photon output is within range, find xy points above and below threshold.
    // Appropriate setting will be estiamated with a linear interpolation between these points.
    int index = 0;
    for(NSNumber* val in photon_values){
        if([val floatValue] < photons){
            break;
        }
        index = index + 1;
    }
    float x1 = [[IPW_values objectAtIndex:(index-1)] floatValue];
    float x2 = [[IPW_values objectAtIndex:(index)] floatValue];
    float y1 = [[photon_values objectAtIndex:(index-1)] floatValue];
    float y2 = [[photon_values objectAtIndex:(index)] floatValue];
    
    // Calculate gradient and offset for interpolation.
    float dydx = (y1 - y2)/(x1 - x2);
    float intercept = y1 - dydx*x1;
    float floatPulseWidth = (photons - intercept) / dydx;
    NSNumber* pulseWidth = [NSNumber numberWithInteger:floatPulseWidth];

    return pulseWidth;
}

-(NSNumber*)calcPhotonsForIPW:(NSUInteger)ipw forChannel:(NSUInteger)channel inSlave:(BOOL)inSlave
{
    /*
     Calculte what photon output will be produced for a given IPW
     */
    
    /////////////
    // Used modality to define a string prefix for reading from database file
    NSString* prefix;
    if(inSlave == YES){
        prefix = @"slave";
    } else {
        prefix = @"master";
    }
    
    //////////////
    // Get Calibration parameters
    NSArray* IPW_values = [[[self tellieFireParameters] objectForKey:[NSString stringWithFormat:@"channel_%d",channel]] objectForKey:[NSString stringWithFormat:@"%@_IPW",prefix]];
    NSArray* photon_values = [[[self tellieFireParameters] objectForKey:[NSString stringWithFormat:@"channel_%d",channel]] objectForKey:[NSString stringWithFormat:@"%@_photons",prefix]];
    
    ////////////
    // Find minimum calibration point. If request is below minimum, estiamate the IPW
    // setting and inform the user.
    float min_photons = [[photon_values valueForKeyPath:@"@min.self"] floatValue];
    int max_ipw = [[IPW_values objectAtIndex:[photon_values indexOfObject:[photon_values valueForKeyPath:@"@min.self"]]] intValue];
    if(ipw > max_ipw){
        NSLog(@"[TELLIE]: Requested IPW is larger than any value in the calibration curve.\n");
        NSLog(@"[TELLIE]: Using a linear interpolation of 5ph/IPW from min_photons = %.1f (IPW = %d) to estimate photon output at requested setting\n",min_photons, max_ipw);
        float intercept = min_photons - (-5.*max_ipw);
        float photonsFloat = (-5.*ipw) + intercept;
        if(photonsFloat < 0){
            photonsFloat = 0.;
        }
        NSNumber* photons = [NSNumber numberWithFloat:photonsFloat];
        return photons;
    }
    
    /////////////
    // If requested photon output is within range, find xy points above and below threshold.
    // Appropriate setting will be estiamated with a linear interpolation between these points.
    int index = 0;
    for(NSNumber* val in IPW_values){
        index = index + 1;
        if([val intValue] > ipw){
            break;
        }
    }
    index = index - 1;
    
    float x1 = [[IPW_values objectAtIndex:(index-1)] floatValue];
    float x2 = [[IPW_values objectAtIndex:(index)] floatValue];
    float y1 = [[photon_values objectAtIndex:(index-1)] floatValue];
    float y2 = [[photon_values objectAtIndex:(index)] floatValue];
    
    // Calculate gradient and offset for interpolation.
    float dydx = (y1 - y2)/(x1 - x2);
    float intercept = y1 - dydx*x1;
    float photonsFloat = (dydx*ipw) + intercept;
    NSNumber* photons = [NSNumber numberWithInteger:photonsFloat];
    
    return photons;
}

-(BOOL)photonIntensityCheck:(NSUInteger)photons atFrequency:(NSUInteger)frequency
{
    /*
     A detector safety check. At high frequencies the maximum tellie output must be small
     to avoid pushing too much current through individual channels / trigger sums. Use a
     loglog curve to define what counts as detector safe.
     */
    float safe_gradient = -1;
    float safe_intercept = 1.05e6;
    float max_photons = safe_intercept*pow(frequency, safe_gradient);
    if(photons > max_photons){
        return NO;
    } else {
        return YES;
    }
}

-(NSString*)calcTellieFibreForNode:(NSUInteger)node{
    /*
     Use node-to-fibre map loaded from the telliedb to find the priority fibre on a node.
     */
    if(![[self tellieNodeMapping] objectForKey:[NSString stringWithFormat:@"panel_%d",node]]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Node map does not include a reference to node: %d",node);
        return nil;
    }
    
    // Read panel info into local dictionary
    NSMutableDictionary* nodeInfo = [[self tellieNodeMapping] objectForKey:[NSString stringWithFormat:@"panel_%d",node]];
    
    //***************************************//
    // Select appropriate fibre for this node.
    //***************************************//
    NSMutableArray* goodFibres = [[NSMutableArray alloc] init];
    NSMutableArray* lowTransFibres = [[NSMutableArray alloc] init];
    NSMutableArray* brokenFibres = [[NSMutableArray alloc] init];
    // Find which fibres are good / bad etc.
    for(NSString* key in nodeInfo){
        if([[nodeInfo objectForKey:key] intValue] ==  0){
            [goodFibres addObject:key];
        } else if([[nodeInfo objectForKey:key] intValue] ==  1){
            [lowTransFibres addObject:key];
        } else if([[nodeInfo objectForKey:key] intValue] ==  2){
            [brokenFibres addObject:key];
        }
    }
    
    NSString* selectedFibre = @"";
    if([goodFibres count] > 0){
        selectedFibre = [self selectPriorityFibre:goodFibres forNode:node];
    } else if([lowTransFibres count] > 0){
        selectedFibre = [self selectPriorityFibre:lowTransFibres forNode:node];
        NSLogColor([NSColor redColor], @"[TELLIE]: Selected low trasmission fibre %@\n", selectedFibre);
    } else if([brokenFibres count] > 0){
        selectedFibre = [self selectPriorityFibre:brokenFibres forNode:node];
        NSLogColor([NSColor redColor], @"[TELLIE]: Selected broken fibre %@\n", selectedFibre);
    }
    
    [goodFibres release];
    [lowTransFibres release];
    [brokenFibres release];

    return selectedFibre;
}

-(NSNumber*) calcTellieChannelForFibre:(NSString*)fibre
{
    /*
     Use patch pannel map loaded from the telliedb to map a given fibre to the correct tellie channel.
    */
    if([self tellieFibreMapping] == nil){
        NSLogColor([NSColor redColor], @"[TELLIE]: fibre map has not been loaded from couchdb - you need to call loadTellieStaticsFromDB\n");
        return [NSNumber numberWithInt:-1];
    }
    if(![[[self tellieFibreMapping] objectForKey:@"fibres"] containsObject:fibre]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Patch map does not include a reference to fibre: %@\n",fibre);
        return [NSNumber numberWithInt:-2];
    }
    NSUInteger fibreIndex = [[[self tellieFibreMapping] objectForKey:@"fibres"] indexOfObject:fibre];
    NSUInteger channelInt = [[[[self tellieFibreMapping] objectForKey:@"channels"] objectAtIndex:fibreIndex] integerValue];
    NSNumber* channel = [NSNumber numberWithInt:channelInt];
    return channel;
}

-(NSString*)selectPriorityFibre:(NSArray*)fibres forNode:(NSUInteger)node{
    /*
     Select appropriate fibre based on naming convensions for the node at
     which they were installed.
     */
    
    //First find if primary / secondary fibres exist.
    NSString* primaryFibre = [NSString stringWithFormat:@"FT%03dA", node];
    NSString* secondaryFibre = [NSString stringWithFormat:@"FT%03dB", node];
    
    if([fibres indexOfObject:primaryFibre] != NSNotFound){
        return [fibres objectAtIndex:[fibres indexOfObject:primaryFibre]];
    }
    if([fibres indexOfObject:secondaryFibre] != NSNotFound){
        return [fibres objectAtIndex:[fibres indexOfObject:secondaryFibre]];
    }
    
    // If priority fibres don't exist, sort others into A/B arrays
    NSMutableArray* aFibres = [[NSMutableArray alloc] init];
    NSMutableArray* bFibres = [[NSMutableArray alloc] init];
    for(NSString* fibre in fibres){
        if([fibre rangeOfString:@"A"].location != NSNotFound){
            [aFibres addObject:fibre];
        } else if([fibre rangeOfString:@"B"].location != NSNotFound){
            [bFibres addObject:fibre];
        }
    }
    
    // Select from available fibes, with a preference for A type
    NSString* returnFibre = @"";
    if([aFibres count] > 0){
        returnFibre = [aFibres objectAtIndex:0];
    } else if ([bFibres count] > 0){
        returnFibre = [bFibres objectAtIndex:0];
    }
    [aFibres release];
    [bFibres release];
    return returnFibre;
}

-(void) startTellieRun:(NSMutableDictionary*)fireCommands
{
    /*
     Fire a tellie using hardware settings passed as dictionary. This function
     calls a python script on the DAQ1 machine, passing it command line arguments relating
     to specific tellie channel settings. The called python script relays the commands 
     to the tellie hardware using a XMLRPC server which must be lanuched manually via the
     command line prior to launching ORCA.
     
     Arguments: 
        NSMutableDictionary fireCommands :  A dictionary containing hardware settings to
                                            be relayed to the tellie hardware.
     
    */
    ///////////
    //Set tellieFiring flag
    [self setEllieFireFlag:YES];

    //////////
    /// This will likely be run in a thread so set-up an auto release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    ///////////
    // Make a sting accessable inside err; incase of error.
    NSString* errorString;
    
    //////////////
    //Get a Tubii object
    NSArray*  tubiiModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if(![tubiiModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Couldn't find Tubii model.\n");
        [pool release];
        return;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];

    ///////////////
    //Add run control object
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Couldn't find ORRunModel please add one to the experiment\n");
        [pool release];
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];
    
    ///////////////
    //Add SNOPModel object
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Couldn't find SNOPModel\n");
        [pool release];
        return;
    }
    SNOPModel* snopModel = [snopModels objectAtIndex:0];

    ///////////////////////
    // Check TELLIE run type is masked in
    if(!([snopModel lastRunTypeWord] & TELLIE_RUN)){
        NSLogColor([NSColor redColor], @"[TELLIE]: TELLIE bit is not masked into the run type word.\n");
        NSLogColor([NSColor redColor], @"[TELLIE]: Please load the TELLIE standard run type.\n");
        [pool release];
        return;
    }
    
    ///////////////////////
    // Check trigger is being sent to asyncronus port of the MTC/D (EXT_A)
    if(!([theTubiiModel asyncTrigMask] & 0x400000)){
        NSLogColor([NSColor redColor], @"[TELLIE]: Triggers as not being sent to asynchronous MTC/D port\n");
        NSLogColor([NSColor redColor], @"[TELLIE]: Please amend via the TUBii GUI (triggers tab)\n");
        [pool release];
        return;
    }
    
    //////////////
    // Get run mode boolean
    BOOL isSlave = YES;
    if([[fireCommands objectForKey:@"run_mode"] isEqualToString:@"Master"]){
        isSlave = NO;
    }
    
    /////////////
    // Final settings check
    NSNumber* photonOutput = [self calcPhotonsForIPW:[[fireCommands objectForKey:@"pulse_width"] integerValue] forChannel:[[fireCommands objectForKey:@"channel"] integerValue] inSlave:isSlave];
    float rate = 1000.*(1./[[fireCommands objectForKey:@"pulse_separation"] floatValue]);
    NSLog(@"---------------------------Single Fibre Settings Summary-------------------------\n");
    NSLog(@"[TELLIE]: Fibre: %@\n", [fireCommands objectForKey:@"fibre"]);
    NSLog(@"[TELLIE]: Channel: %i\n", [[fireCommands objectForKey:@"channel"] intValue]);
    if (isSlave){
        NSLog(@"[TELLIE]: Mode: slave\n");
    } else {
        NSLog(@"[TELLIE]: Mode: master\n");
    }
    NSLog(@"[TELLIE]: IPW: %d\n", [[fireCommands objectForKey:@"pulse_width"] integerValue]);
    NSLog(@"[TELLIE]: Trigger delay: %1.1f ns\n", [[fireCommands objectForKey:@"trigger_delay"] floatValue]);
    NSLog(@"[TELLIE]: Fibre delay: %1.2f ns\n", [[fireCommands objectForKey:@"fibre_delay"] floatValue]);
    NSLog(@"[TELLIE]: No. triggers %d\n", [[fireCommands objectForKey:@"number_of_shots"] integerValue]);
    NSLog(@"[TELLIE]: Rate %1.1f Hz\n", rate);
    NSLog(@"[TELLIE]: Expected photon output: %i photons / pulse\n", [photonOutput integerValue]);
    NSLog(@"------------\n");
    NSLog(@"[TELLIE]: Estimated excecution time %1.1f mins\n", (([[fireCommands objectForKey:@"number_of_shots"] integerValue] / rate) + 10) / 60.);
    NSLog(@"---------------------------------------------------------------------------------------------\n");

    BOOL safety_check = [self photonIntensityCheck:[photonOutput integerValue] atFrequency:rate];
    if(safety_check == NO){
        NSLogColor([NSColor redColor], @"[TELLIE]: The requested number of photons (%lu), is not detector safe at %f Hz. This setting will not be run.\n", [photonOutput integerValue], rate);
        [pool release];
        return;
    }
    
    ///////////////
    // It's a quirk of TELLIE that entering slave mode can sometimes leave
    // the system in an undefined state. This can be avoided if we always
    // force a master mode operation first. For this purpose a 1 shot master
    // mode sequence is fired here with the max possible IPW setting - ensuring
    // it will never produce light.
    NSArray* fireArgs = @[[[fireCommands objectForKey:@"channel"] stringValue],
                          [NSString stringWithFormat:@"1"],    // number of pulses
                          [NSString stringWithFormat:@"0.01"], // pulse separation (1/rate)
                          [NSString stringWithFormat:@"0"],    // trigger delay (now handled by TUBii)
                          [NSNumber numberWithInt:16383],
                          [[fireCommands objectForKey:@"pulse_height"] stringValue],
                          [[fireCommands objectForKey:@"fibre_delay"] stringValue],
                          ];
    NSLog(@"[TELLIE]: Forcing tellie into known state. May take upto 30s while hardware settings are applied\n");
    @try{
        [[self tellieClient] command:@"init_channel" withArgs:fireArgs];
    } @catch(NSException *e){
        errorString = [NSString stringWithFormat:@"[TELLIE]: Problem init-ing channel: %@\n", [e reason]];
        NSLogColor([NSColor redColor], errorString);
        goto err;
    }
    @try{
        [[self tellieClient] command:@"fire_sequence"];
    } @catch(NSException* e){
        errorString = [NSString stringWithFormat: @"[TELLIE]: Problem with dummy fire: %@\n", [e reason]];
        NSLogColor([NSColor redColor],errorString);
        goto err;
    }
    
    /////////////
    // TELLIE pin readout is an average measurement of the passed "number_of_shots".
    // If a large number of shots are requested it is useful to split the data into smaller chunks,
    // this way we get multiple pin readings.
    NSNumber* loops = [NSNumber numberWithInteger:1];
    int totalShots = [[fireCommands objectForKey:@"number_of_shots"] integerValue];
    float fRemainder = fmod(totalShots, 5e3);
    if( totalShots > 5e3){
        if (fRemainder > 0){
            int iLoops = (totalShots - fRemainder) / 5e3;
            loops = [NSNumber numberWithInteger:(iLoops+1)];
        } else {
            int iLoops = totalShots / 5e3;
            loops =[NSNumber numberWithInteger:iLoops];
        }
    }
    
    ///////////////
    // Now set-up is done, push initial run document
    if([runControl isRunning]){
        @try{
            [self pushInitialTellieRunDocument];
        }@catch(NSException* e){
            NSLogColor([NSColor redColor],@"[TELLIE]: Problem pushing initial tellie run description document: %@\n", [e reason]);
            goto err;
        }
    }
    
    ///////////////
    // Fire loop! Pass variables to the tellie server.
    for(int i = 0; i<[loops integerValue]; i++){
        if([self ellieFireFlag] == NO || [[NSThread currentThread] isCancelled] == YES){
            //errorString = @"ELLIE fire flag set to @NO";
            goto err;
        }

        /////////////////
        // Calculate how many shots to fire in this loop
        NSNumber* noShots = [NSNumber numberWithInt:5e3];
        if(i == ([loops integerValue]-1) && fRemainder > 0){
            noShots = [NSNumber numberWithInt:fRemainder];
        }
        
        //////////////////////
        // Set loop independent tellie channel settings
        if(i == 0){

            ////////
            // Send stop command to ensure buffer is clear
            @try{
                [[self tellieClient] command:@"stop"];
            } @catch(NSException* e){
                // This should only ever be called from the main thread so can raise
                NSLogColor([NSColor redColor], @"[TELLIE]: Problem with tellie server interpreting stop command!\n");
            }
            
            ////////
            // Init channel using fireCommands
            NSArray* fireArgs = @[[[fireCommands objectForKey:@"channel"] stringValue],
                                  [noShots stringValue],
                                  [[fireCommands objectForKey:@"pulse_separation"] stringValue],
                                  [NSNumber numberWithInt:0], // Trigger delay now handled by TUBii
                                  [[fireCommands objectForKey:@"pulse_width"] stringValue],
                                  [[fireCommands objectForKey:@"pulse_height"] stringValue],
                                  [[fireCommands objectForKey:@"fibre_delay"] stringValue],
                                  ];
            
            NSLog(@"[TELLIE]: Init-ing tellie with settings\n");
            @try{
                [[self tellieClient] command:@"init_channel" withArgs:fireArgs];
            } @catch(NSException *e){
                errorString = [NSString stringWithFormat:@"[TELLIE]: Problem init-ing channel on server: %@\n", [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }
            
            @try{
                [theTubiiModel setTellieDelay:[[fireCommands objectForKey:@"trigger_delay"] intValue]];
            } @catch(NSException* e) {
                errorString = [NSString stringWithFormat:@"[TELLIE]: Problem setting trigger delay at TUBii: %@\n", [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }
            
        }

        //////////////////
        // Start a new subrun
        [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
        [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];
        
        ////////////////////
        // Init can take a while. Make sure no-one hit
        // a stop button
        if([[NSThread currentThread] isCancelled]){
            goto err;
        }
        
        /////////////////////
        // Set loop dependent tellie channel settings
        @try{
            [[self tellieClient] command:@"set_pulse_number" withArgs:@[noShots]];
        } @catch(NSException* e) {
            errorString = @"[TELLIE]: Problem setting pulse number on server.\n";
            NSLogColor([NSColor redColor], errorString);
            goto err;
        }
        
        ///////////////
        // Make a temporary directoy to add sub_run fields being run in this loop
        NSMutableDictionary* valuesToFillPerSubRun = [NSMutableDictionary dictionaryWithCapacity:100];
        [valuesToFillPerSubRun setDictionary:fireCommands];
        [valuesToFillPerSubRun setObject:noShots forKey:@"number_of_shots"];
        [valuesToFillPerSubRun setObject:photonOutput forKey:@"photons"];
        
        NSLog(@"[TELLIE]: Firing fibre %@: %d pulses, %1.0f Hz\n", [fireCommands objectForKey:@"fibre"], [noShots integerValue], rate);
        
        ///////////////
        // Handle master / slave mode firing
        //////////////
        // SLAVE MODE
        if([[fireCommands objectForKey:@"run_mode"] isEqualToString:@"Slave"]){
            ///////////
            // Tell tellie to accept a sequence of external triggers
            @try{
                [[self tellieClient] command:@"trigger_averaged"];
            } @catch(NSException* e) {
                errorString = [NSString stringWithFormat:@"[TELLIE]: Problem setting pulse number on server: %@\n", [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }
            ////////////
            // Set the tubii model aand ask it to fire
            @try{
                [theTubiiModel fireTelliePulser_rate:rate pulseWidth:100e-9 NPulses:[noShots intValue]];
            } @catch(NSException* e){
                errorString = [NSString stringWithFormat:@"[TELLIE]: Problem setting TUBii parameters: %@\n", [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }
        //////////////
        // MASTER MODE
        } else {
            /////////////
            // Tell tellie to fire a master mode sequence
            @try{
                [[self tellieClient] command:@"fire_sequence"];
            } @catch(NSException* e){
                errorString = [NSString stringWithFormat: @"[TELLIE]: Problem requesting tellie master to fire: %@\n", [e reason]];
                NSLogColor([NSColor redColor],errorString);
                goto err;
            }
        }

        //////////////////
        // Before we poll, check thread is still alive.
        // polling can take a while so worth doing here first.
        if([[NSThread currentThread] isCancelled]){
            goto err;
        }
        //////////////////
        // Poll tellie for a pin reading. Give the sequence a 3s grace period to finish
        // long for some reason
        float pollTimeOut = (1./rate)*[noShots floatValue] + 3.;
        NSArray* pinReading = nil;
        @try{
            pinReading = [self pollTellieFibre:pollTimeOut];
        } @catch(NSException* e){
            errorString = [NSString stringWithFormat:@"[TELLIE] Problem polling for pin: %@\n", [e reason]];
            NSLogColor([NSColor redColor], errorString);
            goto err;
        }
        NSLog(@"[TELLIE]: Pin response received %i +/- %1.1f\n", [[pinReading objectAtIndex:0] integerValue], [pinReading objectAtIndex:1]);
        @try {
            [valuesToFillPerSubRun setObject:[pinReading objectAtIndex:0] forKey:@"pin_value"];
            [valuesToFillPerSubRun setObject:[pinReading objectAtIndex:1] forKey:@"pin_rms"];
        } @catch (NSException *e) {
            errorString = [NSString stringWithFormat:@"[TELLIE]: Unable to add pin readout to sub_run file due to error: %@\n",[e reason]];
            NSLogColor([NSColor redColor], errorString);
            goto err;
        }
        
        ////////////
        // Update run document
        if([runControl isRunning]){
            @try{
                [self updateTellieRunDocument:valuesToFillPerSubRun];
            } @catch(NSException* e){
                NSLogColor([NSColor redColor],@"[TELLIE]: Problem updating tellie run description document: %@\n", [e reason]);
                goto err;
            }
        }
    }

    ////////////
    // Release pooled memory
    [pool release];
    [self setEllieFireFlag:NO];

    ////////////
    // Finish and tidy up
    NSLog(@"[TELLIE]: TELLIE fire sequence completed\n");
    
    [[NSThread currentThread] cancel];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORTELLIERunFinished object:self];
    });
    return;
err:
    {
        [pool release];
        [self setEllieFireFlag:NO];
        
        //Resetting the mtcd to settings before the smellie run
        NSLog(@"[TELLIE]: Killing requested flash sequence\n");
        
        //Make a dictionary to push into sub-run array to indicate error.
        //NSMutableDictionary* errorDict = [NSMutableDictionary dictionaryWithCapacity:10];
        //[errorDict setObject:errorString forKey:@"tellie_error"];
        //[self updateTellieRunDocument:errorDict];
        
        //Post a note. on the main thread to request a call to stopTellieRun
        [[NSThread currentThread] cancel];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ORTELLIERunFinished object:self];
        });
    }
}

-(void) stopTellieRun
{
    /*
     Make tellie stop firing, tidy up and ensure system is in a well defined state.
    */

    //////////////////////
    // Set fire flag to no. If a run sequence is currently underway, this will stop
    [self setEllieFireFlag:NO];
    
    /////////////
    // This may run in a thread so add release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //////////////////////
    // Send stop command to tellie hardware
    @try{
        NSString* responseFromTellie = [[self tellieClient] command:@"stop"];
        NSLog(@"[TELLIE]: Sent stop command to tellie, received: %@\n",responseFromTellie);
    } @catch(NSException* e){
        // This should only ever be called from the main thread so can raise
        NSLogColor([NSColor redColor], @"[TELLIE]: Problem with tellie server interpreting stop command!\n");
        [pool release];
        return;
    }

    ///////////////////
    // Incase of slave, also get a Tubii object so we can stop Tubii sending pulses
    NSArray*  tubiiModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if(![tubiiModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Couldn't find TUBii model in stopRun.\n");
        [pool release];
        return;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];
    @try{
        [theTubiiModel stopTelliePulser];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"[TELLIE]: Problem stopping TUBii pulser!\n");
        [pool release];
        return;
    }
    
    NSLog(@"[TELLIE]: Stop commands sucessfully sent to tellie and TUBii\n");
    [pool release];
}

/*****************************/
/*   tellie db interactions  */
/*****************************/
-(void) pushInitialTellieRunDocument
{
    /*
     Create a standard tellie run doc using ELLIEModel / SNOPModel / ORRunModel class
     variables and push up to the telliedb. Additionally, the run doc dictionary set as
     the tellieRunDoc propery, to be updated later in the run.
     */
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:10];
    
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE_UPLOAD]: Couldn't find ORRunModel\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE_UPLOAD]: Couldn't find SNOPModel\n");
        return;
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"TELLIE_RUN"];
    NSMutableArray* subRunArray = [NSMutableArray arrayWithCapacity:10];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@"%lu",[runControl runNumber]] forKey:@"index"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"timestamp"];

    [runDocDict setObject:[NSMutableArray arrayWithObjects:[NSNumber numberWithUnsignedLong:[runControl runNumber]],[NSNumber numberWithUnsignedLong:[runControl runNumber]], nil] forKey:@"run_range"];

    [runDocDict setObject:subRunArray forKey:@"sub_run_info"];

    [self setTellieRunDoc:runDocDict];

    [[aSnotModel orcaDbRefWithEntryDB:self withDB:@"telliedb"] addDocument:runDocDict tag:kTellieRunDocumentAdded];

    //wait for main thread to receive acknowledgement from couchdb
    NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow:2.0];
    while ([timeout timeIntervalSinceNow] > 0 && ![[self tellieRunDoc] objectForKey:@"_id"]) {
        [NSThread sleepForTimeInterval:0.1];
    }
}

- (void) updateTellieRunDocument:(NSDictionary*)subRunDoc
{
    /*
     Update [self tellieRunDoc] with subrun information.
     
     Arguments:
     NSDictionary* subRunDoc:  Subrun information to be added to the current [self tellieRunDoc].
     */
    
    // Get run control
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE_UPLOAD]: Couldn't find ORRunModel\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];
    
    NSMutableDictionary* runDocDict = [[self tellieRunDoc] mutableCopy];
    NSMutableDictionary* subRunDocDict = [subRunDoc mutableCopy];

    [subRunDocDict setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];

    NSMutableArray * subRunInfo = [[runDocDict objectForKey:@"sub_run_info"] mutableCopy];
    [subRunInfo addObject:subRunDocDict];
    [runDocDict setObject:subRunInfo forKey:@"sub_run_info"];

    //Update tellieRunDoc property.
    [self setTellieRunDoc:runDocDict];

    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRefWithEntryDB:self withDB:@"telliedb"]
         updateDocument:runDocDict
         documentId:[runDocDict objectForKey:@"_id"]
         tag:kTellieRunDocumentUpdated];
    }
    [subRunInfo release];
    [runDocDict release];
    [subRunDocDict release];
}

-(void) loadTELLIEStaticsFromDB
{
    /*
     Load current tellie channel calibration and patch map settings from telliedb. 
     This function accesses the telliedb and pulls down the most recent fireParameters
     and patchMapping documents. The data is then saved to the member variables 
     tellieFireParameters and tellieFibreMapping.
     */

    // Load the SNOPModel to access orcaDBIPAddress and orcaDBPort variables
    NSArray* snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE_DATABASE]: Couldn't find SNOPModel\n");
        return;
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    // **********************************
    // Load latest calibration constants
    // **********************************
    NSString* parsUrlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/telliedb/_design/tellieQuery/_view/fetchFireParameters?descending=False&limit=1",[aSnotModel orcaDBUserName], [aSnotModel orcaDBPassword], [aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];
    
    NSString* webParsString = [parsUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL* parsUrl = [NSURL URLWithString:webParsString];
    NSMutableURLRequest* parsUrlRequest = [NSMutableURLRequest requestWithURL:parsUrl
                                                                  cachePolicy:0
                                                              timeoutInterval:20];
    
    // Get data string from URL
    NSError* parsDataError =  nil;
    NSURLResponse* parsUrlResponse;
    NSData* parsData = [NSURLConnection sendSynchronousRequest:parsUrlRequest
                                            returningResponse:&parsUrlResponse
                                                        error:&parsDataError];

    if(parsDataError){
        NSLog(@"[TELLIE_DATABASE]: %@\n\n",parsDataError);
    }
    NSString* parsReturnStr = [[NSString alloc] initWithData:parsData encoding:NSUTF8StringEncoding];
    // Format queried data to dictionary
    NSError* parsDictError =  nil;
    NSMutableDictionary* parsDict = [NSJSONSerialization JSONObjectWithData:[parsReturnStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&parsDictError];
    if(parsDictError){
        NSLog(@"[TELLIE_DATABASE]: Error querying couchDB, please check the connection is correct %@\n",parsDictError);
    }
    [parsReturnStr release];

    NSMutableDictionary* fireParametersDoc =[[[parsDict objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"[TELLIE_DATABASE]: channel calibrations sucessfully loaded!\n");
    [self setTellieFireParameters:fireParametersDoc];

    // **********************************
    // Load latest fibre-channel mapping doc.
    // **********************************
    NSString* mapUrlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/telliedb/_design/tellieQuery/_view/fetchCurrentMapping?key=2147483647",[aSnotModel orcaDBUserName], [aSnotModel orcaDBPassword], [aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];

    NSString* webMapString = [mapUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL* mapUrl = [NSURL URLWithString:webMapString];
    NSMutableURLRequest* mapUrlRequest = [NSMutableURLRequest requestWithURL:mapUrl
                                                                 cachePolicy:0
                                                             timeoutInterval:20];

    // Get data string from URL
    NSError* mapDataError =  nil;
    NSURLResponse* mapUrlResponse;
    NSData* mapData = [NSURLConnection sendSynchronousRequest:mapUrlRequest
                                            returningResponse:&mapUrlResponse
                                                        error:&mapDataError];
    /*
    NSData* mapData = [NSData dataWithContentsOfURL:mapUrl
                                            options:NSDataReadingMapped
                                              error:&mapDataError];
    */
    if(mapDataError){
        NSLog(@"\n%@\n\n",mapDataError);
    }
    NSString* mapReturnStr = [[NSString alloc] initWithData:mapData encoding:NSUTF8StringEncoding];
    // Format queried data to dictionary
    NSError* mapDictError =  nil;
    NSMutableDictionary* mapDict = [NSJSONSerialization JSONObjectWithData:[mapReturnStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&mapDictError];
    if(mapDictError){
        NSLog(@"[TELLIE_DATABASE]: Error querying couchDB, please check the connection is correct %@\n",mapDictError);
    }
    [mapReturnStr release];

    NSMutableDictionary* mappingDoc =[[[mapDict objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"[TELLIE_DATABASE]: mapping document sucessfully loaded!\n");
    [self setTellieFibreMapping:mappingDoc];
    
    // **********************************
    // Load latest node-fibre mapping doc.
    // **********************************
    NSString* nodeUrlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/telliedb/_design/mapping/_view/node_to_fibre?descending=True&limit=1",[aSnotModel orcaDBUserName], [aSnotModel orcaDBPassword], [aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];
    
    NSString* webNodeString = [nodeUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL* nodeUrl = [NSURL URLWithString:webNodeString];
    NSMutableURLRequest* nodeUrlRequest = [NSMutableURLRequest requestWithURL:nodeUrl
                                                                  cachePolicy:0
                                                              timeoutInterval:20];
    
    // Get data string from URL
    NSError* nodeDataError =  nil;
    NSURLResponse* nodeUrlResponse;
    NSData* nodeData = [NSURLConnection sendSynchronousRequest:nodeUrlRequest
                                             returningResponse:&nodeUrlResponse
                                                         error:&nodeDataError];
    if(nodeDataError){
        NSLog(@"[TELLIE_DATABASE]: %@\n",nodeDataError);
    }
    NSString* nodeReturnStr = [[NSString alloc] initWithData:nodeData encoding:NSUTF8StringEncoding];
    
    // Format queried data to dictionary
    NSError* nodeDictError =  nil;
    NSMutableDictionary* nodeDict = [NSJSONSerialization JSONObjectWithData:[nodeReturnStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&nodeDictError];
    if(nodeDictError){
        NSLog(@"[TELLIE_DATABASE]: Error querying couchDB, please check the connection is correct %@\n",nodeDictError);
    }
    
    NSMutableDictionary* nodeDoc =[[[nodeDict objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"[TELLIE_DATABASE]: node mapping document sucessfully loaded!\n");
    [self setTellieNodeMapping:nodeDoc];
    
    [nodeReturnStr release];
}

/*********************************************************/
/*                  Smellie Functions                    */
/*********************************************************/
-(void) setSmellieNewRun:(NSNumber *)runNumber{
    NSArray* args = @[runNumber];
    [[self smellieClient] command:@"new_run" withArgs:args];
}

-(void)setSmellieLaserHeadMasterMode:(NSNumber*)laserSwitchChan withIntensity:(NSNumber*)intensity withRepRate:(NSNumber*)rate withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withNPulses:(NSNumber*)noPulses withGainVoltage:(NSNumber *)gain
{
    /*
    Run the SMELLIE system in Master Mode (NI Unit provides the trigger signal for both the lasers and the detector) using the PicoQuant Laser Heads
    
    :param ls_chan: the laser switch channel
    :param intensity: the laser intensity in per mil
    :param rep_rate: the repition rate of requested laser sequence
    :param fs_input_channel: the fibre switch input channel
    :param fs_output_channel: the fibre switch output channel
    :param n_pulses: the number of pulses
    :param gain: the gain setting to be applied at the MPU
    */
    NSArray* args = @[laserSwitchChan, intensity, rate, fibreInChan, fibreOutChan, noPulses, gain];
    [[self smellieClient] command:@"laserheads_master_mode" withArgs:args];
}

-(void)setSmellieLaserHeadSlaveMode:(NSNumber*)laserSwitchChan withIntensity:(NSNumber*)intensity withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withTime:(NSNumber*)time withGainVoltage:(NSNumber*)gain
{
    /*
    Run the SMELLIE system in Slave Mode (SNO+ MTC/D provides the trigger signal for both the lasers and the detector) using the PicoQuant Laser Heads

    :param ls_chan: the laser switch channel
    :param intensity: the laser intensity in per mil
    :param fs_input_channel: the fibre switch input channel
    :param fs_output_channel: the fibre switch output channel
    :param n_pulses: the number of pulses
    :param time: time until SNODROP exits slave mode
    :param gain: the gain setting to be applied at the MPU
    */
    NSArray* args = @[laserSwitchChan, intensity, fibreInChan, fibreOutChan, time, gain];
    [[self smellieClient] command:@"laserheads_slave_mode" withArgs:args];
}

-(void)setSmellieSuperkMasterMode:(NSNumber*)intensity withRepRate:(NSNumber*)rate withWavelengthLow:(NSNumber*)wavelengthLow withWavelengthHi:(NSNumber*)wavelengthHi withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withNPulses:(NSNumber*)noPulses withGainVoltage:(NSNumber *)gain
{
    /*
     Run the SMELLIE superK laser in Master Mode
     
     :param intensity: the laser intensity in per mil
     :param rep_rate: the repetition rate of requested laser sequence
     :param wavelength_low: the low edge of the wavelength window
     :param wavelength_hi: the high edge of the wavelength window
     :param fs_input_channel: the fibre switch input channel
     :param fs_output_channel: the fibre switch output channel
     :param n_pulses: the number of pulses
     :param gain: the gain setting to be applied at the MPU
     */
    NSArray* args = @[intensity, rate, wavelengthLow, wavelengthHi, fibreInChan, fibreOutChan, noPulses, gain];
    [[self smellieClient] command:@"superk_master_mode" withArgs:args];
}


-(void)sendCustomSmellieCmd:(NSString*)customCmd withArgs:(NSArray*)argsArray
{
    [[self smellieClient] command:customCmd withArgs:argsArray];
}


//complete this after the smellie documents have been recieved
-(void) smellieDocumentsRecieved
{
    /*
     Update smeillieDBReadInProgress property bool.
     */
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(smellieDocumentsRecieved) object:nil];
    if (![self smellieDBReadInProgress]) { //killed already
        return;
    }
    
    [self setSmellieDBReadInProgress:NO];
}

-(void)startSmellieRunInBackground:(NSDictionary*)smellieSettings
{
    [self performSelectorOnMainThread:@selector(startSmellieRun:) withObject:smellieSettings waitUntilDone:NO];
}

-(NSArray*)getSmellieRunLaserArray:(NSDictionary*)smellieSettings
{
    //Extract the lasers to be fired into an array
    NSMutableArray* laserArray = [NSMutableArray arrayWithCapacity:5];
    if([[smellieSettings objectForKey:@"375nm_laser_on"] intValue] == 1){
        [laserArray addObject:@"375nm"];
    } if([[smellieSettings objectForKey:@"405nm_laser_on"] intValue] == 1) {
        [laserArray addObject:@"405nm"];
    } if([[smellieSettings objectForKey:@"440nm_laser_on"] intValue] == 1) {
        [laserArray addObject:@"440nm"];
    } if([[smellieSettings objectForKey:@"500nm_laser_on"] intValue] == 1) {
        [laserArray addObject:@"500nm"];
    } if([[smellieSettings objectForKey:@"superK_laser_on"] intValue] == 1) {
        [laserArray addObject:@"superK"];
    }
    return laserArray;
};

-(NSMutableArray*)getSmellieRunFibreArray:(NSDictionary*)smellieSettings
{
    //Extract the fibres to be fired into an array
    NSMutableArray* fibreArray = [NSMutableArray arrayWithCapacity:12];
    if ([[smellieSettings objectForKey:@"FS007"] intValue] == 1){
        [fibreArray addObject:@"FS007"];
    } if ([[smellieSettings objectForKey:@"FS107"] intValue] == 1){
        [fibreArray addObject:@"FS107"];
    } if ([[smellieSettings objectForKey:@"FS207"] intValue] == 1){
        [fibreArray addObject:@"FS207"];
    } if ([[smellieSettings objectForKey:@"FS025"] intValue] == 1){
        [fibreArray addObject:@"FS025"];
    } if ([[smellieSettings objectForKey:@"FS125"] intValue] == 1){
        [fibreArray addObject:@"FS125"];
    } if ([[smellieSettings objectForKey:@"FS225"] intValue] == 1){
        [fibreArray addObject:@"FS225"];
    } if ([[smellieSettings objectForKey:@"FS037"] intValue] == 1){
        [fibreArray addObject:@"FS037"];
    } if ([[smellieSettings objectForKey:@"FS137"] intValue] == 1){
        [fibreArray addObject:@"FS137"];
    } if ([[smellieSettings objectForKey:@"FS237"] intValue] == 1){
        [fibreArray addObject:@"FS237"];
    } if ([[smellieSettings objectForKey:@"FS055"] intValue] == 1){
        [fibreArray addObject:@"FS055"];
    } if ([[smellieSettings objectForKey:@"FS155"] intValue] == 1){
        [fibreArray addObject:@"FS155"];
    } if ([[smellieSettings objectForKey:@"FS255"] intValue] == 1){
        [fibreArray addObject:@"FS255"];
    } if ([[smellieSettings objectForKey:@"FS093"] intValue] == 1){
        [fibreArray addObject:@"FS093"];
    } if ([[smellieSettings objectForKey:@"FS193"] intValue] == 1){
        [fibreArray addObject:@"FS193"];
    } if ([[smellieSettings objectForKey:@"FS293"] intValue] == 1){
        [fibreArray addObject:@"FS293"];
    }
    return fibreArray;
}

-(NSMutableArray*)getSmellieLowEdgeWavelengthArray:(NSDictionary*)smellieSettings
{
    //Read data
    int wavelengthLow = [[smellieSettings objectForKey:@"superK_wavelength_start"] intValue];
    //int bandwidth = [[smellieSettings objectForKey:@"superK_wavelength_bandwidth"] intValue];
    int stepSize = [[smellieSettings objectForKey:@"superK_wavelength_step_length"] intValue];
    float noSteps = [[smellieSettings objectForKey:@"superK_wavelength_no_steps"] floatValue];
    
    NSMutableArray* lowEdges = [NSMutableArray arrayWithCapacity:noSteps];
    if(wavelengthLow == 0 || noSteps == 0){
        [lowEdges addObject:[NSNumber numberWithInteger:wavelengthLow]];
        return lowEdges;
    }
    
    //Create array
    for(int i=0;i<noSteps;i++){
        int edge = wavelengthLow + i*stepSize;
        [lowEdges addObject:[NSNumber numberWithInt:edge]];
    }
    return lowEdges;
}

-(NSMutableArray*)getSmellieRunIntensityArray:(NSDictionary*)smellieSettings forLaser:(NSString *)laser
{
    //Extract bounds
    int minIntensity = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_intensity_minimum",laser]] intValue];
    int increment = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_intensity_increment",laser]] intValue];
    int noSteps = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_intensity_no_steps",laser]] intValue];

    //Check to see if the maximum intensity is the same as the minimum intensity
    NSMutableArray* intensities = [NSMutableArray arrayWithCapacity:noSteps];

    //Create intensities array
    for(int i=0; i < noSteps; i++){
        [intensities addObject:[NSNumber numberWithInt:(minIntensity + increment*i)]];
    }
    
    return intensities;
}

-(NSMutableArray*)getSmellieRunGainArray:(NSDictionary*)smellieSettings forLaser:(NSString *)laser
{
    //Extract bounds
    float minIntensity = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_gain_minimum",laser]] floatValue];
    float increment = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_gain_increment",laser]] floatValue];
    int noSteps = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_gain_no_steps",laser]] intValue];
    
    //Check to see if the maximum intensity is the same as the minimum intensity
    NSMutableArray* gains = [NSMutableArray arrayWithCapacity:noSteps];
    
    //Create intensities array
    for(int i=0; i < noSteps; i++){
        [gains addObject:[NSNumber numberWithFloat:(minIntensity + increment*i)]];
    }
    
    return gains;
}

-(void)startSmellieRun:(NSDictionary*)smellieSettings
{
    /*
     Form a smellie run using the passed smellie run file, stored in smellieSettings dictionary.
    */
    NSLog(@"[SMELLIE]:Setting up a SMELLIE Run\n");

    //////////////
    // This will likely run in thread so make an auto release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    //////////////
    //   GET TUBii & RunControl MODELS
    //////////////
    //Get a Tubii object
    NSArray*  tubiiModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if(![tubiiModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find Tubii model.\n");
        [pool release];
        return;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];

    ///////////////
    //Get the run controller
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add it to the experiment and restart the run.\n");
        [pool release];
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    ///////////////
    // FIND AND LOAD RELEVANT CONFIG
    NSNumber* configVersionNo;
    if([smellieSettings objectForKey:@"config_name"]){
        NSLog( @"[SMELLIE]: Loading config file: %@\n", [smellieSettings objectForKey:@"config_name"]);
        configVersionNo = [self fetchConfigVersionFor:[smellieSettings objectForKey:@"config_name"]];
    } else {
        configVersionNo = [self fetchRecentConfigVersion];
        NSLog( @"[SMELLIE]: Loading config file: %i\n", [configVersionNo intValue]);
    }
    [self setSmellieConfigVersionNo:configVersionNo];
    [self fetchConfigurationFile:configVersionNo];

    ///////////////
    // RUN CONTROL
    ///////////////////////
    // Check SMELLIE run type is masked in
    if(!([runControl runType] & SMELLIE_RUN)){
        NSLogColor([NSColor redColor], @"[SMELLIE] SMELLIE bit is not masked into the run type word\n");
        NSLogColor([NSColor redColor], @"[SMELLIE]: Please load the SMELLIE standard run type.\n");
        goto err;
    }
    
    ///////////////////////
    // Check trigger is being sent to asyncronus port (EXT_A)
    if(!([theTubiiModel asyncTrigMask] & 0x800000)){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Triggers as not being sent to asynchronous MTC/D port\n");
        NSLogColor([NSColor redColor], @"[SMELLIE]: Please amend via the TUBii GUI (triggers tab)\n");
        goto err;
    }
    
    ////////////////////////
    // SET MASTER / SLAVE MODE
    NSString *operationMode = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"operation_mode"]];
    if([operationMode isEqualToString:@"Slave Mode"]){
        [self setSmellieSlaveMode:YES];
        NSLog(@"[SMELLIE]: Running in SLAVE mode\n");
    }else if([operationMode isEqualToString:@"Master Mode"]){
        [self setSmellieSlaveMode:NO];
        NSLog(@"[SMELLIE]: Running in MASTER mode\n");
    }else{
        NSLogColor([NSColor redColor], @"[SMELLIE]: Slave / master mode could not be read in run plan file.\n");
        goto err;
    }
    
    /////////////////////
    // GET SMELLIE LASERS AND FIBRES TO LOOP OVER
    // Wavelengths, intensities and gains variables
    // for each fibre are generated within the laser
    // loop.
    //
    NSMutableArray* laserArray = [self getSmellieRunLaserArray:smellieSettings];
    NSMutableArray* fibreArray = [self getSmellieRunFibreArray:smellieSettings];

    // Make a dictionary to hold settings for pushing upto database
    NSMutableDictionary *valuesToFillPerSubRun = [[NSMutableDictionary alloc] initWithCapacity:100];
    
    //////////////////////
    // Define some parameters for overheads calculation
    NSNumber* changeIntensity = [NSNumber numberWithFloat:0.5];
    NSNumber* changeFibre = [NSNumber numberWithFloat:0.1];
    NSNumber* changeFixedLaser = [NSNumber numberWithFloat:45];
    NSNumber* changeSKWavelength = [NSNumber numberWithFloat:1];
    NSNumber* changeGain = [NSNumber numberWithFloat:0.5];
    
    /////////////////////
    // Create and push initial smellie run doc and tell smellie which run we're in
    if([runControl isRunning]){
        @try{
            [self setSmellieNewRun:[NSNumber numberWithUnsignedLong:[runControl runNumber]]];
        } @catch(NSException* e) {
            NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with server request: %@\n", [e reason]);
            goto err;
        }
        
        @try{
            [self pushInitialSmellieRunDocument];
        } @catch(NSException* e){
            NSLogColor([NSColor redColor],@"[SMELLIE]: Problem pushing initial run log: %@\n", [e reason]);
            goto err;
        }
    }
    
    // ***********************
    // BEGIN LOOPING!
    // laser loop
    //
    for(NSString* laserKey in laserArray){
        if(([[NSThread currentThread] isCancelled])){
            NSLogColor([NSColor redColor], @"[SMELLIE]: thread has been cancelled, killing sequence.\n");
            goto err;
        }
        NSLog(@"[SMELLIE]: Fire sequence requested for laser: %@\n", laserKey);
        
        // Add laser to the subrun file
        [valuesToFillPerSubRun setObject:laserKey forKey:@"laser"];
 
        ////////////////////////////
        // Do some additional array
        // building to define the
        // inner loops for this laser
        
        // Create wavelength, intensity and gain arrays for this laser
        NSMutableArray* intensityArray = [self getSmellieRunIntensityArray:smellieSettings forLaser:laserKey];
        NSMutableArray* gainArray = [self getSmellieRunGainArray:smellieSettings forLaser:laserKey];
        NSMutableArray* lowEdgeWavelengthArray = [NSMutableArray arrayWithObject:[NSNumber numberWithInt:0]]; // Make an array with single entry
        if([laserKey isEqual:@"superK"]){
            lowEdgeWavelengthArray = [self getSmellieLowEdgeWavelengthArray:smellieSettings];
        }
        NSNumber* rate = [smellieSettings objectForKey:@"trigger_frequency"];

        // ***********
        // Fibre loop
        //
        for(NSString* fibreKey in fibreArray){
            if(([[NSThread currentThread] isCancelled])){
                NSLogColor([NSColor redColor], @"[SMELLIE]: thread has been cancelled, killing sequence.\n");
                goto err;
            }
            NSLog(@"[SMELLIE]: Fire sequence requested for fibre: %@\n", fibreKey);

            // Add fibre to the subRun file
            [valuesToFillPerSubRun setObject:fibreKey forKey:@"fibre"];
            
            // ***************
            // Wavelength loop
            //
            for(NSNumber* wavelength in lowEdgeWavelengthArray){
                if(([[NSThread currentThread] isCancelled])){
                    NSLogColor([NSColor redColor], @"[SMELLIE]: thread has been cancelled, killing sequence.\n");
                    goto err;
                }
                
                // By default set the wavelength window to nil in rundoc
                NSNumber* wavelengthLowEdge = [NSNumber numberWithInt:0];
                NSNumber* wavelengthHighEdge = [NSNumber numberWithInt:0];
                
                // If this is the superK loop, make sure the wavelength window is set apropriately
                if([laserKey isEqualToString:@"superK"]){
                    wavelengthLowEdge = wavelength;
                    wavelengthHighEdge = [NSNumber numberWithInt:([wavelength integerValue] + [[smellieSettings objectForKey:@"superK_wavelength_bandwidth"] integerValue])];
                }

                [valuesToFillPerSubRun setObject:wavelengthLowEdge forKey:@"wavelength_low_edge"];
                [valuesToFillPerSubRun setObject:wavelengthHighEdge forKey:@"wavelength_high_edge"];
                
                // **************
                // Intensity loop
                //
                for(NSNumber* intensity in intensityArray){
                    if(([[NSThread currentThread] isCancelled])){
                        NSLogColor([NSColor redColor], @"[SMELLIE]: thread has been cancelled, killing sequence.\n");
                        goto err;
                    }
                    
                    // Add intensity value into runDoc
                    [valuesToFillPerSubRun setObject:intensity forKey:@"intensity"];
                    
                    // **************
                    // Gain loop
                    //
                    for(NSNumber* gain in gainArray){
                        if(([[NSThread currentThread] isCancelled])){
                            NSLogColor([NSColor redColor], @"[SMELLIE]: thread has been cancelled, killing sequence.\n");
                            goto err;
                        }
                        
                        ///////////////////////
                        // Inner most loop.
                        // Need to begin a new
                        // subrun and tell hardware
                        // what it should be running
                        //
                        
                        //////////////////////
                        // GET FINAL SMELLIE SETTINGS
                        [valuesToFillPerSubRun setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];
                        [valuesToFillPerSubRun setObject:gain forKey:@"gain"];

                        NSNumber* laserSwitchChannel = [[self smellieLaserHeadToSepiaMapping] objectForKey:laserKey];
                        NSNumber* fibreInputSwitchChannel = [[self smellieLaserToInputFibreMapping] objectForKey:laserKey];
                        NSNumber* fibreOutputSwitchChannel = [[self smellieFibreSwitchToFibreMapping] objectForKey:fibreKey];
                        NSNumber* numOfPulses = [smellieSettings objectForKey:@"triggers_per_loop"];
                        
                        //////////////////////
                        // Calculate how long we expect this run loop to take
                        // Active firing time
                        float fireTime = [rate floatValue]*[numOfPulses floatValue];
                        // Overheads
                        // Assuption is that at the start of a new outer loop, all the inner
                        // loops must start from the first object in their array.
                        float overheads = [changeGain floatValue];
                        if([gain isEqualTo:[gainArray firstObject]]){ // New intensity
                            overheads = overheads + [changeIntensity floatValue];
                            if([intensity isEqualTo:[intensityArray firstObject]]){ // New wavelength
                                if([laserKey isEqualTo:@"superK"]){ // only important for superK
                                    overheads = overheads + [changeSKWavelength floatValue];
                                }
                                if([wavelength isEqualTo:[lowEdgeWavelengthArray firstObject]]){ // New fibre
                                    overheads = overheads + [changeFibre floatValue];
                                    if([fibreKey isEqualTo:[fibreArray firstObject]]){ // New laser
                                        if(![laserKey isEqualTo:@"superK"]){ // Only changing fixed lasers takes time
                                            overheads = overheads + [changeFixedLaser floatValue];
                                        }
                                    }
                                }
                            }
                        }
                        NSNumber* sequenceTime = [NSNumber numberWithFloat:(fireTime+overheads)];
                        
                        //// **NOTE** ////
                        // Need to add a call to TUBii
                        // to set the trigger delay. This
                        // will be done using:
                        // [theTUBiiModel setSmellieDelay]
                        //
                        // The delay field isn't currently
                        // included in the run description
                        // doc - needs discussion with
                        // smellie group
                        
                        //////////////
                        // Slave mode
                        if([self smellieSlaveMode]){
                            if([laserKey isEqualTo:@"superK"]){
                                NSLogColor([NSColor redColor], @"[SMELLIE]: SuperK laser cannot be run in slave mode\n");
                            } else {
                                @try{
                                    [self setSmellieLaserHeadSlaveMode:laserSwitchChannel withIntensity:intensity withFibreInput:fibreInputSwitchChannel withFibreOutput:fibreOutputSwitchChannel withTime:sequenceTime withGainVoltage:gain];
                                } @catch(NSException* e){
                                    NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with smellie server request: %@\n", [e reason]);
                                    goto err;
                                }

                            }

                            //// **NOTE** ////
                            // May have to include a delay
                            // here to ensure smellie
                            // hardware is properly set
                            // before TUBii sends triggers
                            
                            //Set tubii up for sending correct triggers
                            @try{
                                //Fire trigger pulses!
                                [theTubiiModel fireSmelliePulser_rate:[rate floatValue] pulseWidth:100e-9 NPulses:numOfPulses];
                            } @catch(NSException* e) {
                                NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with TUBii server request: %@\n", [e reason]);
                                goto err;
                            }

                        //////////////
                        // Master mode
                        } else {

                            //Set SMELLIE settings
                            if([laserKey isEqualTo:@"superK"]){
                                @try{
                                    [self setSmellieSuperkMasterMode:intensity withRepRate:rate withWavelengthLow:wavelengthLowEdge withWavelengthHi:wavelengthHighEdge withFibreInput:fibreInputSwitchChannel withFibreOutput:fibreOutputSwitchChannel withNPulses:numOfPulses withGainVoltage:gain];
                                } @catch(NSException* e){
                                    NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with smellie server request: %@\n", [e reason]);
                                    goto err;
                                }
                            } else {
                                @try{
                                    [self setSmellieLaserHeadMasterMode:laserSwitchChannel withIntensity:intensity withRepRate:rate withFibreInput:fibreInputSwitchChannel withFibreOutput:fibreOutputSwitchChannel withNPulses:numOfPulses withGainVoltage:gain];
                                } @catch(NSException* e){
                                    NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with smellie server request: %@\n", [e reason]);
                                    goto err;
                                }
                            }
                            
                        }

                        //////////////////
                        //Push record of sub-run settings to db
                        if([runControl isRunning]){
                            @try{
                                [self updateSmellieRunDocument:valuesToFillPerSubRun];
                            } @catch(NSException* e){
                                NSLogColor([NSColor redColor], @"[SMELLIE]: Problem updating couchdb run file: %@\n", [e reason]);
                                goto err;
                            }
                        }
                        
                        //////////////////
                        //Check if run file requests a sleep time between sub_runs
                        if([smellieSettings objectForKey:@"sleep_between_sub_run"]){
                            NSTimeInterval sleepTime = [[smellieSettings objectForKey:@"sleep_between_sub_run"] floatValue];
                            [NSThread sleepForTimeInterval:sleepTime];
                        }
                        
                        //////////////////
                        // RUN CONTROL
                        //Prepare new subrun - will produce a subrun boundrary in the zdab.
                        if([runControl isRunning]){
                            [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
                            [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];
                        }
                    }//end of GAIN loop
                }//end of INTENSITY loop
            }//end of WAVELENGTH loop
        }//end of FIBRE loop
    }//end of LASER loop

    //Release dict holding sub-run info
    [valuesToFillPerSubRun release];
    [pool release];
    
    //Post a note. on the main thread to request a call to stopSmellieRun
    [[NSThread currentThread] cancel];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSMELLIERunFinished object:self];
    });
    return;

err:
{
    //Resetting the mtcd to settings before the smellie run
    NSLogColor([NSColor redColor], @"[SMELLIE]: Sent to err statement. Stopping fire sequence.\n");
    [pool release];

    //Post a note. on the main thread to request a call to stopSmellieRun
    [[NSThread currentThread] cancel];
    dispatch_sync(dispatch_get_main_queue(), ^{
	    [[NSNotificationCenter defaultCenter] postNotificationName:ORSMELLIERunFinished object:self];
    });
}
}

-(void)stopSmellieRun
{
    /*
     Some sign off / tidy up stuff to be called at the end of a smellie run. 
    
     The key operation is to set the safestates.
    */

    ///////////
    // This could be run in a thread, so set-up an auto release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //Get a Tubii object
    NSArray*  tubiiModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if(![tubiiModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find TUBii model. Please add it to the experiment and restart the run.\n");
        goto err;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];
    [theTubiiModel stopSmelliePulser];
    
    NSLog(@"[SMELLIE]: Run sequence stopped.\n");
    [pool release];
    return;
    
err:
    [pool release];
    NSLog(@"[SMELLIE]: Run sequence stopped - TUBii is in an undefined state (may still be sending triggers).\n");
}

/*****************************/
/*  smellie db interactions  */
/*****************************/
- (void) fetchSmellieConfigurationInformation
{
    /*
        Get smellie config information from the smelliedb.
    */

    //this is dependant upon the current couchDB view that exsists within the database
    NSString *requestString = [NSString stringWithFormat:@"_design/smellieMainQuery/_view/pullEllieConfigHeaders"];
    
    [[self generalDBRef:@"smellie"] getDocumentId:requestString tag:kSmellieConfigHeaderRetrieved];
    
    [self setSmellieDBReadInProgress:YES];
    // Is there a better way to do this... Do we know it's received after the delay?
    [self performSelector:@selector(smellieDocumentsRecieved) withObject:nil afterDelay:10.0];
}

-(void) smellieDBpush:(NSMutableDictionary*)dbDic
{
    [self _pushEllieCustomRunToDB:@"smellie" runFiletoPush:dbDic withDocType:@"smellie_run_description"];
}

-(void) smellieConfigurationDBpush:(NSMutableDictionary*)dbDic
{
    [self _pushEllieConfigDocToDB:@"smellie" runFiletoPush:dbDic withDocType:@"smellie_run_configuration"];
}

-(void) pushInitialSmellieRunDocument
{
    /*
     Create a standard smellie run doc using ELLIEModel / SNOPModel / ORRunModel class
     variables and push up to the smelliedb. Additionally, the run doc dictionary set as
     the tellieRunDoc propery, to be updated later in the run.
     */
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:10];

    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add one to the experiment and restart the run.\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find SNOPModel. Please add one to the experiment and restart the run.\n");
        return;
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"SMELLIE_RUN"];
    NSMutableArray* subRunArray = [NSMutableArray arrayWithCapacity:15];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@"%lu",[runControl runNumber]] forKey:@"index"];
    [runDocDict setObject:[aSnotModel smellieRunNameLabel] forKey:@"run_description_used"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"timestamp"];
    [runDocDict setObject:[self smellieConfigVersionNo] forKey:@"configuration_version"];
    [runDocDict setObject:[NSNumber numberWithInt:[runControl runNumber]] forKey:@"run"];
    [runDocDict setObject:[NSMutableArray arrayWithObjects:[NSNumber numberWithUnsignedLong:[runControl runNumber]],[NSNumber numberWithUnsignedLong:[runControl runNumber]], nil] forKey:@"run_range"];

    [runDocDict setObject:subRunArray forKey:@"sub_run_info"];

    [self setSmellieRunDoc:runDocDict];

    [[aSnotModel orcaDbRefWithEntryDB:self withDB:@"smellie"] addDocument:runDocDict tag:kSmellieRunDocumentAdded];

    //wait for main thread to receive acknowledgement from couchdb
    NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow:5.0];
    while ([timeout timeIntervalSinceNow] > 0 && ![runDocDict objectForKey:@"_id"]) {
        [NSThread sleepForTimeInterval:0.1];
    }
}

- (void) updateSmellieRunDocument:(NSDictionary*)subRunDoc
{
    /*
     Update [self tellieRunDoc] with subrun information.
     
     Arguments:
     NSDictionary* subRunDoc:  Subrun information to be added to the current [self tellieRunDoc].
     */
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find SNOPModel. Please add one to the experiment and restart the run.\n");
        return;
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add it to the experiment and restart the run.\n");
        return;    }
    ORRunModel* runControl = [runModels objectAtIndex:0];
    
    NSMutableDictionary* runDocDict = [[self smellieRunDoc] mutableCopy];
    NSMutableDictionary* subRunDocDict = [subRunDoc mutableCopy];

    [subRunDocDict setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];

    NSMutableArray * subRunInfo = [[runDocDict objectForKey:@"sub_run_info"] mutableCopy];
    [subRunInfo addObject:subRunDocDict];
    [runDocDict setObject:subRunInfo forKey:@"sub_run_info"];

    //Update tellieRunDoc property.
    [self setSmellieRunDoc:runDocDict];

    //check to see if run is offline or not
    [[aSnotModel orcaDbRefWithEntryDB:self withDB:@"smellie"] updateDocument:runDocDict documentId:[runDocDict objectForKey:@"_id"] tag:kTellieRunDocumentUpdated];
    [subRunInfo release];
    [runDocDict release];
    [subRunDocDict release];
}

-(void) _pushSmellieRunDocument
{
    /*
     Creat a standard smellie run doc using ELLIEModel / SNOPModel / ORRunModel class
     variables and push up to the smelliedb.
     */
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:100];

    //Collect a series of objects from the SNOPModel
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find SNOPModel. Please add one to the experiment and restart the run.\n");
        return;
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add one to the experiment and restart the run.\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"smellie_run"];
    NSString* smellieRunNameLabel = [aSnotModel smellieRunNameLabel];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@"%lu",[runControl runNumber]] forKey:@"index"];
    [runDocDict setObject:smellieRunNameLabel forKey:@"run_description_used"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"timestamp"];
    NSNumber *smellieConfigurationVersion = [self smellieConfigVersionNo];
    [runDocDict setObject:smellieConfigurationVersion forKey:@"configuration_version"];
    [runDocDict setObject:[NSNumber numberWithInt:[runControl runNumber]] forKey:@"run"];

    // Sub run info
    if([runDocDict objectForKey:@"sub_run_info"]){
        [runDocDict setObject:[self smellieSubRunInfo] forKey:@"sub_run_info"];
    } else {
        [runDocDict setObject:[NSNumber numberWithInt:0] forKey:@"sub_run_info"];
    }

    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:@"smellie"] addDocument:runDocDict tag:kSmellieSubRunDocumentAdded];
}

-(void) _pushEllieConfigDocToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile withDocType:(NSString*)aDocType
{
    /*
     Create and push a smellie config file to couchdb.
     
     Arguments:
     NSString* aCouchDBName:             Name of the couchdb repo the document will be uploaded to.
     NSMutableDictionary customRunFile:  Custom run settings to be uploaded to db.
     NSString* aDocType:                 Name to be used in the 'doc_type' field of the uploaded doc.
     
     */
    NSMutableDictionary* configDocDic = [NSMutableDictionary dictionaryWithCapacity:100];

    //Collect a series of objects from the SNOPModel
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find SNOPModel. Please add one to the experiment and restart the run.\n");
        return;
    }
    //Initialise the SNOPModel
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"%@",aDocType];

    NSLog(@"document_type: %@",docType);

    [configDocDic setObject:docType forKey:@"doc_type"];
    [configDocDic setObject:[self stringDateFromDate:nil] forKey:@"time_stamp"];
    [configDocDic setObject:customRunFile forKey:@"configuration_info"];

    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:aCouchDBName] addDocument:configDocDic tag:kSmellieRunDocumentAdded];
}


-(void) _pushEllieCustomRunToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile withDocType:(NSString*)aDocType
{
    /*
     Push custom run information from the GUI to a couchDB database.
     
     Arguments:
     NSString* aCouchDBName            : The couchdb database name.
     NSMutableDictionary* customRunFile: GUI settings stored in a dictionary.
     NSString* aDocType                : Type of document being uploaded.
     */
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:100];

    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel* aSnotModel = [objs objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"%@",aDocType];
    NSLog(@"document_type: %@",docType);

    [runDocDict setObject:docType forKey:@"doc_type"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"time_stamp"];
    [runDocDict setObject:customRunFile forKey:@"run_info"];

    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:aCouchDBName] addDocument:runDocDict tag:kSmellieRunDocumentAdded];
}

-(NSNumber*) fetchRecentConfigVersion
{
    /*
     Query smellie config documenets on the smelliedb to find the most recent config versioning
     number.
    */
    //Collect a series of objects from the SNOPModel
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find SNOPModel. Please add one to the experiment and restart the run.\n");
        return @-1;
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/smellie/_design/smellieMainQuery/_view/fetchMostRecentConfigVersion?descending=True&limit=1",[aSnotModel orcaDBUserName],[aSnotModel orcaDBPassword],[aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSNumber *currentVersionNumber;
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error =  nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if(error){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Error in querying couchDB: %@\n", error);
    }

    @try{
        //format the json response
        NSString *stringValueOfCurrentVersion = [NSString stringWithFormat:@"%@",[[[json valueForKey:@"rows"] valueForKey:@"value"]objectAtIndex:0]];
        currentVersionNumber = [NSNumber numberWithInt:[stringValueOfCurrentVersion intValue]];
    }
    @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"[SMELLIE]: Error in fetching the SMELLIE CONFIGURATION FILE: %@\n", [e reason]);
        return @-1;
    }
    NSLog(@"[SMELLIE]: config version sucessfully loaded!\n");
    return currentVersionNumber;
}

-(NSNumber*) fetchConfigVersionFor:(NSString*)name
{
    /* 
     Find and return the version number of a named config doc
    */
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noSNOPModel"
                          reason:@"*** Please add a SNOPModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString *urlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/smellie/_design/smellieMainQuery/_view/pullEllieConfigHeaders",[aSnotModel orcaDBUserName],[aSnotModel orcaDBPassword],[aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSError *error =  nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if(error){
        NSException* e = [NSException
                          exceptionWithName:@"jsonReadError"
                          reason:@"*** Database JSON could not be read properly"
                          userInfo:nil];
        [e raise];
    }
    
    NSDictionary* entries = [json objectForKey:@"rows"];
    for(NSDictionary* entry in entries){
        if([[entry valueForKey:@"value"] valueForKey:@"config_name"]){
            NSString* configName = [NSString stringWithFormat:@"%@",[[entry valueForKey:@"value"] valueForKey:@"config_name"]];
            if([configName isEqualToString:name]){
                NSString* stringValueOfCurrentVersion = [NSString stringWithFormat:@"%@",[[[entry valueForKey:@"value"] valueForKey:@"configuration_info"] valueForKey:@"configuration_version"]];
                return [NSNumber numberWithInt:[stringValueOfCurrentVersion intValue]];
            }
        }
    }
    NSLogColor([NSColor redColor], @"[SMELLIE]: WARNING No config file found for %@\n", name);
    return [self fetchRecentConfigVersion];
}

-(NSMutableDictionary*) fetchConfigurationFile:(NSNumber*)currentVersion
{
    /*
     Fetch the current configuration document of a given version number.
     
     Arguments:
        NSNumber* currentVersion: The version number to be used with the query.
    */
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noSNOPModel"
                          reason:@"*** Please add a SNOPModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString *urlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/smellie/_design/smellieMainQuery/_view/pullEllieConfigHeaders?key=[%i]&limit=1",[aSnotModel orcaDBUserName],[aSnotModel orcaDBPassword],[aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort],[currentVersion intValue]];

    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error =  nil;
    NSMutableDictionary *currentConfig = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if(error){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Error querying the couchDB: %@\n", error);
    }
    [ret release];

    NSMutableDictionary* configForSmellie = [[[[currentConfig objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"] objectForKey:@"configuration_info"];

    //Set laser head to sepia mapping
    NSMutableDictionary *laserHeadToSepiaMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    for(int laserHeadIndex =0; laserHeadIndex < 6; laserHeadIndex++){
        for (id specificConfigValue in configForSmellie){
            if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput%i",laserHeadIndex]]){
                NSString *laserHeadConnected = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"laserHeadConnected"]];
                [laserHeadToSepiaMapping setObject:[NSNumber numberWithInt:laserHeadIndex] forKey:laserHeadConnected];
            }
        }
    }
    //NSLog(@"setSmellieLaserHeadToSepiaMapping: %@\n", laserHeadToSepiaMapping);
    [self setSmellieLaserHeadToSepiaMapping:laserHeadToSepiaMapping];
    [laserHeadToSepiaMapping release];

    //Set laser head to gain control mapping
    NSMutableDictionary *laserHeadToGainControlMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    for(int laserHeadIndex =0; laserHeadIndex < 6; laserHeadIndex++){
        for (id specificConfigValue in configForSmellie){
            if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput%i",laserHeadIndex]]){
                NSString *laserHeadConnected = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"laserHeadConnected"]];
                NSNumber *laserGainControl = [NSNumber numberWithFloat:[[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"gainControlFactor"] floatValue]];
                [laserHeadToGainControlMapping setObject:laserGainControl forKey:laserHeadConnected];
            }
        }
    }
    //NSLog(@"setSmellieLaserHeadToGainMapping: %@\n", laserHeadToGainControlMapping);
    [self setSmellieLaserHeadToGainMapping:laserHeadToGainControlMapping];
    [laserHeadToGainControlMapping release];

    //Set laser to input fibre mapping
    NSMutableDictionary *laserToInputFibreMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    for (id specificConfigValue in configForSmellie){
        if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput0"]]
           || [specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput1"]]
           || [specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput2"]]
           || [specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput3"]]
           || [specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput4"]]
           || [specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput5"]]){
            NSString *fibreSwitchInputConnected = [[configForSmellie objectForKey:specificConfigValue] objectForKey:@"fibreSwitchInputConnected"];
            NSNumber* parsedFibreReference = [NSNumber numberWithInt:[[fibreSwitchInputConnected stringByReplacingOccurrencesOfString:@"Channel" withString:@""] intValue]];
            NSString * laserHeadReference = [[configForSmellie objectForKey:specificConfigValue] objectForKey:@"laserHeadConnected"];
            [laserToInputFibreMapping setObject:parsedFibreReference forKey:laserHeadReference];
        }
    }
    [self setSmellieLaserToInputFibreMapping:laserToInputFibreMapping];
    [laserToInputFibreMapping release];

    //Set fibre switch to fibre mapping
    NSMutableDictionary *fibreSwitchOutputToFibre = [[NSMutableDictionary alloc] initWithCapacity:20];
    for(int outputChannelIndex = 1; outputChannelIndex < 15; outputChannelIndex++){
        for (id specificConfigValue in configForSmellie){
            if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"Channel%i",outputChannelIndex]]){
                NSString *fibreReference = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"detectorFibreReference"]];
                [fibreSwitchOutputToFibre setObject:[NSNumber numberWithInt:outputChannelIndex] forKey:fibreReference];
            }
        }
    }
    [self setSmellieFibreSwitchToFibreMapping:fibreSwitchOutputToFibre];
    [fibreSwitchOutputToFibre release];
    
    NSLog(@"[SMELLIE] config file (version %i) sucessfully loaded!\n", [currentVersion intValue]);
    return configForSmellie;
}


/****************************************/
/*        Misc generic methods          */
/****************************************/
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
    /*
     Checks a result returned from a couchdb query for ellie doocument add / retrieval
     tags.
     
     Arguments:
     id aResult:     Object returned by cauchdb query.
     NSString* aTag: The query tag to check against expected cases.
     id anOp:        This doesn't appear to be used??
     */
    @synchronized(self){
        if([aResult isKindOfClass:[NSDictionary class]]){
            NSString* message = [aResult objectForKey:@"Message"];
            if(message){
                [aResult prettyPrint:@"CouchDB Message:"];
            }

            //Look through all of the possible tags for ellie couchDB results

            //This is called when smellie run header is queried from CouchDB
            if ([aTag isEqualToString:kSmellieRunHeaderRetrieved]){
                NSLog(@"Object: %@\n",aResult);
                NSLog(@"result: %@\n",[aResult objectForKey:@"run_name"]);
                //[self parseSmellieRunHeaderDoc:aResult];
            }else if ([aTag isEqualToString:kSmellieConfigHeaderRetrieved]){
                NSLog(@"Smellie configuration file Object: %@\n",aResult);
                //[self parseSmellieConfigHeaderDoc:aResult];
            }else if ([aTag isEqualToString:kTellieRunDocumentAdded]){
                NSMutableDictionary* runDoc = [[self tellieRunDoc] mutableCopy];
                [runDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                [self setTellieRunDoc:runDoc];
                [runDoc release];
            } else if ([aTag isEqualToString:kSmellieRunDocumentAdded]){
                NSMutableDictionary* runDoc = [[self smellieRunDoc] mutableCopy];
                [runDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                [self setSmellieRunDoc:runDoc];
                [runDoc release];
            }
            //If no tag is found for the query result
            else {
                NSLog(@"No Tag assigned to that query/couchDB View \n");
                NSLog(@"Object: %@\n",aResult);
            }
        }

        else if([aResult isKindOfClass:[NSArray class]]){
            [aResult prettyPrint:@"CouchDB"];
        }else{
            //no docs found 
        }
    }
}

- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;
{
    /*
     Get an ORCouchDB object pointing to a sno+ couchDB repo.
     
     Arguments:
     id aCouchDelegate:  An ELLIEModel object which will be delgated some functionality during
     ORCouchDB function calls.
     NSString* entryDB:  The SNO+ couchDB repo to be assocated with the ORCouchDB object.
     
     Returns:
     ORCouchDB* result:  An ORCouchDB object pointing to the entryDB repo.
     
     COMMENT:
     I'm not sure why this is here? There is an identical method in SNOPModel. Might be worth
     deleting this method and replacing any reference to it with the SNOPModel version.
     */
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel* aSnotModel = [objs objectAtIndex:0];

    ORCouchDB* result = [ORCouchDB couchHost:aSnotModel.orcaDBIPAddress
                                        port:aSnotModel.orcaDBPort
                                    username:aSnotModel.orcaDBUserName
                                         pwd:aSnotModel.orcaDBPassword
                                    database:entryDB
                                    delegate:self];
    
    if (aCouchDelegate)
        [result setDelegate:aCouchDelegate];
    
    return result;
}

- (ORCouchDB*) generalDBRef:(NSString*)aCouchDb
{
    /*
     Get and return a reference to a couchDB repo.
     
     Arguments:
     NSString* aCouchDb : The database name e.g. telliedb/rat
     */
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];

    //Initialise the SNOPModel
    SNOPModel* aSnotModel = [objs objectAtIndex:0];

    //Commented out for testing
    return [ORCouchDB couchHost:[aSnotModel orcaDBIPAddress]
                           port:[aSnotModel orcaDBPort]
                       username:[aSnotModel orcaDBUserName]
                            pwd:[aSnotModel orcaDBPassword]
                       database:aCouchDb
                       delegate:aSnotModel];
}

- (NSString*) stringDateFromDate:(NSDate*)aDate
{
    /*
     Format date object to a string for inclusion in couchDB files.
     
     Arguments:
     NSDate* aDate : A NSDate object with the current time / date.
     
     Returns:
     NSString* result : The date formatted into a human readable sting.
     */
    NSDateFormatter* snotDateFormatter = [[NSDateFormatter alloc] init];
    [snotDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SS'Z'"];
    snotDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate* strDate;
    if (!aDate)
        strDate = [NSDate date];
    else
        strDate = aDate;
    NSString* result = [snotDateFormatter stringFromDate:strDate];
    [snotDateFormatter release];

    return result;
}

- (NSString*) stringUnixFromDate:(NSDate*)aDate
{
    /*
     Format date object to a string with the standard unix format.
     
     Arguments:
     NSDate* aDate : A NSDate object with the current time / date.
     
     Returns:
     NSString* result : The date formatted into a human readable sting.
     */
    NSDate* strDate;
    if(!aDate){
        strDate = [NSDate date];
    }else{
        strDate = aDate;
    }
    NSString* result = [NSString stringWithFormat:@"%f",[strDate timeIntervalSince1970]];
    strDate = nil;

    return result;
}

@end
