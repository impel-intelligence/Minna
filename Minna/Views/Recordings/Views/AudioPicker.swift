//
//  AudioPicker.swift
//  Minna
//
//  Created by Taylor Lineman on 9/9/26.
//

import Logging
import SwiftUI
import AVFoundation
import AudioEngine
import SFSafeSymbols

struct AudioPicker: View {
    @Binding var selectedInputDevice: AVCaptureDevice?
    @State var devices: [AVCaptureDevice] = (try? DeviceFinder.microphones()) ?? []
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Input")
                .font(.headline)
            Button {
                selectedInputDevice = nil
            } label: {
                Label {
                    Text("Disable Microphone")
                } icon: {
                    Image(systemSymbol: .microphoneSlash)
                        .foregroundStyle(selectedInputDevice == nil ? Color.white : Color.primary)
                        .frame(width: 28, height: 28)
                        .background {
                            Circle()
                                .foregroundStyle(selectedInputDevice == nil ? Color.accentColor : Color.gray.opacity(0.5))
                        }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            ForEach(devices, id: \.uniqueID) { device in
                Button {
                    selectedInputDevice = device
                } label: {
                    Label {
                        Text(device.localizedName)
                    } icon: {
                        Image(systemSymbol: device.icon)
                            .foregroundStyle(selectedInputDevice == device ? Color.white : Color.primary)
                            .frame(width: 28, height: 28)
                            .background {
                                Circle()
                                    .foregroundStyle(selectedInputDevice == device ? Color.accentColor : Color.gray.opacity(0.5))
                            }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .id(devices.count)
        .padding(10)
        .onAppear {
            loadAudioDevices()
        }
        .task {
            for await _ in NotificationCenter.default .notifications(named: AVCaptureDevice.wasConnectedNotification) {
                loadAudioDevices()
            }
            
            for await _ in NotificationCenter.default.notifications(named: AVCaptureDevice.wasDisconnectedNotification) {
                loadAudioDevices()
            }
        }
    }
    
    func loadAudioDevices() {
        do {
            devices = try DeviceFinder.microphones()
            
            if selectedInputDevice == nil {
                selectedInputDevice = devices.first
            }
        } catch {
            Log.logger.error("Failed to load microphones", error: error)
        }
    }
}

#Preview {
    @Previewable @State var inputDevice: AVCaptureDevice?
    AudioPicker(selectedInputDevice: $inputDevice)
}
