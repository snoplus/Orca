//
//  ORAmptekDP5Model.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Imported Files
#import "ORDataTaker.h"
#import "ORIpeCard.h"
#import "SBC_Linking.h"
#import "SBC_Config.h"

//for UDP sockets
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>


@class ORReadOutList;
@class ORDataPacket;
@class TimedWorker;
@class ORIpeFLTModel;
@class OREdelweissFLTModel;
@class PMC_Link;
@class SBC_Link;
@class ORSBCLinkJobStatus;

#define IsBitSet(A,B) (((A) & (B)) == (B))
#define ExtractValue(A,B,C) (((A) & (B)) >> (C))



//Amptek constants
//status packet
#define kStatusLen 64
#define kFastCountOffset  0
#define kSlowCountOffset  4
#define kGPCounterOffset  8
#define kAccTimeOffset    12
#define kUnusedOffset     16
#define kRealtimeOffset   20
#define kFirmwareVersionOffset   24
#define kFPGAVersionOffset       25
#define kSerialNumberOffset      26
#define kFlags1Offset            35
#define kFlags2Offset            36
#define kFirmwareBuildNumberOffset            37
#define kFlags4Offset            38
#define kDeviceIDOffset          39

#define D0 0x01
#define D1 0x02
#define D2 0x04
#define D3 0x08
#define D4 0x10
#define D5 0x20
#define D6 0x40
#define D7 0x80


//control reg bit masks
#define kCtrlInvert 	(0x00000001 << 16) //RW
#define kCtrlLedOff 	(0x00000001 << 15) //RW
#define kCtrlOnLine		(0x00000001 << 14) //RW
#define kCtrlNumFIFOs	(0x0000000f << 28) //RW

//status reg bit masks
#define kEWStatusIrq			(0x00000001 << 31) //R - cleared on W
#define kEWStatusPixErr		(0x00000001 << 16) //R - cleared on W
//status low/high new 2013/doc rev. 200 -tb-
#define kEWStatusPixErr2013		(0x00000001 << 16) //R - cleared on W


//Cmd reg bit masks
#define kEWCmdEvRes			(0x00000001 <<  3) //W - self cleared
#define kEWCmdFltReset		(0x00000001 <<  2) //W - self cleared
#define kEWCmdSltReset		(0x00000001 <<  1) //W - self cleared
#define kEWCmdFwCfg			(0x00000001 <<  0) //W - self cleared

#if 0
//Interrupt Request and Mask reg bit masks
//Interrupt Request Read only - cleared on Read
//Interrupt Mask Read/Write only
#define kIrptFtlTmo		(0x00000001 << 15) 
#define kIrptPgFull		(0x00000001 << 14) 
#define kIrptPgRdy		(0x00000001 << 13) 
#define kIrptEvRdy		(0x00000001 << 12) 
#define kIrptSwRq		(0x00000001 << 11) 
#define kIrptFanErr		(0x00000001 << 10) 
#define kIrptVttErr		(0x00000001 <<  9) 
#define kIrptGPSErr		(0x00000001 <<  8) 
#define kIrptClkErr		(0x0000000F <<  4) 
#define kIrptPpsErr		(0x00000001 <<  3) 
#define kIrptPixErr		(0x00000001 <<  2) 
#define kIrptWdog		(0x00000001 <<  1) 
#define kIrptFltRq		(0x00000001 <<  0) 
#endif

//Revision Masks
#define kRevisionProject (0x0000000F << 28) //R
#define kDocRevision	 (0x00000FFF << 16) //R
#define kImplemention	 (0x0000FFFF <<  0) //R

//Page Manager Masks
#define kPageMngResetShift			22
#define kPageMngNumFreePagesShift	15
#define kPageMngPgFullShift			14
#define kPageMngNextPageShift		8
#define kPageMngReadyShift			7
#define kPageMngOldestPageShift	1
#define kPageMngReleaseShift		0


//Trigger Timing
#define kTrgTimingTrgWindow		(0x00000007 <<  16) //R/W
#define kTrgEndPageDelay		(0x000007FF <<   0) //R/W

