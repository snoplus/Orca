//
//  ORDataSet.h
//  Orca
//
//  Created by Mark Howe on Tue Mar 18 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files

#pragma mark •••Forward Declarations
@class ORDataPacket;

@interface ORDataSet : OrcaObject {
    NSMutableDictionary*    realDictionary;
    NSArray*                sortedArray;
    NSString*               key;		//crate x, card y, etc...
    id                      data;		//data will be nil unless this is a leaf node.	
    unsigned long			totalCounts;
	//NSLock*					dataSetLock;
	long					runNumber;
    float                   minX,maxX,minY,maxY;
}

#pragma mark •••Initialization
- (id) initWithKey: (NSString*) aKey guardian:(ORDataSet*)aGuardian;
- (void) dealloc;

#pragma mark •••Accessors
- (float) minX;
- (float) maxX;
- (float) minY;
- (float) maxY;
- (void) setMinX:(float)aValue;
- (void) setMaxX:(float)aValue;
- (void) setMinY:(float)aValue;
- (void) setMaxY:(float)aValue;

- (id) findObjectWithFullID:(NSString*)aFullID;
- (NSArray*) collectObjectsOfClass:(Class)aClass;
- (long) runNumber;
- (void) setRunNumber:(long)aRunNumber;
- (id) objectForKeyArray:(NSMutableArray*)anArray;
- (ORDataSet*) dataSetWithName:(NSString*)aName;
- (void) setKey:(NSString*)aKey;
- (NSString*) key;
- (NSString*)name; 
- (NSString*) shortName;
- (unsigned) count;
- (NSEnumerator*) objectEnumerator;
- (unsigned long) totalCounts;
- (void) setTotalCounts:(unsigned long) newCount;
- (void) incrementTotalCounts;
- (void) incrementTotalCountsBy:(unsigned long) aValue;
- (unsigned long) recountTotal;
- (id) 	 data;
- (void) setData:(id)someData;
- (void) clear;
- (void) clearWithUpdate:(BOOL)update;
- (void) runTaskStopped;
- (void) runTaskBoundary;
- (void) doDoubleClick:(id)sender;
- (NSString*) prependFullName:(NSString*)name;
- (NSArray*) collectObjectsOfClass:(Class)aClass;
- (NSComparisonResult) compare:(NSString *)aString;
- (void) removeAllObjects;
- (void) removeObject:(id)anObj;
- (void) removeObjectForKey: (id) aKey;
- (void) processResponse:(NSDictionary*)aResponse;
- (NSArray*) collectionOfDataSets;
- (id) objectForKey: (id) aKey;

#pragma mark •••Level Info
- (BOOL) leafNode;

#pragma mark •••Data Insertion
- (void) incrementCount:(NSString*)firstArg,...;
- (void) loadHistogram:(unsigned long*)ptr numBins:(unsigned long)numBins withKeyArray:(NSArray*)keyArray;
- (void) loadHistogram2D:(unsigned long*)ptr numBins:(unsigned long)numBins withKeyArray:(NSArray*)keyArray;
- (void) histogram:(unsigned long)aValue numBins:(unsigned long)numBins sender:(id)obj  withKeys:(NSString*)key,...;
- (void) histogramWW:(unsigned long)aValue weight:(unsigned long)aWeight numBins:(unsigned long)numBins sender:(id)obj  withKeys:(NSString*)key,...;
- (void) mergeHistogram:(unsigned long*)ptr numBins:(unsigned long)numBins withKeyArray:(NSArray*)keyArray;
- (void) mergeEnergyHistogram:(unsigned long*)ptr numBins:(unsigned long)numBins   maxBins:(unsigned long)maxBins  firstBin:(unsigned long)firstBin  stepSize:(unsigned long)stepSize   counts:(unsigned long)counts withKeys:(NSString*)firstArg,...;
- (void) histogram2DX:(unsigned long)xValue y:(unsigned long)yValue size:(unsigned short)numBins  sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) loadData2DX:(unsigned long)xValue y:(unsigned long)yValue z:(unsigned long)zValue size:(unsigned short)numBins sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) sumData2DX:(unsigned long)xValue y:(unsigned long)yValue z:(unsigned long)zValue size:(unsigned short)numBins sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) clearDataUpdate:(BOOL)update withKeys:(NSString*)firstArg,...;
- (void) loadWaveform:(NSData*)aWaveForm offset:(unsigned long)anOffset unitSize:(int)unitSize sender:(id)obj  withKeys:(NSString*)keyArg,...;
- (void) loadWaveform:(NSData*)aWaveForm offset:(unsigned long)anOffset unitSize:(int)aUnitSize mask:(unsigned long)aMask sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) loadWaveform:(NSData*)aWaveForm offset:(unsigned long)anOffset unitSize:(int)aUnitSize startIndex:(unsigned long)aStartIndex scaleOffset:(long)aDataOffset mask:(unsigned long)aMask specialBits:(unsigned long)aSpecialMask bitNames:(NSArray*)bitNames sender:(id)obj withKeys:(NSString*)firstArg,...;
- (void) loadWaveform:(NSData*)aWaveForm offset:(unsigned long)anOffset unitSize:(int)aUnitSize startIndex:(unsigned long)aStartIndex mask:(unsigned long)aMask sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) loadWaveform:(NSData*)aWaveForm offset:(unsigned long)anOffset unitSize:(int)aUnitSize startIndex:(unsigned long)aStartIndex mask:(unsigned long)aMask specialBits:(unsigned long)aSpecialMask bitNames:(NSArray*)someNames sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) loadFFTReal:(NSArray*)realArray imaginary:(NSArray*)imaginaryArray withKeyArray:(NSArray*)keyArray;
- (void) loadGenericData:(NSString*)aString sender:(id)obj withKeys:(NSString*)topLevel,...;
- (void) loadGenericData:(NSString*)aString sender:(id)obj usingKeyArray:(NSArray*)myArgs;
- (void) loadScalerSum:(unsigned long)aValue sender:(id)obj withKeys:(NSString*)firstArg,...;
- (void) loadFFTReal:(NSArray*)realArray imaginary:(NSArray*)imaginaryArray withKeyArray:(NSArray*)keyArray;
- (void) loadTimeSeries:(float)aValue atTime:(unsigned long)aTime sender:(id)obj withKeys:(NSString*)firstArg,...;
- (void) loadSpectrum:(NSData*)aSpectrum  sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector;

#pragma mark •••Writing Data
- (void) writeDataToFile:(FILE*)aFile;
- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo keys:(NSMutableArray*)aKeyArray;
- (NSString*) summarizeIntoString:(NSMutableString*)summary;
- (NSString*) summarizeIntoString:(NSMutableString*)summary level:(int)level;

#pragma mark •••Data Source Methods
- (unsigned)  numberOfChildren;
- (id)   childAtIndex:(int)index;

@end

extern NSString* ORDataSetRemoved;
extern NSString* ORDataSetCleared;
extern NSString* ORDataSetAdded;
extern NSString* ORForceLimitsMinXChanged;
extern NSString* ORForceLimitsMaxXChanged;
extern NSString* ORForceLimitsMaxYChanged;
extern NSString* ORForceLimitsMinYChanged;

