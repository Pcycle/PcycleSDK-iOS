//
//  PcycleBluetooth.h
//  PcycleSDK
//
//  Created by Arthur on 15/1/5.
//  Copyright (c) 2015年 FlyingFrog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreBluetooth/CoreBluetooth.h"

@protocol PcycleBluetoothDelegate;

@interface PcycleBluetooth : NSObject <CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate>
{
    CBCentralManager *_centralManager;
    
    NSMutableDictionary *_peripherals;
    NSMutableDictionary *_peripheralCharacteristics;
    
    CBPeripheralManager *_peripheralManager;
    
    NSString *_peripheralName;
    
    NSMutableDictionary *_services;
    NSMutableDictionary *_characteristics;
    
    NSMutableArray *_backgroundMessages;
    
    id<PcycleBluetoothDelegate> _pcycleBluetoothDelegate;
    
    BOOL _isPaused;
    BOOL _alreadyNotified;
}

@property (atomic, strong) NSMutableDictionary *_peripherals;
//@property (nonatomic,assign) id< PcycleBluetoothDelegate > _pcycleBluetoothDelegate;

- (void)initialize:(BOOL)asCentral asPeripheral:(BOOL)asPeripheral;
- (void)initWithDelegate:(id<PcycleBluetoothDelegate>) delegate asCentral:(BOOL)asCentral asPeripheral:(BOOL)asPeripheral;
- (void)deInitialize;
- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs options:(NSDictionary *)options;
- (void)stopScan;
- (void)retrieveListOfPeripheralsWithServices:(NSArray *)serviceUUIDs;
- (void)connectToPeripheral:(NSString *)name;
- (void)disconnectPeripheral:(NSString *)name;
- (void)readCharacteristic:(NSString *)name service:(NSString *)serviceString characteristic:(NSString *)characteristicString;
- (void)writeCharacteristic:(NSString *)name service:(NSString *)serviceString characteristic:(NSString *)characteristicString data:(NSData *)data withResponse:(BOOL)withResponse;
- (void)subscribeCharacteristic:(NSString *)name service:(NSString *)serviceString characteristic:(NSString *)characteristicString;
- (void)unsubscribeCharacteristic:(NSString *)name service:(NSString *)serviceString characteristic:(NSString *)characteristicString;
- (void)peripheralName:(NSString *)newName;
- (void)createService:(NSString *)uuid primary:(BOOL)primary;
- (void)removeService:(NSString *)uuid;
- (void)removeServices;
- (void)createCharacteristic:(NSString *)uuid properties:(CBCharacteristicProperties)properties permissions:(CBAttributePermissions)permissions value:(NSData *)value;
- (void)removeCharacteristic:(NSString *)uuid;
- (void)removeCharacteristics;
- (void)startAdvertising;
- (void)stopAdvertising;
- (void)updateCharacteristicValue:(NSString *)uuid value:(NSData *)value;
- (void)pauseMessages:(BOOL)isPaused;
//- (void)sendUnityMessage:(BOOL)isString message:(NSString *)message;

- (NSString *) base64StringFromData:(NSData *)data length:(int)length;

- (NSString *) findPeripheralName:(CBPeripheral*)peripheral;

@end

@protocol PcycleBluetoothDelegate <NSObject>

@required

-(void) pcycleBluetooth:(PcycleBluetooth *) pcycleBluetooth didDiscoverPeripheral:(CBPeripheral *)peripheral UUID:(NSString *)uuid RSSI:(NSNumber *)RSSI;


-(void) pcycleBluetooth:(PcycleBluetooth *) pcycleBluetooth dataFromPeripheral:(CBPeripheral *)peripheral data:(NSData *)data error:(NSError *)error;

-(void) pcycleBluetooth:(PcycleBluetooth *) pcycleBluetooth didConnectPcycleDevice:(CBPeripheral *)peripheral error:(NSError *)error;


-(void) pcycleBluetooth:(PcycleBluetooth *) pcycleBluetooth didDisconnectPcycleDevice:(CBPeripheral *)peripheral error:(NSError *)error;

-(void) pcycleBluetooth:(PcycleBluetooth *) pcycleBluetooth didCenterInit:(CBCentralManagerState)state;


@end

