@interface ORAmptekDP5Model : OrcaObject <ORDataTaker>
{
	@private
		unsigned long	hwVersion;
		NSString*		patternFilePath;
//TODO: rm   slt 		unsigned long	interruptMask;
		unsigned long	nextPageDelay;
		float			pulserAmp;
		float			pulserDelay;
		unsigned short  selectedRegIndex;
		unsigned long   writeValue;
		unsigned long	eventDataId;//TODO: remove or change -tb-
		unsigned long	multiplicityId;//TODO: remove -tb-
		unsigned long	spectrumEventId;
		unsigned long	waveFormId;
		unsigned long	fltEventId;
		unsigned long   eventCounter;
		int				actualPageIndex;
        TimedWorker*    poller;
		BOOL			pollingWasRunning;
		ORReadOutList*	readOutGroup;
		NSArray*		dataTakers;			//cache of data takers.   //TODO: remove   -tb-   2014 
		BOOL			first;
        BOOL            accessAllowedToHardwareAndSBC;                //TODO: remove -tb-


		BOOL            displayTrigger;    //< Display pixel and timing view of trigger data
		BOOL            displayEventLoop;  //< Display the event loop parameter
		unsigned long   lastDisplaySec;
		unsigned long   lastDisplayCounter;
		double          lastDisplayRate;
		
		unsigned long   lastSimSec;
		unsigned long   pageSize; //< Length of the ADC data (0..100us)

		// PMC_Link*		pmcLink;  //TODO: remove SLT stuff -tb-   2014 
        
		unsigned long controlReg;
        unsigned long statusReg;//deprecated 2013-06 -tb-
//TODO: rm   slt - -         unsigned long statusLowReg; //was statusRegLow
//TODO: rm   slt - -         unsigned long statusHighReg;//was statusRegHigh
		unsigned long long clockTime;
		
        NSString* sltScriptArguments;
        BOOL secondsSetInitWithHost;
	
    	//UDP KCmd tab
		    //vars in GUI
        int crateUDPCommandPort;
        NSString* crateUDPCommandIP;
//TODO: rm            int crateUDPReplyPort;
        NSString* crateUDPCommand;//TODO: rename -tb-
        NSString* textCommand;//TODO: rename -tb-


		    //sender connection (client)
	    int      UDP_COMMAND_CLIENT_SOCKET;
	    uint32_t UDP_COMMAND_CLIENT_IP;
        struct sockaddr_in UDP_COMMAND_sockaddrin_to;
        socklen_t  sockaddrin_to_len;//=sizeof(GLOBAL_sockin_to);
        struct sockaddr sock_to;
        int sock_to_len;//=sizeof(si_other);
		    //reply connection (server/listener)
	    int                UDP_REPLY_SERVER_SOCKET;//=-1;
        struct sockaddr_in UDP_REPLY_servaddr;
        struct sockaddr_in sockaddr_from;
        socklen_t sockaddr_fromLength;
		int isListeningOnServerSocket;
		
        #define MAXDP5PACKETLENGTH 32775
		unsigned char dp5Packet[MAXDP5PACKETLENGTH +1000];// according to DP5 manual (+some spares) -tb-
        int currentDP5PacketLen; //current length
        int countReceivedPackets; //current length
        int expectedDP5PacketLen; //for adding up UDP packets ...
        int waitForResponse; //a flag ...
		
        
        
        
        
        
        #if 0
    int selectedFifoIndex;
    unsigned long pixelBusEnableReg;
    unsigned long eventFifoStatusReg;
	#endif
	
	//UDP Data Packet tab
//TODO: from SLT         int crateUDPDataPort;
//TODO: from SLT         NSString* crateUDPDataIP;
//TODO: from SLT     int crateUDPDataReplyPort;
		    //reply connection (server/listener)
//TODO: from SLT  	    int                UDP_DATA_REPLY_SERVER_SOCKET;//=-1;
//TODO: from SLT          struct sockaddr_in UDP_DATA_REPLY_servaddr;
        struct sockaddr_in sockaddr_data_from;
        socklen_t sockaddr_data_fromLength;
		    //sender connection (client)
//TODO: from SLT          	    int      UDP_DATA_COMMAND_CLIENT_SOCKET;
	    uint32_t UDP_DATA_COMMAND_CLIENT_IP;
       struct sockaddr_in UDP_DATA_COMMAND_sockaddrin_to;
    int isListeningOnDataServerSocket;
    int requestStoppingDataServerSocket;
//TODO: from SLT        int numRequestedUDPPackets;
	    //pthread handling
	    pthread_t dataReplyThread;
        pthread_mutex_t dataReplyThread_mutex;
    int sltDAQMode;
    
#if 0
    int cmdWArg1;
    int cmdWArg2;
    int cmdWArg3;
    int cmdWArg4;
    
