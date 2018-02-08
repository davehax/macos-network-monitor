//
//  AppDelegate.swift
//  Network Monitor Status Bar
//
//  Created by David Falconer on 3/2/18.
//  Copyright © 2018 David Falconer. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    let popover = NSPopover()
    let networkMonitor = NetworkMonitor()
    var networkMonitorView:NetworkMonitorView?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // S U P E R important!!! You must provide an initial frame to your custom view class for it to draw in!
        let frame:NSRect = NSRect(x: 0, y: 0, width: 60, height: 22)
        networkMonitorView = NetworkMonitorView(frame: frame)
        
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("empty"))
            button.addSubview(networkMonitorView!)
            
        }
        
        constructMenu()
        
        var interfaceName:String = "";
        do {
            interfaceName = try NetworkMonitor.getDefaultInterfaceName()
        }
        catch NetworkMonitorError.noWifiInterface {
            print("No WiFi interface could be found.")
            exit(-1)
        }
        catch {
            print("Other error")
            exit(-2)
        }
        
        networkMonitor.startMonitoring(interfaceName: interfaceName) {
            (bytesIn, bytesOut) -> Void in
                self.networkMonitorView!.bytesIn = bytesIn
                self.networkMonitorView!.bytesOut = bytesOut
            
                // Drawing must take place in the main thread.
                // Therefore we must dispatch commands to the main thread!
                DispatchQueue.main.async { [unowned self] in // unowned self to prevent ARC from holding on to memory
                    self.networkMonitorView!.setNeedsDisplay(NSMakeRect(0, 0, 60, 22))
                }
            
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        networkMonitor.stopMonitoring()
    }
    
    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
}

