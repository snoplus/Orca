//-------------------------------------------------------------------------
//  ORPQModel.h
//
//  Created by Mark A. Howe on Wednesday 10/18/2006.
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

#pragma mark ***Imported Files

#define kSnoCrates          20
#define kSnoCardsPerCrate   16
#define kSnoChannelsPerCard 32
#define kSnoChannels        (kSnoCrates * kSnoCardsPerCrate * kSnoChannelsPerCard)

@class ORPQConnection;
@class ORPQModel;

@interface ORPQModel : OrcaObject
{
@private
	ORPQConnection* pqConnection;
	NSString*	hostName;
    NSString*	userName;
    NSString*	password;
    NSString*	dataBaseName;
    BOOL		stealthMode;
}

+ (ORPQModel *)getCurrent;

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) applicationIsTerminating:(NSNotification*)aNote;

#pragma mark ***Accessors

/**
 @brief Arbitrary detector db query
 @param anObject Callback object
 @param aSelector Callback object selector (called with an ORPQResult object, or nil on error)
 @param aTimeoutSecs Timeout time in seconds (0 for no timeout)
 */
- (void) dbQuery:(NSString*)aCommand object:(id)anObject selector:(SEL)aSelector timeout:(float)aTimeoutSecs;

/**
 @brief Get specified field from detector db
 @param anObject Callback object
 @param aSelector Callback object selector (called with an NSMutableData object
 containing an int32_t array of values in detector crate/card/channel order, or nil on error)
 */
- (void) pmtdbQuery:(NSString*)aPmtdbField object:(id)anObject selector:(SEL)aSelector;

- (void) cancelDbQueries;
- (BOOL) stealthMode;
- (void) setStealthMode:(BOOL)aStealthMode;
- (NSString*) dataBaseName;
- (void) setDataBaseName:(NSString*)aDataBaseName;
- (NSString*) password;
- (void) setPassword:(NSString*)aPassword;
- (NSString*) userName;
- (void) setUserName:(NSString*)aUserName;
- (NSString*) hostName;
- (void) setHostName:(NSString*)aHostName;
- (void) logQueryException:(NSException*)e;
- (id) nextObject;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***SQL Access
- (BOOL) testConnection;
- (BOOL) connected;
- (void) disconnectSql;

@end

extern NSString* ORPQModelStealthModeChanged;
extern NSString* ORPQDataBaseNameChanged;
extern NSString* ORPQPasswordChanged;
extern NSString* ORPQUserNameChanged;
extern NSString* ORPQHostNameChanged;
extern NSString* ORPQConnectionValidChanged;
extern NSString* ORPQLock;

@interface ORPQOperation : NSOperation
{
    id delegate;
    id object;      // object for callback
    SEL selector;   // selector for main thread callback when done (no callback if nil)
}

- (id)	 initWithDelegate:(id)aDelegate;
- (id)	 initWithDelegate:(id)aDelegate object:(id)anObject selector:(SEL)aSelector;
- (void) dealloc;
@end

@interface ORRunState : NSObject
{
    @public int run;
    @public int state;
}
@end

enum ePQCommandType {
    kPQCommandType_General,
    kPQCommandType_GetPMT,
};

@interface ORPQQueryOp : ORPQOperation
{
    NSString *command;
    int commandType;
}
- (void) setCommand:(NSString*)aCommand;
- (void) setCommandType:(int)aCommandType;
- (void) setPmtdbFieldName:(NSString*)aFieldName;
- (void) cancel;
- (void) main;
@end

#define kClear 0
#define kPost  1
@interface ORPQPostAlarmOp : ORPQOperation
{
	BOOL opType;
	id alarm;
}
- (void) dealloc;
- (void) postAlarm:(id)anAlarm;
- (void) clearAlarm:(id)anAlarm;
- (void) main;
@end

