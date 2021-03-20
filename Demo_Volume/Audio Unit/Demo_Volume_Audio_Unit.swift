//
//  Demo_Volume_Audio_Unit.swift
//
//  Copyright © 2021 Neon Silicon. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation
import CoreAudioKit

public class Demo_Volume_Audio_Unit: AUAudioUnit {
       
    private var swift_kernel: Swift_Kernel
    
    public let parameters: Demo_Volume_Parameter_Manager
    
    
    lazy private var inputBusArray: AUAudioUnitBusArray = {
        AUAudioUnitBusArray(audioUnit: self,
                            busType: .input,
                            busses: [swift_kernel.input_bus])
    }()

    lazy private var outputBusArray: AUAudioUnitBusArray = {
        AUAudioUnitBusArray(audioUnit: self,
                            busType: .output,
                            busses: [swift_kernel.output_bus])
    }()
    
    public override var inputBusses: AUAudioUnitBusArray {
        return inputBusArray
    }

    public override var outputBusses: AUAudioUnitBusArray {
        return outputBusArray
    }

    weak var demo_volume_AU_VC: Demo_Volume_AU_VC?
    
    // Stereo only in this demo
    public override var channelCapabilities: [NSNumber]? {
        return [2, 2]
    }
    
    public override var latency: TimeInterval {
        return 0.0
    }
    
    public override var tailTime: TimeInterval {
        return 0.0
    }
    
    public override var parameterTree: AUParameterTree? {
        get { return parameters.parameterTree }
        set { /* The ParameterTree won't be modified after creation. */ }
    }
    
    // Channel counts are passed to the view controller via KVO notifications
    public var numberOfInputChannels: UInt32
    public var numberOfOutputChannels: UInt32
    
    // MARK: KVC methods
    public override class func setNilValueForKey(_ key: String) {
        
        if ( key == "numberOfInputChannels" ) {
            self.setValue(0, forKey: key)
        } else if ( key == "numberOfOutputChannels" ) {
            self.setValue(0, forKey: key)
        } else {
            super.setNilValueForKey(key)
        }
    }
    
    // MARK: Factory Presets
    public override var factoryPresets: [AUAudioUnitPreset] {
        return parameters.factory_presets
    }
    
    private var _currentPreset: AUAudioUnitPreset?
    
    public override var currentPreset: AUAudioUnitPreset? {
        
        get { return _currentPreset }
        
        set {
            guard let preset = newValue else {
                _currentPreset = nil
                print("Error: setCurrentPreset not set! - invalid AUAudioUnitPreset")
                return
            }

            if preset.number >= 0 { // Factory preset
                
                let parameter_values = parameters.factory_presets_values[preset.number]
                parameters.setParameterValues(values: parameter_values)
                _currentPreset = preset
            
            } else { // User preset
                // We don't really do anything here since the demo has no preset storage
                _currentPreset = currentPreset
            }
        }
    }
    
    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {

        swift_kernel = Swift_Kernel()
        
        parameters = Demo_Volume_Parameter_Manager(swift_kernel: swift_kernel)
        
        self.numberOfInputChannels = 0
        self.numberOfOutputChannels = 0

        // Init super class
        try super.init(componentDescription: componentDescription, options: options)

        self.currentPreset = self.factoryPresets[self.parameters.default_factory_preset];
    }
    
    public override var maximumFramesToRender: AUAudioFrameCount {
        
        get {
            return swift_kernel.maximum_frames_to_render
        }
        
        set {
            if !renderResourcesAllocated {
                swift_kernel.maximum_frames_to_render = newValue
            }
        }
    }
    
    public override func allocateRenderResources() throws {

        if !(self.swift_kernel.input_bus.format.channelCount == 2 && self.swift_kernel.output_bus.format.channelCount == 2) {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioUnitErr_FailedInitialization), userInfo: nil)
        }
        
        try super.allocateRenderResources()
        
        swift_kernel.allocate_render_resources()
        
        // Inform the UI of the change in the channel counts by KVC.
        self.setValue(0, forKey: "numberOfInputChannels")
        self.setValue(0, forKey: "numberOfOutputChannels")
    }

    public override func deallocateRenderResources() {
        
        self.setValue(self.swift_kernel.input_bus.format.channelCount, forKey: "numberOfInputChannels")
        self.setValue(self.swift_kernel.output_bus.format.channelCount, forKey: "numberOfOutputChannels")
        
        super.deallocateRenderResources()
        
        swift_kernel.deallocate_render_resources()
    }
    
    public override var internalRenderBlock: AUInternalRenderBlock {
        return swift_kernel.internal_render_block
    }

    // Cannot process in place because this makes no sense for mono->stereo
    public override var canProcessInPlace: Bool {
        return false
    }
    
    // MARK: View Configurations
    public override func supportedViewConfigurations(_ availableViewConfigurations: [AUAudioUnitViewConfiguration]) -> IndexSet {
        
        var indexSet = IndexSet()

        for (index, config) in availableViewConfigurations.enumerated() {
            
            if ((config.width >= 200 && config.height >= 200) ||
                (config.width >= 667 && config.height >= 315) ||
                (config.width == 0 && config.height == 0)) {
                
                indexSet.insert(index)
            }
        }
        return indexSet
    }

}

