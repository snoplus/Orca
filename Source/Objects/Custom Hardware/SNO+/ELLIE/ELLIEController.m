//
//  ELLIEController.m
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//

#import "ELLIEController.h"
#import "ELLIEModel.h"
#import "SNOPModel.h"

@implementation ELLIEController
    NSMutableDictionary *laserHeadDic;
    NSMutableDictionary *configForSmellie;
    BOOL *laserHeadSelected;
    BOOL *fibreSwitchOutputSelected;
//smellie maxiumum trigger frequency

//Set up functions
-(id)init
{
    self = [super initWithWindowNibName:@"ellie"];
    //[smellieConfigAttenutationFactor setKeyboardType:UIKeyboardTypeNumberPad];


    laserHeadSelected = NO;
    fibreSwitchOutputSelected = NO;
    
    
    @try{
    
    //this function operates under the assumption that there is an initial file already in place
    NSNumber *currentConfigurationVersion = [[NSNumber alloc] initWithInt:0];
    
    //fetch the current version of the smellie configuration
    currentConfigurationVersion = [self fetchRecentVersion];
    
    //fetch the data associated with the current configuration
    configForSmellie = [[NSMutableDictionary alloc] initWithCapacity:10];
    configForSmellie = [[self fetchCurrentConfigurationForVersion:currentConfigurationVersion] mutableCopy];
    
    //increment the current version of the incrementation
    currentConfigurationVersion = [NSNumber numberWithInt:[currentConfigurationVersion intValue] + 1];
    [configForSmellie setObject:currentConfigurationVersion forKey:@"configuration_version"];
    
    //SMELLIE Configuration file
    //Make sure these buttons are working on start up for Smellie
    [smellieNumIntensitySteps setEnabled:YES];
    [smellieMaxIntensity setEnabled:YES];
    [smellieMinIntensity setEnabled:YES];
    [smellieNumTriggersPerLoop setEnabled:YES];
    [smellieOperationMode setEnabled:YES];
    [smellieOperatorName setEnabled:YES];
    [smellieTriggerFrequency setEnabled:YES];
    [smellieRunName setEnabled:YES];
    [smellie405nmLaserButton setEnabled:YES];
    [smellie375nmLaserButton setEnabled:YES];
    [smellie440nmLaserButton setEnabled:YES];
    [smellie500nmLaserButton setEnabled:YES];
    [smellieFibreButtonFS007 setEnabled:YES];
    [smellieFibreButtonFS107 setEnabled:YES];
    [smellieFibreButtonFS207 setEnabled:YES];
    [smellieFibreButtonFS025 setEnabled:YES];
    [smellieFibreButtonFS125 setEnabled:YES];
    [smellieFibreButtonFS225 setEnabled:YES];
    [smellieFibreButtonFS037 setEnabled:YES];
    [smellieFibreButtonFS137 setEnabled:YES];
    [smellieFibreButtonFS237 setEnabled:YES];
    [smellieFibreButtonFS055 setEnabled:YES];
    [smellieFibreButtonFS155 setEnabled:YES];
    [smellieFibreButtonFS255 setEnabled:YES];
    [smellieAllFibresButton setEnabled:YES];
    [smellieAllLasersButton setEnabled:YES];
    [smellieMakeNewRunButton setEnabled:NO];
    
    }
    @catch (NSException *e) {
        NSLog(@"CouchDB for ELLIE isn't connected properly. Please reload the ELLIE Gui and check the database connections\n");
        NSLog(@"Reason for error %@",e);
    }
        
    //load most recent smellie config file 
    laserHeadDic = [[NSMutableDictionary alloc] initWithCapacity:100];
        
    
    
    //NSMutableDictionary *smellieRunInfo = [[NSMutableDictionary alloc] init];
    
    //NSLog(@"Value of smellie %@",[smellieRunInfo objectForKey:@"run_name"]);
    
    //[smellieRunName release];
    
    /*Setting up TELLIE GUI */
    [self initialiseTellie];


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
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[super registerNotificationObservers];
    
    //we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(setAllLasersAction:)
						 name : ELLIEAllLasersChanged
					   object : model];
    
    [notifyCenter addObserver : self
					 selector : @selector(setAllFibresAction:)
						 name : ELLIEAllFibresChanged
					   object : model];
    
    [notifyCenter addObserver:self
                     selector:@selector(loadCurrentInformationForLaserHead)
                         name:NSComboBoxSelectionDidChangeNotification
                       object:smellieConfigLaserHeadField];
    
}


//TELLIE Functions 

//Check to see if Tellie setting are correct
-(BOOL) areTellieSettingsValid
{
    return YES;
}
     
-(void) initialiseTellie
{
    [self updateGuiTellieIsNotReady];
    [telliePollButton setEnabled:YES];
    
}

-(void) updateGuiTellieIsReady
{
    //Now we have confirmed the validation
    [tellieValidateSettingsButton setEnabled:NO];
    [tellieChangeSettings setEnabled:YES];
    [startTellieButton setEnabled:YES];
    [stopTellieButton setEnabled:YES];
    [tellieChannelTf setEnabled:NO];
    [telliePhotonsTf setEnabled:NO];
    [telliePulseRateTf setEnabled:NO];
    [telliePulseHeightTf setEnabled:NO];
    [telliePulseWidthTf setEnabled:NO];
}

-(void) updateGuiTellieIsNotReady
{
    //Now we have confirmed the validation
    [tellieValidateSettingsButton setEnabled:YES];
    [tellieChangeSettings setEnabled:NO];
    [startTellieButton setEnabled:NO];
    [stopTellieButton setEnabled:NO];
    [tellieChannelTf setEnabled:YES];
    [telliePhotonsTf setEnabled:YES];
    [telliePulseRateTf setEnabled:YES];
    [telliePulseHeightTf setEnabled:YES];
    [telliePulseWidthTf setEnabled:YES];
}

