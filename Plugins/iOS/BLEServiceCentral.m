//
//  BLEServiceCentral.m
//  BLEController
//
//  Created by seiji on 1/13/16.
//
//

#import "BLEServiceCentral.h"

@interface BLEServiceCentral () <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    CBCentralManager *_manager;
    CBUUID *_serviceUUID;
    CBUUID *_characteristicUUID;

    CBPeripheral *_peripheral;
    CBCharacteristic *_characteristic;

    BOOL _isSubscribe;
}
@end

@implementation BLEServiceCentral

+ (instancetype)sharedInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [self new];
    });
    return _sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        _serviceUUID = [CBUUID UUIDWithString:SERVICE_UUID_DEFAULT];
        _characteristicUUID = [CBUUID UUIDWithString:CHARACTERISTIC_UUID];
    }
    return self;
}

#pragma mark - BLEServiceProtocol
- (void)start:(NSString *)uuidString
{
    if (uuidString != nil) {
        _serviceUUID = [CBUUID UUIDWithString:uuidString];
    }
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)pause
{
    if (_peripheral != nil) {
        [_manager cancelPeripheralConnection:_peripheral];
    }
    _peripheral = nil;
    _characteristic = nil;
    [_manager stopScan];
}

- (void)resume
{
    [_manager scanForPeripheralsWithServices:@[_serviceUUID] options:nil];
}

- (void)stop
{
    [self pause];
    _manager = nil;
}

- (void)read
{
    [_peripheral readValueForCharacteristic:_characteristic];
}

- (BOOL)write:(NSData *)data withResponse:(BOOL)withResponse
{
    CBCharacteristicWriteType type = CBCharacteristicWriteWithoutResponse;
    if (withResponse)
        type = CBCharacteristicWriteWithResponse;

    [_peripheral writeValue:[data reverse] forCharacteristic:_characteristic type:type];
    return YES;
}

#pragma mark - BLEServiceCentral ()
- (NSString *)stringFromCBCentralManagerState:(CBCentralManagerState)state
{
    switch (state) {
        case CBCentralManagerStatePoweredOff: return @"PoweredOff";
        case CBCentralManagerStatePoweredOn: return @"PoweredOn";
        case CBCentralManagerStateResetting: return @"Resetting";
        case CBCentralManagerStateUnauthorized: return @"Unauthorized";
        case CBCentralManagerStateUnknown: return @"Unknown";
        case CBCentralManagerStateUnsupported: return @"Unsupported";
    }
}

- (NSString*)stringFromBLEServiceCentralState:(BLEServiceCentralState)state {
    switch (state) {
        case BLEServiceCentralStateStarting: return @"Starting";
        case BLEServiceCentralStateWaitingForDiscovering: return @"WaitingForDiscovering";
        case BLEServiceCentralStateWaitingForConnecting: return @"WaitingForConnecting";
        case BLEServiceCentralStateWaitingForDiscoveringService: return @"WaitingForDiscoveringService";
        case BLEServiceCentralStateWaitingForDiscoveringCharacteristics: return @"WaitingForDiscoveringCharacteristics";
        case BLEServiceCentralStateWaitingForSubscribing: return @"WaitingForSubscribing";
        case BLEServiceCentralStateSubscribing: return @"Subscribing";
        case BLEServiceCentralStateError: return @"Error";
    }
}

- (void)transitionState:(BLEServiceCentralState)newState
{
    switch (_state) {
        case BLEServiceCentralStateStarting:
            switch (newState) {
                case BLEServiceCentralStateWaitingForDiscovering:
                    [_manager scanForPeripheralsWithServices:@[_serviceUUID] options:nil];
                    break;
                default:
                    break;
            }
            break;
        case BLEServiceCentralStateWaitingForDiscovering:
            switch (newState) {
                case BLEServiceCentralStateWaitingForDiscovering:
                    break;
                case BLEServiceCentralStateWaitingForConnecting:
                    [_manager connectPeripheral:_peripheral options:nil];
                    [_manager stopScan];
                    break;
                default:
                    break;
            }
            break;
        case BLEServiceCentralStateWaitingForConnecting:
            switch (newState) {
                case BLEServiceCentralStateWaitingForDiscovering:
                    [_manager scanForPeripheralsWithServices:@[_serviceUUID] options:nil];
                    break;
                case BLEServiceCentralStateWaitingForDiscoveringService:
                    _peripheral.delegate = self;
                    [_peripheral discoverServices:@[_serviceUUID]];
                    break;
                    
                default:
                    break;
            }
            break;
        case BLEServiceCentralStateWaitingForDiscoveringService:
            switch (newState) {
                case BLEServiceCentralStateWaitingForDiscovering:
                    [_manager scanForPeripheralsWithServices:@[_serviceUUID] options:nil];
                    break;
                case BLEServiceCentralStateWaitingForDiscoveringCharacteristics:
                    for (CBService *service in _peripheral.services) {
                        [_peripheral discoverCharacteristics:@[_characteristicUUID] forService:service];
                    }
                    break;
                default:
                    break;
            }
            break;
        case BLEServiceCentralStateWaitingForDiscoveringCharacteristics:
            switch (newState) {
                case BLEServiceCentralStateWaitingForDiscovering:
                    [_manager scanForPeripheralsWithServices:@[_serviceUUID] options:nil];
                    break;
                case BLEServiceCentralStateWaitingForSubscribing:
                    [_peripheral setNotifyValue:YES forCharacteristic:_characteristic];
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
    BLE_LOG(@"[%@] => [%@]", [self stringFromBLEServiceCentralState:_state], [self stringFromBLEServiceCentralState:newState]);
    _state = newState;
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    BLE_LOG(@"%@", [self stringFromCBCentralManagerState:central.state]);
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(centralServiceDidUpdateState:)]) {
        [self.delegate centralServiceDidUpdateState:self];
    }
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self transitionState:BLEServiceCentralStateWaitingForDiscovering];
    } else {
        [self transitionState:BLEServiceCentralStateStarting];
    }
}

