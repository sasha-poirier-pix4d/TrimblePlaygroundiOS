//
//  WebSocketView.swift
//  TrimblePlayground
//
//  Created by Sasha Poirier on 01.02.2024.
//

import Foundation
import SwiftUI

struct CatalystWebSocketView: View {
    @Binding public var messages : [PseudoExtras]
    
    @ObservedObject var ws = CatalystWebsocket()
    
    @State var failures: Int = 0
    
    @State private var task: URLSessionWebSocketTask?

    private func receive() {
        if (task == nil) {
            print("Task was somehow null...")
        }
        task?.receive { result in switch result {
            case .failure (let error):
                print("Failure: \(error)")
                //Possible failures
                /*
                 If server not online
                 Failure: Error Domain=NSURLErrorDomain Code=-1004 "Could not connect to the server." UserInfo={NSErrorFailingURLStringKey=ws://127.0.0.1:9635/, NSLocalizedDescription=Could not connect to the server., NSErrorFailingURLKey=ws://127.0.0.1:9635/}
                 */
                
                /*
                 Seen when navigating back
                 Failure: Error Domain=NSPOSIXErrorDomain Code=57 "Socket is not connected" UserInfo={NSErrorFailingURLStringKey=ws://127.0.0.1:9635/, NSErrorFailingURLKey=ws://127.0.0.1:9635/}
                 */
                DispatchQueue.main.async {
                    self.failures += 1
                }
                
            case .success (let message):
                switch message {
                    case .string (let text):
                        do {
                            let parsed = try PseudoExtras.parse(string: text)
                            
                            
                            DispatchQueue.main.async {
                                if (parsed != nil) {
                                    self.messages.append(parsed!)
                                }
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.failures += 1
                            }
                            print("Failed parsing following string: \(text)")
                        }
                    case .data (let data):
                        print("Data: \(data)")
                        break
                    @unknown default:
                        print("What")
                        break
                }
                self.receive()
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Button("Try connect WebSocket") {
                    print("Requesting WS port from TMM...")
                    guard let request = TMMServerSocketPortRequest(returl: "socketport://spp4d.playground.ios").makeTMMRequestURL() else {
                        print("Failed to make request URL")
                        return
                    }
                    UIApplication.shared.open(request) { success in
                        print("UIApplication.shared.open received: \(success)")
                    }
                }.buttonStyle(.bordered)
                Text("WS Failures : \(ws.failures)")
                Text("Self Failures : \(self.failures)")
            }
            
            Button("Add Malley to WebSocket") {
                ws.addMaley()
            }.buttonStyle(.bordered)
            List(messages) { message in
                VStack {
                    Text(String(format: "%.5f", message.utcTime))
                    HStack {
                        Text(String(format: "Lat : %.5f", message.latitude))
                        Text(String(format: "Lon %.5f", message.longitude))
                    }
                }
            }
        }
        .onChange(of: ws.messages, { oldValue, newValue in
            print("WebSocket messages changed")
            messages += newValue
        })
        .padding()
        .onOpenURL { url in
            print("onOpenUrl : \(url)")
            
            guard let response = TMMServerSocketPortResponse.decode(response: url) else {
                print("Failed parsing TMM response")
                return
            }
            print("TMM sent port: \(response.port)")
            
            self.messages.removeAll()
            guard let url = URL(string:"ws://127.0.0.1:\(response.port)") else { return }
            let req = URLRequest(url: url)
            
            self.task = URLSession.shared.webSocketTask(with: req)
            self.task?.resume()
            print("Connected probably")
            receive()
        }
    }
}
