#include "ORCAEN792Readout.hh"
#include <errno.h>


#define ShiftAndExtract(aValue,aShift,aMask) (((aValue)>>(aShift)) & (aMask))
#define v792BufferSizeInLongs 1024
#define v792BufferSizeInBytes (v792BufferSizeInLongs * sizeof(uint32_t))

bool ORCAEN792Readout::Readout(SBC_LAM_Data* lamData)
{
    /* The deviceSpecificData is as follows:          */ 
    /* 0: model type                          */
    /* 1: statusOne register                          */
    /* 2: statusTwo register                          */
    /* 3: fifo buffer address                         */
    /* 4: fifo buffer size (in longs)                 */
    uint16_t status1;
    uint16_t status2;
    int32_t result;
	uint32_t dataId             = GetHardwareMask()[0];
	uint32_t locationMask       = ((GetCrate() & 0x01e)<<21) | ((GetSlot() & 0x0000001f)<<16);
    //uint32_t modelType          = GetDeviceSpecificData()[0];
    uint32_t status1Address     = GetDeviceSpecificData()[1];
    uint32_t status2Address     = GetDeviceSpecificData()[2];
	uint32_t fifoAddress        = GetDeviceSpecificData()[3];
	//uint32_t bufferSizeInLongs  = GetDeviceSpecificData()[4];
	
    uint32_t addressModifier = 0x09;
	
	result = VMERead(status2Address, addressModifier, sizeof(status2),status2);
    if (result != sizeof(status2)) {
        LogBusError("CAEN 0x%0x status 2 read",GetBaseAddress());
        return false;
	}
    uint8_t bufferIsFull    =  (status2 & 0x0004) >> 2;
	
	if(bufferIsFull){
		//wow, the buffer is full. We will use dma to read out the whole buffer and decoder it locally into events
		uint32_t buffer[v792BufferSizeInLongs];
		
		result = DMARead(fifoAddress,
						 addressModifier,
						 (uint32_t) 4,
						 (uint8_t*) buffer,
						 v792BufferSizeInBytes);
		
		if(result == v792BufferSizeInBytes){
			uint8_t doingEvent = 0;
			int32_t numMemorizedChannels;
			int32_t numDecoded;
			int32_t savedDataIndex = dataIndex;
			uint32_t i;
			for(i=0;i<v792BufferSizeInLongs;i++){
				
				uint32_t dataWord = buffer[i];
				uint8_t dataType = ShiftAndExtract(dataWord,24,0x7);
				
				switch (dataType) {
					case 2: 
						//header
						if (doingEvent){
							//something pathelogical happend. We were in an event and then
							//got another header. dump the record in progress and start over.
							dataIndex = savedDataIndex;
						}
						savedDataIndex = dataIndex; 
						numMemorizedChannels = ShiftAndExtract(dataWord,8,0x3f);
						numDecoded = 0;
						doingEvent = 1;
						ensureDataCanHold(numMemorizedChannels + 3);
						//load the ORCA header
						data[dataIndex++] = dataId | (numMemorizedChannels + 3);
						data[dataIndex++] = locationMask;
						break;
						
					case 0: 
						if(doingEvent){
							//valid data. put into ORCA record
							data[dataIndex++] = dataWord;
							numDecoded++;
							if(numDecoded > numMemorizedChannels){
								//something is wrong, dump the event
								dataIndex = savedDataIndex;
								doingEvent = 0;
							}
						}
						break;
						
					case 4: 
						if(doingEvent){
							if(numDecoded==numMemorizedChannels){
								//end of block. Put into ORCA record since it holds the event counter
								data[dataIndex++] = dataWord;
							}
							else {
								//something is wrong, dump the event
								dataIndex = savedDataIndex;
							}
							doingEvent = 0;
						}
						break;
						
					default:
						if(doingEvent){
							//something is wrong, dump the current event
							dataIndex = savedDataIndex;
							doingEvent = 0;
						}
						break;
				}
			}
			if(doingEvent){
				//appearently the last event was not complete. Dump it.
				dataIndex = savedDataIndex;
			}
			
		}
		else {
			LogBusError("CAEN 0x%0x dma read error",GetBaseAddress());
			return false; 
		}
	}
	
	else {
 
		result = VMERead(status1Address,addressModifier,sizeof(status1),status1);
		
		if (result != sizeof(status1)) {
			LogBusError("CAEN 0x%0x status 1 read",GetBaseAddress());
			return false; 
		}
        
		uint8_t dataIsReady     =  status1 & 0x0001;
		if (dataIsReady) {
			
			//OK, at least one data value is ready, first value read should be a header
			uint32_t dataWord;
			result = VMERead(fifoAddress, addressModifier, sizeof(dataWord), dataWord);
			if((result == sizeof(dataWord)) && (ShiftAndExtract(dataWord,24,0x7) == 0x2)){
				int32_t numMemorizedChannels = ShiftAndExtract(dataWord,8,0x3f);
				int32_t i;
				if((numMemorizedChannels>0)){
					//make sure the data buffer can hold our data. Note that we do NOT ship the end of block. 
					ensureDataCanHold(numMemorizedChannels + 3);
					
					//save the location in case we have to dump the data because of an error
                    int32_t savedDataIndex = dataIndex;
					data[dataIndex++] = dataId | (numMemorizedChannels + 3);
					data[dataIndex++] = locationMask;
					uint8_t dataOK = true;
					for(i=0;i<numMemorizedChannels;i++){
						result = VMERead(fifoAddress, addressModifier, sizeof(dataWord), dataWord);
						if((result == sizeof(dataWord)) && (ShiftAndExtract(dataWord,24,0x7) == 0x0)){
                            data[dataIndex++] = dataWord;
                        }
						else {
							dataOK = false;
							dataIndex = savedDataIndex;
							LogBusError("Rd Err: CAEN 792 0x%04x %s", GetBaseAddress(),strerror(errno)); 
							FlushDataBuffer();
							break;
						}
					}
					if(dataOK){
						//OK we read the data, get the end of block
						result = VMERead(fifoAddress, addressModifier, sizeof(dataWord), dataWord);
						if((result != sizeof(dataWord)) || (ShiftAndExtract(dataWord,24,0x7) != 0x4)){
							//some kind of bad error, report and flush the buffer
							LogBusError("Rd Err: CAEN 792 0x%04x %s", GetBaseAddress(),strerror(errno)); 
							dataIndex = savedDataIndex;
							FlushDataBuffer();
						}
						else data[dataIndex++] = dataWord;
					}
				}
			}
		}
	}
	
    return true; 
}

void ORCAEN792Readout::FlushDataBuffer()
{
 	uint32_t fifoAddress     = GetDeviceSpecificData()[1];
	//flush the buffer, read until not valid datum
	int32_t i;
	for(i=0;i<0x07FC;i++) {
		uint32_t dataValue;
		int32_t result = VMERead(fifoAddress, 0x9, sizeof(dataValue), dataValue);
		if(result<0){
			LogBusError("Flush Err: CAEN 792 0x%04x %s", GetBaseAddress(),strerror(errno)); 
			break;
		}
		if(ShiftAndExtract(dataValue,24,0x7) == 0x6) break;
	}
}
