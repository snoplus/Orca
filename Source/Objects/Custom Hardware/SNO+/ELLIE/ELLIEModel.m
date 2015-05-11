//
//  ELLIEModel.m
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
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
#import "SNOPModel.h"
#import "ORRunModel.h"
#import "SNOPController.h"

//tags to define that an ELLIE run file has been updated
#define kSmellieRunDocumentAdded   @"kSmellieRunDocumentAdded"
#define kSmellieRunDocumentUpdated   @"kSmellieRunDocumentUpdated"
#define kTellieRunDocumentAdded   @"kTellieRunDocumentAdded"
#define kTellieRunDocumentUpdated   @"kTellieRunDocumentUpdated"
#define kAmellieRunDocumentAdded   @"kAmellieRunDocumentAdded"
#define kAmellieRunDocumentUpdated   @"kAmellieRunDocumentUpdated"
#define kSmellieRunHeaderRetrieved   @"kSmellieRunHeaderRetrieved"

NSString* ELLIEAllLasersChanged = @"ELLIEAllLasersChanged";
NSString* ELLIEAllFibresChanged = @"ELLIEAllFibresChanged";
NSString* smellieRunDocsPresent = @"smellieRunDocsPresent";


@interface ELLIEModel (private)
-(void) _pushEllieCustomRunToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile;
-(NSString*) stringDateFromDate:(NSDate*)aDate;
@end

@implementation ELLIEModel

@synthesize smellieRunSettings;
@synthesize exampleTask;
@synthesize smellieRunHeaderDocList;


- (void) setUpImage
{
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

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[super dealloc];
}

- (void) registerNotificationObservers
{
    //[super registerNotificationObservers];
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    //we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    
    
}

- (ORCouchDB*) generalDBRef:(NSString*)aCouchDb
{
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    
    //Initialise the SNOPModel
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    
	return [ORCouchDB couchHost:[aSnotModel orcaDBIPAddress]
                           port:[aSnotModel orcaDBPort]
                       username:[aSnotModel orcaDBUserName]
                            pwd:[aSnotModel orcaDBPassword]
                       database:aCouchDb
                       delegate:aSnotModel];
}

//This calls a python script but can only take two command line arguments 
-(NSString*)callPythonScript:(NSString*)pythonScriptFilePath withCmdLineArgs:(NSArray*)commandLineArgs
{
    if([commandLineArgs count] != 3){
        NSLog(@"Three command line arguments are required!");
        return nil;
    }
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/python"]; // Tell the task to execute the ssh command
    [task setArguments: [NSArray arrayWithObjects: pythonScriptFilePath, [commandLineArgs objectAtIndex:0],[commandLineArgs objectAtIndex:1],[commandLineArgs objectAtIndex:2],nil]];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle *file;
    file = [pipe fileHandleForReading]; // This file handle is a reference to the output of the ssh command
    
    @try{
        [task launch];
    }
    @catch (NSException *e) {
        NSLog(@"SMELLIE Connection Error: %@",e);
    }
    @finally {
        //do something here
    }
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *responseFromCmdLine;
    responseFromCmdLine = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]; // This string now contains the entire output of the ssh command.
    
    [task release];
    return [responseFromCmdLine autorelease];
}


//used to create the timestamp in the couchDB files 
- (NSString*) stringDateFromDate:(NSDate*)aDate
{
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
    strDate = nil;
    return [[result retain] autorelease];
}

//Push the information from the GUI into a couchDB database
-(void) _pushEllieCustomRunToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile
{
    NSAutoreleasePool* runDocPool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:100];
    
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    
    //Initialise the SNOPModel
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    
    NSString* docType = [NSMutableString stringWithFormat:@"%@%@",aCouchDBName,@"_run"];
    
    NSLog(@"document_type: %@",docType);
    
    [runDocDict setObject:docType forKey:@"doc_type"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"time_stamp"];
    [runDocDict setObject:customRunFile forKey:@"run_info"];
            
    //self.runDocument = runDocDict;
    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:aCouchDBName] addDocument:runDocDict tag:kSmellieRunDocumentAdded];
    
    [runDocPool release];
}

