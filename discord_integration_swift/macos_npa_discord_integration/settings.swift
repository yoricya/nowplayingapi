//
//  settings.swift
//  macos_npa_discord_integration
//
//  Created by Ярослав on 01.02.2025.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @State var api_url: String
    @State var api_token: String
    @State var discord_appID: String
    
    var body: some View {
        VStack {
            TextField("Base API URL", text: $api_url)
            HStack {
                Text("Base API URL").font(.system(size: 11))
                Spacer()
            }

            TextField("Base API Token", text: $api_token)
            HStack {
                Text("Base API Token").font(.system(size: 11))
                Spacer()
            }
            
            TextField("Discord app ID", text: $discord_appID)
            HStack {
                Text("Discord app ID").font(.system(size: 11))
                Spacer()
            }

            Spacer()
            HStack {
                Button("Save settings"){
                    UserDefaults.standard.set(api_url, forKey: "base_api_url")
                    UserDefaults.standard.set(api_token, forKey: "base_api_token")
                    UserDefaults.standard.set(discord_appID, forKey: "discord_app_id")
                    exit(0)
                }
                Spacer()
                Text("All changes must be required restart!").foregroundColor(.red)
            }
        }
        .padding().frame(width: 500, height: 300)
    }
}


class PopupWindowController: NSWindowController {
    convenience init() {
        let baseUrl = UserDefaults.standard.string(forKey: "base_api_url") ?? "http://192.168.1.1:5581/"
        let api_token = UserDefaults.standard.string(forKey: "base_api_token") // 831c7b971560ab624f116753643c1bb44f49c033b1c67582d411bb2b4ac07d61e28d79e24da53dc98e0883df0a7df2db
        let discord_appID = UserDefaults.standard.string(forKey: "discord_app_id") ?? "1290636014657863771"
        
        let popupView = NSHostingController(rootView: SettingsView(api_url: baseUrl, api_token: api_token ?? "", discord_appID: discord_appID))
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.title = "NPA-DiscsordI Settings"
        window.contentViewController = popupView
        
        self.init(window: window)
    }
    
    override func showWindow(_ sender: Any?) {
         super.showWindow(sender)
        
         NSApp.activate(ignoringOtherApps: true)
         self.window?.makeKeyAndOrderFront(nil)
     }
}
