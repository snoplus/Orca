//--------------------------------------------------------
// ORSmartFolder
// Created by Mark  A. Howe on Thu Apr 08 2004
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORSmartFolder.h"
#import "ORQueue.h"

#pragma mark ***External Strings

NSString* ORFolderCopyEnabledChangedNotification	= @"ORFolderCopyEnabledChangedNotification";
NSString* ORFolderDeleteWhenCopiedChangedNotification = @"ORFolderDeleteWhenCopiedChangedNotification";
NSString* ORFolderRemoteHostChangedNotification		= @"ORFolderRemoteHostChangedNotification";
NSString* ORFolderRemotePathChangedNotification		= @"ORFolderRemotePathChangedNotification";
NSString* ORFolderRemoteUserNameChangedNotification = @"ORFolderRemoteUserNameChangedNotification";
NSString* ORFolderPassWordChangedNotification		= @"ORFolderPassWordChangedNotification";
NSString* ORFolderVerboseChangedNotification		= @"ORFolderVerboseChangedNotification";
NSString* ORFolderDirectoryNameChangedNotification  = @"ORFolderDirectoryNameChangedNotification";
NSString* ORDataFileQueueRunningChangedNotification = @"ORDataFileQueueRunningChangedNotification";
NSString* ORFolderLock								= @"ORFolderLock";
NSString* ORFolderTransferTypeChangedNotification	= @"ORFolderTransferTypeChangedNotification";

@interface ORSmartFolder (private)
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void)_deleteAllSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void)_sendAllSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
@end

@implementation ORSmartFolder
- (id) init
{
    if(self = [super init]){
        [NSBundle loadNibNamed: @"SmartFolder" owner: self];	// We're responsible for releasing the top-level objects in the NIB (our view, right now).
    }
    
    [self setDirectoryName:@"~"];
    [self setRemoteHost:@""];
    [self setRemoteUserName:@""];
    [self setPassWord:@""];
    
    //[self registerNotificationObservers];
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [view removeFromSuperview];
    [view release];
    [remoteHost release];
    [remotePath release];
    [remoteUserName release];
    [passWord release];
    [directoryName release];
    [fileQueue release];
    [theWorkingFileMover release];
    [super dealloc];
}


#pragma mark ***Accessors
- (NSString *)title
{
    return title; 
}

- (void)setTitle:(NSString *)aTitle 
{
    [title autorelease];
    title = [aTitle copy];
    if(title)[titleField setStringValue:title];
}


- (NSUndoManager*) undoManager
{
    return [[NSApp delegate] undoManager];
}

- (NSView*) view
{
    return view;
}

- (BOOL) copyEnabled
{
    return copyEnabled;
}
- (void) setCopyEnabled:(BOOL)aNewCopyEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCopyEnabled:copyEnabled];
    
    copyEnabled = aNewCopyEnabled;
    
    [[NSNotificationCenter defaultCenter] 
		    postNotificationName:ORFolderCopyEnabledChangedNotification 
                          object: self];
}

- (BOOL) deleteWhenCopied
{
    return deleteWhenCopied;
}
- (void) setDeleteWhenCopied:(BOOL)aNewDeleteWhenCopied
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDeleteWhenCopied:deleteWhenCopied];
    
    deleteWhenCopied = aNewDeleteWhenCopied;
    
    [[NSNotificationCenter defaultCenter] 
		    postNotificationName:ORFolderDeleteWhenCopiedChangedNotification 
                          object: self];
}

- (NSString*) remoteHost
{
    return remoteHost;
}
- (void) setRemoteHost:(NSString*)aNewRemoteHost
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRemoteHost:remoteHost];
    
    [remoteHost autorelease];
    remoteHost = [aNewRemoteHost copy];
    
    [[NSNotificationCenter defaultCenter] 
		    postNotificationName:ORFolderRemoteHostChangedNotification 
                          object: self];
}

- (NSString*) remotePath
{
    return remotePath;
}
- (void) setRemotePath:(NSString*)aNewRemotePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRemotePath:remotePath];
    
    [remotePath autorelease];
    remotePath = [aNewRemotePath copy];
    
    [[NSNotificationCenter defaultCenter] 
		    postNotificationName:ORFolderRemotePathChangedNotification 
                          object: self];
}

- (NSString*) remoteUserName
{
    return remoteUserName;
}
- (void) setRemoteUserName:(NSString*)aNewRemoteUserName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRemoteUserName:remoteUserName];
    
    [remoteUserName autorelease];
    remoteUserName = [aNewRemoteUserName copy];
    
    [[NSNotificationCenter defaultCenter] 
		    postNotificationName:ORFolderRemoteUserNameChangedNotification 
                          object: self];
}