-(void) smellieDBpush:(NSMutableDictionary*)dbDic
{
    [self _pushEllieCustomRunToDB:@"smellie" runFiletoPush:dbDic];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
	@synchronized(self){
		if([aResult isKindOfClass:[NSDictionary class]]){
			NSString* message = [aResult objectForKey:@"Message"];
			if(message){
				[aResult prettyPrint:@"CouchDB Message:"];
			}
            
            //Look through all of the possible tags for ellie couchDB results 
            
            //This is called when smellie run header is queried from CouchDB
            if ([aTag isEqualToString:kSmellieRunHeaderRetrieved])
            {
                NSLog(@"here\n");
                NSLog(@"Object: %@\n",aResult);
                NSLog(@"result: %@\n",[aResult objectForKey:@"run_name"]);
                //[self parseSmellieRunHeaderDoc:aResult];
            }
            
            //If no tag is found for the query result
			else {
                NSLog(@"No Tag assigned to that query/couchDB View \n");
                NSLog(@"Object: %@\n",aResult);
            }
		}
        
		else if([aResult isKindOfClass:[NSArray class]]){
            [aResult prettyPrint:@"CouchDB"];
		}
        
		else {
			//no docs found 
		}
	}
}

-(void)startSmellieRunInBackground:(NSDictionary*)smellieSettings
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self performSelectorOnMainThread:@selector(startSmellieRun:) withObject:smellieSettings waitUntilDone:NO];
    [pool release];
    
}

//SMELLIE Control Functions
-(void)setSmellieSafeStates
{
    NSArray * setSafeStates = @[@"30",@"0",@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:setSafeStates];
}

-(void)setLaserSwitch:(NSString*)laserSwitchChannel
{
    NSArray * setLaserSwitchFlagAndArgument = @[@"2050",laserSwitchChannel,@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:setLaserSwitchFlagAndArgument];
}

-(void)setFibreSwitch:(NSString*)fibreSwitchChannel
{
    NSArray * setFibreSwitchFlagAndArgument = @[@"2050",fibreSwitchChannel,@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:setFibreSwitchFlagAndArgument];
}

-(void)setLaserIntensity:(NSString*)laserIntensity
{
    NSArray * setLaserIntensityFlagAndArgument = @[@"50",laserIntensity,@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:setLaserIntensityFlagAndArgument];
}

-(void)setLaserSoftLockOn
{
    NSArray * softLockOnFlag = @[@"60",@"0",@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:softLockOnFlag];
}

-(void)setLaserSoftLockOff
{
    NSArray * softLockOffFlag = @[@"70",@"0",@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:softLockOffFlag];
}

-(void)setSmellieMasterMode:(NSString*)triggerFrequency withNumOfPulses:(NSString*)numOfPulses
{
    NSString * argumentString = [NSString stringWithFormat:@"%@s%@",triggerFrequency,numOfPulses];
    NSArray * smellieMasterModeFlag = @[@"80",argumentString]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:smellieMasterModeFlag];
}

-(void)sendCustomSmellieCmd:(NSString*)customCmd withArgument1:(NSString*)customArgument1 withArgument2:(NSString*)customArgument2
{
    //Make sure all the arguments default to a safe value if not specified
    if([customCmd isEqualToString:nil]){
        customCmd = @"0";
    }
    
    if([customArgument1 isEqualToString:nil]){
        customArgument1 = @"0";
    }
    
    if([customArgument2 isEqualToString:nil]){
        customArgument2 = @"0";
    }
        
    NSArray * smellieCustomCmd = @[customCmd,customArgument1,customArgument2];
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:smellieCustomCmd];
    
}

