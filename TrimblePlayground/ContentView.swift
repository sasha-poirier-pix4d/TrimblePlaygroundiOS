//
//  ContentView.swift
//  TrimblePlayground
//
//  Created by Sasha Poirier on 01.02.2024.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State public var messages = [PseudoExtras]()
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 46.52955441265417, longitude: 6.60091479193325), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
    
    var body: some View {
        HStack {
            Text("Parent messages : \(messages.count)")
            Button("Add Malley") {
                messages.append(PseudoExtras.malley)
                print("messages \(messages.count)")
                
            }.buttonStyle(.bordered)
        }
        Map(
            coordinateRegion: $region,
            annotationItems: messages,
            annotationContent: {message in
                return MapMarker(coordinate: CLLocationCoordinate2D(latitude: message.latitude, longitude: message.longitude))
            }
        ).mapControlVisibility(.hidden)
        
        TabView{
            CatalystWebSocketView(messages: self.$messages)
                .tabItem{
                    Label("WebSockets",systemImage: "wifi.router")
                }
            CatalystFacadeView(messages: self.$messages)
                .tabItem{
                    Label("SDK Facade",systemImage: "shippingbox")
                }
            CatalystSDKView(messages: self.$messages)
                .tabItem{
                    Label("Full SDK",systemImage: "cube.transparent")
                }
        }
    }
}

#Preview {
    ContentView()
}