- (NSString*) passWord
{
    return passWord;
}
- (void) setPassWord:(NSString*)aNewPassWord
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPassWord:passWord];
    
    [passWord autorelease];
    passWord = [aNewPassWord copy];
    
    [[NSNotificationCenter defaultCenter] 
		    postNotificationName:ORFolderPassWordChangedNotification 
                          object: self];
}

- (BOOL) verbose
{
    return verbose;
}
- (void) setVerbose:(BOOL)aNewVerbose
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVerbose:verbose];
    
    verbose = aNewVerbose;
    
    [[NSNotificationCenter defaultCenter] 
		    postNotificationName:ORFolderVerboseChangedNotification 
                          object: self];
}

- (eFileTransferType) transferType
{
    return transferType;
}
- (void) setTransferType:(eFileTransferType)aNewTransferType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTransferType:transferType];
    
    transferType = aNewTransferType;
    
    [[NSNotificationCenter defaultCenter] 
		    postNotificationName:ORFolderTransferTypeChangedNotification 
                          object: self];
}

- (BOOL) useFolderStructure
{
	return useFolderStructure;
}

- (void) setUseFolderStructure:(BOOL)aFlag;
{
	useFolderStructure = aFlag;
}

- (NSString*) finalDirectoryName
{
	NSString* path = @"~"; //default
	if(useFolderStructure){
		NSCalendarDate* date = [NSCalendarDate date];
		NSString* year  = [NSString stringWithFormat:@"%d",[date yearOfCommonEra]];
		NSString* month = [NSString stringWithFormat:@"%02d",[date monthOfYear]];
		path = [self directoryName];
		path = [path stringByAppendingPathComponent:year];
		path = [path stringByAppendingPathComponent:month];
	
		if(defaultLastPathComponent) path = [path stringByAppendingPathComponent:defaultLastPathComponent];
	}
	else {
		path = [self directoryName];
		if(defaultLastPathComponent) path = [path stringByAppendingPathComponent:defaultLastPathComponent];
	}
	return path;
}

- (NSString*) defaultLastPathComponent
{
	return defaultLastPathComponent;
}

- (void) setDefaultLastPathComponent:(NSString*)aString
{
    [defaultLastPathComponent autorelease];
    defaultLastPathComponent = [aString copy];
}


- (NSString*) directoryName
{
    return directoryName;
}
- (void) setDirectoryName:(NSString*)aNewDirectoryName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDirectoryName:directoryName];
    
    [directoryName autorelease];
    directoryName = [aNewDirectoryName copy];
 	      
    [[NSNotificationCenter defaultCenter] 
		    postNotificationName:ORFolderDirectoryNameChangedNotification 
                          object: self];
}

- (ORFileMover *) theWorkingFileMover
{
    return theWorkingFileMover; 
}

- (void) setTheWorkingFileMover: (ORFileMover *) aTheWorkingFileMover
{
    [theWorkingFileMover autorelease];
    theWorkingFileMover = [aTheWorkingFileMover retain];
}

- (void) sendAll
{
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* files = [fileManager directoryContentsAtPath:[[self directoryName]stringByExpandingTildeInPath]];
    NSEnumerator* e = [files objectEnumerator];
    NSString* aFile;
    while(aFile = [e nextObject]){
        NSString* fullName = [[[self directoryName] stringByAppendingPathComponent:aFile] stringByExpandingTildeInPath];
        BOOL isDir;
        if ([fileManager fileExistsAtPath:fullName isDirectory:&isDir] && !isDir){
            NSRange range = [fullName rangeOfString:@".DS_Store"];
            if(range.location == NSNotFound){
                [self queueFileForSending:fullName];
            }
        }
    }
    
    [self startTheQueue];
    
}

- (void) deleteAll
{
    if(!fileQueue){
        ORFileMover* mover = [[ORFileMover alloc] init];
        [mover cleanSentFolder:[[self directoryName]stringByExpandingTildeInPath]];
        [mover release];
    }
}

// ----------------------------------------------------------
// - queueIsRunning:
// ----------------------------------------------------------
- (BOOL) queueIsRunning
{
    return queueIsRunning;
}

