//
//  NetworkMonitor.swift
//  Network Monitor Status Bar
//
//  Created by David Falconer on 7/2/18.
//  Copyright © 2018 David Falconer. All rights reserved.
//

import Foundation
import CoreWLAN

enum NetworkMonitorError: Error {
    case noInternet
    case noWifiInterface
    case noWiredInterface
}

class NetworkMonitor {
    let netstatWrapper:NetstatWrapper
    var firstLoop:Bool
    var indexBytesIn:Int
    var indexBytesOut:Int
    var headers:[Substring]
    
    init() {
        netstatWrapper = NetstatWrapper()
        firstLoop = true
        indexBytesIn = 0
        indexBytesOut = 0
        headers = []
    }
    
    /// Gets the default network interface name.
    /// This "should" be equivalent to the current Network connection in use for almost all traffic
    ///
    /// - Returns: The default network interface name e.g. "en0"
    /// - Throws: NetworkMonitorError
    class func getDefaultInterfaceName() throws -> String {
        let interfaceName:String = try getDefaultWifiInterfaceName()
        return interfaceName
    }
    
    
    
    /// Start monitoring the amount of bytes in and out on the default interface
    ///
    /// - Throws: Throws an instance of NetworkMonitorError
    func startMonitoring(onUpdate: @escaping (String, String) -> Void) throws -> Void {
        let interfaceName:String = try NetworkMonitor.getDefaultInterfaceName()
        startMonitoring(interfaceName: interfaceName, onUpdate: onUpdate)
    }
    
    /// Start monitoring the amount of bytes in and out on the specified interface
    ///
    /// - Parameter interfaceName: name of the interface to monitor
    func startMonitoring(interfaceName: String, onUpdate: @escaping (String, String) -> Void) -> Void {
        // Indicate that this is the first loop
        firstLoop = true
        
        // Declare the arguments to be passed to netstat
        let arguments:[String] = ["-s", "1", "--interfaces", interfaceName]
        
        // Using our wrapper class we will call netstat and, through the trailing closure, handle parsing data output by netstat
        netstatWrapper.start(arguments: arguments) {
            
            (fileHandle:FileHandle) -> Void in
                // Get the output from netstat if there is any
                if let str = String(data: fileHandle.availableData, encoding: String.Encoding.utf8) {
                    // netstat may have multiple "lines" of data for us to process.
                    // We're only interested in the last available line.
                    let lastLine = self.takeLastLine(netstatOutput: str)
                    
                    // Split the line of text into an array with each index representing a column
                    // of data you would see on the command line if you called netstat there
                    let parts = lastLine.split(separator: " ")
//                    print(parts)
                    
                    // First loop - this is the header line
                    if (self.firstLoop == true) {
                        self.firstLoop = false
                        self.parseHeadersAndSetIndices(parts: parts)
                    }
                    // netstat will periodically output the headers for the tabular data again.
                    // If this is the case we should ignore the output
                    else if (parts[0] != self.headers[0]) {
                        let bytesIn = parts[self.indexBytesIn]
                        let bytesOut = parts[self.indexBytesOut]
                        
//                        print("Bytes in: \(bytesIn)\t\tBytes out:\(bytesOut)")
                        
                        // Pass the data to the provided callback function
                        onUpdate(String(bytesIn), String(bytesOut))
                    }
                    
                }
                else {
                    print("No data")
                    self.stopMonitoring()
                }
            }
    }
    
    /// Stop monitoring
    func stopMonitoring() -> Void {
        netstatWrapper.stop()
    }
    
    
    /// Attempts to get the default WiFi interface name
    ///
    /// - Returns: String
    /// - Throws: NetworkMonitorError
    private static func getDefaultWifiInterfaceName() throws -> String {
        // Get the shared CWWiFiClient instance - less resource usage that creating your own
        let wifiClient:CWWiFiClient = CWWiFiClient.shared()
        
        // Get the default interface
        let wifiInterface:CWInterface? = wifiClient.interface()
        
        // Guard against the default interface being nil
        guard wifiInterface != nil else {
            throw NetworkMonitorError.noWifiInterface
        }
        
        // Return the interface name
        let interfaceName:String = (wifiInterface?.interfaceName)!
        return interfaceName;
    }
    
    /// Called once
    ///
    /// - Parameter parts: Substring array representing output from the netstat program
    private func parseHeadersAndSetIndices(parts:[Substring]) -> Void {
        var indexBytesInSet:Bool = false
        var indexBytesOutSet:Bool = false
        headers = parts
        
        for i in 0..<parts.count {
            print("\(i): \(parts[i])")
            if (parts[i] == "bytes") {
                if (!indexBytesInSet) {
                    indexBytesIn = i
                    indexBytesInSet = true
                }
                else if (!indexBytesOutSet) {
                    indexBytesOut = i
                    indexBytesOutSet = true
                }
            }
        }
    }
    
    /// netstat outputs data with each "line" delimited by a \n character
    ///
    /// - Parameter string: netstat output
    /// - Returns: The last line of the netstat output
    private func takeLastLine(netstatOutput:String) -> String {
        guard netstatOutput != "" else {
            return netstatOutput
        }
        
        let parts = netstatOutput.split(separator: "\n")
        return String(parts[parts.count-1])
    }
    
    /// Print default network information e.g. interface name, name of network (SSID), max. transmit rate, RSSI and BSSID
    class func printDefaulInterfaceInfo() -> Void {
        // Side note - Swift recommends the usage of constants if the code block doesn't mutate the value of the variable
        let wifiClient:CWWiFiClient = CWWiFiClient.shared()
        
        let wifiInterface:CWInterface? = wifiClient.interface()
        print("Using WiFi Interface \(wifiInterface!.interfaceName!)")
        
        let transmitRate:Double? = wifiInterface?.transmitRate()
        print("WiFi transmit rate \(transmitRate!) Mbps")
        
        let ssid:String? = wifiInterface?.ssid()
        print ("WiFi SSID is currently \(ssid!)")
        
        let bssid:String? = wifiInterface?.bssid()
        print("WiFi BSSID is currently \(bssid!)")
        
        let rssi:Int? = wifiInterface?.rssiValue()
        print("WiFi RSSI Value is currently \(rssi!)")
        
        //        let wifiConfig:CWConfiguration? = wifiInterface?.configuration()
    }
    
    
    
}
