# Implementation of AUv3 in Swift

Demo Volume is an AUv3 Audio Unit that is written in almost exclusively Swift. The point of Demo Volume is to investigate the possibility of developing AU's where

1) You don't want to include Objective-C++ or C++
2) You want to write the DSP in C but don't want to include Objective-C
3) Would like to write the DSP code in a different language than either C or C++.

The source consists of a Dummy App container application and the AUv3 implemented as an app extension. The Dummy app does absolutely nothing. The AUv3 has a single parameter to control the output volume. It is a complete working AUv3 so the entire code path can be explored.

The targets are configured as Mac Catalyst implementations so that they should be easy to get running without having to code sign them or provide a development team. To run them on iOS, you will need to configure the development team and code signing.

## What Does What?

The *AUViewController* and factory are contained in Demo_Volume_AU_VC.swift. The Demo_Volume_Audio_Unit.swift file contains the *AUAudioUnit* implementation.

Demo_Volume_Parameter_Manager.swift handles all interactions with the *AUParameterTree*, *AUAudioUnitPreset* classes for managing parameters and factory presets. There is no implementation for working with user presets in the demo AU. 

Swift_Kernel.swift serves the same purpose that the Objective-C/C++ kernel adapter/shim does in a typical AUv3. In this case, it could all be placed within the main _AUAudioUnit_. I feel it is better to separate it out because it isolates the code that needs to interact with with the *AUInternalRenderBlock*. This helps to reduce the surface that is exposed to being captured in the closure. The internal render block, resource allocation, and parameter changes to the DSP code reside within this "kernel" class.

The final important piece is the *Buffered_Audio_Bus* struct contained in the Buffered_Audio_Bus.swift file. This struct is essentially a port of the input *BufferedInputBus* from the AudioUnit template file that you get when creating an AUv3 target in Xcode. This struct is pretty much the central piece for being able to do the implementation in Swift (with a little bit of supporting C).

The C_Support_for_Swift.h file contains some example code showing how you might bridge out to C and potentially other languages from the Swift code for doing the DSP. The file also contains a couple of functions to support AudioBuffers from the AudioBufferLists in a way that I feel has less risk of making unwanted memory copies/allocations. You need to add the file to the "(Target_Name)-Bridging-Header.h" imports.

## State of the Code

The idea and the code came about when I was too loopy from a fever due to Covid vaccination to do any real work. That's kind of a warning. The code has been tested for memory leaks and unwanted allocations and various other things using instruments. But, this should not be considered production ready code -- it isn't!

I think that it is potentially a good starting point for some exploration into simplifying writing AUv3's with Swift as the only glue to the DSP code written in some non-C++ language. 

There isn't much interesting in the DSP code of the demo AU either. It consists of only a couple examples of how you might think about bridging out of the Swift file. It simply uses some Accelerate based calls to apply the volume level parameter to the output. 

## License
If you use this code or documentation in an article, video, or other educational or demonstration setting, consider the project to be under a Creative Commons cc-by-4.0 license.

You are free to use the source code in a development project in any way you please, without attribution or any other restrictions. But, understand that this code comes with no promises or guarantees of being fit for any purpose other than exploration and discovery.