// ----------------------------------------------------------
// - setQueueIsRunning:
// ----------------------------------------------------------
- (void) setQueueIsRunning: (BOOL) flag
{
    queueIsRunning = flag;
    
    [[NSNotificationCenter defaultCenter]
	postNotificationName:ORDataFileQueueRunningChangedNotification
                  object: self];
}

- (NSString*) queueStatusString
{   
    if(queueIsRunning) {
		if([theWorkingFileMover transferType] == eUseCURL){
			if(startCount > 1) return [NSString stringWithFormat:@"Working: %d/%d",workingOnFile,startCount];
			else return [NSString stringWithFormat:@"Working"];
		}
		else {
			if(startCount > 1)return [NSString stringWithFormat:@"Working: %d/%d  %d%%",workingOnFile,startCount,[theWorkingFileMover percentDone]];
			else return [NSString stringWithFormat:@"Working: %d%%",[theWorkingFileMover percentDone]];
		}
    }
    else return @"Idle";
}

- (NSWindow *)window 
{
    return window; 
}

- (void)setWindow:(NSWindow *)aWindow 
{
    window = aWindow; //don't retain this...
}


#pragma mark ���Data Handling

- (void) queueFileForSending:(NSString*)fullPath
{
    if(!fileQueue)fileQueue = [[ORQueue alloc] init];
    
    ORFileMover* mover = [[ORFileMover alloc] init];
    [mover setVerbose:[self verbose]];
    [mover setDelegate:self];
    [mover setFullPath:fullPath];
	[mover setTransferType:transferType];
	
    NSString* remoteFilePath = [remotePath stringByAppendingPathComponent:[fullPath lastPathComponent]];
    [mover setMoveParams:fullPath to:remoteFilePath remoteHost:remoteHost userName:remoteUserName passWord:passWord];
    
    [fileQueue enqueue:mover];
    
    [mover release]; //still retained by the queue, will be release fully when copy is done.
    
    if(queueIsRunning){
        startCount++;
        [[NSNotificationCenter defaultCenter]
            postNotificationName:ORDataFileQueueRunningChangedNotification
                          object: self];
        
    }
    else [self startTheQueue];
}

- (void) startTheQueue
{
    if(!queueIsRunning){
        startCount = [fileQueue count];
        workingOnFile = 0;
        //start the process by dequeuing and sending the first file. The next will be sent when this one is
        //finished.
        [self setTheWorkingFileMover:[fileQueue dequeue]];
        if(theWorkingFileMover){
            [theWorkingFileMover doMove];
            workingOnFile = 1;
            [self setQueueIsRunning:YES];
        }
        else {
            NSLog(@"<%@> Nothing to send.\n",title);
        }
    }
}

- (void) stopTheQueue
{
    if(queueIsRunning){
        NSLog(@"<%@> File transfer stopped manually\n",title);
        [self setQueueIsRunning:NO];
        [fileQueue removeAllObjects];
        [fileQueue release];
        fileQueue = nil;
        [theWorkingFileMover stop];
    }
}

- (BOOL) shouldRemoveFile:(NSString*)aFile
{
    if([[directoryName stringByExpandingTildeInPath] isEqualToString:[aFile stringByDeletingLastPathComponent]]){
        if(deleteWhenCopied)return YES;
        else return NO;
    }
    else return NO;
}

- (void) fileMoverIsDone: (NSNotification*)aNote
{
    // [[aNote object] release];
    //OK, the last file being sent is done, get started on the next one.
    [self setTheWorkingFileMover:[fileQueue dequeue]];
    if(theWorkingFileMover){
        [theWorkingFileMover doMove];
        workingOnFile++;
        [[NSNotificationCenter defaultCenter]
            postNotificationName:ORDataFileQueueRunningChangedNotification
                          object: self];
        
    }
    else {
        [fileQueue release];
        fileQueue = nil;
        [self setQueueIsRunning:NO];
        NSLog(@"<%@> Send queue empty.\n",title);
    }
}

- (NSString*) ensureSubFolder:(NSString*)subFolder inFolder:(NSString*)folderName
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
    NSString* tmpDir = [[folderName stringByExpandingTildeInPath] stringByAppendingPathComponent:subFolder];
    if(![fm fileExistsAtPath:tmpDir]){
        if(![fm createDirectoryAtPath:tmpDir attributes:nil]){
            NSString* aFolder = [[folderName stringByExpandingTildeInPath] stringByDeletingLastPathComponent];
            NSString* subFolder1 = [[folderName stringByExpandingTildeInPath] lastPathComponent];
            [self ensureSubFolder:subFolder1 inFolder:aFolder];
            [fm createDirectoryAtPath:tmpDir attributes:nil];
        }
    }
    return tmpDir;
}