    uint32_t BBCmdFFMask;
    NSString* crateUDPDataCommand;
#endif


    //data taking: flags and vars  //TODO: remove ALL SLT stuff -tb-   2014 
    int takeUDPstreamData;
    int takeRawUDPData;
    int takeADCChannelData;
    int takeEventData;
    int savedUDPSocketState;
    uint32_t partOfRunFLTMask;//TODO: remove SLT stuff -tb-   2014 
    
    //BB interface
//TODO: from SLT         int idBBforWCommand;
//TODO: from SLT         bool useBroadcastIdBB;
//TODO: from SLT         NSString * chargeBBFile;
         int lowLevelRegInHex;
    
    //BB charging
//TODO: REMOVE IT slt        OREdelweissFLTModel *fltChargingBB;
    //FIC charging
//TODO: REMOVE IT slt        OREdelweissFLTModel *fltChargingFIC;
    
    int resetEventCounterAtRunStart;
    int numSpectrumBins;
    int spectrumRequestType;
    int spectrumRequestRate;
    int isPollingSpectrum;
    struct timeval lastRequestTime;//    struct timezone tz; is obsolete ... -tb-
    
}

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
// - (void) setGuardian:(id)aGuardian;

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Notifications
- (void) registerNotificationObservers;
- (void) runIsAboutToStart:(NSNotification*)aNote;
- (void) runIsStopped:(NSNotification*)aNote;
- (void) runIsBetweenSubRuns:(NSNotification*)aNote;
- (void) runIsStartingSubRun:(NSNotification*)aNote;

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Accessors
- (int) isPollingSpectrum;
- (void) setIsPollingSpectrum:(int)aIsPollingSpectrum;
- (void) requestSpectrumTimedWorker;
- (int) spectrumRequestRate;
- (void) setSpectrumRequestRate:(int)aSpectrumRequestRate;
- (int) spectrumRequestType;
- (void) setSpectrumRequestType:(int)aSpectrumRequestType;
- (int) numSpectrumBins;
- (void) setNumSpectrumBins:(int)aNumSpectrumBins;
- (NSString*) textCommand;
- (void) setTextCommand:(NSString*)aTextCommand;
- (int) resetEventCounterAtRunStart;
- (void) setResetEventCounterAtRunStart:(int)aResetEventCounterAtRunStart;
- (int) lowLevelRegInHex;
- (void) setLowLevelRegInHex:(int)aLowLevelRegInHex;

//TODO: rm   slt - - - (unsigned long) statusHighReg;
//TODO: rm   slt - - - (void) setStatusHighReg:(unsigned long)aStatusRegHigh;
//TODO: rm   slt - - - (unsigned long) statusLowReg;
//TODO: rm   slt - - - (void) setStatusLowReg:(unsigned long)aStatusRegLow;


- (int) takeADCChannelData;
- (void) setTakeADCChannelData:(int)aTakeADCChannelData;
- (int) takeRawUDPData;
- (void) setTakeRawUDPData:(int)aTakeRawUDPData;



//TODO: rm
#if 0
- (NSString *) chargeBBFile;
- (void) setChargeBBFile:(NSString *)aChargeBBFile;
- (bool) useBroadcastIdBB;
- (void) setUseBroadcastIdBB:(bool)aUseBroadcastIdBB;
- (int) idBBforWCommand;
- (void) setIdBBforWCommand:(int)aIdBBforWCommand;



- (int) takeEventData;
- (void) setTakeEventData:(int)aTakeEventData;
- (int) takeUDPstreamData;
- (void) setTakeUDPstreamData:(int)aTakeUDPstreamData;

- (NSString*) crateUDPDataCommand;
- (void) setCrateUDPDataCommand:(NSString*)aCrateUDPDataCommand;
- (uint32_t) BBCmdFFMask;
- (void) setBBCmdFFMask:(uint32_t)aBBCmdFFMask;
- (int) cmdWArg4;
- (void) setCmdWArg4:(int)aCmdWArg4;
- (int) cmdWArg3;
- (void) setCmdWArg3:(int)aCmdWArg3;
- (int) cmdWArg2;
- (void) setCmdWArg2:(int)aCmdWArg2;
- (int) cmdWArg1;
- (void) setCmdWArg1:(int)aCmdWArg1;
#endif




