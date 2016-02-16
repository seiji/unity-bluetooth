//
//  BLEServiceCentral.h
//  BLEController
//
//  Created by seiji on 1/13/16.
//
//

#import "BLEService.h"

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