- (NSString*) ensureExists:(NSString*)folderName
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
    NSString* tmpDir = [folderName stringByExpandingTildeInPath];
    if(![fm fileExistsAtPath:tmpDir]){
        if(![fm createDirectoryAtPath:tmpDir attributes:nil]){
            NSString* aFolder = [[folderName stringByExpandingTildeInPath] stringByDeletingLastPathComponent];
            [self ensureExists:aFolder];
            [fm createDirectoryAtPath:tmpDir attributes:nil];
        }
    }
    return tmpDir;
}



#pragma mark ***Notifications

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                      selector: @selector(copyEnabledChanged:)
                          name: ORFolderCopyEnabledChangedNotification
                       object : self];
    
    [notifyCenter addObserver : self
                      selector: @selector(deleteWhenCopiedChanged:)
                          name: ORFolderDeleteWhenCopiedChangedNotification
                       object : self];
    
    [notifyCenter addObserver : self
                      selector: @selector(remoteHostChanged:)
                          name: ORFolderRemoteHostChangedNotification
                       object : self];
    
    [notifyCenter addObserver : self
                      selector: @selector(remotePathChanged:)
                          name: ORFolderRemotePathChangedNotification
                       object : self];
    
    [notifyCenter addObserver : self
                      selector: @selector(remoteUserNameChanged:)
                          name: ORFolderRemoteUserNameChangedNotification
                       object : self];
    
    [notifyCenter addObserver : self
                      selector: @selector(passWordChanged:)
                          name: ORFolderPassWordChangedNotification
                       object : self];
    
    [notifyCenter addObserver : self
                      selector: @selector(verboseChanged:)
                          name: ORFolderVerboseChangedNotification
                       object : self];

    [notifyCenter addObserver : self
                      selector: @selector(transferTypeChanged:)
                          name: ORFolderTransferTypeChangedNotification
                       object : self];
    
    [notifyCenter addObserver : self
                      selector: @selector(directoryNameChanged:)
                          name: ORFolderDirectoryNameChangedNotification
                       object : self];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(queueChanged:)
                         name : ORDataFileQueueRunningChangedNotification
                        object: self ];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(securityStateChanged:)
                         name : ORGlobalSecurityStateChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : [self lockName]
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(sheetChanged:)
                         name : NSWindowWillBeginSheetNotification
                        object: window?window:[view window]];
    
    [notifyCenter addObserver : self
                     selector : @selector(sheetChanged:)
                         name : NSWindowDidEndSheetNotification
                        object: window?window:[view window]];
}

- (void) updateWindow
{
    [self deleteWhenCopiedChanged:nil];
    [self remoteHostChanged:nil];
    [self remotePathChanged:nil];
    [self remoteUserNameChanged:nil];
    [self passWordChanged:nil];
    [self verboseChanged:nil];
    [self transferTypeChanged:nil];
    [self directoryNameChanged:nil];
    [self copyEnabledChanged:nil];
    [self securityStateChanged:nil];
    [self lockChanged:nil];
}

- (void) updateButtons
{
    BOOL enable = ![gSecurity isLocked: [self lockName]] && !sheetDisplayed;
    [remoteHostTextField setEnabled:enable];
    [remotePathTextField setEnabled:enable];
    [userNameTextField setEnabled:enable];
    [passWordSecureTextField setEnabled:enable];
    [copyButton setEnabled:enable];
    [deleteButton setEnabled:enable];
    [verboseButton setEnabled:enable];
    [enableDeleteButton setEnabled:enable];
    [enableCopyButton setEnabled:enable];
    [chooseDirButton setEnabled:enable];
}

- (void) fileMoverPercentChanged: (NSNotification*)aNote
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORDataFileQueueRunningChangedNotification
                      object: self];
    
}

- (void) sheetChanged:(NSNotification*)aNotification
{
    if([[aNotification name] isEqualToString:NSWindowWillBeginSheetNotification]){
        if(!sheetDisplayed){
            sheetDisplayed = YES;
            [remoteHostTextField setEnabled:NO];
            [remotePathTextField setEnabled:NO];
            [userNameTextField setEnabled:NO];
            [passWordSecureTextField setEnabled:NO];
            [copyButton setEnabled:NO];
            [deleteButton setEnabled:NO];
            [verboseButton setEnabled:NO];
            [enableCopyButton setEnabled:NO];
            [enableDeleteButton setEnabled:NO];
            [chooseDirButton setEnabled:NO];
            //lockEnabledState = [lockButton isEnabled];
            //if(lockEnabledState)[lockButton setEnabled:NO];
        }
    }
    else {
        if(sheetDisplayed){
            sheetDisplayed = NO;
            [self updateButtons];
            //if(lockEnabledState)[lockButton setEnabled:YES];
        }
    }
    
}

