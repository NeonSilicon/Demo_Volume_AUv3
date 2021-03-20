//
//  Buffered_Audio_Bus.swift
//  Demo_Volume
//
//  Copyright © 2021 Neon Silicon. All rights reserved.
//

/*
 This is basically a port of the BufferedAudioBus.hpp code to use in a Swift setting.
 This only implements the input BufferedAudioBus.
 */

import Foundation
import AudioToolbox
import AVFoundation

struct Buffered_Audio_Bus {
    
    public var bus: AUAudioUnitBus
    
    public var maximum_frame_count: AUAudioFrameCount
    
    public var pcm_buffer: AVAudioPCMBuffer?
    
    public var original_audio_buffer_list: UnsafePointer<AudioBufferList>?
    
    public var mutable_audio_buffer_list: UnsafeMutablePointer<AudioBufferList>?
    
    init(default_format: AVAudioFormat, max_channel_count: AVAudioChannelCount) {
        
        self.maximum_frame_count = 0
        
        do {
            self.bus = try AUAudioUnitBus(format: default_format)
        } catch {
            print("Error: creating audio buffers failed.")
            fatalError()
        }
                
        self.bus.maximumChannelCount = max_channel_count
    }
    
    public mutating func allocate_render_resources(maximum_frame_count: AUAudioFrameCount) {
        
        self.maximum_frame_count = maximum_frame_count
        
        self.pcm_buffer = AVAudioPCMBuffer(pcmFormat: self.bus.format, frameCapacity: maximum_frame_count)

        self.original_audio_buffer_list = self.pcm_buffer?.audioBufferList
        self.mutable_audio_buffer_list = self.pcm_buffer?.mutableAudioBufferList
    }
    
    public mutating func deallocate_render_resources() {
        
        self.original_audio_buffer_list = nil
        self.mutable_audio_buffer_list = nil
        self.pcm_buffer = nil
    }
    
    public func pull_input(action_flags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                           timestamp: UnsafePointer<AudioTimeStamp>,
                           frame_count: AVAudioFrameCount,
                           input_bus_number: Int, pull_input_block: AURenderPullInputBlock?) -> AUAudioUnitStatus {
        
        
        guard let pull_input_block = pull_input_block else {
            return kAudioUnitErr_NoConnection
        }
        
        guard let oabl = original_audio_buffer_list, let mabl = mutable_audio_buffer_list else {
            return kAudioUnitErr_Uninitialized
        }
        
        // This is a C function that is declared in the Buffered_Audio_Bus.h file.
        // Include this header file in your project's bridging header file.
        prepare_input_buffer_list(oabl, mabl, frame_count)
        
        return pull_input_block(action_flags, timestamp, frame_count, input_bus_number, mabl);
    }
}