- (int) sltDAQMode;
- (void) setSltDAQMode:(int)aSltDAQMode;
//TODO: rm   slt - - - (int) numRequestedUDPPackets;
//TODO: rm   slt - - - (void) setNumRequestedUDPPackets:(int)aNumRequestedUDPPackets; 
- (int) isListeningOnDataServerSocket;
- (void) setIsListeningOnDataServerSocket:(int)aIsListeningOnDataServerSocket;
- (int) requestStoppingDataServerSocket;
- (void) setRequestStoppingDataServerSocket:(int)aValue;


//TODO: rm   slt - - - (int) crateUDPDataReplyPort;
//TODO: rm   slt - - - (void) setCrateUDPDataReplyPort:(int)aCrateUDPDataReplyPort;
//TODO: rm   slt - - - (NSString*) crateUDPDataIP;
//TODO: rm   slt - - - (void) setCrateUDPDataIP:(NSString*)aCrateUDPDataIP;
//TODO: rm   slt - - - (int) crateUDPDataPort;
//TODO: rm   slt - - - (void) setCrateUDPDataPort:(int)aCrateUDPDataPort;


#if 0
- (unsigned long) eventFifoStatusReg;
- (void) setEventFifoStatusReg:(unsigned long)aEventFifoStatusReg;
- (unsigned long) pixelBusEnableReg;
- (void) setPixelBusEnableReg:(unsigned long)aPixelBusEnableReg;
- (int) selectedFifoIndex;
- (void) setSelectedFifoIndex:(int)aSelectedFifoIndex;
#endif



- (int) isListeningOnServerSocket;
- (void) setIsListeningOnServerSocket:(int)aIsListeningOnServerSocket;
- (NSString*) crateUDPCommand;
- (void) setCrateUDPCommand:(NSString*)aCrateUDPCommand;

#if 0
- (int) crateUDPReplyPort;
- (void) setCrateUDPReplyPort:(int)aCrateUDPReplyPort;
#endif



- (NSString*) crateUDPCommandIP;
- (void) setCrateUDPCommandIP:(NSString*)aCrateUDPCommandIP;
- (int) crateUDPCommandPort;
- (void) setCrateUDPCommandPort:(int)aCrateUDPCommandPort;
- (BOOL) secondsSetInitWithHost;
- (void) setSecondsSetInitWithHost:(BOOL)aSecondsSetInitWithHost;
- (NSString*) sltScriptArguments;
- (void) setSltScriptArguments:(NSString*)aSltScriptArguments;
- (unsigned long long) clockTime;
- (void) setClockTime:(unsigned long long)aClockTime;

- (unsigned long) statusReg;
- (void) setStatusReg:(unsigned long)aStatusReg;
- (unsigned long) controlReg;
- (void) setControlReg:(unsigned long)aControlReg;

- (unsigned long) projectVersion;
- (unsigned long) documentVersion;
- (unsigned long) implementation;
- (unsigned long) hwVersion;//=SLT FPGA version/revision
- (void) setHwVersion:(unsigned long) aVersion;

- (NSString*) patternFilePath;
- (void) setPatternFilePath:(NSString*)aPatternFilePath;

- (unsigned long) nextPageDelay;
- (void) setNextPageDelay:(unsigned long)aDelay;
//TODO: rm   slt - (unsigned long) interruptMask;
//TODO: rm   slt - (void) setInterruptMask:(unsigned long)aInterruptMask;
- (float) pulserDelay;
- (void) setPulserDelay:(float)aPulserDelay;
- (float) pulserAmp;
- (void) setPulserAmp:(float)aPulserAmp;
- (short) getNumberRegisters;			
- (NSString*) getRegisterName: (short) anIndex;
- (unsigned long) getAddress: (short) anIndex;
//- (unsigned long) getAddressOffset: (short) anIndex;
- (short) getAccessType: (short) anIndex;

- (unsigned short) 	selectedRegIndex;
- (void)		setSelectedRegIndex: (unsigned short) anIndex;
- (unsigned long) 	writeValue;
- (void)		setWriteValue: (unsigned long) anIndex;
//- (void) loadPatternFile;