- (void) securityStateChanged:(NSNotification*)aNotification
{
    [self checkGlobalSecurity];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:[self lockName] to:secure];
    [lockButton setEnabled:secure];
    [self updateButtons];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked: [self lockName]];
    [lockButton setState: locked];
    [self updateButtons];
}



- (void) copyEnabledChanged:(NSNotification*)note
{
	[enableCopyButton setState:[self copyEnabled]];
}

- (void) deleteWhenCopiedChanged:(NSNotification*)aNote
{
	[enableDeleteButton setState:[self deleteWhenCopied]];
}

- (void) remoteHostChanged:(NSNotification*)aNote
{
	if(remoteHost)[remoteHostTextField setStringValue:remoteHost];
}

- (void) remotePathChanged:(NSNotification*)aNote
{
	if(remotePath)[remotePathTextField setStringValue:remotePath];
}

- (void) remoteUserNameChanged:(NSNotification*)aNote
{
	if(remoteUserName)[userNameTextField setStringValue:remoteUserName];
}

- (void) passWordChanged:(NSNotification*)aNote
{
	if(passWord)[passWordSecureTextField setStringValue:passWord];
}

- (void) verboseChanged:(NSNotification*)aNote
{
	[verboseButton setState: verbose];
}

- (void) transferTypeChanged:(NSNotification*)aNote
{
	[transferTypePopupButton selectItemAtIndex:transferType];
}

- (void) directoryNameChanged:(NSNotification*)aNote
{
	if(directoryName)[dirTextField setStringValue:directoryName];
	else [dirTextField setStringValue:@"~"];
}

- (void) queueChanged:(NSNotification*)note
{        
	if([self queueIsRunning]){
		[copyButton setTitle:@"Stop"];
	}
	else {
		[copyButton setTitle:@"Send All..."];
	}
	[deleteButton setEnabled:![self queueIsRunning]];
}
- (NSString*) lockName
{
    return [NSString stringWithFormat:@"%@_%@",ORFolderLock,title];
}

#pragma mark ***Actions

- (IBAction) lockButtonAction:(id)sender
{
    [gSecurity tryToSetLock:[self lockName] to:[sender intValue] forWindow:window?window:[view window]];
}

- (IBAction) copyEnabledAction:(id)sender
{
    [self setCopyEnabled:[sender state]];
}

- (IBAction) deleteEnabledAction:(id)sender
{
    [self setDeleteWhenCopied:[sender state]];
}


- (IBAction) chooseDirButtonAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setPrompt:@"Choose"];
	[openPanel beginSheetForDirectory:directoryName?directoryName:NSHomeDirectory()
                                 file:nil
                                types:nil
                       modalForWindow:window?window:[view window]
                        modalDelegate:self
                       didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
    
}


