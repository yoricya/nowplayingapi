//
//  macos_npa_discord_integrationApp.swift
//  macos_npa_discord_integration
//
//  Created by Ярослав on 30.01.2025.
//

import SwiftUI  
import AppKit

@main
struct MenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var main_trackModel: TrackModel?
    var main_ds_rpc: RPC_connector?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let baseUrl = UserDefaults.standard.string(forKey: "base_api_url") ?? "https://nowplayingapi.yoricya.ru/" // Base API
        let api_token = UserDefaults.standard.string(forKey: "base_api_token") // 831c7b971560ab624f116753643c1bb44f49c033b1c67582d411bb2b4ac07d61e28d79e24da53dc98e0883df0a7df2db
        let discord_appID = UserDefaults.standard.string(forKey: "discord_app_id") ?? "1290636014657863771" // VKMusic
        
        if api_token == nil {
            PopupWindowController().showWindow(nil)
            return
        }
        
        // Init track model
        main_trackModel = TrackModel(base_url: baseUrl, base_token: api_token!)
        
        // Start fetching track data
        main_trackModel!.startUpdating()
        
        // Init Discord RPC
        main_ds_rpc = RPC_connector(appId: discord_appID, api: self.main_trackModel!)
        
        DispatchQueue.global().async {
            self.main_ds_rpc?.reconnect()
        }
        
        setupStatusBar()
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(named: "npa_ico")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        setupPopover()
    }
    
    func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 200, height: 150)
        popover.behavior = .transient
        
        if let m = main_trackModel {
            if let m1 = main_ds_rpc {
                popover.contentViewController = NSHostingController(rootView: PopoverView(trackModel: m, ds_rpc: m1))
                return
            }
        }
        
        exit(1)
    }
    
    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}

struct PopoverView: View {
    @ObservedObject var trackModel: TrackModel
    var ds_rpc: RPC_connector
    
    @State var isReconectRPCButtonDisabled = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
//            coverImage
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .frame(width: 60, height: 60)
//                .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(trackModel.trackName)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                
                Text(trackModel.artist)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                if !ds_rpc.is_gateway_connected {
                    Spacer()
                    Text({() -> String in                        
                        if ds_rpc.is_reconnecting_now {
                            return ds_rpc.reconnect_attempts > 3
                            ? "Reconnect RPC... (Try to restart Discord)"
                            : "Reconnect RPC..."
                        }
            
                        
                        return ds_rpc.reconnect_attempts > 3
                        ? "DiscordRPC Disconnected (Try to restart Discord)"
                        : "DiscordRPC Disconnected"
                    }())
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: trackModel.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    HStack {
                        Text(trackModel.currentTime)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Button("Reconnect RPC") {
                            if isReconectRPCButtonDisabled || ds_rpc.is_reconnecting_now {
                                return
                            }
                            
                            ds_rpc.reconnect_attempts += 1
                            
                            print("Reconnect RPC...")
                            
                            isReconectRPCButtonDisabled = true
                            
                            ds_rpc.reconnect()
                            trackModel.is_playing_now = false
                            
                            DispatchQueue.global().async {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                    isReconectRPCButtonDisabled = false
                                }
                            }
                        }.disabled(isReconectRPCButtonDisabled).opacity(isReconectRPCButtonDisabled ? 0.5 : 1)
                        
                        Button("Settings") {
                            PopupWindowController().showWindow(nil)
                        }
                        
                        Button("Exit") {
                            if ds_rpc.is_gateway_connected {
                                ds_rpc.rpc.reset_presence()
                            }
                            
                            exit(0)
                        }
                    
                        Spacer()
                        
                        Text(trackModel.remainingTime)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 400)
    }
}
