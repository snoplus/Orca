//
//  ELLIEModel.h
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//  Revision history:
//  Ed Leming 30/12/2015 - Memory updates and tidy up.
//

#import <Foundation/Foundation.h>
#import "ELLIEController.h"
#import "XmlrpcClient.h"

@class ORCouchDB;
@class ORRunModel;
@class ORRunController;

@interface ELLIEModel :  OrcaObject
{
    ///////////////////////////////////////////
    //Define instance variables for ELLIEModel
    
    NSMutableDictionary* _smellieRunSettings;
    NSMutableDictionary* _currentOrcaSettingsForSmellie;
    NSMutableDictionary* _tellieRunDoc;
    NSMutableDictionary* _smellieRunDoc;
    NSTask* _exampleTask;
    NSMutableDictionary* _smellieRunHeaderDocList;
    NSMutableArray* _smellieSubRunInfo;
    bool _smellieDBReadInProgress;
    float _pulseByPulseDelay;

    //Server Clients
    NSString* _tellieHost;
    NSString* _telliePort;

    NSString* _smellieHost;
    NSString* _smelliePort;

    NSString* _interlockHost;
    NSString* _interlockPort;
    NSThread* interlockThread;

    XmlrpcClient* _tellieClient;
    XmlrpcClient* _smellieClient;
    XmlrpcClient* _interlockClient;

    //tellie settings
    NSMutableDictionary* _tellieSubRunSettings;
    NSMutableDictionary* _tellieFireParameters;
    NSMutableDictionary* _tellieFibreMapping;
    NSMutableDictionary* _tellieNodeMapping;
    NSArray* _tellieRunNames;
    BOOL _ellieFireFlag;
    BOOL _tellieMultiFlag;

    //smellie config mappings
    NSMutableDictionary* _smellieLaserHeadToSepiaMapping;
    NSMutableDictionary* _smellieLaserToInputFibreMapping;
    NSMutableDictionary* _smellieFibreSwitchToFibreMapping;
    NSNumber* _smellieConfigVersionNo;
    BOOL _smellieSlaveMode;

    // Run threads
    NSThread* _tellieThread;
    NSThread* _smellieThread;
}

@property (nonatomic,retain) NSMutableDictionary* tellieFireParameters;
@property (nonatomic,retain) NSMutableDictionary* tellieFibreMapping;
@property (nonatomic,retain) NSMutableDictionary* tellieNodeMapping;
@property (nonatomic,retain) NSArray* tellieRunNames;
@property (nonatomic,retain) NSMutableDictionary* tellieSubRunSettings;
@property (nonatomic,retain) NSMutableDictionary* smellieRunSettings;
@property (nonatomic,retain) NSMutableDictionary* currentOrcaSettingsForSmellie;
@property (nonatomic,retain) NSMutableDictionary* smellieLaserHeadToSepiaMapping;
@property (nonatomic,retain) NSMutableDictionary* smellieLaserToInputFibreMapping;
@property (nonatomic,retain) NSMutableDictionary* smellieFibreSwitchToFibreMapping;
@property (nonatomic,retain) NSNumber* smellieConfigVersionNo;
@property (nonatomic,assign) BOOL smellieSlaveMode;
@property (nonatomic,retain) NSMutableDictionary* tellieRunDoc;
@property (nonatomic,retain) NSMutableDictionary* smellieRunDoc;
@property (nonatomic,assign) BOOL ellieFireFlag;
@property (nonatomic,assign) BOOL tellieMultiFlag;
@property (nonatomic,retain) NSTask* exampleTask;
@property (nonatomic,retain) NSMutableDictionary* smellieRunHeaderDocList;
@property (nonatomic,retain) NSMutableArray* smellieSubRunInfo;
@property (nonatomic,assign) bool smellieDBReadInProgress;
@property (nonatomic,assign) float pulseByPulseDelay;
@property (nonatomic,retain) NSString* tellieHost;
@property (nonatomic,retain) NSString* smellieHost;
@property (nonatomic,retain) NSString* interlockHost;
@property (nonatomic,retain) NSString* telliePort;
@property (nonatomic,retain) NSString* smelliePort;
@property (nonatomic,retain) NSString* interlockPort;
@property (nonatomic,retain) XmlrpcClient* tellieClient;
@property (nonatomic,retain) XmlrpcClient* smellieClient;
@property (nonatomic,retain) XmlrpcClient* interlockClient;
@property (nonatomic,retain) NSThread* tellieThread;
@property (nonatomic,retain) NSThread* smellieThread;


-(id) init;
-(id) initWithCoder:(NSCoder*)deoder;
-(void)encodeWithCoder:(NSCoder*)encoder;
-(void) setUpImage;
-(void) makeMainController;
-(void) wakeUp;
-(void) sleep;
-(void) dealloc;

/************************/
/* SERVER tab Functions */
/************************/
-(BOOL)pingTellie;
-(BOOL)pingSmellie;
-(BOOL)pingInterlock;

/************************/
/*   TELLIE Functions   */
/************************/

