//
//  Demo_Volume_Parameter_Manager.swift
//
//  Copyright © 2021 Neon Silicon. All rights reserved.
//

/*
 Note that most of this structure looks heavy for this implementation.
 It makes dealing with parameters easier when the number of parameters gets large.
 It's also easier to add larger numbers of presets.
 */

import Foundation
import AudioToolbox

public class Demo_Volume_Parameter_Manager {
    
    // I would usually define these in a C enum instead.
    // But since we are completely in Swift, this will do for the example.
    static let volume_address: AUParameterAddress = 0
    
    // MARK: Parameters
    // Note: The parameters are initialized using a closure. The closure runs only once.
    var volume_parameter: AUParameter = {
        let parameter = AUParameterTree.createParameter(
            withIdentifier: "volume", name: "Volume",
            address: Demo_Volume_Parameter_Manager.volume_address,
            min: AUValue(0.0),
            max: AUValue(1.0),
            unit: .generic, unitName: nil,
            flags: [.flag_IsReadable,
                    .flag_IsWritable,
                    .flag_IsHighResolution],
            valueStrings: nil, dependentParameters: nil)
        
        parameter.value = 0.75
        return parameter
    }()
    
    let parameterTree: AUParameterTree
    
    init(swift_kernel: Swift_Kernel) {
        
        parameterTree = AUParameterTree.createTree(withChildren: [
            volume_parameter
        ])
        
        // Closure observing all externally-generated parameter value changes.
        parameterTree.implementorValueObserver = { param, value in
            swift_kernel.set_parameter(parameter: param, value: value)
        }

        // Closure returning state of requested parameter.
        parameterTree.implementorValueProvider = { param in
            return swift_kernel.value_for_parameter(parameter: param)
        }
        
        // Closure returning string representation of requested parameter value.
        parameterTree.implementorStringFromValueCallback = { param, value in
            
            switch param.address {
            
            case Demo_Volume_Parameter_Manager.volume_address:
                return String(format: "%.2f", value ?? param.value)
            
            default:
                return "?"
            }
        }
    }
    
    func setParameterValues(values : Demo_Volume_Parameter_Set) {
        volume_parameter.value = values.volume
    }
    
    // MARK: Factory Presets
    
    public var number_of_factory_presets : Int {
        return self.factory_presets.count
    }
    
    public let default_factory_preset = 0
    
    public let factory_presets : [AUAudioUnitPreset] = [
        AUAudioUnitPreset(number: 0, name: "Zero"),
        AUAudioUnitPreset(number: 1, name: "One")
    ]
    
    public let factory_presets_values : [Demo_Volume_Parameter_Set] = [
        Demo_Volume_Parameter_Set(name: "Zero", volume: 0.0),
        Demo_Volume_Parameter_Set(name: "One", volume: 1.0)
    ]
    
    // MARK: Current State for pushing and popping
    func state(name: String) -> Demo_Volume_Parameter_Set {
        
        let volume = volume_parameter.value
        
        return Demo_Volume_Parameter_Set(name: name, volume: volume)
    }
}

// Used for defining a preset
public struct Demo_Volume_Parameter_Set {
    
    var name : String = ""
    var volume: AUValue = 0.0
}

fileprivate extension AUAudioUnitPreset {
    
    convenience init(number: Int, name: String) {
        self.init()
        self.number = number
        self.name = name
    }
}