- (IBAction) copyButtonAction:(id)sender
{
    if(![[view window] makeFirstResponder:[view window]]){
	    [[view window] endEditingFor:nil];		
    }
    
    NSBeginAlertSheet(queueIsRunning?@"Stop Sending?":@"Send All Files?",
                      queueIsRunning?@"Stop":@"Send",
                      @"Cancel",
                      nil,window?window:[view window],
                      self,
                      @selector(_sendAllSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,
                      queueIsRunning?@"You can always send them later.":
                      [NSString stringWithFormat:@"Push 'Send' to send ALL files in:\n<%@>",directoryName]);
}

- (IBAction) deleteButtonAction:(id)sender
{
    NSBeginAlertSheet(@"Delete All Sent Files?",
                      @"Delete",
                      @"Cancel",
                      nil,window?window:[view window],
                      self,
                      @selector(_deleteAllSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,
                      [NSString stringWithFormat:@"Push 'Delete' to delete files that are in:\n<%@/sentFiles>",directoryName]);
    
}


- (IBAction) remoteHostTextFieldAction:(id)sender
{
    [self setRemoteHost:[sender stringValue]];
}

- (IBAction) remotePathTextFieldAction:(id)sender
{
    [self setRemotePath:[sender stringValue]];
}

- (IBAction) passWordSecureTextFieldAction:(id)sender
{
    [self setPassWord:[sender stringValue]];
}

- (IBAction) userNameTextFieldAction:(id)sender
{
    [self setRemoteUserName:[sender stringValue]];
}

- (IBAction) verboseButtonAction:(id)sender
{
    [self setVerbose:[sender state]];
}

- (IBAction) transferPopupButtonAction:(id)sender
{
	[self setTransferType:[sender indexOfSelectedItem]];
}


#pragma mark ***Archival

static NSString* ORFolderTitle		  = @"ORFolderTitle";
static NSString* ORFolderCopyEnabled      = @"ORFolderCopyEnabled";
static NSString* ORFolderDeleteWhenCopied = @"ORFolderDeleteWhenCopied";
static NSString* ORFolderRemoteHost       = @"ORFolderRemoteHost";
static NSString* ORFolderRemotePath       = @"ORFolderRemotePath";
static NSString* ORFolderRemoteUserName   = @"ORFolderRemoteUserName";
static NSString* ORFolderPassWord         = @"ORFolderPassWord";
static NSString* ORFolderVerbose	  = @"ORFolderVerbose";
static NSString* ORFolderDirectoryName    = @"ORFolderDirectoryName";

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [NSBundle loadNibNamed: @"SmartFolder" owner: self];	// We're responsible for releasing the top-level objects in the NIB (our view, right now).
    [[self undoManager] disableUndoRegistration];
    [self setCopyEnabled:[decoder decodeBoolForKey:ORFolderCopyEnabled]];
    [self setDeleteWhenCopied:[decoder decodeBoolForKey:ORFolderDeleteWhenCopied]];
    [self setRemoteHost:[decoder decodeObjectForKey:ORFolderRemoteHost]];
    [self setRemotePath:[decoder decodeObjectForKey:ORFolderRemotePath]];
    [self setRemoteUserName:[decoder decodeObjectForKey:ORFolderRemoteUserName]];
    [self setPassWord:[decoder decodeObjectForKey:ORFolderPassWord]];
    [self setVerbose:[decoder decodeBoolForKey:ORFolderVerbose]];
    [self setDirectoryName:[decoder decodeObjectForKey:ORFolderDirectoryName]];
    [self setTitle:[decoder decodeObjectForKey:ORFolderTitle]];
    [self setTransferType:[decoder decodeIntForKey:@"transferType"]];
    [[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];
    [self updateWindow];	
    
    return self;
}
- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeBool:copyEnabled forKey:ORFolderCopyEnabled];
    [encoder encodeBool:deleteWhenCopied forKey:ORFolderDeleteWhenCopied];
    [encoder encodeObject:remoteHost forKey:ORFolderRemoteHost];
    [encoder encodeObject:remotePath forKey:ORFolderRemotePath];
    [encoder encodeObject:remoteUserName forKey:ORFolderRemoteUserName];
    [encoder encodeObject:passWord forKey:ORFolderPassWord];
    [encoder encodeBool:verbose forKey:ORFolderVerbose];
    [encoder encodeObject:directoryName forKey:ORFolderDirectoryName];
    [encoder encodeObject:title forKey:ORFolderTitle];
    [encoder encodeInt:transferType forKey:@"transferType"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
	[dictionary setObject:[NSNumber numberWithInt:copyEnabled] forKey:@"CopyEnabled"];
    [dictionary setObject:[NSNumber numberWithInt:deleteWhenCopied] forKey:@"DeleteWhenCopied"];
    if(remoteHost)[dictionary setObject:remoteHost forKey:@"RemoteHost"];
    if(remotePath)[dictionary setObject:remotePath forKey:@"RemotePath"];
    if(remoteUserName)[dictionary setObject:remoteUserName forKey:@"RemoteUserName"];
    [dictionary setObject:[NSNumber numberWithInt:verbose] forKey:@"Verbose"];
    if(directoryName)[dictionary setObject:directoryName forKey:@"DirectoryName"];
    [dictionary setObject:[NSNumber numberWithInt:transferType] forKey:@"TransferType"];
	return dictionary;
}


@end


@implementation ORSmartFolder (private)
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* dirName = [[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath];
        [self setDirectoryName:dirName];
    }
}

- (void)_deleteAllSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
    if(returnCode == NSAlertDefaultReturn){
        [self deleteAll];
    }
}

- (void)_sendAllSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
    if(returnCode == NSAlertDefaultReturn){
        if(!queueIsRunning)[self sendAll];
        else [self stopTheQueue];
    }
}

@end

