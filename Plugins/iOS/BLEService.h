//
//  BLEService.h
//
//  Created by seiji on 1/13/16.
//
//
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define BLE_LOG(fmt,...) NSLog((@"%s L:%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#ifdef DEBUG
#else
#define NSLog(...)
#endif

#define SERVICE_UUID_DEFAULT @"789F0690-FB6E-4D46-8DD8-52B14B29A1A1"
#define CHARACTERISTIC_UUID  @"7F855F82-9378-4508-A3D2-CD989104AF22"

@protocol BLEServiceProtocol <NSObject>

- (void)start:(NSString *)uuidString;

- (void)pause;

- (void)resume;

- (void)stop;

- (BOOL)write:(NSData *)data withResponse:(BOOL)withResponse;

@end

@interface NSData (Order)

- (NSData *)reverse;

@end

typedef NS_ENUM(NSInteger, BLEServiceCentralState) {
    BLEServiceCentralStateStarting,
    BLEServiceCentralStateWaitingForDiscovering,
    BLEServiceCentralStateWaitingForConnecting,
    BLEServiceCentralStateWaitingForDiscoveringService,
    BLEServiceCentralStateWaitingForDiscoveringCharacteristics,
    BLEServiceCentralStateWaitingForSubscribing,
    BLEServiceCentralStateSubscribing,
    BLEServiceCentralStateError,
};

@class BLEServiceCentral;

@protocol BLEServiceCentralDelegate <NSObject>

@optional

- (void)centralServiceDidUpdateState:(BLEServiceCentral *)service;

- (void)centralServiceDidConnectPeripheral:(BLEServiceCentral *)service;

- (void)centralServiceDidDisconnectPeripheral:(BLEServiceCentral *)service;

- (void)centralService:(BLEServiceCentral *)service
 didReceiveNotifyValue:(NSData *)data;

@end

@interface BLEServiceCentral : NSObject <BLEServiceProtocol>

+ (instancetype)sharedInstance;

@property (nonatomic, weak) id <BLEServiceCentralDelegate> delegate;
@property (nonatomic, assign) BLEServiceCentralState state;

@end

typedef NS_ENUM(NSInteger, BLEServicePeripheralState) {
    BLEServicePeripheralStateStarting,
    BLEServicePeripheralStateWaitingForServiceToAdd,
    BLEServicePeripheralStateWaitingForAdvertisingToStart,
    BLEServicePeripheralStateAdvertising,
    BLEServicePeripheralStateError,
};

@class BLEServicePeripheral;

@protocol BLEServicePeripheralDelegate <NSObject>

@optional

- (void)peripheralServiceDidUpdateState:(BLEServicePeripheral *)service;

- (NSData *)peripheralServiceDidReceiveReadRequest:(BLEServicePeripheral *)service;

- (void)peripheralService:(BLEServicePeripheral *)service
  didReceiveWriteRequests:(NSData *)data;

- (void)peripheralServiceDidSubscribeToCharacteristic:(BLEServicePeripheral *)service;

- (void)peripheralServiceDidUnsubscribeFromCharacteristic:(BLEServicePeripheral *)service;

@end

@interface BLEServicePeripheral: NSObject <BLEServiceProtocol>

@property (nonatomic, weak) id <BLEServicePeripheralDelegate> delegate;
@property (nonatomic, assign) BLEServicePeripheralState state;

+ (instancetype)sharedInstance;

@end

