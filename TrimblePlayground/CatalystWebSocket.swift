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
    
    @State private var currentWarning: WarningItem?
    
    private func setWarning(warning: WarningItem) {
        DispatchQueue.main.async {
            currentWarning = warning
        }
    }
    
    struct WarningItem: Identifiable {
        public let id = UUID()
        public let code: Int
        public let domain: String
    }
    
    enum Domains: String {
        case NSURLErrorDomain = "Cannot connect to WebSocket, make sure you are connected to"
        case TMMNotAccepting = "Make sure you have Trimble Mobile Manager installed"
        case TMMParseFailure = "Failed to receive WebSocket port from TMM"
        case MessageParsingFailure = "Failed parsing a TMM location message"
    }

    private func receive() {
        if (task == nil) {
            print("Task was somehow null...")
        }
        task?.receive { result in switch result {
            //Possible failures
            /*
             Cannot connect to server (i.e. server not connected, which means the Trimble Catalyst DA2 probably isn't connected through TMM)
             Failure: Error Domain=NSURLErrorDomain Code=-1004 "Could not connect to the server." UserInfo={NSErrorFailingURLStringKey=ws://127.0.0.1:9635/, NSLocalizedDescription=Could not connect to the server., NSErrorFailingURLKey=ws://127.0.0.1:9635/}
             */
            /*
             Issue when navigating back
             
             This appears to be an iOS security feature, where background internet tasks are generally not allowed
                but in particular are not allowed for WebSockets (URLSession can be run in background, but it doesn't support WS)
             
             Failure: Error Domain=NSPOSIXErrorDomain Code=57 "Socket is not connected" UserInfo={NSErrorFailingURLStringKey=ws://127.0.0.1:9635/, NSErrorFailingURLKey=ws://127.0.0.1:9635/}
             */
            case .failure (let error):
                print("Failure: \(error)")
                switch (error as NSError).domain {
                    case "NSURLErrorDomain":
                        self.setWarning(warning: WarningItem(code: 0, domain: Domains.NSURLErrorDomain.rawValue))
                        break
                    case "NSPOSIXErrorDomain":
                        break
                    default:
                        break
                }
                switch (error as NSError).code {
                case -1004:
                    //Probably couldn't connect...
                    print("Failed to connect")
                    break
                case 57:
                    //Probably when navigating back to app
                    //Try to reconnect to ws
                    // maybe restart whole process & request port again
                    break
                default:
                    print("What")
                    break
                }
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
                            self.setWarning(warning: WarningItem(code: 0, domain: Domains.TMMParseFailure.rawValue))
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
                        if (!success) {
                            self.setWarning(warning: WarningItem(code: 0, domain: Domains.TMMNotAccepting.rawValue))
                        }
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
                self.setWarning(warning: WarningItem(code: 0, domain: Domains.TMMParseFailure.rawValue))
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
        .alert(item: $currentWarning) { show in
            Alert(title: Text(String(show.code)), message: Text(show.domain), dismissButton: .cancel())
        }
    }
}
