//
//  Swift_Kernel.swift
//
//  Copyright © 2021 Neon Silicon. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation
import CoreAudioKit
import Accelerate

class Swift_Kernel {
        
    public var maximum_frames_to_render: AUAudioFrameCount
    public var output_bus: AUAudioUnitBus
    public var input_bus: AUAudioUnitBus {
        get {
            return _input_bus.bus
        }
    }
    
    private var _input_bus: Buffered_Audio_Bus
    
    public var volume_level: Float32 = 0.0
    
    init() {
        
        let default_input_format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)
        let default_output_format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)
     
        guard let input_format = default_input_format else {
            print("Error: Cannot create input format for audio busses.")
            fatalError()
        }
        guard let output_format = default_output_format else {
            print("Error: Cannot create output format for audio busses.")
            fatalError()
        }
        
        _input_bus = Buffered_Audio_Bus(default_format: input_format, max_channel_count: 2)
        
        do {
            output_bus = try AUAudioUnitBus(format: output_format)
        } catch {
            print("Error: Cannot create output audio bus.")
            fatalError()
        }
        
        self.maximum_frames_to_render = 512
    }
    
    public func set_parameter(parameter: AUParameter, value: AUValue) {
        
        if parameter.address == Demo_Volume_Parameter_Manager.volume_address {
            
            volume_level = Float32(value)
        }
    }
    
    public func value_for_parameter(parameter: AUParameter) -> AUValue {
        
        if parameter.address == Demo_Volume_Parameter_Manager.volume_address {
        
            return AUValue(volume_level)
            
        } else {
            
            return 1.0 // This would be an error and won't happen
        }
    }
    
    public func allocate_render_resources() {
        
        _input_bus.allocate_render_resources(maximum_frame_count: self.maximum_frames_to_render)
        
        // Initialize any AU DSP code here
    }
    
    public func deallocate_render_resources() {
        
        _input_bus.deallocate_render_resources()
        // clear and DSP memory/state
    }
    
    public func reset() {
        // Reset the DSP code state to clean initial state.
        volume_level = 0.0
    }
    
    /*
     The internal render block that the render thread calls to do the processing.
     
     There are some different examples included that show different ways you might
     use to hook to external DSP processing.
     
     Note that in a realistic plugin you would want to pass the parameters to your DSP
     code in the set_parameter method above to avoid the live acces from your DSP code
     back to the self that is captured in the closure.
     */
    public var internal_render_block: AUInternalRenderBlock {
                
        return {[unowned self] action_flags, time_stamp, frame_count, output_bus_number, output_data, real_time_event_list_head, pull_input_block in
            
            var pull_flags = AudioUnitRenderActionFlags(rawValue: 0) // I assume this is AudioUnitRenderActionFlags.unitRenderAction_PreRender
            
            let err = self._input_bus.pull_input(action_flags: &pull_flags,
                                                 timestamp: time_stamp,
                                                 frame_count: frame_count,
                                                 input_bus_number: output_bus_number,
                                                 pull_input_block: pull_input_block)
            
            guard err == 0 else {
                return err
            }
            
            // Get the input audio buffer list that has been set by the host.
            let in_abl = self._input_bus.mutable_audio_buffer_list
            
            let out_abl = output_data
            
            if let rtevh = real_time_event_list_head {
                // do stuff to process rtevh
            }
            
            // This example uses C to extract audio buffers and then passes them
            // to a couple of C functions to process.
            let count = AVAudioFrameCount(frame_count)
            
            let in_L = extract_buffer(in_abl, 0)
            let out_L = extract_buffer(out_abl, 0)
            input_to_output_with_volume(in_L, out_L, count, &volume_level)
            
            let in_R = extract_buffer(in_abl, 1)
            let out_R = extract_buffer(out_abl, 1)
            input_to_output_with_volume(in_R, out_R, count, &volume_level)
            
            /*
            // Example using Accelerate from Swift. Note the added steps to handle the UnsafePointers
            let count = vDSP_Length(frame_count)
            
            let in_L = extract_buffer(in_abl, 0)    // This is the C support function to bypass any Swift pointer potential issues.
            let out_L = extract_buffer(out_abl, 0)
            if let non_nil_in_L = in_L, let non_nil_out_L = out_L {
                vDSP_vsmul(non_nil_in_L, 1, &volume_level, non_nil_out_L, 1, count)
            }
            
            let in_R = extract_buffer(in_abl, 1)
            let out_R = extract_buffer(out_abl, 1)
            if let non_nil_in_R = in_R, let non_nil_out_R = out_R {
                vDSP_vsmul(non_nil_in_R, 1, &volume_level, non_nil_out_R, 1, count)
            }
            */
            
            // This would be an example going out to a C based DSP system.
            // Does a simple copy.
            // copy_stero_input_to_output(in_abl, out_abl, frame_count)
            
            return noErr
        }
    }
}
