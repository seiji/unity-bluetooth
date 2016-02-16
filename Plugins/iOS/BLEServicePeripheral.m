//
//  BLEServicePeripheral.m
//  BLEController
//
//  Created by seiji on 1/8/16.
//
//

#import "BLEServicePeripheral.h"

@interface BLEServicePeripheral () <CBPeripheralManagerDelegate>
{
    CBPeripheralManager *_manager;
    CBUUID *_serviceUUID;
    CBUUID *_characteristicUUID;
    NSDictionary *advertisingData;
    
    CBMutableService *_service;
    CBMutableCharacteristic *_characteristic;
    
    BOOL _isSubscribed;
    
    NSMutableArray *_transmitQueue;
}
@end

@implementation BLEServicePeripheral

+ (instancetype)sharedInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [self new];
    });
    return _sharedInstance;
}

- (id) init {
    if (self = [super init]) {
        _serviceUUID = [CBUUID UUIDWithString:SERVICE_UUID_DEFAULT];
        _characteristicUUID = [CBUUID UUIDWithString:CHARACTERISTIC_UUID];
        _transmitQueue = [NSMutableArray new];
    }
    return self;
}

#pragma mark - BLEServiceProtocol
- (void)start:(NSString *)uuidString
{
    if (uuidString != nil) {
        _serviceUUID = [CBUUID UUIDWithString:uuidString];
    }
    [_transmitQueue removeAllObjects];
    advertisingData = @{CBAdvertisementDataServiceUUIDsKey : @[_serviceUUID]};
    _manager = [[CBPeripheralManager alloc]
                initWithDelegate:self
                queue:nil
                options:@{CBPeripheralManagerOptionShowPowerAlertKey:@YES}];
}

- (void)pause
{
    [_manager stopAdvertising];
    [self write:[@"" dataUsingEncoding:NSUTF8StringEncoding] withResponse:NO];
}

- (void)resume
{
    [_transmitQueue removeAllObjects];
    [_manager startAdvertising:advertisingData];
}

- (void)stop
{
    [self pause];
    _manager = nil;
}

- (void)read:(NSData *)data
{
    // nothing
}

- (BOOL)write:(NSData *)data withResponse:(BOOL)withResponse
{
    @synchronized(_transmitQueue) {
        [_transmitQueue addObject:[data reverse]];
    }
    [self processTransmitQueue];
    return TRUE;
}

#pragma mark - BLEServicePeripheral ()

- (void)processTransmitQueue
{
    NSData* data = [_transmitQueue firstObject];
    if (data != nil) {
        while ([_manager updateValue:data forCharacteristic:_characteristic onSubscribedCentrals:nil] && _isSubscribed) {
            @synchronized(_transmitQueue) {
                [_transmitQueue removeObjectAtIndex:0];
            }
            
            data = [_transmitQueue firstObject];
            if (data == nil) {
                break;
            }
        }
    }
}

- (NSString *)stringFromCBPeripheralManagerState:(CBPeripheralManagerState)state
{
    switch (state) {
        case CBPeripheralManagerStatePoweredOff: return @"PoweredOff";
        case CBPeripheralManagerStatePoweredOn: return @"PoweredOn";
        case CBPeripheralManagerStateResetting: return @"Resetting";
        case CBPeripheralManagerStateUnauthorized: return @"Unauthorized";
        case CBPeripheralManagerStateUnknown: return @"Unknown";
        case CBPeripheralManagerStateUnsupported: return @"Unsupported";
    }
}