- (BOOL) displayTrigger; //< Staus of dispaly of trigger information
- (void) setDisplayTrigger:(BOOL) aState; 
- (BOOL) displayEventLoop; //< Status of display of event loop performance information
- (void) setDisplayEventLoop:(BOOL) aState;
- (unsigned long) pageSize; //< Length of the ADC data (0..100us)
- (void) setPageSize: (unsigned long) pageSize;   


#pragma mark ***Polling
- (TimedWorker *) poller;
- (void) setPoller: (TimedWorker *) aPoller;
- (void) setPollingInterval:(float)anInterval;
- (void) makePoller:(float)anInterval;

#pragma mark ***UDP Communication
//  UDP K command connection
//reply socket (server)
- (int) startListeningServerSocket;
- (void) stopListeningServerSocket;
- (int) openServerSocket;
- (void) closeServerSocket;
- (int) receiveFromReplyServer;
- (int) parseReceivedDP5Packet;

//command socket (client)
- (int) openCommandSocket;
- (int) isOpenCommandSocket;
- (void) closeCommandSocket;


- (int) requestSpectrum;
- (int) requestSpectrumOfType:(int)pid2;
- (int) sendTextCommand;
- (int) sendTextCommandString:(NSString*)aString;
- (int) readbackTextCommand;
- (int) readbackTextCommandString:(NSString*)aString;
- (int) sendUDPCommand;
- (int) sendUDPCommandString:(NSString*)aString;
- (int) sendUDPPacket:(unsigned char*)packet length:(int) aLength;
- (int) sendBinaryString:(NSString*)aString;

- (int) sendUDPCommandBinary;




#if 0
//TODO: UNUSED:
//  UDP data packet connection
//reply socket (server)
- (int) startListeningDataServerSocket;
- (void) stopListeningDataServerSocket;
- (int) receiveFromDataReplyServer;
//command socket (client)
- (int) openDataCommandSocket;
- (void) closeDataCommandSocket;
- (int) isOpenDataCommandSocket;
- (int) sendUDPDataCommand:(char*)data length:(int) len;
- (int) sendUDPDataCommandString:(NSString*)aString;
- (int) sendUDPDataCommandRequestPackets:(int8_t) num;
- (int) sendUDPDataCommandRequestUDPData;
- (int) sendUDPDataCommandChargeBBFile;
- (void) loopCommandRequestUDPData;
- (int) sendUDPDataWCommandRequestPacketArg1:(int) arg1 arg2:(int) arg2 arg3:(int) arg3  arg4:(int) arg4; 
  //BB commands
- (int) sendUDPDataWCommandRequestPacket;

- (int) sendUDPDataTab0x0ACommand:(uint32_t) aBBCmdFFMask;//send 0x0A  Command
- (int) sendUDPDataTabBloqueCommand;
- (int) sendUDPDataTabDebloqueCommand;
- (int) sendUDPDataTabDemarrageCommand;
#endif

#pragma mark ***HW Access
//note that most of these method can raise 
//exceptions either directly or indirectly
//TODO: REMOVE IT slt- (int)           chargeBBWithFile:(char*)data numBytes:(int) numBytes;
//TODO: REMOVE IT slt- (int)           chargeBBusingSBCinBackgroundWithData:(NSData*)theData   forFLT:(OREdelweissFLTModel*) aFLT;
//TODO: REMOVE IT slt- (void)          chargeBBStatus:(ORSBCLinkJobStatus*) jobStatus;
//TODO: REMOVE IT slt- (int)           chargeFICusingSBCinBackgroundWithData:(NSData*)theData   forFLT:(OREdelweissFLTModel*) aFLT;
//TODO: REMOVE IT slt- (void)          chargeFICStatus:(ORSBCLinkJobStatus*) jobStatus;
- (int)           writeToCmdFIFO:(char*)data numBytes:(int) numBytes;  
- (void)		  readAllControlSettingsFromHW;

- (void)		  readAllStatus;
- (void)		  checkPresence;
//TODO: rm   slt - -- (unsigned long) readControlReg;
//TODO: rm   slt - -- (void)		  writeControlReg;
//TODO: rm   slt - -- (void)		  printControlReg;
//TODO: rm   slt - - - (unsigned long) readStatusReg;
//TODO: rm   slt - - - (unsigned long) readStatusLowReg;
//TODO: rm   slt - - - (unsigned long) readStatusHighReg;
//TODO: rm   slt - - - (void)		  printStatusReg;
//TODO: rm   slt - - - (void)          printStatusLowHighReg;

