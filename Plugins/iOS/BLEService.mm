//
//  BLEService.h
//  BLEController
//
//  Created by seiji on 1/13/16.
//
//

#import "BLEService.h"

#define SERVICE_UUID_DEFAULT @"789F0690-FB6E-4D46-8DD8-52B14B29A1A1"
#define CHARACTERISTIC_UUID  @"7F855F82-9378-4508-A3D2-CD989104AF22"

static char const *UNITY_GAMEOBJECT_NAME = "BluetoothCallback";

@interface BLEServiceUnityDelegator : NSObject <BLEServiceCentralDelegate,BLEServicePeripheralDelegate>
@end

extern "C" {
    NSObject<BLEServiceProtocol> *_bleService = nil;
    BLEServiceUnityDelegator *_delegator = nil;
    
    void _iOSBLECreateServicePeripheral()
    {
        _bleService = [BLEServicePeripheral new];
        _delegator = [BLEServiceUnityDelegator new];
        
        ((BLEServicePeripheral *)_bleService).delegate = _delegator;
    }
    
    void _iOSBLECreateServiceCentral()
    {
        _bleService = [BLEServiceCentral new];
        _delegator = [BLEServiceUnityDelegator new];
        
        ((BLEServiceCentral *)_bleService).delegate = _delegator;
    }
    
    void _iOSBLEServiceStart(char *uuidString)
    {
        if (_bleService != nil) {
            [_bleService start:[NSString stringWithFormat:@"%s", uuidString]];
        }
    }
    
    void _iOSBLEServicePause(BOOL isPause)
    {
        if (_bleService != nil) {
            isPause ? [_bleService pause] : [_bleService resume];
        }
    }
    
    void _iOSBLEServiceStop()
    {
        if (_bleService != nil) {
            [_bleService stop];
        }
    }
    
    void _iOSBLEServiceWrite(unsigned char *data, int length, BOOL withResponse)
    {
        if (_bleService != nil) {
            [_bleService write:[NSData dataWithBytes:data length:length]
                  withResponse:withResponse];
        }
    }
}
#pragma mark - BLEServiceUnityDelegator

@implementation BLEServiceUnityDelegator
#pragma mark - BLEServiceCentralDelegate

- (void)centralServiceDidUpdateState:(BLEServiceCentral *)service
{
    UnitySendMessage(UNITY_GAMEOBJECT_NAME, "OnDidUpdateState", "");
}

- (void)centralService:(BLEServiceCentral *)service
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *, id> *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
//    UnitySendMessage(UNITY_GAMEOBJECT_NAME, "OnDidUpdateState", peripheral.identifier);
}

- (void)centralServiceDidConnectPeripheral:(BLEServiceCentral *)service
{
    UnitySendMessage(UNITY_GAMEOBJECT_NAME, "OnDidConnect", "");
}

- (void)centralServiceDidDisconnectPeripheral:(BLEServiceCentral *)service
{
    UnitySendMessage(UNITY_GAMEOBJECT_NAME, "OnDidDisconnect", "");
}

- (void)centralService:(BLEServiceCentral *)service
 didReceiveNotifyValue:(NSData *)data
{
    NSString *base64String = [data base64EncodedStringWithOptions:0];
    const char *utf8String = [base64String cStringUsingEncoding:NSUTF8StringEncoding];
    
    UnitySendMessage(UNITY_GAMEOBJECT_NAME, "OnDidReceiveWriteRequests", utf8String);
}

#pragma mark - BLEServicePeripheralDelegate
- (void)peripheralServiceDidUpdateState:(BLEServicePeripheral *)service
{
    UnitySendMessage(UNITY_GAMEOBJECT_NAME, "OnDidUpdateState", "");
}

- (NSData *)peripheralServiceDidReceiveReadRequest:(BLEServicePeripheral *)service
{
    Byte value = arc4random()&0xff;
    NSData *data = [NSData dataWithBytes:&value length:1];
    return data;
}

- (void)peripheralService:(BLEServicePeripheral *)service
  didReceiveWriteRequests:(NSData *)data
{
    NSString *base64String = [data base64EncodedStringWithOptions:0];
    const char *utf8String = [base64String cStringUsingEncoding:NSUTF8StringEncoding];
    
    UnitySendMessage(UNITY_GAMEOBJECT_NAME, "OnDidReceiveWriteRequests", utf8String);
}

- (void)peripheralServiceDidSubscribeToCharacteristic:(BLEServicePeripheral *)service
{
    UnitySendMessage(UNITY_GAMEOBJECT_NAME, "OnDidConnect", "");
}

- (void)peripheralServiceDidUnsubscribeFromCharacteristic:(BLEServicePeripheral *)service
{
    UnitySendMessage(UNITY_GAMEOBJECT_NAME, "OnDidDisconnect", "");
}

@end

#pragma mark - BLEServiceCentral
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
//    if (uuidString != nil) {
//        _serviceUUID = [CBUUID UUIDWithString:uuidString];
//    }
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
    BLE_LOG(@"%@ : %@", peripheral, RSSI);
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(centralService:didDiscoverPeripheral:advertisementData:RSSI:)]) {
        [self.delegate centralService:self didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    }
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

#pragma mark - BLEServicePeripheral
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
//    [self write:[@"" dataUsingEncoding:NSUTF8StringEncoding] withResponse:NO];
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
                case BLEServicePeripheralStateWaitingForServiceToAdd: {
                    ;
                    CBCharacteristicProperties prop =
                    CBCharacteristicPropertyRead |
                    CBCharacteristicPropertyWrite |
                    CBCharacteristicPropertyWriteWithoutResponse |
                    CBCharacteristicPropertyNotify;
//                    CBCharacteristicPropertyNotifyEncryptionRequired;
                    
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
                }
                default: {
                    break;
                }
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
        default:
            return;
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

#pragma mark - NSData (Order)
@implementation NSData (Order)

- (NSData *)reverse
{
    const char *bytes = (const char *)[self bytes];
    char *reverseBytes = (char *)malloc(sizeof(char) * [self length]);
    int index = (int)[self length] - 1;
    for (int i = 0; i < [self length]; i++)
        reverseBytes[index--] = bytes[i];
    NSData *reversedData = [NSData dataWithBytes:reverseBytes length:[self length]];
    free(reverseBytes);
    
    return reversedData;
}

@end