// TELLIE calc & control functons
-(NSArray*) pollTellieFibre:(double)seconds;
-(BOOL)photonIntensityCheck:(NSUInteger)photons atFrequency:(NSUInteger)frequency;
-(NSMutableDictionary*) returnTellieFireCommands:(NSString*)fibre  withNPhotons:(NSUInteger)photons withFireFrequency:(NSUInteger)frequency withNPulses:(NSUInteger)pulses withTriggerDelay:(NSUInteger)delay inSlave:(BOOL)mode;
-(NSNumber*) calcTellieChannelPulseSettings:(NSUInteger)channel withNPhotons:(NSUInteger)photons withFireFrequency:(NSUInteger)frequency inSlave:(BOOL)mode;
-(NSNumber*) calcTellieChannelForFibre:(NSString*)fibre;
-(NSString*) calcTellieFibreForNode:(NSUInteger)node;
-(NSString*) calcTellieFibreForChannel:(NSUInteger)channel;
-(NSNumber*)calcPhotonsForIPW:(NSUInteger)ipw forChannel:(NSUInteger)channel inSlave:(BOOL)inSlave;
-(NSString*)selectPriorityFibre:(NSArray*)fibres forNode:(NSUInteger)node;
-(void) startTellieRunThread:(NSDictionary*)fireCommands;
-(void)startTellieMultiRunThread:(NSArray*)fireCommandArray;
-(void) startTellieMultiRun:(NSArray*)fireCommandArray;
-(void) startTellieRun:(NSDictionary*)fireCommands;
-(void) stopTellieRun;
-(void) waitForTellieRunToFinish;
-(void) tellieTidyUp;

// TELLIE database interactions
-(void) pushInitialTellieRunDocument;
-(void) updateTellieRunDocument:(NSDictionary*)subRunDoc;
-(void) loadTELLIEStaticsFromDB;
-(void) loadTELLIERunPlansFromDB;
-(void)parseTellieFirePars:(id)aResult;
-(void)parseTellieFibreMap:(id)aResult;
-(void)parseTellieNodeMap:(id)aResult;

/************************/
/*  SMELLIE Functions   */
/************************/

//SMELLIE Control Functions
-(void) setSmellieNewRun:(NSNumber *)runNumber;
-(void) deactivateSmellie;

-(void) setSmellieLaserHeadMasterMode:(NSNumber*)laserSwitchChan withIntensity:(NSNumber*)intensity withRepRate:(NSNumber*)rate withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withNPulses:(NSNumber*)noPulses withGainVoltage:(NSNumber*)gain;

-(void) setSmellieLaserHeadSlaveMode:(NSNumber*)laserSwitchChan withIntensity:(NSNumber*)intensity withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withTime:(NSNumber*)time withGainVoltage:(NSNumber*)gain;

-(void)setSmellieSuperkMasterMode:(NSNumber*)intensity withRepRate:(NSNumber*)rate withWavelengthLow:(NSNumber*)wavelengthLow withWavelengthHi:(NSNumber*)wavelengthHi withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withNPulses:(NSNumber*)noPulses withGainVoltage:(NSNumber *)gain;

-(NSMutableArray*)getSmellieRunLaserArray:(NSDictionary*)smellieSettings;
-(NSMutableArray*)getSmellieRunFibreArray:(NSDictionary*)smellieSettings;
-(NSMutableArray*)getSmellieRunIntensityArray:(NSDictionary*)smellieSettings forLaser:(NSString*)laser;
-(NSMutableArray*)getSmellieRunGainArray:(NSDictionary*)smellieSettings forLaser:(NSString*)laser;
-(NSMutableArray*)getSmellieLowEdgeWavelengthArray:(NSDictionary*)smellieSettings;
-(void) startSmellieRunInBackground:(NSDictionary*)smellieSettings;
-(void) activateKeepAlive:(NSNumber *)runNumber;
-(void) killKeepAlive;
-(void) pulseKeepAlive:(id)passed;
-(void) startSmellieRunThread:(NSDictionary*)smellieSettings;
-(void) startSmellieRun:(NSDictionary*)smellieSettings;
-(void) stopSmellieRun;
-(void) waitForSmellieRunToFinish;
-(void) smellieTidyUp;
-(NSNumber*)estimateSmellieRunTime:(NSDictionary*)smellieSettings;

// SMELLIE database interactions
-(void) pushInitialSmellieRunDocument;
-(void) updateSmellieRunDocument:(NSDictionary*)subRunDoc;
-(void) fetchCurrentSmellieConfig;
-(void) parseCurrentConfigVersion:(id)aResult;
-(void) fetchConfigurationFile:(NSNumber*)currentVersion;
-(void) parseConfigurationFile:(id)aResult;

/*************************/
/* Misc generic methods  */
/*************************/
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp;
- (ORCouchDB*) couchDBRef:(id)aCouchDelegate withDB:(NSString*)entryDB;
- (NSString*) stringDateFromDate:(NSDate*)aDate;
- (NSString*) stringUnixFromDate:(NSDate*)aDate;


@end

extern NSString* ELLIEAllLasersChanged;
extern NSString* ELLIEAllFibresChanged;
extern NSString* smellieRunDocsPresent;