//Validate that the GUI settings make sense
-(IBAction)validateTellieSettingsAction:(id)sender
{
    //Confirm the validation of the tellie fibre settings
    BOOL settingsOk = [self areTellieSettingsValid];
    
    if(settingsOk){
        [self updateGuiTellieIsReady];
    }
    else if (!settingsOk){
        [self updateGuiTellieIsNotReady];
    }
    else{
        NSLog(@"TELLIE_CONTROL:Please reset the Tellie GUI by closing it and reopening it\n");
    }
}

- (BOOL) isNumeric:(NSString *)s{
    NSScanner *sc = [NSScanner scannerWithString: s];
    if ( [sc scanFloat:NULL] )
    {
        return [sc isAtEnd];
    }
    return NO;
}

-(void)controlTextDidBeginEditing:(NSNotification *)note{
    
}

- (void)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    NSLog(@"Selector method is (%@)", NSStringFromSelector( commandSelector ) );
    /*if (commandSelector == @selector(insertNewline:)) {
        if([control isKindOfClass:[NSTextField class]]){
            [control setBackgroundColor:[NSColor greenColor]];
        }
    }*/
}

-(void)controlTextDidEndEditing:(NSNotification *)note {
    NSTextField * changedField = [note object];
    
    //check to see if the note is the trigger delay
    if([note object] == tellieTriggerDelayTf)
    {
        int triggerDelayNumber = [changedField intValue];
        //5ns discrete steps, so again, adjustment needed if user enters e.g. 1.0 ns)
        int minimumNumberTriggerDelaySteps = 5;     //in ns
        int minimumTriggerDelay = 0;                //in ns
        int maxmiumTriggerDelay = 1275;             //in ns
        int triggerDelayRemainder = (triggerDelayNumber  % minimumNumberTriggerDelaySteps);
        
        if(triggerDelayNumber  > maxmiumTriggerDelay){
            NSLog(@"Tellie: Maximum Trigger Delay is 1275ns, setting to the maximum trigger delay\n");
            [[note object] setIntValue:maxmiumTriggerDelay];
        }
        else if (triggerDelayNumber  < minimumTriggerDelay){
            NSLog(@"Tellie: Minimum Trigger Delay is 0ns, setting to the minimum trigger delay\n");
            [[note object] setIntValue:minimumTriggerDelay];
        }
        else{
            if (triggerDelayRemainder == 0) {
                //do nothing, this value is valid
            }
            else {
                //Make the trigger delay divisible by 5
                [[note object] setIntValue:(triggerDelayNumber  - triggerDelayRemainder)];
            }
        }
    } //end of checking trigger delay
    
    //set the background colour to green
    [[note object] setBackgroundColor:[NSColor orangeColor]];
}


//Poll the Tellie Fibre
-(IBAction)pollTellieFibreAction:(id)sender
{
    [model pollTellieFibre];
}

//manual override to stop the Tellie Fibre firing
-(IBAction)stopTellieFibreAction:(id)sender
{
    [model stopTellieFibre:nil];
}

-(IBAction)fireTellieFibreAction:(id)sender
{
    [model fireTellieFibre:nil];
}

-(BOOL) isTellieChannelValid
{
    //Need logic to check the channel is correct here
    return YES;
}

-(BOOL) isTelliePhotonNumberValid
{
    //Need a valid range for the number of photons for Tellie
    return YES;
}

-(BOOL) isTelliePulseRateValid
{
    //Need a valid range for the Pulse rate of Tellie
    return YES;
}

-(BOOL) isTelliePulseHeightValid
{
    //Need a valid pulse height range for Tellie
    return YES;
}

-(BOOL) isTelliePulseWidthValid
{
    //Need a valid Pulse width range for Tellie
    return YES;
}

-(BOOL) isTellieTriggerDelayValid
{
    //0 to 1275 ns (in 5ns discrete steps, so again, adjustment needed if user enters e.g. 1.0 ns)
    int minimumTriggerDelay = 0;
    int maximumTriggerDelay = 1275;
    NSNumber *tellieTriggerDelay = [NSNumber numberWithInt:[[tellieTriggerDelayTf value] intValue]];
    if( ([tellieTriggerDelay intValue] <= maximumTriggerDelay) && ([tellieTriggerDelay intValue] >= minimumTriggerDelay)){
        NSLog(@"TELLIE_CONTROL: Setting Trigger Delay to %i ns\n",[tellieTriggerDelay intValue]);
        return YES;
    }
    else{
        NSLog(@"TELLIE_CONTROL: Trigger delay cannot be larger than 1275ns\n");
        return NO;
    }
}

-(BOOL) isTellieFibreDelayValid
{
    //Need a valid fibre delay range
    return YES;
}

//SMELLIE functions -------------------------


-(void) loadCurrentInformationForLaserHead
{
    //load information from a configArray
    [smellieConfigAttenuatorField selectItemWithObjectValue:nil];
    [smellieConfigFsInputCh selectItemWithObjectValue:nil];
    [smellieConfigFsOutputCh selectItemWithObjectValue:nil];
    [smellieConfigDetectorFibreRef selectItemWithObjectValue:nil];
}

//enables all lasers if the "all lasers" box is enabled 
-(IBAction)setAllLasersAction:(id)sender;
{
    if([smellieAllLasersButton state] == 1){
        //Set the state of all Lasers to 1
        [smellie375nmLaserButton setState:1];
        [smellie405nmLaserButton setState:1];
        [smellie440nmLaserButton setState:1];
        [smellie500nmLaserButton setState:1];
    }
    
}

//enables all fibres if the "all fibres" box is enabled 
-(IBAction)setAllFibresAction:(id)sender;
{
    if([smellieAllFibresButton state] == 1){
        [smellieFibreButtonFS007 setState:1];
        [smellieFibreButtonFS107 setState:1];
        [smellieFibreButtonFS207 setState:1];
        [smellieFibreButtonFS025 setState:1];
        [smellieFibreButtonFS125 setState:1];
        [smellieFibreButtonFS225 setState:1];
        [smellieFibreButtonFS037 setState:1];
        [smellieFibreButtonFS137 setState:1];
        [smellieFibreButtonFS237 setState:1];
        [smellieFibreButtonFS055 setState:1];
        [smellieFibreButtonFS155 setState:1];
        [smellieFibreButtonFS255 setState:1];
    }
}

