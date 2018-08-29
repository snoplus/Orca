//
//  ORKatrinCardDecoder.h
//  Orca
//
//  Created by Mark Howe on 10/18/05.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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



#import "ORIpeCardDecoder.h"

@class ORDataPacket;
@class ORDataSet;

/** Decoder for the event data stream. 
  * These objects are generated in Flt energy mode.
  */
@interface ORKatrinFLTDecoderForEnergy : ORIpeCardDecoder {
}
// Documentation in m-file
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
@end


/** Decoder for the extended event data stream. 
  * These objects are generated in Flt trace mode.
  */
@interface ORKatrinFLTDecoderForWaveForm : ORIpeCardDecoder {
}
// Documentation in m-file
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
@end


/** Decoder for the hitrate stream.   (copy of "event data stream" -tb-)
  * This objects are generated in Flt measure mode.
  */
@interface ORKatrinFLTDecoderForHitRate : ORIpeCardDecoder {
}
// Documentation in m-file
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
@end




/** Decoder for the threshold scan stream. 
  * This objects are generated in Flt measure mode.
  */
@interface ORKatrinFLTDecoderForThresholdScan : ORIpeCardDecoder {
  uint32_t lastEnergy[22];		//!< Energy of the last sample. Used to calculate the difference per sample
  uint32_t lastHitrate[22];		//!< Trigger rate of the last sample. Used to calculate the difference per sample
}
// Documentation in m-file
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
@end




/** Decoder for the hardware histogram data stream.  
  * This objects are generated in Flt measure mode + Histogramming flag set.
  */
@interface ORKatrinFLTDecoderForHistogram : ORIpeCardDecoder {
}
// Documentation in m-file
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
@end


