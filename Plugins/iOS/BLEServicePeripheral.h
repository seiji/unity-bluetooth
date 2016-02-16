//
//  BLEServicePeripheral.h
//  BLEController
//
//  Created by seiji on 1/8/16.
//
//

#import "BLEService.h"

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