- (NSString*)stringFromBLEServicePeripheralState:(BLEServicePeripheralState)state {
    switch (state) {
        case BLEServicePeripheralStateStarting: return @"Starting";
        case BLEServicePeripheralStateWaitingForServiceToAdd: return @"WaitingForServiceToAdd";
        case BLEServicePeripheralStateWaitingForAdvertisingToStart: return @"WaitingForAdvertisingToStart";
        case BLEServicePeripheralStateAdvertising: return @"Advertising";
        case BLEServicePeripheralStateError: return @"Error";
    }
}
- (void)transitionState:(BLEServicePeripheralState)newState
{
    switch (_state) {
        case BLEServicePeripheralStateStarting:
            switch (newState) {
                case BLEServicePeripheralStateWaitingForServiceToAdd:
                    ;
                    CBCharacteristicProperties prop =
                    CBCharacteristicPropertyRead |
                    CBCharacteristicPropertyWrite |
                    CBCharacteristicPropertyWriteWithoutResponse |
                    CBCharacteristicPropertyNotify |
                    CBCharacteristicPropertyNotifyEncryptionRequired ;
                    
                    CBAttributePermissions perm =
                    CBAttributePermissionsReadable | CBAttributePermissionsWriteable;
                    
                    _characteristic = [[CBMutableCharacteristic alloc]
                                       initWithType:_characteristicUUID
                                       properties:prop
                                       value:nil
                                       permissions:perm];
                    _service = [[CBMutableService alloc] initWithType:_serviceUUID primary:YES];
                    _service.characteristics = @[_characteristic];
                    
                    [_manager addService:_service];
                    break;
                default:
                    return;
                    break;
            }
            break;
        case BLEServicePeripheralStateWaitingForServiceToAdd:
            switch (newState) {
                case BLEServicePeripheralStateWaitingForAdvertisingToStart:
                    ;
                    [_manager startAdvertising:advertisingData];
                    break;
                default:
                    return;
                    break;
            }
            break;
        case BLEServicePeripheralStateWaitingForAdvertisingToStart:
            switch (newState) {
                case BLEServicePeripheralStateStarting:
                    ;
                    [_manager stopAdvertising];
                    break;
                case BLEServicePeripheralStateAdvertising:
                    ;
                    break;
                default:
                    return;
                    break;
            }
            break;
        case BLEServicePeripheralStateAdvertising:
            switch (newState) {
                case BLEServicePeripheralStateStarting:
                    ;
                    [_manager stopAdvertising];
                    break;
                default:
                    return;
                    break;
            }
            break;
        case BLEServicePeripheralStateError:
            break;
    }
    
    BLE_LOG(@"[%@] => [%@]", [self stringFromBLEServicePeripheralState:_state], [self stringFromBLEServicePeripheralState:newState]);
    _state = newState;
}

#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    BLE_LOG(@"%@", [self stringFromCBPeripheralManagerState:peripheral.state]);
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(peripheralServiceDidUpdateState:)]) {
        [self.delegate peripheralServiceDidUpdateState:self];
    }
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        [self transitionState:BLEServicePeripheralStateWaitingForServiceToAdd];
    } else {
        [self transitionState:BLEServicePeripheralStateStarting];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service error:(nullable NSError *)error
{
    BLE_LOG();
    if (error == nil) {
        [self transitionState:BLEServicePeripheralStateWaitingForAdvertisingToStart];
    } else {
        BLE_LOG(@"%@", error);
        [self transitionState:BLEServicePeripheralStateError];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
         willRestoreState:(NSDictionary<NSString *, id> *)dict
{
    BLE_LOG();
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(nullable NSError *)error
{
    BLE_LOG();
    if (error == nil) {
        [self transitionState:BLEServicePeripheralStateAdvertising];
    } else {
        BLE_LOG(@"%@", error);
        [self transitionState:BLEServicePeripheralStateError];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    BLE_LOG();
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(peripheralServiceDidSubscribeToCharacteristic:)]) {
        [self.delegate peripheralServiceDidSubscribeToCharacteristic:self];
    }
    _isSubscribed = YES;
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    BLE_LOG();
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(peripheralServiceDidUnsubscribeFromCharacteristic:)]) {
        [self.delegate peripheralServiceDidUnsubscribeFromCharacteristic:self];
    }
    _isSubscribed = NO;
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveReadRequest:(CBATTRequest *)request
{
    BLE_LOG();
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(peripheralServiceDidReceiveReadRequest:)]) {
        NSData *data = [self.delegate peripheralServiceDidReceiveReadRequest:self];
        request.value = data;
    }
    [_manager respondToRequest:request
                        withResult:CBATTErrorSuccess];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
  didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
//    BLE_LOG();
    for (CBATTRequest *r in requests) {
        if ([_characteristic isEqual:r.characteristic]) {
            NSData *data = [r.value reverse];
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(peripheralService:didReceiveWriteRequests:)]) {
                [self.delegate peripheralService:self didReceiveWriteRequests:data];
            }
            [_manager respondToRequest:r
                                withResult:CBATTErrorSuccess];
            return;
        }
        [_manager respondToRequest:r
                            withResult:CBATTErrorWriteNotPermitted];
    }
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    [self processTransmitQueue];
}

@end