//removes the tick in case for "all lasers" if any of the lasers and not pressed
-(IBAction)allLaserValidator:(id)sender
{
    if( ([smellie375nmLaserButton state] != 1) || ([smellie405nmLaserButton state] != 1) || ([smellie440nmLaserButton state] != 1) || ([smellie500nmLaserButton state] != 1))
    {
        [smellieAllLasersButton setState:0];
    }
    
}

//removes the tick in case for "all fibres" if any of the lasers and not pressed
-(IBAction)allFibreValidator:(id)sender
{
    if( ([smellieFibreButtonFS007 state] != 1) || ([smellieFibreButtonFS107 state] != 1) || ([smellieFibreButtonFS025 state] != 1) || ([smellieFibreButtonFS125 state] != 1) || ([smellieFibreButtonFS225 state] != 1) || ([smellieFibreButtonFS037 state] != 1) || ([smellieFibreButtonFS137 state] != 1) || ([smellieFibreButtonFS237 state] != 1) || ([smellieFibreButtonFS055 state] != 1) || ([smellieFibreButtonFS155 state] != 1) || ([smellieFibreButtonFS255 state] != 1))
    {
        [smellieAllFibresButton setState:0];
    }
    
}

//Force the string value to be less than 100 and a valid value
-(IBAction)validateLaserMaxIntensity:(id)sender;
{
    NSString* maxLaserIntString = [smellieMaxIntensity stringValue];
    int maxLaserIntensity;
    
    @try{
        maxLaserIntensity  = [maxLaserIntString intValue];
    }
    @catch (NSException *e) {
        maxLaserIntensity = 100;
        [smellieMaxIntensity setIntValue:maxLaserIntensity];
        NSLog(@"SMELLIE_RUN_BUILDER: Maximum Laser intensity is invalid. Setting to 100%% by Default\n");
    }
    
    if((maxLaserIntensity < 0) ||(maxLaserIntensity > 100))
    {
        maxLaserIntensity = 100;
        [smellieMaxIntensity setIntValue:maxLaserIntensity];
        NSLog(@"SMELLIE_RUN_BUILDER: Maximum Laser intensity is too high (or too low). Setting to 100%% by Default\n");
    }
}

-(IBAction)validateLaserMinIntensity:(id)sender;
{
    NSString* minLaserIntString = [smellieMinIntensity stringValue];
    int minLaserIntensity;
    
    @try{
        minLaserIntensity  = [minLaserIntString intValue];
    }
    @catch (NSException *e) {
        minLaserIntensity = 20;
        [smellieMinIntensity setIntValue:minLaserIntensity];
        NSLog(@"SMELLIE_RUN_BUILDER: Minimum Laser intensity is invalid. Setting to 20%% by Default\n");
    }
    
    if((minLaserIntensity < 0) || (minLaserIntensity > 100))
    {
        minLaserIntensity = 0;
        [smellieMinIntensity setIntValue:minLaserIntensity];
        NSLog(@"SMELLIE_RUN_BUILDER: Minimum Laser intensity is too low or high. Setting to 0%% by Default\n");
    }
}

//The number of intensity steps cannot be more than the maximum intensity less minimum intensity 
-(IBAction)validateIntensitySteps:(id)sender;
{
    int numberOfIntensitySteps;
    int maxNumberOfSteps;
    
    @try{
        numberOfIntensitySteps = [smellieNumIntensitySteps intValue];
        maxNumberOfSteps = [smellieMaxIntensity intValue] - [smellieMinIntensity intValue];
    }
    @catch(NSException *e){
        NSLog(@"SMELLIE_RUN_BUILDER: Number of Intensity steps is invalid. Setting the number of steps to 1\n");
        numberOfIntensitySteps = 1;
        [smellieNumIntensitySteps setIntValue:numberOfIntensitySteps];
    }
    
    if( (numberOfIntensitySteps > maxNumberOfSteps)|| (numberOfIntensitySteps < 1) || (remainderf((1.0*maxNumberOfSteps),(1.0*numberOfIntensitySteps)) != 0)){
        numberOfIntensitySteps = 1;
        [smellieNumIntensitySteps setIntValue:numberOfIntensitySteps];
        NSLog(@"SMELLIE_RUN_BUILDER: Number of Intensity steps is invalid. Setting the the maximum correct value\n");
    }
    
}

//checks to make sure the trigger frequency isn't too high
-(IBAction)validateSmellieTriggerFrequency:(id)sender;
{
    int triggerFrequency;
    //maxmium allowed trigger frequency in the GUI
    int maxmiumTriggerFrequency = 1000;
    
    @try{
        triggerFrequency = [smellieTriggerFrequency intValue];
    }
    @catch(NSException *e){
        NSLog(@"SMELLIE_RUN_BUILDER: Trigger Frequency is invalid. Setting the frequency to 10 Hz\n");
        triggerFrequency = 10;
        [smellieTriggerFrequency setIntValue:triggerFrequency];
    }
    
    if( (triggerFrequency > maxmiumTriggerFrequency) || (triggerFrequency < 0)){
        [smellieTriggerFrequency setIntValue:10];
        NSLog(@"SMELLIE_RUN_BUILDER: Trigger Frequency is invalid. Setting the frequency to 10 Hz\n");
    }
}

-(IBAction)validateNumTriggersPerStep:(id)sender;
{
    int numberTriggersPerStep;
    //maxmium allowed number of triggers per loop
    int maximumNumberTriggersPerStep = 100000;
    
    @try{
        numberTriggersPerStep = [smellieNumTriggersPerLoop intValue];
    }
    @catch(NSException *e){
        NSLog(@"SMELLIE_RUN_BUILDER: Triggers per loop is invalid. Setting to 100\n");
        [smellieNumTriggersPerLoop setIntValue:100];
    }
    
    if( (numberTriggersPerStep > maximumNumberTriggersPerStep) || (numberTriggersPerStep < 0)){
        NSLog(@"SMELLIE_RUN_BUILDER: Triggers per loop is invalid. Setting to 100\n");
        [smellieNumTriggersPerLoop setIntValue:100];
    }
}

