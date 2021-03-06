//
//  PcycleBluetooth.m
//  PcycleSDK
//
//  Created by Arthur on 15/1/5.
//  Copyright (c) 2015年 FlyingFrog. All rights reserved.
//

#import "PcycleBluetooth.h"

@implementation PcycleBluetooth

@synthesize _peripherals;

- (void)initialize:(BOOL)asCentral asPeripheral:(BOOL)asPeripheral
{
    _isPaused = FALSE;
    
    _centralManager = nil;
    _peripheralManager = nil;
    _services = nil;
    _characteristics = nil;
    
    if (asCentral)
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    if (asPeripheral)
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    _services = [[NSMutableDictionary alloc] init];
    _characteristics = [[NSMutableDictionary alloc] init];
    _peripherals = [[NSMutableDictionary alloc] init];
    _peripheralCharacteristics = [[NSMutableDictionary alloc] init];
    
    _pcycleBluetoothDelegate = nil;
}

- (void)initWithDelegate:(id<PcycleBluetoothDelegate>) delegate asCentral:(BOOL)asCentral asPeripheral:(BOOL)asPeripheral
{
    [self initialize:asCentral asPeripheral:asPeripheral];
    
    _pcycleBluetoothDelegate = delegate;
}

- (void)deInitialize
{
    if (_backgroundMessages != nil)
    {
/*
        for (UnityMessage *message in _backgroundMessages)
        {
            if (message != nil)
            {
                [message deInitialize];
                [message release];
            }
        }
        
        [_backgroundMessages release];
 */
        _backgroundMessages = nil;
        
        if (_peripheralManager != nil)
            [self stopAdvertising];
        
        [self removeCharacteristics];
        [self removeServices];
        
        if (_centralManager != nil)
            [self stopScan];
        
        [_peripherals removeAllObjects];
        [_peripheralCharacteristics removeAllObjects];
    }
}

- (void)pauseMessages:(BOOL)isPaused
{
    if (isPaused != _isPaused) {
        
        if (_backgroundMessages == nil)
            _backgroundMessages = [[NSMutableArray alloc] init];
        
        _isPaused = isPaused;
        
        // if we are not paused now since we know we changed state
        // that means we were paused so we need to pump the saved
        // messages to Unity
        if (isPaused) {
            
            if (_backgroundMessages != nil) {
                
/*
                
                for (UnityMessage *message in _backgroundMessages) {
                    
                    if (message != nil) {
                        
                        [message sendUnityMessage];
                        [message deInitialize];
                        [message release];
                    }

                }
 */
                [_backgroundMessages removeAllObjects];
            }
        }
    }
}

- (void)createService:(NSString *)uuid primary:(BOOL)primary
{
    CBUUID *cbuuid = [CBUUID UUIDWithString:uuid];
    CBMutableService *service = [[CBMutableService alloc] initWithType:cbuuid primary:primary];
    
    NSMutableArray *characteristics = [[NSMutableArray alloc] init];
    
    NSEnumerator *enumerator = [_characteristics keyEnumerator];
    id key;
    while ((key = [enumerator nextObject]))
        [characteristics addObject:[_characteristics objectForKey:key]];
    
    service.characteristics = characteristics;
    
    [_services setObject:service forKey:cbuuid];
    
    if (_peripheralManager != nil)
    {
        [_peripheralManager addService:service];
    }
}

- (void)removeService:(NSString *)uuid
{
    if (_services != nil)
    {
        if (_peripheralManager != nil)
        {
            CBMutableService *service = [_services objectForKey:uuid];
            if (service != nil)
                [_peripheralManager removeService:service];
        }
        
        [_services removeObjectForKey:uuid];
    }
}

- (void)removeServices
{
    if (_services != nil)
    {
        [_services removeAllObjects];
        
        if (_peripheralManager != nil)
            [_peripheralManager removeAllServices];
    }
}

- (void)peripheralName:(NSString *)newName
{
    _peripheralName = newName;
}

- (void)createCharacteristic:(NSString *)uuid properties:(CBCharacteristicProperties)properties permissions:(CBAttributePermissions)permissions value:(NSData *)value
{
    CBUUID *cbuuid = [CBUUID UUIDWithString:uuid];
    CBCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:cbuuid properties:properties value:value permissions:permissions];
    
    [_characteristics setObject:characteristic forKey:cbuuid];
}

- (void)removeCharacteristic:(NSString *)uuid
{
    if (_characteristics != nil)
        [_characteristics removeObjectForKey:uuid];
}

