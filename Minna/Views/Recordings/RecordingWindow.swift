//
//  RecordingWindow.swift
//  Minna
//
//  Created by Taylor Lineman on 8/26/26.
//  Edited by Claude Fable 5 (Anthropic) on 2026-09-08
//

import SwiftUI
import AudioEngine
import Logging
import FoundationModels
import InfiniteGrid
import SFSafeSymbols
import AVFoundation

extension View {
    func glow(color: Color = .red, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }
}

// TODO: Tell the user if their volume = 0 we can not record system audio
struct RecordingWindow: View {
    @State var transcriptionString: TranscriptionString = {
        var container = AttributeContainer()
        container[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] = .pink.opacity(0.8)
        return TranscriptionString(volatileAttributes: container)
    }()
    
    @State var noteTaker: NoteTaker = NoteTaker()
    @State var transcriptionSession: TranscriptionSession?
    @State var isTranscribing: Bool = false
    
    @State private var isCursorVisible = false

    @State var translation: CGPoint = .zero
    @State var scale: CGFloat = 1

    @State var graph = NoteGraphModel()
    @State var showsSimulationControls: Bool = false
    
    @State var selectedInputDevice: AVCaptureDevice?
    @State var showAudioPicker: Bool = false
    
    @State var recordSystemAudio: Bool = true

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                canvas
                HStack {
                    Spacer()
                    Text("X: \(translation.x), Y: \(translation.y)")
                        .padding(5)
                        .glassEffect()
                }
                .padding(.trailing, 10)
                controls
            }
            .animation(.default, value: showsSimulationControls)
            .onDisappear {
                Task {
                    do {
                        try await transcriptionSession?.stopMicrophoneTranscription()
                    } catch {
                        Log.logger.error("Failed to stop transcription", error: error)
                        isTranscribing = true
                    }
                    
                    do {
                        try await transcriptionSession?.stopSystemTranscription()
                    } catch {
                        Log.logger.error("Failed to stop transcription", error: error)
                        isTranscribing = true
                    }
                }
            }
            .navigationTitle("Note Taker")
            .toolbar {
                ToolbarItem {
                    Button {
                        showsSimulationControls.toggle()
                    } label: {
                        Label {
                            Text("Simulation settings")
                        } icon: {
                            Image(systemSymbol: .sliderHorizontal3)
                        }
                    }
                    .popover(isPresented: $showsSimulationControls) {
                        SimulationControlsView(model: graph)
                    }
                }
            }
        }
    }
    
    var canvas: some View {
        CanvasView(translation: $translation, scale: $scale) {
            NoteGraphView(model: graph, scale: $scale)
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            // Aim center gravity at the world point currently in the middle of the window, so notes gather on screen rather than at the grid origin.
            graph.simulation.center = (CGPoint(x: size.width / 2, y: size.height / 2) / scale) - translation
        }
        .onChange(of: noteTaker.sections) {
            graph.sync(sections: noteTaker.sections)
        }
    }
    
    var controls: some View {
        GlassEffectContainer {
            VStack(spacing: 5) {
                Button {
                    if isTranscribing {
                        isTranscribing = false
                        
                        Task {
                            do {
                                try await stopRecording()
                            } catch {
                                Log.logger.error("Failed to stop transcription", error: error)
                                isTranscribing = true
                            }
                        }
                    } else {
                        isTranscribing = true
                        
                        Task {
                            do {
                                try await startRecording()
                            } catch {
                                Log.logger.error("Failed to start transcription", error: error)
                                isTranscribing = false
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemSymbol: .microphone)
                            .accessibilityHidden(true)
                            .symbolEffect(.bounce, value: isTranscribing)
                        Text(isTranscribing ? "Now Recording" : "Transcribe Audio")
                    }
                }
                .buttonStyle(NoteTakerControlButtonStyle(isActive: $isTranscribing, activeColor: .red, activeTextColor: .white))
                
                HStack {
                    Button {
                        showAudioPicker.toggle()
                    } label: {
                        Label {
                            if let selectedInputDevice {
                                Text(selectedInputDevice.localizedName)
                            } else {
                                Text("Microphone Disabled")
                            }
                        } icon: {
                            if let selectedInputDevice {
                                Image(systemSymbol: selectedInputDevice.icon)
                            } else {
                                Image(systemSymbol: .microphoneSlash)
                            }
                        }
                        .minimumScaleFactor(0.2)
                        .frame(maxHeight: .infinity)
                    }
                    .buttonStyle(NoteTakerControlSimpleButtonStyle())
                    .onAppear {
                        do {
                            if selectedInputDevice == nil {
                                try selectedInputDevice = DeviceFinder.defaultMicrophone()
                            }
                        } catch {
                            Log.logger.error("Failed to selected default device", error: error)
                        }
                    }
                    .popover(isPresented: $showAudioPicker) {
                        AudioPicker(selectedInputDevice: $selectedInputDevice)
                    }
                    
                    Button {
                        recordSystemAudio.toggle()
                    } label: {
                        Label {
                            Text("System Audio")
                        } icon: {
                            
                        }
                        .minimumScaleFactor(0.2)
                        .frame(maxHeight: .infinity)
                    }
                    .buttonStyle(NoteTakerControlButtonStyle(isActive: $recordSystemAudio, activeColor: .green, activeTextColor: .white))
                }
                .frame(maxHeight: 50)
                
                if isTranscribing {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(noteTaker.waitingString.isEmpty ? "Waiting on transcription..." : "Transcription")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            Spacer()
                        }
                        
                        if !noteTaker.waitingString.isEmpty {
                            Text(noteTaker.waitingString)
                        }
                    }
                    .padding(5)
                    .frame(maxWidth: .infinity)
                    .glassEffect(
                        .regular.interactive(),
                        in: .rect(cornerRadius: 12)
                    )
                }
            }
            .frame(width: 250)
            .padding(10)
        }
        .animation(.default, value: isTranscribing)
        .onChange(of: recordSystemAudio) { oldValue, newValue in
            Task {
                do {
                    if newValue && !oldValue {
                        // We now need to record system audio
                        try await transcriptionSession?.attachSystemTranscriber()
                        Log.logger.info("Attached system transcriber.")
                        
                        if isTranscribing {
                            Log.logger.info("Started recording system audio.")
                            try await transcriptionSession?.startSystemTranscription()
                        }
                    } else if oldValue && !newValue {
                        // We need to disable system audio recording
                        try await transcriptionSession?.detachSystemTranscriber()
                        Log.logger.info("Detached system transcriber.")
                    }
                } catch {
                    Log.logger.error("Failed to update system transcriber from \(oldValue) to \(newValue)", error: error)
                }
            }
        }
        .onChange(of: selectedInputDevice) { _, newValue in
            Task {
                do {
                    if let device = newValue {
                        // Device exists so attach
                        if let deviceID = try device.audioObjectID {
                            try await transcriptionSession?.attachMicrophoneTranscriber(device: deviceID)
                            Log.logger.info("Attached microphone (\(device.localizedName)) to transcriber.")

                            if isTranscribing {
                                try await transcriptionSession?.startMicrophoneTranscription()
                                Log.logger.info("Started recording microphone.")
                            }
                        }
                    } else {
                        try await transcriptionSession?.detachMicrophoneTranscriber()
                    }
                } catch {
                    Log.logger.error("Failed to update microphone transcription", error: error)
                }
            }
        }
    }
    
    func stopRecording() async throws {
        if selectedInputDevice != nil {
            try await transcriptionSession?.stopMicrophoneTranscription()
            Log.logger.info("Stopped recording microphone.")
        }
        
        if recordSystemAudio {
            try await transcriptionSession?.stopSystemTranscription()
            Log.logger.info("Stopped recording system audio.")
        }
    }
    
    func startRecording() async throws {
        noteTaker.startNoteTaking()
        
        transcriptionSession = try await TranscriptionSession(outputs: [
            transcriptionString, // For UI Updates
            noteTaker // For note taking
        ])
        
        if let selectedInputDevice = selectedInputDevice, let deviceID = try? selectedInputDevice.audioObjectID {
            Log.logger.info("Attaching microphone \(selectedInputDevice.localizedName) to transcriber")
            try await transcriptionSession?.attachMicrophoneTranscriber(device: deviceID)
            try await transcriptionSession?.startMicrophoneTranscription()
        }
        
        if recordSystemAudio {
            Log.logger.info("Attaching microphone system audio to transcriber")
            try await transcriptionSession?.attachSystemTranscriber()
            try await transcriptionSession?.startSystemTranscription()
        }
    }
}

#Preview {
    NavigationStack {
        RecordingWindow()
    }
}
