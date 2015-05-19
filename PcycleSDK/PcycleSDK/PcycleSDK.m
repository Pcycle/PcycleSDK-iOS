//
//  PcycleSDK.m
//  PcycleSDK
//
//  Created by Arthur on 14/12/27.
//  Copyright (c) 2014年 FlyingFrog. All rights reserved.
//

#import "PcycleSDK.h"
#import <Foundation/Foundation.h>


@implementation PcycleSDK

-(instancetype) initWithDelegate:(id<PcycleSDKDelegate>) delegate
{
    _pcycleBluetooth = [[PcycleBluetooth alloc] init];
    
    [_pcycleBluetooth initWithDelegate:self asCentral:YES asPeripheral:NO];
    
    _pcycleSDKDelegate = delegate;
    
    _currentConnectDeviceUUID = nil;
    _resistance = 0;
    
    return self;
}

-(void) scanForPcycleDevices
{
    if (_pcycleBluetooth == nil)
    {
        NSLog(@"%@", @"没有初始化！");
    }
    
    NSMutableArray *actualUUIDs = nil;
    
    NSString *serviceUUIDsString = [NSString stringWithFormat:@"%@", @"FFE0"];
    
    NSArray *serviceUUIDs = [serviceUUIDsString componentsSeparatedByString:@"|"];
        
    if (serviceUUIDs.count > 0)
    {
        actualUUIDs = [[NSMutableArray alloc] init];
            
        for (NSString* sUUID in serviceUUIDs)
        {
            [actualUUIDs addObject:[CBUUID UUIDWithString:sUUID]];
        }
    }
    
    [_pcycleBluetooth scanForPeripheralsWithServices:actualUUIDs options:nil];
    
    NSLog(@"PcycleSDK : Begin to Scan for Pcycle Device");
}

-(void) stopScan
{
    if(_pcycleBluetooth != nil)
    {
        [_pcycleBluetooth stopScan];
    }
}

-(void) connectToPcycleDevice:(NSString*) UUID
{
    if (_pcycleBluetooth != nil && UUID != nil)
    {
        [_pcycleBluetooth connectToPeripheral:UUID];
    }
}

-(void) disconnectPcycleDevice:(NSString*) UUID
{
    if (_pcycleBluetooth != nil && UUID != nil)
    {
        [_pcycleBluetooth disconnectPeripheral:UUID];
    }
}


-(void) requestCurrentVelocity
{
    unsigned char data[20] = {0xA5, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0xA5};
    
    _operationFlag = 0xA5;
    
    [_pcycleBluetooth writeCharacteristic:_currentConnectDeviceUUID service:@"FFE0" characteristic:@"FFE1" data:[NSData dataWithBytes:data length:20] withResponse:YES];
}

- (void)requestStepFreq
{
    unsigned char data[20] = {0xAA, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0xAA};
    
    [_pcycleBluetooth writeCharacteristic:_currentConnectDeviceUUID service:@"FFE0" characteristic:@"FFE1" data:[NSData dataWithBytes:data length:20] withResponse:YES];
}

- (void)requestFirmwareVer
{
    unsigned char data[20] = {0xA8, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0xA8};
    
    [_pcycleBluetooth writeCharacteristic:_currentConnectDeviceUUID service:@"FFE0" characteristic:@"FFE1" data:[NSData dataWithBytes:data length:20] withResponse:YES];
}

-(void) setResistance:(float) newton
{
    unsigned char data[20] = {0xA6, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0};
    
    _operationFlag = 0xA6;
    
    if (newton > 100.0f)
    {
        newton = 100.0f;
    }
    
    if (newton < 0)
    {
        newton = 0;
    }
    
    //只保留小数点后1位
    newton = ((int)(newton * 10.0)) / 10.0;
    _resistance = newton;
    
    int n = (int)newton;
    data[3] = (int)((newton - n) * 10);
    
    NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x", n]];
        
    unsigned char temp;
        
    if ([hexString length] > 2)
    {
        data[1] = [hexString characterAtIndex:0] - '0';
        
        temp = [hexString characterAtIndex:1];
        
        if (temp >= 'a')
        {
            data[2] = (temp - 'a' + 10) * 16;
        }
        else
        {
            data[2] = (temp - '0') * 16;
        }
        
        temp = [hexString characterAtIndex:2];
        
        if (temp >= 'a')
        {
            data[2] += (temp - 'a' + 10);
        }
        else
        {
            data[2] += (temp - '0');
        }
    }
    else if ([hexString length] == 2)
    {
        temp = [hexString characterAtIndex:0];
        
        if (temp >= 'a')
        {
            data[2] = (temp - 'a' + 10) * 16;
        }
        else
        {
            data[2] = (temp - '0') * 16;
        }
        
        temp = [hexString characterAtIndex:1];
        
        if (temp >= 'a')
        {
            data[2] += (temp - 'a' + 10);
        }
        else
        {
            data[2] += (temp - '0');
        }
    }
    else
    {
        temp = [hexString characterAtIndex:0];
        
        if (temp >= 'a')
        {
            data[2] += (temp - 'a' + 10);
        }
        else
        {
            data[2] += (temp - '0');
        }
    }
        
        
    
    data[19] = [self calCheckSum:data length:19];
    
    [_pcycleBluetooth writeCharacteristic:_currentConnectDeviceUUID service:@"FFE0" characteristic:@"FFE1" data:[NSData dataWithBytes:data length:20] withResponse:YES];
}