- (void)removeCharacteristics
{
    if (_characteristics != nil)
        [_characteristics removeAllObjects];
}

- (void)startAdvertising
{
    if (_peripheralManager != nil && _services != nil)
    {
        NSMutableArray *services = [[NSMutableArray alloc] init];
        
        NSEnumerator *enumerator = [_services keyEnumerator];
        id key;
        while ((key = [enumerator nextObject]))
        {
            CBMutableService *service = [_services objectForKey:key];
            [services addObject:service.UUID];
        }
        
        if (_peripheralName == nil)
            _peripheralName = @"";
        
        [_peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : services, CBAdvertisementDataLocalNameKey : _peripheralName }];
    }
}

- (void)stopAdvertising
{
    if (_peripheralManager != nil)
        [_peripheralManager stopAdvertising];
}

- (void)updateCharacteristicValue:(NSString *)uuid value:(NSData *)value
{
    if (_characteristics != nil)
    {
        CBUUID *cbuuid = [CBUUID UUIDWithString:uuid];
        CBMutableCharacteristic *characteristic = [_characteristics objectForKey:cbuuid];
        if (characteristic != nil)
        {
            characteristic.value = value;
            if (_peripheralManager != nil)
                [_peripheralManager updateValue:value forCharacteristic:characteristic onSubscribedCentrals:nil];
        }
    }
}

// central delegate implementation
- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs options:(NSDictionary *)options
{
    if (_centralManager != nil)
    {
        if (_peripherals != nil)
            [_peripherals removeAllObjects];
        
        NSLog(@"PcycleBluetooth : scanForPeripheralsWithServices %@", serviceUUIDs);
        
        [_centralManager scanForPeripheralsWithServices:serviceUUIDs options:options];
    }
}

- (void) stopScan
{
    if (_centralManager != nil)
        [_centralManager stopScan];
}

- (void)retrieveListOfPeripheralsWithServices:(NSArray *)serviceUUIDs
{
    if (_centralManager != nil)
    {
        if (_peripherals != nil)
            [_peripherals removeAllObjects];
        
        NSArray * list = [_centralManager retrieveConnectedPeripheralsWithServices:serviceUUIDs];
        if (list != nil)
        {
            for (int i = 0; i < list.count; ++i)
            {
                CBPeripheral *peripheral = [list objectAtIndex:i];
                if (peripheral != nil)
                {
                    NSString *identifier = [[peripheral identifier] UUIDString];
                    NSString *name = [peripheral name];
                    
                    NSString *message = [NSString stringWithFormat:@"RetrievedConnectedPeripheral~%@~%@", identifier, name];
                    
                    NSLog(@"%@", message);
                    
                    [_peripherals setObject:peripheral forKey:identifier];
                }
            }
        }
    }
}

