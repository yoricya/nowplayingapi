//
//  discord.swift
//  macos_npa_discord_integration
//
//  Created by Ярослав on 31.01.2025.
//

import Foundation

public class RPC_connector {
    public let rpc: SwordRPC
    let api: TrackModel
    
    var dispatchTimer: DispatchSourceTimer?
    var old_track_hash: String?
    public var is_gateway_connected = false
    
    public var is_reconnecting_now = false
    public var reconnect_attempts = 0
    
    init(appId: String, api: TrackModel) {
        self.rpc = SwordRPC(appId: appId, handlerInterval: 500)
        self.api = api
        
        rpc.onConnect { rpc in
            self.is_gateway_connected = true
            self.reconnect_attempts = 0
            
            print("[Discord-Connector] RPC Connected")
            self.startUpdating()
        }
        
        rpc.onDisconnect { rpc, code, msg in
            self.is_gateway_connected = false
            
            self.stopUpdating()
            print("[Discord-Connector] RPC disconnected: \(String(describing: msg)) (\(String(describing: code)))")
        }
        
        rpc.onError { rpc, code, msg in
            self.is_gateway_connected = false
            
            self.stopUpdating()
            print("[Discord-Connector] RPC error: \(String(describing: msg)) (\(String(describing: code)))")
        }
    }
    
    func reconnect() {
        is_reconnecting_now = true
        rpc.disconnect()
        if !rpc.connect() && reconnect_attempts <= 4 {
            reconnect_attempts += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.reconnect()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.is_reconnecting_now = false
        }
    }
    
    func startUpdating() {
        print("[Discord-Connector] start updating...")
        
        dispatchTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        dispatchTimer?.schedule(deadline: .now(), repeating: 1.0)
        
        dispatchTimer?.setEventHandler {
            if !self.api.is_playing_now && self.old_track_hash != nil {
                self.old_track_hash = nil
                self.rpc.reset_presence()
                print("[Discord-Connector] Reset track")
            }
            
            if !self.api.is_playing_now || !self.is_gateway_connected {
                return
            }
            
            if self.old_track_hash != nil && self.api.to_hash() == self.old_track_hash! {
                return
            }
            
            self.old_track_hash = self.api.to_hash()
            
            print("[Discord-Connector] Update track")
            
            var presence = RichPresence()
            presence.type = 2
            presence.state = self.api.artist
            presence.details = self.api.trackName
            presence.timestamps = RichPresence.Timestamps(end: Date(timeIntervalSince1970: TimeInterval(self.api.end_timestamp / 1000)), start: Date(timeIntervalSince1970: TimeInterval(self.api.start_timestamp / 1000)) as Date)
            
            // Set image
            if self.api.album_image_link != nil {
                presence.assets = RichPresence.Assets(largeImage: self.api.album_image_link)
            }
            
            //            // Set button (Not working)
            //            if api.track_link != nil {
            //                presence.buttons = [RichPresence.Button(label: "Open in web", url: api.track_link!), RichPresence.Button(label: "Google", url: "https://google.com")]
            //            }
            
            self.rpc.set_presence(pr: presence)
        }
        
        dispatchTimer?.resume()
    }
    
    func stopUpdating() {
        dispatchTimer?.cancel()
        dispatchTimer = nil
    }
}