-(void)startSmellieRun:(NSDictionary*)smellieSettings
{
    //Deconstruct runFile into indiviual subruns ------------------
    
    NSLog(@"Starting SMELLIE Run\n");
    
    NSLog(@"Setting SMELLIE into Safe States before starting a Run\n");
    [self setSmellieSafeStates];
    
    //Extract the number of intensity steps
    NSNumber * numIntStepsObj = [smellieSettings objectForKey:@"num_intensity_steps"];
    int numIntSteps = [numIntStepsObj intValue];
    
    //Extract the lasers to be fired into an array
    NSMutableArray * laserArray = [[NSMutableArray alloc] init];
    [laserArray addObject:[smellieSettings objectForKey:@"375nm_laser_on"] ];
    [laserArray addObject:[smellieSettings objectForKey:@"405nm_laser_on"] ];
    [laserArray addObject:[smellieSettings objectForKey:@"440nm_laser_on"] ];
    [laserArray addObject:[smellieSettings objectForKey:@"500nm_laser_on"] ];
    
    //Extract the fibres to be fired into an array
    NSMutableArray *fibreArray = [[NSMutableArray alloc] init];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS007"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS107"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS207"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS025"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS125"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS225"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS037"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS137"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS237"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS055"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS155"] ];
    [fibreArray addObject:[smellieSettings objectForKey:@"FS255"] ];
 
    ///Loop through each Laser
    for(int laserLoopInt = 0;laserLoopInt < [laserArray count];laserLoopInt++){
        
        //Only loop through lasers that are included in the run 
        if([[laserArray objectAtIndex:laserLoopInt] intValue] != 1){
            continue;
        }
        
        //TODO:Read in the configuration Map
        
        if([[[laserArray objectAtIndex:laserLoopInt] key] isEqualToString:@"375nm_laser_on"]){
            [self setLaserSwitch:@"1"]; //whichever channel the 375 is connected to 
        }
        else if ([[[laserArray objectAtIndex:laserLoopInt] key] isEqualToString:@"405nm_laser_on"]){
            [self setLaserSwitch:@"2"]; //whichever channel the 405 is connected to 
        }
        else if ([[[laserArray objectAtIndex:laserLoopInt] key] isEqualToString:@"440nm_laser_on"]){
            [self setLaserSwitch:@"3"]; //whichever channel the 440 is connected to
        }
        else if ([[[laserArray objectAtIndex:laserLoopInt] key] isEqualToString:@"500nm_laser_on"]){
            [self setLaserSwitch:@"4"]; //whichever channel the 500 is connected to
        }
        else{
            NSLog(@"SMELLIE RUN:No laser selected for this iteration");
        }
       
        
        //Loop through each Fibre
        for(int fibreLoopInt = 0; fibreLoopInt < [fibreArray count];fibreLoopInt++){
        
            //Only loop through fibres that are included in the run 
            if([[fibreArray objectAtIndex:fibreLoopInt] intValue] != 1){
                continue;
            }
            
            //For the moment always go through switch 5
            [self setFibreSwitch:@"5"];
            
            //Loop through each intensity of a SMELLIE run 
            for(int intensityLoopInt =0;intensityLoopInt < numIntSteps; intensityLoopInt++){
            
                //TODO: Listen for the stop smellie run notification 
                //Call the smellie system here 
                NSLog(@" Laser:%@ ", [laserArray objectAtIndex:laserLoopInt]);
                NSLog(@" Fibre:%@ ",[fibreArray objectAtIndex:fibreLoopInt]);
                NSLog(@" Intensity:%i \n'",intensityLoopInt);
                
            }//end of looping through each intensity setting on the smellie laser
            
        }//end of looping through each Fibre
        
    }//end of looping through each laser
    
    //actually start a rin with arguments
    
    /*NSMutableArray * smellieSubRun = [[NSMutableArray alloc] init];
    [smellieSubRun addObject:@"2"]; //laser channel
    [smellieSubRun addObject:@"0"]; //fibre channel
    [smellieSubRun addObject:@"100"]; //laser intensity
    [smellieSubRun addObject:@"100"]; //number of pulses
    [smellieSubRun addObject:@"100"]; //pulse frequency
    
    NSLog(@"smellieSubRunParams: %@",smellieSubRun);*/
    
    //NSString *arg1 = [NSString stringWithFormat:@"%@%@%@%@%@", @"2", @"0",@"100",@"100",@"100"];
    
    //NSArray *args = [NSArray arrayWithObjects:arg1,nil];
    
    //NSLog(@"%@",[self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/orcaSmellieRun.py" withCmdLineArgs:nil]);
    
    //[smellieSubRun release];
    [fibreArray release];
    [laserArray release];
    
}

-(void)stopSmellieRun
{
    //Even though this is stopping in Orca it can still contine on SNODROP!
    //Need a stop run command here
    //TODO: add a try and except statement here
    
    
    //TODO: Send stop smellie run notification 
    NSLog(@"Stopping SMELLIE Run\n");
}


@end