-(IBAction)validationSmellieRunAction:(id)sender;
{
    //NSLog(@" output: %@",[model callPythonScript:@"/Users/jonesc/testScript.py" withCmdLineArgs:nil]);
    [smellieMakeNewRunButton setEnabled:NO];
    
    //Error messages
    NSString* smellieRunErrorString = [[NSString alloc] initWithString:@"Unable to Validate. Check all fields are entered and see Status and Error Log" ];
    
    NSNumber* validationErrorFlag = [NSNumber numberWithInt:1];
    //validationErrorFlag = [NSNumber numberWithInt:1];
    
    //check the Operator has entered their name 
    if([[smellieOperatorName stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a Operator Name \n");
    }

    //TODO:Check there are no files with the same name (although each will have a unique id)
    //check the Operator has a valid run name 
    else if([[smellieRunName stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a Run Name\n");
    }
    
    //check that an operation mode has been given 
    else if([[smellieOperationMode stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter an Operation Mode \n");
    }
    
    //check the maximum laser intensity is given
    else if([[smellieMaxIntensity stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter an Maxmium Laser Intensity\n");
    }
    
    //check the minimum laser intensity is given
    else if([[smellieMinIntensity stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter an Minimum Laser Intensity\n");
    }
    
    //check the intensity step is given 
    else if([[smellieNumIntensitySteps stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a number of intensity steps\n");
    }
    
    //check the trigger frequency is given 
    else if([[smellieTriggerFrequency stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a trigger frequency\n");
    }
    
    //check the trigger frequency is given
    else if([[smellieNumTriggersPerLoop stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a number of triggers per loop\n");
    }
    
    else{
        validationErrorFlag = [NSNumber numberWithInt:2];
    }
    
    //If any errors has been detected in the validation 
    if([validationErrorFlag intValue] == 1){
        [smellieRunErrorTextField setStringValue:smellieRunErrorString];
        [smellieMakeNewRunButton setEnabled:NO]; //Disable the user from this button
    }
    else if ([validationErrorFlag intValue] == 2){
        [smellieRunErrorTextField setStringValue:@"No Error"];
        [smellieMakeNewRunButton setEnabled:YES]; //Enable the user from this button

        //We need to block out all the textFields until the run has been submitted!
        [smellieNumIntensitySteps setEnabled:NO];
        [smellieMaxIntensity setEnabled:NO];
        [smellieMinIntensity setEnabled:NO];
        [smellieNumTriggersPerLoop setEnabled:NO];
        [smellieOperationMode setEnabled:NO];
        [smellieOperatorName setEnabled:NO];
        [smellieTriggerFrequency setEnabled:NO];
        [smellieRunName setEnabled:NO];
        [smellie405nmLaserButton setEnabled:NO];
        [smellie375nmLaserButton setEnabled:NO];
        [smellie440nmLaserButton setEnabled:NO];
        [smellie500nmLaserButton setEnabled:NO];
        [smellieFibreButtonFS007 setEnabled:NO];
        [smellieFibreButtonFS107 setEnabled:NO];
        [smellieFibreButtonFS207 setEnabled:NO];
        [smellieFibreButtonFS025 setEnabled:NO];
        [smellieFibreButtonFS125 setEnabled:NO];
        [smellieFibreButtonFS225 setEnabled:NO];
        [smellieFibreButtonFS037 setEnabled:NO];
        [smellieFibreButtonFS137 setEnabled:NO];
        [smellieFibreButtonFS237 setEnabled:NO];
        [smellieFibreButtonFS055 setEnabled:NO];
        [smellieFibreButtonFS155 setEnabled:NO];
        [smellieFibreButtonFS255 setEnabled:NO];
        [smellieAllFibresButton setEnabled:NO];
        [smellieAllLasersButton setEnabled:NO];
        
    }
    else{
        NSLog(@"SMELLIE_BUILD_RUN: Unknown invalid Entry or no entries sent\n");
    }
    
    [smellieRunErrorString release];
    
    //Example functions of how this values can be pulled 
    //state 1 is ON, state 0 is OFF for these buttons
    //NSLog(@"375 laser setting %i \n",[smellie375nmLaserButton state]);
    //NSLog(@"Entry into the Operator Field %@ \n",[smellieOperationMode stringValue]);
    
    //[model validationSmellieSettings];
}

-(IBAction)testButtonAction:(id)sender
{
    [model testFunction];
}

-(IBAction)makeNewSmellieRun:(id)sender
{
    NSAutoreleasePool* smellieSettingsPool = [[NSAutoreleasePool alloc] init];
    
    NSMutableDictionary * smellieRunSettingsFromGUI = [NSMutableDictionary dictionaryWithCapacity:100];
    
    //Build Objects to store values
    NSString * smellieOperatorNameString = [NSString stringWithString:[smellieOperatorName stringValue]];
    NSString * smellieRunNameString = [NSString stringWithString:[smellieRunName stringValue]];
    NSString * smellieOperatorModeString = [NSString stringWithString:[smellieOperationMode stringValue]];
    
    NSNumber * smellieMaxIntensityNum = [NSNumber numberWithInt:[smellieMaxIntensity intValue]];
    NSNumber * smellieMinIntensityNum = [NSNumber numberWithInt:[smellieMinIntensity intValue]];
    NSNumber * smellieNumIntensityStepsNum = [NSNumber numberWithInt:[smellieNumIntensitySteps intValue]];
    NSNumber * smellieTriggerFrequencyNum = [NSNumber numberWithInt:[smellieTriggerFrequency intValue]];
    NSNumber * smellieNumTriggersPerLoopNum = [NSNumber numberWithInt:[smellieNumTriggersPerLoop intValue]];
    
    NSNumber * smellie405nmLaserButtonNum = [NSNumber numberWithInteger:[smellie405nmLaserButton state]];
    NSNumber * smellie375nmLaserButtonNum = [NSNumber numberWithInteger:[smellie375nmLaserButton state]];
    NSNumber * smellie440nmLaserButtonNum = [NSNumber numberWithInteger:[smellie440nmLaserButton state]];
    NSNumber * smellie500nmLaserButtonNum = [NSNumber numberWithInteger:[smellie500nmLaserButton state]];
    
    NSNumber * smellieFibreButtonFS007Num = [NSNumber numberWithInteger:[smellieFibreButtonFS007 state]];
    NSNumber * smellieFibreButtonFS107Num = [NSNumber numberWithInteger:[smellieFibreButtonFS107 state]];
    NSNumber * smellieFibreButtonFS207Num = [NSNumber numberWithInteger:[smellieFibreButtonFS207 state]];
    NSNumber * smellieFibreButtonFS025Num = [NSNumber numberWithInteger:[smellieFibreButtonFS025 state]];
    NSNumber * smellieFibreButtonFS125Num = [NSNumber numberWithInteger:[smellieFibreButtonFS125 state]];
    NSNumber * smellieFibreButtonFS225Num = [NSNumber numberWithInteger:[smellieFibreButtonFS225 state]];
    NSNumber * smellieFibreButtonFS037Num = [NSNumber numberWithInteger:[smellieFibreButtonFS037 state]];
    NSNumber * smellieFibreButtonFS137Num = [NSNumber numberWithInteger:[smellieFibreButtonFS137 state]];
    NSNumber * smellieFibreButtonFS237Num = [NSNumber numberWithInteger:[smellieFibreButtonFS237 state]];
    NSNumber * smellieFibreButtonFS055Num = [NSNumber numberWithInteger:[smellieFibreButtonFS055 state]];
    NSNumber * smellieFibreButtonFS155Num = [NSNumber numberWithInteger:[smellieFibreButtonFS155 state]];
    NSNumber * smellieFibreButtonFS255Num = [NSNumber numberWithInteger:[smellieFibreButtonFS255 state]];
    
    
    [smellieRunSettingsFromGUI setObject:smellieOperatorNameString forKey:@"operator_name"];
    [smellieRunSettingsFromGUI setObject:smellieRunNameString forKey:@"run_name"];
    [smellieRunSettingsFromGUI setObject:smellieOperatorModeString forKey:@"operation_mode"];
    [smellieRunSettingsFromGUI setObject:smellieMaxIntensityNum forKey:@"max_laser_intensity"];
    [smellieRunSettingsFromGUI setObject:smellieMinIntensityNum forKey:@"min_laser_intensity"];
    [smellieRunSettingsFromGUI setObject:smellieNumIntensityStepsNum forKey:@"num_intensity_steps"];
    [smellieRunSettingsFromGUI setObject:smellieTriggerFrequencyNum forKey:@"trigger_frequency"];
    [smellieRunSettingsFromGUI setObject:smellieNumTriggersPerLoopNum forKey:@"triggers_per_loop"];
    [smellieRunSettingsFromGUI setObject:smellie375nmLaserButtonNum forKey:@"375nm_laser_on"];
    [smellieRunSettingsFromGUI setObject:smellie405nmLaserButtonNum forKey:@"405nm_laser_on"];
    [smellieRunSettingsFromGUI setObject:smellie440nmLaserButtonNum forKey:@"440nm_laser_on"];
    [smellieRunSettingsFromGUI setObject:smellie500nmLaserButtonNum forKey:@"500nm_laser_on"];
    
    //Fill the SMELLIE Fibre Array information
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS007Num forKey:@"FS007"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS107Num forKey:@"FS107"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS207Num forKey:@"FS207"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS025Num forKey:@"FS025"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS125Num forKey:@"FS125"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS225Num forKey:@"FS225"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS037Num forKey:@"FS037"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS137Num forKey:@"FS137"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS237Num forKey:@"FS237"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS055Num forKey:@"FS055"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS155Num forKey:@"FS155"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS255Num forKey:@"FS255"];
    
    NSLog(@" operator_name (string) %@\n",[smellieRunSettingsFromGUI objectForKey:@"operator_name"]);
    NSLog(@" max intensity (string) %@\n",[smellieRunSettingsFromGUI objectForKey:@"max_laser_intensity"]);
    NSLog(@" laser state (string) %@\n",[smellieRunSettingsFromGUI objectForKey:@"405nm_laser_on"]);
    
    [model smellieDBpush:smellieRunSettingsFromGUI];
    
    //Re-enable these buttons for editing
    [smellieNumIntensitySteps setEnabled:YES];
    [smellieMaxIntensity setEnabled:YES];
    [smellieMinIntensity setEnabled:YES];
    [smellieNumTriggersPerLoop setEnabled:YES];
    [smellieOperationMode setEnabled:YES];
    [smellieOperatorName setEnabled:YES];
    [smellieTriggerFrequency setEnabled:YES];
    [smellieRunName setEnabled:YES];
    [smellie405nmLaserButton setEnabled:YES];
    [smellie375nmLaserButton setEnabled:YES];
    [smellie440nmLaserButton setEnabled:YES];
    [smellie500nmLaserButton setEnabled:YES];
    [smellieFibreButtonFS007 setEnabled:YES];
    [smellieFibreButtonFS107 setEnabled:YES];
    [smellieFibreButtonFS207 setEnabled:YES];
    [smellieFibreButtonFS025 setEnabled:YES];
    [smellieFibreButtonFS125 setEnabled:YES];
    [smellieFibreButtonFS225 setEnabled:YES];
    [smellieFibreButtonFS037 setEnabled:YES];
    [smellieFibreButtonFS137 setEnabled:YES];
    [smellieFibreButtonFS237 setEnabled:YES];
    [smellieFibreButtonFS055 setEnabled:YES];
    [smellieFibreButtonFS155 setEnabled:YES];
    [smellieFibreButtonFS255 setEnabled:YES];
    [smellieAllFibresButton setEnabled:YES];
    [smellieAllLasersButton setEnabled:YES];
    [smellieMakeNewRunButton setEnabled:NO];
    
    [smellieSettingsPool release];
    
    
}

-(NSNumber*) fetchRecentVersion
{
    
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    
    //Initialise the SNOPModel
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%u/smellie/_design/smellieMainQuery/_view/fetchMostRecentConfigVersion?descending=True&limit=1",[aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSNumber *currentVersionNumber;
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error =  nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if(!error){
        @try{
            //format the json response
            NSString *stringValueOfCurrentVersion = [NSString stringWithFormat:@"%@",[[[json valueForKey:@"rows"] valueForKey:@"value"]objectAtIndex:0]];
            currentVersionNumber = [NSNumber numberWithInt:[stringValueOfCurrentVersion intValue]];
            //NSLog(@"parsedNumber%@",currentVersionNumber);
            //NSLog(@"parsedString %@",stringValueOfCurrentVersion);
            //NSLog(@"valueforkey2=%@", [[json valueForKey:@"rows"] valueForKey:@"value"]);
        }
        @catch (NSException *e) {
            NSLog(@"Error in fetching the SMELLIE CONFIGURATION FILE: %@ . Please fix this before changing the configuration file",e);
        }
    }
    else{
        NSLog(@"Error querying couchDB, please check the connection is correct %@",error);
    }

    return currentVersionNumber;
}

-(NSMutableDictionary*) fetchCurrentConfigurationForVersion:(NSNumber*)currentVersion
{
    NSArray*  objs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    //NSDictionary* currentConfig;
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%u/smellie/_design/smellieMainQuery/_view/pullEllieConfigHeaders?key=[%i]&limit=1",[aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort],[currentVersion intValue]];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error =  nil;
    NSMutableDictionary *currentConfig = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if(!error){
        NSLog(@"sucessful query\n");
    }
    else{
        NSLog(@"Error querying couchDB, please check the connection is correct %@",error);
    }
    
    return [[[[currentConfig objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"] objectForKey:@"configuration_info"];
}

//Submit Smellie configuration file to the Database

-(IBAction)onSelectOfSepiaInput:(id)sender
{
    
    //TODO: Read in current information about that Sepia Input and to the detector
    //[self fetchRecentVersion];
    //Download the most recent smellie configuration - this is implemented by run number
    //NSArray*  objs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    //ELLIEModel* anELLIEModel = [objs objectAtIndex:0];
    //[anELLIEModel fetchSmellieConfigurationInformation];
    
    //print down the current self-test pmt values
    [smellieConfigSelfTestNoOfPulses setStringValue:[configForSmellie objectForKey:@"selfTestNumOfPulses"]];
    [smellieConfigSelfTestLaserTriggerFreq setStringValue:[configForSmellie objectForKey:@"selfTestLaserTrigFrequency"]];
    [smellieConfigSelfTestPmtSampleRate setStringValue:[configForSmellie objectForKey:@"selfTestPmtSamplerRate"]];
    [smellieConfigSelfTestNoOfPulsesPerLaser setStringValue:[configForSmellie objectForKey:@"selfTestNumOfPulsesPerLaser"]];
    [smellieConfigSelfTestNiTriggerOutputPin setStringValue:[configForSmellie objectForKey:@"selfTestNiTriggerOutputPin"]];
    [smellieConfigSelfTestNiTriggerInputPin setStringValue:[configForSmellie objectForKey:@"selfTestNiTriggerInputPin"]];
    
    
    int laserHeadIndex = [sender indexOfSelectedItem];
    
    for (id specificConfigValue in configForSmellie){
        if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput%i",laserHeadIndex]]){
            
            //Get the values of the configuration
            NSString *laserHeadConnected = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"laserHeadConnected"]];
            NSString *attentuatorConnected = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"splitterTypeConnected"]];
            NSString *fibreSwitchInputConnected = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"fibreSwitchInputConnected"]];
            NSString *attenutationFactor = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"attenuationFactor"]];
            
            @try{
                //try and select the correct index of the combo boxes to make this work 
                [smellieConfigLaserHeadField selectItemAtIndex:[smellieConfigLaserHeadField indexOfItemWithObjectValue:laserHeadConnected]];
                [smellieConfigAttenuatorField selectItemAtIndex:[smellieConfigAttenuatorField indexOfItemWithObjectValue:attentuatorConnected]];
                [smellieConfigFsInputCh selectItemAtIndex:[smellieConfigFsInputCh indexOfItemWithObjectValue:fibreSwitchInputConnected]];
                [smellieConfigAttenutationFactor setStringValue:attenutationFactor];
                laserHeadSelected = YES;
            }
            @catch (NSException * error) {
                NSLog(@"Error Parsing Configuration File: %@",error);
            }
            
        }
    }
}

-(IBAction)onClickLaserHead:(id)sender
{
    if(laserHeadSelected){
        //update the correct value which is selected
        NSString *currentSepiaInputChannel = [NSString stringWithFormat:@"laserInput%@",[smellieConfigSepiaInputChannel objectValueOfSelectedItem]];
        
        //copy the current object into an array
        NSMutableDictionary *currentSmellieConfigForSepiaInput = [[configForSmellie objectForKey:currentSepiaInputChannel] mutableCopy];
        
        //update with new value
        [currentSmellieConfigForSepiaInput setObject:[smellieConfigLaserHeadField objectValueOfSelectedItem] forKey:@"laserHeadConnected"];
        [configForSmellie setObject:currentSmellieConfigForSepiaInput forKey:currentSepiaInputChannel];

    }
}


- (IBAction)onClickAttenuator:(id)sender
{
    if(laserHeadSelected){
        //update the correct value which is selected
        NSString *currentSepiaInputChannel = [NSString stringWithFormat:@"laserInput%@",[smellieConfigSepiaInputChannel objectValueOfSelectedItem]];
        
        //copy the current object into an array
        NSMutableDictionary *currentSmellieConfigForSepiaInput = [[configForSmellie objectForKey:currentSepiaInputChannel] mutableCopy];
        
        //update with new value
        [currentSmellieConfigForSepiaInput setObject:[smellieConfigAttenuatorField objectValueOfSelectedItem] forKey:@"splitterTypeConnected"];
        [configForSmellie setObject:currentSmellieConfigForSepiaInput forKey:currentSepiaInputChannel];
    
    }
}

- (IBAction)onClickFibreSwithInput:(id)sender
{
    if(laserHeadSelected){
        //update the correct value which is selected
        NSString *currentSepiaInputChannel = [NSString stringWithFormat:@"laserInput%@",[smellieConfigSepiaInputChannel objectValueOfSelectedItem]];
        
        //copy the current object into an array
        NSMutableDictionary *currentSmellieConfigForSepiaInput = [[configForSmellie objectForKey:currentSepiaInputChannel] mutableCopy];
        
        //update with new value
        [currentSmellieConfigForSepiaInput setObject:[smellieConfigFsInputCh objectValueOfSelectedItem] forKey:@"fibreSwitchInputConnected"];
        [configForSmellie setObject:currentSmellieConfigForSepiaInput forKey:currentSepiaInputChannel];
        
    }
}
- (IBAction)onClickFibeSwitchOutput:(id)sender
{
    //TODO: Read in current information about that Sepia Input and to the detector
    for (id specificConfigValue in configForSmellie){
        if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"%@",[sender objectValueOfSelectedItem]]]){
            
            //Get the values of the configuration
            NSString *detectorFibreReference = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"detectorFibreReference"]];
            
            
            @try{
                //try and select the correct index of the combo boxes to make this work
                [smellieConfigDetectorFibreRef selectItemAtIndex:[smellieConfigDetectorFibreRef indexOfItemWithObjectValue:detectorFibreReference]];
                fibreSwitchOutputSelected = YES;
            }
            @catch (NSException * error) {
                NSLog(@"Error Parsing Configuration File: %@",error);
            }
            
        }
    }
}

- (IBAction)onClickDetectorFibreReference:(id)sender
{
    if(fibreSwitchOutputSelected){
        //update the correct value which is selected
        NSString *currentSepiaInputChannel = [NSString stringWithFormat:@"%@",[smellieConfigFsOutputCh objectValueOfSelectedItem]];
        
        //copy the current object into an array
        NSMutableDictionary *currentSmellieConfigForSepiaInput = [[configForSmellie objectForKey:currentSepiaInputChannel] mutableCopy];
        
        //update with new value
        [currentSmellieConfigForSepiaInput setObject:[smellieConfigDetectorFibreRef objectValueOfSelectedItem] forKey:@"detectorFibreReference"];
        [configForSmellie setObject:currentSmellieConfigForSepiaInput forKey:currentSepiaInputChannel];
    }
}


BOOL isNumeric(NSString *s)
{
    NSScanner *sc = [NSScanner scannerWithString: s];
    if ( [sc scanFloat:NULL] )
    {
        return [sc isAtEnd];
    }
    return NO;
}


- (IBAction)onChangeAttenuationFactor:(id)sender
{
    if(laserHeadSelected){
        
        float attenutationFactor = [smellieConfigAttenutationFactor floatValue];
        
        BOOL isAttenutationFactorNumeric = isNumeric([smellieConfigAttenutationFactor stringValue]);
        
        if(isAttenutationFactorNumeric == YES){
            
            //check the attenuation factor makes sense
            if((attenutationFactor < 0.0) || (attenutationFactor > 100.0)){
                NSLog(@"SMELLIE_CONFIGURATION_BUILDER: Please enter an attentuation factor between 0.0 and 100.0\n");
                [smellieConfigAttenutationFactor setFloatValue:0.0];
            }
            else{
                NSString *currentSepiaInputChannel = [NSString stringWithFormat:@"laserInput%@",[smellieConfigSepiaInputChannel objectValueOfSelectedItem]];
                //copy the current object into an array
                NSMutableDictionary *currentSmellieConfigForSepiaInput = [[configForSmellie objectForKey:currentSepiaInputChannel] mutableCopy];
                [currentSmellieConfigForSepiaInput
                    setObject:[NSString stringWithString:[smellieConfigAttenutationFactor stringValue]]
                    forKey:@"attenuationFactor"];
        
        
                [configForSmellie setObject:currentSmellieConfigForSepiaInput forKey:currentSepiaInputChannel];
            }
        }
        else{
            NSLog(@"SMELLIE_CONFIGURATION_BUILDER: Please enter a numerical value for the attenutation Factor\n");
            [smellieConfigAttenutationFactor setFloatValue:0.0];
        }
    }
}

- (IBAction)onClickNumOfPulses:(id)sender
{
    //copy the current object into an array
    NSMutableDictionary *currentSmellieConfig = [configForSmellie mutableCopy];
    
    BOOL isNumOfPulsesNumeric = isNumeric([smellieConfigSelfTestNoOfPulses stringValue]);
    
    if(isNumOfPulsesNumeric == YES){
        [currentSmellieConfig setObject:[NSString stringWithString:[smellieConfigSelfTestNoOfPulses stringValue]]
                                 forKey:@"selfTestNumOfPulses"];
        configForSmellie = [currentSmellieConfig mutableCopy];
    }
    else{
        NSLog(@"SMELLIE_CONFIGURATION_BUILDER: Please enter a numerical value for the number of pulses\n");
        [smellieConfigSelfTestNoOfPulses setFloatValue:10.0];
    }
}

- (IBAction)onClickSelfTestLasertTrigFreq:(id)sender
{
    //copy the current object into an array
    NSMutableDictionary *currentSmellieConfig = [configForSmellie mutableCopy];
    
    BOOL isLaserFreqNumeric = isNumeric([smellieConfigSelfTestLaserTriggerFreq stringValue]);
    
    if(isLaserFreqNumeric == YES){
    
        float selfTestlaserFreq = [smellieConfigSelfTestLaserTriggerFreq floatValue];
        
        //PMT monitoring system cannot deal with a frequency that is greater than 17Khz.
        //Also it is dangerous to try and trigger the laser at high rates
        if((selfTestlaserFreq < 0.0) || (selfTestlaserFreq > 17000.0)){
            NSLog(@"SMELLIE_CONFIGURATION_BUILDER: Laser self test frequency has to be between 0.0 and 17000 Hz\n");
            [smellieConfigSelfTestNoOfPulses setFloatValue:10.0];
        }
        
        else{
            [currentSmellieConfig setObject:[NSString stringWithString:[smellieConfigSelfTestLaserTriggerFreq stringValue]]
                                     forKey:@"selfTestLaserTrigFrequency"];
    
            configForSmellie = [currentSmellieConfig mutableCopy];
        }
    }
    else{
        NSLog(@"SMELLIE_CONFIGURATION_BUILDER: Please enter a numerical value for the Self test laser frequency\n");
    }
}

- (IBAction)onClickSelfTestPmtSampleRate:(id)sender
{
    //copy the current object into an array
    NSMutableDictionary *currentSmellieConfig = [configForSmellie mutableCopy];
    
    BOOL isSelfTestPmtSampleRateNumeric = isNumeric([smellieConfigSelfTestPmtSampleRate stringValue]);
    
    if(isSelfTestPmtSampleRateNumeric == YES){
    
        [currentSmellieConfig setObject:[NSString stringWithString:[smellieConfigSelfTestPmtSampleRate stringValue]]
                                 forKey:@"selfTestPmtSamplerRate"];
    
        configForSmellie = [currentSmellieConfig mutableCopy];
    }
    else{
        NSLog(@"SMELLIE_CONFIGURATION_BUILDER: Please enter a numerical value for the Self test Pmt sample rate\n");
    }
}

//PMT samples to take per Laser
- (IBAction)onClickNumOfPulsesPerLaser:(id)sender
{
    NSMutableDictionary *currentSmellieConfig = [configForSmellie mutableCopy];
    
    BOOL isNumberOfPulsesPerLaserNumeric = isNumeric([smellieConfigSelfTestNoOfPulsesPerLaser stringValue]);
    
    if(isNumberOfPulsesPerLaserNumeric == YES){
    
        [currentSmellieConfig setObject:[NSString stringWithString:[smellieConfigSelfTestNoOfPulsesPerLaser stringValue]]
                                 forKey:@"selfTestNumOfPulsesPerLaser"];
    
        configForSmellie = [currentSmellieConfig mutableCopy];
        
    }
    else{
        NSLog(@"SMELLIE_CONFIGURATION_BUILDER: Please enter a numerical value for the Self test Pmt samples per laser\n");
    }
}

- (IBAction)onClickNiTriggerOutputPin:(id)sender
{
    NSMutableDictionary *currentSmellieConfig = [configForSmellie mutableCopy];
    
    [currentSmellieConfig setObject:[NSString stringWithString:[smellieConfigSelfTestNiTriggerOutputPin stringValue]]
                             forKey:@"selfTestNiTriggerOutputPin"];
    
    configForSmellie = [currentSmellieConfig mutableCopy];
}
- (IBAction)onClickNiTriggerInputPin:(id)sender
{
    NSMutableDictionary *currentSmellieConfig = [configForSmellie mutableCopy];
    
    [currentSmellieConfig setObject:[NSString stringWithString:[smellieConfigSelfTestNiTriggerInputPin stringValue]]
                             forKey:@"selfTestNiTriggerInputPin"];
    
    configForSmellie = [currentSmellieConfig mutableCopy];
}

-(IBAction)onClickValidateSmellieConfig:(id)sender
{
    //TODO: Check the file is correct and send a message to the user
    
    [smellieConfigSubmitButton setEnabled:YES];
}

- (IBAction)onClickSubmitButton:(id)sender
{
    
    //add a version number to the smellie configuration also add a run number 
    
    //post to the database
    [model smellieConfigurationDBpush:configForSmellie];
    [self close];
}


//Custom Command for Smellie
-(IBAction)executeSmellieCmdDirectAction:(id)sender
{
    NSString * cmd = [[NSString alloc] init];
    NSLog(@"CMD %@",[executeCmdBox stringValue]);
    NSLog(@"CMD %i",[executeCmdBox indexOfSelectedItem]);
    
    int cmdIndex = [executeCmdBox indexOfSelectedItem];
    
    if(cmdIndex == 0){
        cmd = @"10";
    }
    else if (cmdIndex == 1){
        cmd = @"20";
    }
    else if (cmdIndex == 2){
        cmd = @"30";
    }
    else if (cmdIndex == 3){
        cmd = @"2050";
    }
    else if (cmdIndex == 4){
        cmd = @"40";
    }
    else if (cmdIndex == 5){
        cmd = @"50";
    }
    else if(cmdIndex == 6){
        cmd = @"60";
    }
    else if(cmdIndex == 7){
        cmd = @"70";
    }
    else if(cmdIndex == 8){
        [model setSmellieMasterMode:[NSString stringWithString:[smellieDirectArg1 stringValue]] withNumOfPulses:[NSString stringWithString:[smellieDirectArg2 stringValue]]];
        //cmd = @"80";
    }
    else if(cmdIndex == 9){
        //hardcoded command to kill external software on SNODROp (SMELLIE DAQ software)
        cmd = @"110";
    }
    else{
        cmd = @"0"; //not sure what is going on here
    }
    
    
    //NSString * cmd = [NSString stringWithString:[smellieDirectCmd stringValue]];
    NSString * arg1 = [NSString stringWithString:[smellieDirectArg1 stringValue]];
    NSString * arg2 = [NSString stringWithString:[smellieDirectArg2 stringValue]];
    if(arg1 == NULL){
        arg1 = @"0";
    }
    
    if(arg2 == NULL){
        arg2 = @"0";
    }
    
    [model sendCustomSmellieCmd:cmd withArgument1:arg1 withArgument2:arg2];
}

//TELLIE functions -------------------------



@end