//--------------------------------------------------------------------------------
/*!\class	ORCaenCard
 * \brief	Handles basic routines for accessing and controlling a CAEN VME module.
 * \methods
 *			\li \b 			- Constructor
 *			\li \b 
 * \note
 * \author	Jan M. Wouters
 * \history	2002-02-25 (mh) - Original
 *			2002-11-18 (jmw) - Modified for ORCA.
 */
//--------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "ORVmeIOCard.h"
#import "ORCaenDataDecoder.h"

// Constants needed by CAEN Vme modules.
//#define kCaenNoContrlErr	-30053
//#define kCaenNoPowerErr		-30054
#define kCaenNoRegErr		-30000
#define kCaenIllegalOpErr	-30001

enum {
	kReadOnly,
	kWriteOnly,
	kReadWrite
};

#define kD16 2
#define kD32 4

// Class variables.
@interface ORCaenCard : ORVmeIOCard {
    uint32_t   	mErrorCount;
    ORCaenDataDecoder 	*mDecoder;
    uint32_t 		mTotalEventCounter;
    uint32_t 		mEventCounter[ 32 ];
}
				
#pragma mark ***Initialization
#pragma mark ***Accessors
- (uint32_t) 	errorCount;
- (uint32_t)	getTotalEventCount;
- (uint32_t) 	getEventCount: (unsigned short) i;

#pragma mark ***Commands
- (OSErr) 			read: (unsigned short) pReg returnValue: (unsigned short*) pValue;
- (OSErr) 			write: (unsigned short) pReg sendValue: (unsigned short) pValue;
- (OSErr) 			readOutputBuffer: (uint32_t *) pOutputBuffer withSize: (unsigned short *) pBufferSize;
- (OSErr) 			readThreshold: (unsigned short) pChan returnValue: (unsigned short *) pthres_Value;
- (OSErr) 			writeThreshold: (unsigned short) pChan sendValue: (unsigned short) pthres_Value;


	// Methods that subclasses should define.
- (short)  			accessSize: (short) i;
- (short)  			accessType: (short) i;
- (uint32_t) 	getAddressOffset: (short) i;
- (uint32_t) 	getBufferOffset;
- (unsigned short) 	getDataBufferSize;
- (short) 			getNumberRegisters;
- (unsigned short) 	getStatus1RegOffset;
- (unsigned short) 	getStatus2RegOffset;
- (uint32_t) 	getThresholdOffset;

@end

