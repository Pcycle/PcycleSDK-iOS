//
//  PcycleSDK.h
//  PcycleSDK
//
//  Created by Arthur on 14/12/18.
//  Copyright (c) 2014年 FlyingFrog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PcycleBluetooth.h"

//! Project version number for PcycleSDK.
FOUNDATION_EXPORT double PcycleSDKVersionNumber;

//! Project version string for PcycleSDK.
FOUNDATION_EXPORT const unsigned char PcycleSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <PcycleSDK/PublicHeader.h>


@protocol PcycleSDKDelegate;


typedef NS_ENUM(NSInteger, PcycleRollStickAction) {
    PcycleRollStickActionOrign = 0,
    PcycleRollStickActionUp,
    PcycleRollStickActionDown,
    PcycleRollStickActionLeft,
    PcycleRollStickActionRight,
    PcycleRollStickActionLeftUp,
    PcycleRollStickActionRightUp,
    PcycleRollStickActionLeftDown,
    PcycleRollStickActionRightDown
};


/*!
 *  @class PcycleSDK
 *
 *  @discussion PcycleSDK类，为整个SDK的顶层接口类，所有功能都由此类进行提供
 *
 */
@interface PcycleSDK : NSObject<PcycleBluetoothDelegate>
{
    PcycleBluetooth *_pcycleBluetooth;
    id<PcycleSDKDelegate> _pcycleSDKDelegate;
    NSString *_currentConnectDeviceUUID;
    float _resistance;
    unsigned char _operationFlag;
}

/**
 *  进行初始化
 */
-(void) initWithDelegate:(id<PcycleSDKDelegate>) delegate;


/**
 *  开始扫描Pcycle设备
 */
-(void) scanForPcycleDevices;

/**
 *  停止扫描
 */
-(void) stopScan;

/**
 *  连接Pcycle设备
 *
 *  @param UUID 要连接设备的UUID
 */
-(void) connectToPcycleDevice:(NSString*) UUID;

/**
 *  断开与Pcycle设备的连接
 *
 *  @param UUID 要断开设备的UUID
 */
-(void) disconnectPcycleDevice:(NSString*) UUID;

/**
 *  请求当前速度
 */
-(void) requestCurrentVelocity;

/**
 *  设置阻力
 *
 *  @param newton 牛顿（单位）
 */
-(void) setResistance:(float) newton;

#if 0
/**
 *  获取固件版本
 *
 *  @return 字符串形式的固件版本信息
 */
-(NSString*) getFirmwareVersion;
#endif

@end

@protocol PcycleSDKDelegate <NSObject>

@optional


-(void) pcycleSDK:(PcycleSDK *) pcycleSDK currentVelocity:(float) metersPerSecond error:(NSError *) error;

-(void) pcycleSDK:(PcycleSDK *) pcycleSDK discoverPcycleDevice:(NSString *)name UUID:(NSString *)uuid RSSI:(NSNumber *)RSSI;

-(void) pcycleSDK:(PcycleSDK *) pcycleSDK didConnectToPcycleDevice:(NSString *)name UUID:(NSString *)uuid error:(NSError *) error;

-(void) pcycleSDK:(PcycleSDK *) pcycleSDK didSetResistance:(float) newton error:(NSError *) error;

-(void) pcycleSDK:(PcycleSDK *) pcycleSDK buttonPressed:(NSNumber *) buttonIndex error:(NSError *) error;

-(void) pcycleSDK:(PcycleSDK *) pcycleSDK rollStickRolled:(PcycleRollStickAction) action error:(NSError *) error;

@end