//TODO: rm   slt - - - (void) writePixelBusEnableReg;
//TODO: rm   slt - -- (void) readPixelBusEnableReg;

- (void)		writeFwCfg;
- (void)		writeSltReset;
- (void)		writeFltReset;
- (void)		writeEvRes;
- (unsigned long long) readBoardID;
//TODO: rm   slt - - - (void) readEventFifoStatusReg;

#if 0 //deprecated 2013-06 -tb-
- (void)		  writeInterruptMask;
- (void)		  readInterruptMask;
- (void)		  readInterruptRequest;
- (void)		  printInterruptRequests;
- (void)		  printInterruptMask;
- (void)		  printInterrupt:(int)regIndex;
#endif


//- (void)		  dumpTriggerRAM:(int)aPageIndex;

- (void)		  writeReg:(int)index value:(unsigned long)aValue;
- (void)          writeReg:(int)index  forFifo:(int)fifoIndex value:(unsigned long)aValue;
- (void)		  rawWriteReg:(unsigned long) address  value:(unsigned long)aValue;//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
- (unsigned long) rawReadReg:(unsigned long) address; //TODO: FOR TESTING AND DEBUGGING ONLY -tb-
- (unsigned long) readReg:(int) index;
- (unsigned long) readReg:(int) index forFifo:(int)fifoIndex;
- (id) writeHardwareRegisterCmd:(unsigned long)regAddress value:(unsigned long) aValue;
- (id) readHardwareRegisterCmd:(unsigned long)regAddress;
- (unsigned long) readHwVersion;
- (unsigned long) readTimeLow;
- (unsigned long) readTimeHigh;
- (unsigned long long) getTime;

- (void)		reset;
- (void)		hw_config;
- (void)		hw_reset;
//- (void)		loadPulseAmp;
//- (void)		loadPulserValues;
//- (void)		swTrigger;
- (void)		initBoard;
- (long)		getSBCCodeVersion;
- (long)		getFdhwlibVersion;
- (long)		getSltPciDriverVersion;
- (long)		getPresentFLTsMap;

#pragma mark *** Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

- (unsigned long) spectrumEventId;
- (void) setSpectrumEventId: (unsigned long) DataId;
- (unsigned long) fltEventId;
- (void) setFltEventId: (unsigned long) DataId;
- (unsigned long) waveFormId;
- (void) setWaveFormId: (unsigned long) DataId;
- (unsigned long) eventDataId;
- (void) setEventDataId: (unsigned long) DataId;
- (unsigned long) multiplicityId;
- (void) setMultiplicityId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢DataTaker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) shipUDPPacket:(ORDataPacket*)aDataPacket data:(char*)udpPacket len:(int)len index:(int)aIndex type:(int)t;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;
- (BOOL) doneTakingData;

- (void) shipSltSecondCounter:(unsigned char)aType;
- (void) shipSltEvent:(unsigned char)aCounterType withType:(unsigned char)aType eventCt:(unsigned long)c high:(unsigned long)h low:(unsigned long)l;

- (ORReadOutList*)	readOutGroup;
- (void)			setReadOutGroup:(ORReadOutList*)newReadOutGroup;
- (NSMutableArray*) children;
- (unsigned long) calcProjection:(unsigned long *)pMult  xyProj:(unsigned long *)xyProj  tyProj:(unsigned long *)tyProj;

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢SBC_Linking Protocol
- (NSString*) driverScriptName;
- (NSString*) sbcLockName;
- (NSString*) sbcLocalCodePath;
- (NSString*) codeResourcePath;
						 

@end

