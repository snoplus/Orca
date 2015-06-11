//
//  ORAmptekDP5Decoder.h
//  Orca
//
//  Created by Mark Howe on 9/30/07.
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

@interface ORAmptekDP5DecoderForSpectrum : ORBaseDecoder{
}
// Documentation in m-file
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end



@interface ORAmptekDP5DecoderForEvent : ORIpeCardDecoder {
}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

@interface ORAmptekDP5DecoderForMultiplicity : ORIpeCardDecoder {
}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end




@interface ORAmptekDP5DecoderForWaveForm : ORIpeCardDecoder {
	@private 
		BOOL getRatesFromDecodeStage;
		NSMutableDictionary* actualFlts;
}
// Documentation in m-file
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end




@interface ORAmptekDP5DecoderForFLTEvent : ORIpeCardDecoder {
	@private 
		BOOL getRatesFromDecodeStage;
		NSMutableDictionary* actualFlts;
}
// Documentation in m-file
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

