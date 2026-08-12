//
//  SentryReporter.swift
//  Minna
//
//  Created by Taylor Lineman on 8/11/26.
//

import SwiftUI
import UniformTypeIdentifiers
import SentrySwift
import Logging

struct SentryReporter: View {
    enum ReporterError: LocalizedError {
        case nameNotPopulated
        case emailNotPopulated
        case descriptionNotPopulated
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .nameNotPopulated:
                return "Name not filled in."
            case .emailNotPopulated:
                return "Email not filled in."
            case .descriptionNotPopulated:
                return "No comments have been written."
            case .unknown:
                return "An unknown error has occurred, please try again."
            }
        }
    }
        
    @Environment(\.dismiss) var dismiss

    var eventId: SentryId
  
    @State var name: String = ""
    @State var email: String = ""
    @State var description: String = ""
    @State var error: ReporterError?
    @State var presentError: Bool = false
    
    @State var sending: Bool = false

    var body: some View {
        Group {
            if eventId == .empty {
                feedbackBody
            } else {
                crashBody
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    submitReport()
                } label: {
                    if sending {
                        ProgressView()
                    } else {
                        Text("Submit Report")
                    }
                }
                .buttonStyle(.glassProminent)
                .keyboardShortcut(KeyEquivalent.return, modifiers: .command)
            }
        }
    }
    
    var feedbackBody: some View {
        VStack {
            VStack(spacing: 10) {
                Text("We love your feedback!")
                    .font(.headline)
                Text("Any and all feedback goes right to the developers! Your feedback is what makes this app great.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)
            Form {
                TextField("Name", text: $name, prompt: Text("John Appleseed"))
                TextField("Email", text: $email, prompt: Text("jane@appleseed.com"))
                VStack(alignment: .leading) {
                    Text("Tell us what happened!")
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
            }
            .formStyle(.grouped)
        }
        .alert(isPresented: $presentError, error: error) {
            Button("Cancel", role: .cancel, action: { })

        }
        .navigationTitle("Submit your thoughts!")
    }
    
    var crashBody: some View {
        VStack {
            VStack(spacing: 10) {
                Text("It looks like we're having issues.")
                    .font(.headline)
                Text("Our team has been notified. If you'd like to help, tell us what happened below.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)
            Form {
                TextField("Name", text: $name, prompt: Text("John Appleseed"))
                TextField("Email", text: $email, prompt: Text("jane@appleseed.com"))
                VStack(alignment: .leading) {
                    Text("What were you doing before the crash?")
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
            }
            .formStyle(.grouped)
        }
        .alert(isPresented: $presentError, error: error) {
            Button("Cancel", role: .cancel, action: { })
        }
        .navigationTitle("Whoops! Something broke.")
    }
    
    private func submitReport() {
        do {
            sending = true
            guard !description.isEmpty else { throw ReporterError.descriptionNotPopulated }
            guard !name.isEmpty else { throw ReporterError.nameNotPopulated }
            guard !email.isEmpty else { throw ReporterError.emailNotPopulated }

            let feedback = SentryFeedback(
                message: description,
                name: name,
                email: email,
                source: .custom,
                associatedEventId: eventId != .empty ? eventId : nil,
                attachments: nil
            )

            SentrySDK.capture(feedback: feedback)
            SentrySDK.flush(timeout: 3)

            dismiss()
        } catch {
            sending = false
            Log.logger.error("Failed to submit sentry report", error: error)
            if let error = error as? ReporterError {
                self.error = error
            } else {
                self.error = .unknown
            }
            self.presentError = true
        }
    }
}

#Preview {
    SentryReporter(eventId: .empty)
}