extern NSString* ORAmptekDP5ModelIsPollingSpectrumChanged;
extern NSString* ORAmptekDP5ModelSpectrumRequestRateChanged;
extern NSString* ORAmptekDP5ModelSpectrumRequestTypeChanged;
extern NSString* ORAmptekDP5ModelNumSpectrumBinsChanged;
extern NSString* ORAmptekDP5ModelTextCommandChanged;
extern NSString* ORAmptekDP5ModelResetEventCounterAtRunStartChanged;
extern NSString* ORAmptekDP5ModelLowLevelRegInHexChanged;
extern NSString* ORAmptekDP5ModelStatusRegHighChanged;
extern NSString* ORAmptekDP5ModelStatusRegLowChanged;
extern NSString* ORAmptekDP5ModelTakeADCChannelDataChanged;
extern NSString* ORAmptekDP5ModelTakeRawUDPDataChanged;
extern NSString* ORAmptekDP5ModelChargeBBFileChanged;
extern NSString* ORAmptekDP5ModelUseBroadcastIdBBChanged;
extern NSString* ORAmptekDP5ModelIdBBforWCommandChanged;
extern NSString* ORAmptekDP5ModelTakeEventDataChanged;
extern NSString* ORAmptekDP5ModelTakeUDPstreamDataChanged;
extern NSString* ORAmptekDP5ModelCrateUDPDataCommandChanged;
extern NSString* ORAmptekDP5ModelBBCmdFFMaskChanged;
extern NSString* ORAmptekDP5ModelCmdWArg4Changed;
extern NSString* ORAmptekDP5ModelCmdWArg3Changed;
extern NSString* ORAmptekDP5ModelCmdWArg2Changed;
extern NSString* ORAmptekDP5ModelCmdWArg1Changed;
extern NSString* ORAmptekDP5ModelSltDAQModeChanged;
extern NSString* ORAmptekDP5ModelNumRequestedUDPPacketsChanged;
extern NSString* ORAmptekDP5ModelIsListeningOnDataServerSocketChanged;
extern NSString* ORAmptekDP5ModelCrateUDPDataReplyPortChanged;
extern NSString* ORAmptekDP5ModelCrateUDPDataIPChanged;
extern NSString* ORAmptekDP5ModelCrateUDPDataPortChanged;
extern NSString* ORAmptekDP5ModelEventFifoStatusRegChanged;
   //TODO: extern NSString* ORAmptekDP5ModelOpenCloseDataCommandSocketChanged;
extern NSString* ORAmptekDP5ModelPixelBusEnableRegChanged;
extern NSString* ORAmptekDP5ModelSelectedFifoIndexChanged;
extern NSString* ORAmptekDP5ModelIsListeningOnServerSocketChanged;
extern NSString* ORAmptekDP5ModelCrateUDPCommandChanged;
extern NSString* ORAmptekDP5ModelCrateUDPReplyPortChanged;
extern NSString* ORAmptekDP5ModelCrateUDPCommandIPChanged;
extern NSString* ORAmptekDP5ModelCrateUDPCommandPortChanged;
extern NSString* ORAmptekDP5ModelSecondsSetInitWithHostChanged;
extern NSString* ORAmptekDP5ModelSltScriptArgumentsChanged;

extern NSString* ORAmptekDP5ModelClockTimeChanged;
extern NSString* ORAmptekDP5ModelRunTimeChanged;
extern NSString* ORAmptekDP5ModelVetoTimeChanged;
extern NSString* ORAmptekDP5ModelDeadTimeChanged;
extern NSString* ORAmptekDP5ModelSecondsSetChanged;
extern NSString* ORAmptekDP5ModelStatusRegChanged;
extern NSString* ORAmptekDP5ModelControlRegChanged;
extern NSString* ORAmptekDP5ModelHwVersionChanged;

extern NSString* ORAmptekDP5ModelPatternFilePathChanged;
extern NSString* ORAmptekDP5ModelInterruptMaskChanged;
extern NSString* ORAmptekDP5ModelPageSizeChanged;
extern NSString* ORAmptekDP5ModelDisplayEventLoopChanged;
extern NSString* ORAmptekDP5ModelDisplayTriggerChanged;
extern NSString* ORAmptekDP5PulserDelayChanged;
extern NSString* ORAmptekDP5PulserAmpChanged;
extern NSString* ORAmptekDP5SelectedRegIndexChanged;
extern NSString* ORAmptekDP5WriteValueChanged;
extern NSString* ORAmptekDP5SettingsLock;
extern NSString* ORAmptekDP5StatusRegChanged;
extern NSString* ORAmptekDP5ControlRegChanged;
extern NSString* ORAmptekDP5ModelNextPageDelayChanged;
extern NSString* ORAmptekDP5ModelPollRateChanged;
extern NSString* ORAmptekDP5ModelReadAllChanged;

extern NSString* ORAmptekDP5V4cpuLock;	

