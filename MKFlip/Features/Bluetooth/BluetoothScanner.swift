import Foundation
import Observation
import CoreBluetooth

/// Dispositivo BLE descoberto durante a varredura.
struct BLEDevice: Identifiable, Sendable {
    let id: UUID                 // identifier do CBPeripheral
    var name: String
    var rssi: Int
    var serviceUUIDs: [String]
    var manufacturer: String?
    var lastSeen: Date

    var signalBars: Int {        // 0–4 a partir do RSSI
        switch rssi {
        case ..<(-90): 0
        case ..<(-75): 1
        case ..<(-60): 2
        case ..<(-45): 3
        default: 4
        }
    }
}

/// Scanner BLE sobre `CBCentralManager`. Apenas observa anúncios públicos de
/// dispositivos próximos — não conecta, não pareia, não explora.
@MainActor
@Observable
final class BluetoothScanner: NSObject {
    var devices: [BLEDevice] = []
    var isScanning = false
    var stateMessage = "Inicializando Bluetooth…"
    var poweredOn = false

    private var central: CBCentralManager?

    func configure() {
        guard central == nil else { return }
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func toggleScan() {
        guard let central, poweredOn else { return }
        if isScanning {
            central.stopScan()
            isScanning = false
            stateMessage = "Varredura parada. \(devices.count) dispositivo(s)."
        } else {
            devices.removeAll()
            central.scanForPeripherals(withServices: nil,
                                       options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            isScanning = true
            stateMessage = "Varredura em andamento…"
        }
    }
}

extension BluetoothScanner: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:   poweredOn = true;  stateMessage = "Bluetooth pronto."
            case .poweredOff:  poweredOn = false; stateMessage = "Bluetooth desligado."
            case .unauthorized: poweredOn = false; stateMessage = "Permissão de Bluetooth negada."
            case .unsupported: poweredOn = false; stateMessage = "BLE não suportado neste ambiente."
            default:           poweredOn = false; stateMessage = "Bluetooth indisponível."
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any],
                                    rssi RSSI: NSNumber) {
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? peripheral.name ?? "Desconhecido"
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?
            .map { $0.uuidString } ?? []
        let manufacturer = (advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data)?
            .prefix(8).map { String(format: "%02X", $0) }.joined(separator: " ")
        let id = peripheral.identifier
        let rssi = RSSI.intValue

        Task { @MainActor in
            if let index = devices.firstIndex(where: { $0.id == id }) {
                devices[index].rssi = rssi
                devices[index].lastSeen = Date()
                if !services.isEmpty { devices[index].serviceUUIDs = services }
            } else {
                devices.append(BLEDevice(id: id, name: name, rssi: rssi,
                                         serviceUUIDs: services, manufacturer: manufacturer,
                                         lastSeen: Date()))
            }
            devices.sort { $0.rssi > $1.rssi }
        }
    }
}