- (void)centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary<NSString *, id> *)advertisementData
    RSSI:(NSNumber *)RSSI
{
    BLE_LOG();
    _peripheral = peripheral;
    [self transitionState:BLEServiceCentralStateWaitingForConnecting];
}

- (void)centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    BLE_LOG();
    [self transitionState:BLEServiceCentralStateWaitingForDiscoveringService];
}

- (void)centralManager:(CBCentralManager *)central
    didFailToConnectPeripheral:(CBPeripheral *)peripheral
    error:(nullable NSError *)error
{
    BLE_LOG();
    if (error != nil) {
        BLE_LOG("%@", error);
    }
    
    _isSubscribe = NO;
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(centralServiceDidDisconnectPeripheral:)]) {
        [self.delegate centralServiceDidDisconnectPeripheral:self];
    }
    [self transitionState:BLEServiceCentralStateWaitingForDiscovering];
}

- (void)centralManager:(CBCentralManager *)central
    didDisconnectPeripheral:(CBPeripheral *)peripheral
    error:(nullable NSError *)error
{
    BLE_LOG();
    if (error != nil) {
        BLE_LOG("%@", error);
    }
    
    _isSubscribe = NO;
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(centralServiceDidDisconnectPeripheral:)]) {
        [self.delegate centralServiceDidDisconnectPeripheral:self];
    }
    [self transitionState:BLEServiceCentralStateWaitingForDiscovering];
}

- (void)centralManager:(CBCentralManager *)central
      willRestoreState:(NSDictionary<NSString *, id> *)dict
{
    BLE_LOG();
}

#pragma mark - CBPeripheralDelegate
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{

}

- (void)peripheral:(CBPeripheral *)peripheral
    didModifyServices:(NSArray<CBService *> *)invalidatedServices
{

}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral
    error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral
    didReadRSSI:(NSNumber *)RSSI
    error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral
    didDiscoverServices:(nullable NSError *)error
{
    BLE_LOG();
    if (error != nil) {
        BLE_LOG("%@", error);
        return;
    }
    [self transitionState:BLEServiceCentralStateWaitingForDiscoveringCharacteristics];
}

- (void)peripheral:(CBPeripheral *)peripheral
    didDiscoverIncludedServicesForService:(CBService *)service
    error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral
    didDiscoverCharacteristicsForService:(CBService *)service
    error:(nullable NSError *)error
{
    BLE_LOG();
    if (error != nil) {
        BLE_LOG("%@", error);
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:_characteristicUUID]) {
            _characteristic = characteristic;
            [self transitionState:BLEServiceCentralStateWaitingForSubscribing];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
    didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
    error:(nullable NSError *)error
{
    BLE_LOG();
    if (error != nil) {
        BLE_LOG("%@", error);
        return;
    }

    if (characteristic.isNotifying) {
        NSData *data = characteristic.value;
        if (data.length == 0) {
            [self pause];
        } else if (self.delegate != nil && [self.delegate respondsToSelector:@selector(centralService:didReceiveNotifyValue:)]) {
            [self.delegate centralService:self didReceiveNotifyValue:[data reverse]];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
    didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
    error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral
    didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
    error:(nullable NSError *)error
{
    BLE_LOG();
    if (error != nil) {
        BLE_LOG("%@", error);
        return;
    }
    
    _isSubscribe = YES;
    [self transitionState:BLEServiceCentralStateWaitingForSubscribing];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(centralServiceDidConnectPeripheral:)]) {
        [self.delegate centralServiceDidConnectPeripheral:self];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
    didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic
    error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral
    didUpdateValueForDescriptor:(CBDescriptor *)descriptor
    error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral
    didWriteValueForDescriptor:(CBDescriptor *)descriptor
    error:(nullable NSError *)error
{

}

@end