- (void)connectToPeripheral:(NSString *)name
{
    if (_peripherals != nil && name != nil)
    {
        CBPeripheral *peripheral = [_peripherals objectForKey:name];
        if (peripheral != nil)
            [_centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)disconnectPeripheral:(NSString *)name
{
    if (_peripherals != nil && name != nil)
    {
        CBPeripheral *peripheral = [_peripherals objectForKey:name];
        if (peripheral != nil)
        {
            for (int serviceIndex = 0; serviceIndex < peripheral.services.count; ++serviceIndex)
            {
                CBService *service = [peripheral.services objectAtIndex:serviceIndex];
                if (service != nil)
                {
                    for (int characteristicIndex = 0; characteristicIndex < service.characteristics.count; ++characteristicIndex)
                    {
                        CBCharacteristic *characteristic = [service.characteristics objectAtIndex:characteristicIndex];
                        if (characteristic != nil)
                        {
                            NSEnumerator *enumerator = [_peripheralCharacteristics keyEnumerator];
                            id key;
                            while ((key = [enumerator nextObject]))
                            {
                                CBMutableCharacteristic *tempCharacteristic = [_peripheralCharacteristics objectForKey:key];
                                if (tempCharacteristic != nil)
                                {
                                    if ([tempCharacteristic isEqual:characteristic])
                                    {
                                        [_peripheralCharacteristics removeObjectForKey:key];
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            [_centralManager cancelPeripheralConnection:peripheral];
        }
    }
}

- (void)readCharacteristic:(NSString *)name service:(NSString *)serviceString characteristic:(NSString *)characteristicString
{
    if (name != nil && serviceString != nil && characteristicString != nil && _peripherals != nil)
    {
        CBPeripheral *peripheral = [_peripherals objectForKey:name];
        if (peripheral != nil)
        {
            CBUUID *cbuuid = [CBUUID UUIDWithString:characteristicString];
            CBCharacteristic *characteristic = [_peripheralCharacteristics objectForKey:cbuuid];
            if (characteristic != nil)
            {
                NSMutableString *outputString = [NSMutableString stringWithCapacity:characteristic.value.length * 5];
                const unsigned char *valueStr = (const unsigned char *)characteristic.value.bytes;
                for (int i = 0; i < characteristic.value.length; ++i) {
                    [outputString appendFormat:@"0x%hhX ", valueStr[i]];
                }
                NSLog(@"%@", outputString);
                [peripheral readValueForCharacteristic:characteristic];
            }
        }
    }
}

- (void)writeCharacteristic:(NSString *)name service:(NSString *)serviceString characteristic:(NSString *)characteristicString data:(NSData *)data withResponse:(BOOL)withResponse
{
    if (name != nil && serviceString != nil && characteristicString != nil && _peripherals != nil && data != nil)
    {
        CBPeripheral *peripheral = [_peripherals objectForKey:name];
        if (peripheral != nil)
        {
            CBUUID *cbuuid = [CBUUID UUIDWithString:characteristicString];
            CBCharacteristic *characteristic = [_peripheralCharacteristics objectForKey:cbuuid];
            if (characteristic != nil)
            {
                CBCharacteristicWriteType type = CBCharacteristicWriteWithoutResponse;
                if (withResponse)
                    type = CBCharacteristicWriteWithResponse;
                
                [peripheral writeValue:data forCharacteristic:characteristic type:type];
            }
        }
    }
}

- (void)subscribeCharacteristic:(NSString *)name service:(NSString *)serviceString characteristic:(NSString *)characteristicString
{
    if (name != nil && serviceString != nil && characteristicString != nil && _peripherals != nil)
    {
        CBPeripheral *peripheral = [_peripherals objectForKey:name];
        if (peripheral != nil)
        {
            CBUUID *cbuuid = [CBUUID UUIDWithString:characteristicString];
            CBCharacteristic *characteristic = [_peripheralCharacteristics objectForKey:cbuuid];
            if (characteristic != nil)
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)unsubscribeCharacteristic:(NSString *)name service:(NSString *)serviceString characteristic:(NSString *)characteristicString
{
    if (name != nil && serviceString != nil && characteristicString != nil && _peripherals != nil)
    {
        CBPeripheral *peripheral = [_peripherals objectForKey:name];
        if (peripheral != nil)
        {
            CBUUID *cbuuid = [CBUUID UUIDWithString:characteristicString];
            CBCharacteristic *characteristic = [_peripheralCharacteristics objectForKey:cbuuid];
            if (characteristic != nil)
                [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        }
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    //_iOSBluetoothLELogString ([NSString stringWithFormat:@"Central State Update: %d", (int)central.state]);
    if (_pcycleBluetoothDelegate != nil)
    {
        [_pcycleBluetoothDelegate pcycleBluetooth:self didCenterInit:central.state];
    }
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
    
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (error)
    {
        NSString *message = [NSString stringWithFormat:@"Error~%@", error.description];
        
        NSLog(@"%@", message);
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *name = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if (_peripherals != nil && peripheral != nil && name != nil)
    {
        //        NSString *identifier = nil;
        //
        //        NSString *foundPeripheral = [self findPeripheralName:peripheral];
        //        if (foundPeripheral == nil)
        //            identifier = [[NSUUID UUID] UUIDString];
        //        else
        //            identifier = foundPeripheral;
        
        CFStringRef uuid = CFUUIDCreateString(nil, peripheral.UUID);
        NSString * uuidStr = (__bridge NSString *)uuid;
        
        //        NSLog([NSString stringWithFormat:@"peripheral uuid:%@", uuid]);
        
        NSString *message = [NSString stringWithFormat:@"DiscoveredPeripheral~%@~%@", uuidStr, peripheral.name];
        NSLog(@"%@", message);
        
        [_peripherals setObject:peripheral forKey:uuidStr];
        
        if (_pcycleBluetoothDelegate != nil)
        {
            [_pcycleBluetoothDelegate pcycleBluetooth:self didDiscoverPeripheral:peripheral UUID:uuidStr RSSI:RSSI];
        }
        
        CFRelease(uuid);
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (_peripherals != nil)
    {
        NSString *foundPeripheral = [self findPeripheralName:peripheral];
        if (foundPeripheral != nil)
        {
            NSString *message = [NSString stringWithFormat:@"DisconnectedPeripheral~%@", foundPeripheral];
            NSLog(@"%@", message);
            
            if (_pcycleBluetoothDelegate != nil)
            {
                [_pcycleBluetoothDelegate pcycleBluetooth:self didDisconnectPcycleDevice:peripheral error:error];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSString *foundPeripheral = [self findPeripheralName:peripheral];
    if (foundPeripheral != nil)
    {
        NSString *message = [NSString stringWithFormat:@"ConnectedPeripheral~%@", foundPeripheral];
        NSLog(@"%@", message);
        
        peripheral.delegate = self;
        
        [peripheral discoverServices:nil];
    }
}

- (CBPeripheral *) findPeripheralInList:(CBPeripheral*)peripheral
{
    CBPeripheral *foundPeripheral = nil;
    
    NSEnumerator *enumerator = [_peripherals keyEnumerator];
    id key;
    while ((key = [enumerator nextObject]))
    {
        CBPeripheral *tempPeripheral = [_peripherals objectForKey:key];
        if ([tempPeripheral isEqual:peripheral])
        {
            foundPeripheral = tempPeripheral;
            break;
        }
    }
    
    return foundPeripheral;
}

- (NSString *) findPeripheralName:(CBPeripheral*)peripheral
{
    NSString *foundPeripheral = nil;
    
    NSEnumerator *enumerator = [_peripherals keyEnumerator];
    id key;
    while ((key = [enumerator nextObject]))
    {
        CBPeripheral *tempPeripheral = [_peripherals objectForKey:key];
        if ([tempPeripheral isEqual:peripheral])
        {
            foundPeripheral = key;
            break;
        }
    }
    
    return foundPeripheral;
}

// peripheral delegate implementation
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSString *message = [NSString stringWithFormat:@"Error~%@", error.description];
        
        NSLog(@"%@", message);
    }
    else
    {
        NSString *foundPeripheral = [self findPeripheralName:peripheral];
        if (foundPeripheral != nil)
        {
            for (CBService *service in peripheral.services)
            {
                //NSString *message = [NSString stringWithFormat:@"DiscoveredService~%@~%@", foundPeripheral, [service.UUID representativeString]];
                //UnitySendMessage ("BluetoothLEReceiver", "OnBluetoothMessage", [message UTF8String]);
                
                [peripheral discoverCharacteristics:nil forService:service];
            }
        }
    }
    
    [_pcycleBluetoothDelegate pcycleBluetooth:self didConnectPcycleDevice:peripheral error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSString *message = [NSString stringWithFormat:@"Error~%@", error.description];
        
        NSLog(@"%@", message);
    }
    else
    {
        NSString *foundPeripheral = [self findPeripheralName:peripheral];
        if (foundPeripheral != nil)
        {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                NSString *message = [NSString stringWithFormat:@"DiscoveredCharacteristic~%@~%@~%@", foundPeripheral, [service UUID], [characteristic UUID]];
                
                NSLog(@"%@", message);
                
                if ([_peripheralCharacteristics objectForKey:[characteristic UUID]] != nil)
                    continue;
                
                [_peripheralCharacteristics setObject:characteristic forKey:[characteristic UUID]];
                
                NSString *temp = [NSString stringWithFormat:@"%@", [characteristic UUID]];
                
                if ([temp isEqual:@"FFE2"])
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
    
#if 0
    if (peripheral != nil)
    {
        characteristicString = [NSString stringWithFormat:@"%@", @"FFE1"];
        
        NSLog(@"characteristicString = %@", characteristicString);
        
        //characteristicString = [NSString stringWithFormat:@"%@", @"FFE1"];
        
        CBUUID *cbuuid = [CBUUID UUIDWithString:characteristicString];
        CBCharacteristic *characteristic = [_peripheralCharacteristics objectForKey:cbuuid];
        if (characteristic != nil)
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        
        characteristicString = [NSString stringWithFormat:@"%@", @"FFE2"];
        
        NSLog(@"characteristicString = %@", characteristicString);
        
        //characteristicString = [NSString stringWithFormat:@"%@", @"FFE1"];
        
        cbuuid = [CBUUID UUIDWithString:characteristicString];
        characteristic = [_peripheralCharacteristics objectForKey:cbuuid];
        if (characteristic != nil)
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
#endif
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSString *message;
    
    if (error)
    {
        message = [NSString stringWithFormat:@"Error~%@", error.description];
        
        
    }
    else
    {
        if (characteristic.value != nil)
        {
            message = [self base64StringFromData:characteristic.value length:(int)characteristic.value.length];
        }
    }
    
    //NSLog(@"PcycleBluetooth : Update Value %@", message);

    [_pcycleBluetoothDelegate pcycleBluetooth:self dataFromPeripheral:peripheral data:characteristic.value error:error];

}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSString *message = [NSString stringWithFormat:@"Error~%@", error.description];
        
        NSLog(@"%@", message);
    }
    else
    {
        //NSString *message = [NSString stringWithFormat:@"DidWriteCharacteristic~%@", characteristic.UUID];
        
        //NSLog(@"%@", message);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSString *message = [NSString stringWithFormat:@"Error~%@", error.description];
        
        NSLog(@"%@", message);
    }
    else
    {
        NSString *message = [NSString stringWithFormat:@"DidUpdateNotificationStateForCharacteristic~%@", characteristic.UUID];
        
        NSLog(@"%@", message);
    }
}

// peripheral manager delegate implementation
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    //_iOSBluetoothLELogString ([NSString stringWithFormat:@"Peripheral State Update: %d", (int)peripheral.state]);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSString *message = [NSString stringWithFormat:@"Error~%@", error.description];
        NSLog(@"%@", message);
    }
    else
    {
        NSString *message = [NSString stringWithFormat:@"ServiceAdded~%@", service.UUID];
        NSLog(@"%@", message);
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (error)
    {
        NSString *message = [NSString stringWithFormat:@"Error~%@", error.description];
        NSLog(@"%@", message);
    }
    else
    {
        NSString *message = [NSString stringWithFormat:@"StartedAdvertising"];
        NSLog(@"%@", message);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    BOOL success = FALSE;
    
    if (_peripheralManager != nil)
    {
        CBMutableCharacteristic *characteristic = [_characteristics objectForKey:request.characteristic.UUID];
        
        if (characteristic != nil)
        {
            request.value = [characteristic.value subdataWithRange:NSMakeRange(request.offset, characteristic.value.length - request.offset)];
            [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
            
            success = TRUE;
        }
    }
    
    if (!success)
        [_peripheralManager respondToRequest:request withResult:CBATTErrorAttributeNotFound];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    BOOL success = FALSE;
    
    if (_peripheralManager != nil)
    {
        for (int i = 0; i < requests.count; ++i)
        {
            CBATTRequest *request = [requests objectAtIndex:i];
            if (request != nil)
            {
                CBMutableCharacteristic *characteristic = [_characteristics objectForKey:request.characteristic.UUID];
                
                if (characteristic != nil)
                {
                    characteristic.value = request.value;
                    success = TRUE;
                }
                else
                {
                    success = FALSE;
                    break;
                }
            }
            else
            {
                success = FALSE;
                break;
            }
        }
    }
    
    if (success)
        [_peripheralManager respondToRequest:[requests objectAtIndex:0] withResult:CBATTErrorSuccess];
    else
        [_peripheralManager respondToRequest:[requests objectAtIndex:0] withResult:CBATTErrorAttributeNotFound];
}

static char base64EncodingTable[64] =
{
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

- (NSString *) base64StringFromData: (NSData *)data length: (int)length
{
    unsigned long ixtext, lentext;
    long ctremaining;
    unsigned char input[3], output[4];
    short i, charsonline = 0, ctcopy;
    const unsigned char *raw;
    NSMutableString *result;
    
    lentext = [data length];
    if (lentext < 1)
        return @"";
    result = [NSMutableString stringWithCapacity: lentext];
    raw = (const unsigned char *)[data bytes];
    ixtext = 0;
    
    while (true) {
        ctremaining = lentext - ixtext;
        if (ctremaining <= 0)
            break;
        for (i = 0; i < 3; i++) {
            unsigned long ix = ixtext + i;
            if (ix < lentext)
                input[i] = raw[ix];
            else
                input[i] = 0;
        }
        output[0] = (input[0] & 0xFC) >> 2;
        output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4);
        output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6);
        output[3] = input[2] & 0x3F;
        ctcopy = 4;
        switch (ctremaining) {
            case 1:
                ctcopy = 2;
                break;
            case 2:
                ctcopy = 3;
                break;
        }
        
        for (i = 0; i < ctcopy; i++)
            [result appendString: [NSString stringWithFormat: @"%c", base64EncodingTable[output[i]]]];
        
        for (i = ctcopy; i < 4; i++)
            [result appendString: @"="];
        
        ixtext += 3;
        charsonline += 4;
        
        if ((length > 0) && (charsonline >= length))
            charsonline = 0;
    }
    return result;
}

#pragma mark Internal


@end
