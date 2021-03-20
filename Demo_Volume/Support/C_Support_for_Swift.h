//
//  C_Support_for_Swift.h
//  Demo_Volume_AUv3
//
//  Copyright © 2021 Neon Silicon. All rights reserved.
//

#ifndef C_Support_for_Swift_h
#define C_Support_for_Swift_h

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

// Example of C entry function for doing DSP in C from Swift
void copy_stero_input_to_output(AudioBufferList *input, AudioBufferList *output, AVAudioFrameCount count) {
    
    float* in_L  = (float*)input->mBuffers[0].mData;
    float* in_R  = (float*)input->mBuffers[1].mData;
    float* out_L = (float*)output->mBuffers[0].mData;
    float* out_R = (float*)output->mBuffers[1].mData;

    cblas_scopy(count, in_L, 1, out_L, 1);
    cblas_scopy(count, in_R, 1, out_R, 1);
}

// Do some C processing and then return the result to Swift
void input_to_output_with_volume(float const* input, float *output, AVAudioFrameCount count, float const* volume) {
    vDSP_vsmul(input, 1, volume, output, 1, count);
}

// Returns an AudioBuffer without risk of copying the input AudioBufferList
float* extract_buffer(AudioBufferList const* input, UInt32 buffer_index) {
    
    return (float*)input->mBuffers[buffer_index].mData;
}


// Used in the Buffered_Audio_Bus class to avoid Swift UnsafePointer issues.
void prepare_input_buffer_list(AudioBufferList const* original_buffer_list,
                               AudioBufferList* mutable_buffer_list,
                               AVAudioFrameCount frame_count) {
    
    UInt32 size = frame_count * sizeof(float);
    
    mutable_buffer_list->mNumberBuffers = original_buffer_list->mNumberBuffers;
    
    for (UInt32 i = 0; i < original_buffer_list->mNumberBuffers; ++i) {
        
        mutable_buffer_list->mBuffers[i].mNumberChannels = original_buffer_list->mBuffers[i].mNumberChannels;
        
        mutable_buffer_list->mBuffers[i].mData = original_buffer_list->mBuffers[i].mData;
        
        mutable_buffer_list->mBuffers[i].mDataByteSize = size;
    }
}


#endif /* C_Support_for_Swift_h */
