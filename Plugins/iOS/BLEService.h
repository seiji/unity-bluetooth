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

typedef NS_ENUM(NSInteger, BLEServicePeripheralState) {
    BLEServicePeripheralStateStarting,
    BLEServicePeripheralStateWaitingForServiceToAdd,
    BLEServicePeripheralStateWaitingForAdvertisingToStart,
    BLEServicePeripheralStateAdvertising,
    BLEServicePeripheralStateError,
};

@protocol BLEServiceProtocol <NSObject>

- (void)start:(NSString *)uuidString;
- (void)pause;
- (void)resume;
- (void)stop;
- (BOOL)write:(NSData *)data withResponse:(BOOL)withResponse;

@end

@class BLEServiceCentral;

@protocol BLEServiceCentralDelegate <NSObject>
@optional
- (void)centralServiceDidUpdateState:(BLEServiceCentral *)service;
- (void)centralService:(BLEServiceCentral *)service
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *, id> *)advertisementData
                  RSSI:(NSNumber *)RSSI;
- (void)centralServiceDidConnectPeripheral:(BLEServiceCentral *)service;
- (void)centralServiceDidDisconnectPeripheral:(BLEServiceCentral *)service;
- (void)centralService:(BLEServiceCentral *)service
 didReceiveNotifyValue:(NSData *)data;
@end

@interface BLEServiceCentral : NSObject <BLEServiceProtocol>
@property (nonatomic, weak) id <BLEServiceCentralDelegate> delegate;
@property (nonatomic, assign) BLEServiceCentralState state;
+ (instancetype)sharedInstance;
@end

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

@interface NSData (Order)
- (NSData *)reverse;
@end
