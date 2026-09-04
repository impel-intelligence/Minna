//
//  NoteGravityManager.swift
//  Minna
//
//  Created by Taylor Lineman on 9/4/26.
//

import SwiftUI

@Observable
class GraphLayout {
    class Node: Identifiable {
        var id: UUID { uuid }
        let uuid: UUID
        
        var position: CGPoint
        var velocity: CGVector
        
        init(uuid: UUID, position: CGPoint, velocity: CGVector) {
            self.uuid = uuid
            self.position = position
            self.velocity = velocity
        }
    }
    
    class Edge {
        let id: UUID = UUID()
        let from: UUID
        let to: UUID
        
        init(from: UUID, to: UUID) {
            self.from = from
            self.to = to
        }
    }
    
    var nodes: [Node] = []
    var edges: [Edge] = []
    
    init() {
        
    }
    
    func insertNode(node: Node, connectedTo: [UUID]) {
        nodes.append(node)
        
        for neighbor in connectedTo {
            edges.append(Edge(from: node.uuid, to: neighbor))
        }
    }
}


struct SampleRepulsionView: View {
    @State var layout: GraphLayout = GraphLayout()
    
    @State var translation: CGPoint = CGPoint()
    @State var scale: CGFloat = 1
    
    var body: some View {
        CanvasView(translation: $translation, scale: $scale) {
            ForEach(layout.nodes) { node in
                ZStack {
                    Circle()
                        .foregroundStyle(.orange)
                    Text(node.uuid.uuidString)
                }
                .frame(width: 45, height: 45)
                .position(node.position)
            }
        }
        .onAppear {
            let node1 = GraphLayout.Node(uuid: UUID(), position: .zero, velocity: .zero)
            let node2 = GraphLayout.Node(uuid: UUID(), position: .zero, velocity: .zero)
            let node3 = GraphLayout.Node(uuid: UUID(), position: .zero, velocity: .zero)
            let node4 = GraphLayout.Node(uuid: UUID(), position: .zero, velocity: .zero)
            layout.insertNode(node: node1, connectedTo: [node2.uuid, node3.uuid])
            layout.insertNode(node: node2, connectedTo: [node1.uuid, node4.uuid])
            layout.insertNode(node: node3, connectedTo: [node1.uuid])
            layout.insertNode(node: node4, connectedTo: [node2.uuid])
        }
    }
}

#Preview {
    SampleRepulsionView()
}
