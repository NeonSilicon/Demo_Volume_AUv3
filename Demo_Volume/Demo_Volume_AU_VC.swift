//
//  Demo_Volume_AU_VC.swift
//  Demo_Volume
//
//  Copyright © 2021 Neon Silicon. All rights reserved.
//

import CoreAudioKit

public class Demo_Volume_AU_VC: AUViewController, AUAudioUnitFactory {
    
    var audioUnit: AUAudioUnit? {
        didSet {
            /*
             We may be on a dispatch worker queue processing an XPC request at
             this time, and quite possibly the main queue is busy creating the
             view. To be thread-safe, dispatch onto the main queue.
             
             It's also possible that we are already on the main queue, so to
             protect against deadlock in that case, dispatch asynchronously.
             */
            if self.isViewLoaded {
                if Thread.isMainThread {
                    self.connectViewWithAU()
                } else {
                    DispatchQueue.main.async {
                        self.connectViewWithAU()
                    }
                }
            }
        }
    }
    
    // MARK: Parameters and controls
    @IBOutlet weak var volume_slider: UISlider!
    
    @IBAction func volume_slider_did_change_value(_ sender: UISlider) {
        
        let value = volume_slider.value
        
        volume_display.text = String(format: "%.2f", value)
        
        if volume_parameter?.value != AUValue(value) {
            volume_parameter?.value = AUValue(value)
        }
    }
    
    @IBOutlet weak var volume_display: UILabel!
    
    var volume_parameter: AUParameter? {
        return parameters?.volume_parameter
    }
    
    var parameterObserverToken: AUParameterObserverToken?
    
    // The KVO Observer is added in connectViewWithAU.
    // This oberver seems to be called off of the main UI thread.
    // The UI update doesn't occur with correct timing unless I set it up in a Dispatch.main.async block.
    // This method seems to be called twice. It looks like they set the allParameterValues to true and then to false in quick succession
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "allParameterValues" {
            
            self.loadUpdatedParameterValuesToUI()
            
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    public var demo_volume_audio_unit: Demo_Volume_Audio_Unit? {
        get {
            return audioUnit as? Demo_Volume_Audio_Unit
        }
    }
    
    public var parameters: Demo_Volume_Parameter_Manager? {
        get {
            return demo_volume_audio_unit?.parameters
        }
    }

    public override func viewDidLoad() {
        
        super.viewDidLoad()

        if audioUnit == nil {
            return
        }
        
        connectViewWithAU()
    }

    // Method is used to hook the AU and the view controller together when used in the App
    // The super of this needs to be called here so the presets info is added.
    internal func connectViewWithAU() {

        guard let paramTree = audioUnit?.parameterTree else { return }
        
        self.demo_volume_audio_unit?.demo_volume_AU_VC = self
        
        // Note that the token(...) method is on AUParameterNode. An AUParmeterTree is just a top level node.
        parameterObserverToken = paramTree.token( byAddingParameterObserver: { [weak self] address, value in
                        
            guard let strongSelf = self else { return }

            DispatchQueue.main.async {
                
                switch address {
                
                case strongSelf.volume_parameter?.address:
                    strongSelf.volume_slider.value = value
                    strongSelf.volume_display.text = String(format: "%.2f", value)
          
                default:
                    break
                }
            }
        } )
        
        // Parameter observers have been set and the au is loaded and connected to the view.
        // Now add the KVO on the allParameters var to get preset changes
        audioUnit?.addObserver(self, forKeyPath: "allParameterValues", options: NSKeyValueObservingOptions.new, context: nil)
        
        // Get the current parameters set in the UI.
        // This must be done here because the host may have loaded the state before the KVO is set.
        self.loadUpdatedParameterValuesToUI()
    }
    
    private func loadUpdatedParameterValuesToUI() {
        
        // Set the values of UI controls
        DispatchQueue.main.async {
            if let volume = self.volume_parameter?.value {
                self.volume_slider.value = volume
                self.volume_display.text = String(format: "%.2f", volume)
        }
        }
    }

    // MARK: AudioUnit Factory
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        
        audioUnit = try Demo_Volume_Audio_Unit(componentDescription: componentDescription, options: [])
                
        return audioUnit!
    }

 
}
