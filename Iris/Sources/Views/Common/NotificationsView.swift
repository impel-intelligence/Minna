//
//  NotificationsView.swift
//  Iris
//
//  Created by Taylor Lineman on 6/17/26.
//

import SwiftUI

struct NotificationsViewButton: View {
    @Environment(\.alertCenter) private var alertCenter
    @State var centerIsVisible: Bool = false
    
    var body: some View {
        Button {
            centerIsVisible.toggle()
        } label: {
            Label {
                Text("Notifications")
            } icon: {
                Image(systemSymbol: alertCenter.notifications.isEmpty ? .bell : .bellBadge)
            }
        }
        .contentTransition(
            .symbolEffect(.replace)
        )
        //        .symbolRenderingMode(alertCenter.notifications.isEmpty ? .monochrome : .multicolor)
        .disabled(alertCenter.notifications.isEmpty)
        .popover(isPresented: $centerIsVisible, arrowEdge: .bottom) {
            NotificationsView(displayed: $centerIsVisible)
        }
    }
}

struct NotificationsView: View {
    @Environment(\.alertCenter) private var alertCenter
    @Binding var displayed: Bool

    private let maxHeight: CGFloat = 300
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        Group {
            ScrollView(.vertical) {
                content
            }
        }
        .frame(width: 300)
        .frame(maxHeight: 300)
    }

    var content: some View {
        VStack {
            ForEach(alertCenter.notifications) { notification in
                notificationRow(notification)
            }
        }
        .padding()
    }
        
    @ViewBuilder
    func notificationRow(_ notification: UserNotification) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(notification.title)
                    .bold()
                Spacer()
                Button {
                    withAnimation(.snappy) {
                        alertCenter.dismiss(notification.id)
                        
                        if alertCenter.notifications.isEmpty {
                            displayed = false
                        }
                    }
                } label: {
                    Label {
                        Text("Dismiss")
                    } icon: {
                        Image(systemSymbol: .xmark)
                    }
                }
                .controlSize(.small)
                .buttonStyle(.borderless)
                .labelStyle(.iconOnly)

            }
            HStack {
                Text(notification.message)
                if !notification.actions.isEmpty {
                    Spacer()
                    Menu {
                        ForEach(notification.actions) { action in
                            Button(action.title) {
                                action.action()
                            }
                        }
                    } label: {
                        Text("Action")
                    }
                    .controlSize(.small)
                }
            }
        }
    }
}

#Preview {
    VStack {
//        NotificationsView(displayed: .constant(true))
        NotificationsViewButton()
            .environment(AlertCenter.shared)
            .onAppear {
                for i in 0..<10 {
                    let notification = UserNotification(title: "Duplicate File \(i)", message: "What do you want to do with this file?", actions: [
                        UserNotification.ActionOption(title: "Move", action: {
                            print("Move")
                        }),
                        UserNotification.ActionOption(title: "Ignore", action: {
                            print("Ignore")
                        })
                    ])
                    
                    AlertCenter.shared.post(notification)
                }
            }
    }
}