#pragma mark - pcycleBluetooth delegate

-(void) pcycleBluetooth:(PcycleBluetooth *) pcycleBluetooth didDiscoverPeripheral:(CBPeripheral *)peripheral UUID:(NSString *)uuid RSSI:(NSNumber *)RSSI
{
    [_pcycleSDKDelegate pcycleSDK:self discoverPcycleDevice:peripheral.name UUID:uuid RSSI:RSSI];
    
    NSLog(@"PcycleSDK : Discover Pcycle Device : %@ %@", peripheral.name, uuid);
}

-(void) pcycleBluetooth:(PcycleBluetooth *) pcycleBluetooth didConnectPcycleDevice:(CBPeripheral *)peripheral error:(NSError *)error
{

    if (error != nil)
    {
        [_pcycleSDKDelegate pcycleSDK:self didConnectToPcycleDevice:nil UUID:nil error:error];
    }
    else
    {
        _currentConnectDeviceUUID = [_pcycleBluetooth findPeripheralName:peripheral];
        [_pcycleSDKDelegate pcycleSDK:self didConnectToPcycleDevice:peripheral.name UUID:_currentConnectDeviceUUID error:error];
    }
}

- (void)pcycleBluetooth:(PcycleBluetooth *)pcycleBluetooth didDisconnectPcycleDevice:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (error != nil)
    {
        [_pcycleSDKDelegate pcycleSDK:self didDisconnectToPcycleDevice:nil UUID:nil error:error];
    }
    else
    {
        _currentConnectDeviceUUID = [_pcycleBluetooth findPeripheralName:peripheral];
        [_pcycleSDKDelegate pcycleSDK:self didDisconnectToPcycleDevice:peripheral.name UUID:_currentConnectDeviceUUID error:error];
    }
}

-(void) pcycleBluetooth:(PcycleBluetooth *) pcycleBluetooth dataFromPeripheral:(CBPeripheral *)peripheral data:(NSData *)data error:(NSError *)error
{
    
    float velocity;
    NSNumber *buttonIndex;
    PcycleRollStickAction action;
    float resistance = 0;
    float stepFreq = 0;
    int ver = 0;
    
    //NSString *message = [NSString stringWithFormat:@"Error~%@", error.description];
    
    //NSLog(@"%@", message);
    
    if (data == nil)
    {
        if (error != nil)
        {
            [_pcycleSDKDelegate pcycleSDK:self recieveError:error];
        }
        
        return;
    }
    
    const unsigned char *valueStr = (const unsigned char *)data.bytes;
    
    NSLog(@"data = %2x", valueStr[0]);
    
    switch (valueStr[0]) {
            
        //速度反馈
        case 0xA5:
            
            velocity = (float)valueStr[1] + valueStr[2] * 0.1;
            [_pcycleSDKDelegate pcycleSDK:self currentVelocity:velocity error:error];
            
            break;
            
        //阻力反馈
        case 0xA6:
            
            resistance = valueStr[1] * 256 + (valueStr[2] >> 4) * 16 + (valueStr[2] & 0x0F) + (float)valueStr[3] * 0.1;
            [_pcycleSDKDelegate pcycleSDK:self didSetResistance:resistance error:error];
            
            break;
        
        //请求版本
        case 0xA8:
            
            ver = valueStr[1] * 16 + valueStr[2];
            [_pcycleSDKDelegate pcycleSDK:self didRequestFirmwareVer:ver error:error];
            
            break;
            
        //步频
        case 0xAA:
            
            stepFreq = valueStr[1] * 256 + (valueStr[2] >> 4) * 16 + (valueStr[2] & 0x0F) + (float)valueStr[3] * 0.1;
            [_pcycleSDKDelegate pcycleSDK:self didRequestStepFreq:stepFreq error:error];
            break;
            
        //按钮
        case 0xB1:
            
            buttonIndex = [NSNumber numberWithInteger:(int)valueStr[1]];
            [_pcycleSDKDelegate pcycleSDK:self buttonPressed:buttonIndex error:error];
            
            break;
            
        //摇杆
        case 0xB5:
            
            action = (int)valueStr[1] + 1;
            [_pcycleSDKDelegate pcycleSDK:self rollStickRolled:action error:error];
            
            break;
        case 0xA7:
            
            break;

        case 0xA9:
            
            break;
            
        default:
            break;
    }
}


-(unsigned char) calCheckSum:(const unsigned char*) data length:(int) length
{
    unsigned char checkSum = 0;
    
    for (int i = 0; i < length; ++i)
    {
        checkSum = checkSum ^ data[i];
    }
    
    return checkSum;
}
























@end
