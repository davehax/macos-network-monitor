//
//  NettopWrapper.swift
//  Network Monitor Status Bar
//
//  Created by David Falconer on 7/2/18.
//  Copyright © 2018 David Falconer. All rights reserved.
//

import Foundation

class NetstatWrapper {
    var process:Process
    var pipe:Pipe
    
    init() {
        process = Process()
        pipe = Pipe()
    }
    
    func start(arguments: [String], onReadData: @escaping (FileHandle) -> Void) -> Void {
        process.launchPath = "/usr/bin/env"
        process.arguments = ["netstat"] + arguments
        process.standardOutput = pipe
        
        // Output handle
        let pipeReadHandle:FileHandle = pipe.fileHandleForReading
        
        // Launch the netstat process
        process.launch()
        
        // Attach an asynchronous handler to be called when there is available data to be read from the stream
        // the name ReadabilityHandler is understandable AFTER you understand the context in which it exists.
        // When trying to figure out how to get data asynchronously, this is stupid beyond all belief.
        // Who named this? Dishonour on their existence and their family.
        pipeReadHandle.readabilityHandler = onReadData
    }
    
    func stop() {
        // Remove the callback from the poorly named readabilityHandler
        pipe.fileHandleForReading.readabilityHandler = nil
        
        // Terminate the netstat process
        process.terminate()
    }
}
