//
//  api.swift
//  macos_npa_discord_integration
//
//  Created by Ярослав on 30.01.2025.
//

import Foundation

let current_track: Track? = nil

struct Track: Codable {
    let is_playing: Bool
    let name: String
    let author: String
    let service_name: String
    let start_timestamp: String
    let end_timestamp: String
    
    let album_image: String?
    let track_url: String?
}

func fetchCurrentTrack(baseUrl: String, api_token: String) async throws -> Track {
    guard let url = URL(string: baseUrl + "get/" + api_token) else {
        throw URLError(.badURL)
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    
    return try JSONDecoder().decode(Track.self, from: data)
}

func formatTime(seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let secs = seconds % 60
    if hours > 0 {
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    } else {
        return String(format: "%02d:%02d", minutes, secs)
    }
}

func calculatePercentage(curTime: Double, allTime: Double) -> Double {
    guard allTime > 0 else {
        return 0.0 // Возвращаем 0, если все время равно нулю, чтобы избежать деления на ноль
    }
    
    let percentage = (curTime / allTime) * 100.0
    return min(100.0, max(0.0, percentage)) // Ограничиваем значение в пределах от 0 до 100
}

class TrackModel: ObservableObject {
    @Published var trackName: String = "--"
    @Published var artist: String = "--"
    @Published var progress: Double = 0.0
    @Published var currentTime: String = "--:--"
    @Published var remainingTime: String = "--:--"
    
    public var album_image_link: String?
    public var track_link: String?
    public var start_timestamp: Int = 0
    public var end_timestamp: Int = 0
    public var is_playing_now = false
        
    public let base_url: String
    public let base_token: String
    
    private var isUpdating = false
    
    init(base_url: String, base_token: String) {
        self.base_url = base_url
        self.base_token = base_token
    }
    
    func startUpdating() {
        isUpdating = true
        
        Task {
            while isUpdating {
                do{
                    await updateTrackInfo()
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }catch{
                    if !Task.isCancelled {
                        startUpdating()
                        print("wtf task has insomnia?")
                    }
                    
                    isUpdating = false
                    break
                }
            }
        }
    }
    
    func stopUpdating() {
        isUpdating = false
    }
    
    func to_hash() -> String {
        return "\(trackName)\(artist)\(start_timestamp)"
    }
    
    func reset_state() {
        DispatchQueue.main.async {
            self.trackName = "--"
            self.artist = "--"
            
            self.progress = 0
            self.currentTime = "--:--"
            self.remainingTime = "--:--"
        }
        
        self.is_playing_now = false
    }
    
    private func updateTrackInfo() async {
        do {
            let track = try await fetchCurrentTrack(baseUrl: self.base_url, api_token: self.base_token)
            
            if !track.is_playing && self.is_playing_now {
                self.reset_state()
            }
            
            if !track.is_playing {
                return
            }
            
            self.is_playing_now = true
            
            // Set base track info
            DispatchQueue.main.async {
                self.trackName = track.name
                self.artist = track.author
            }
            
            // Timestamps working
            let start_timestamp: Int? = Int(track.start_timestamp)
            if start_timestamp == nil {
                return
            }
            
            let end_timestamp: Int? = Int(track.end_timestamp)
            if end_timestamp == nil {
                return
            }

            let curtime_stamp = Int(Date().timeIntervalSince1970)
            
            if end_timestamp! - curtime_stamp >= 0{
                let all_time = (end_timestamp! - start_timestamp!) / 1000
                let cur_time = (curtime_stamp - (start_timestamp! / 1000))
                
                let all_time_str = formatTime(seconds: all_time)
                let cur_time_str = formatTime(seconds: cur_time)

                self.start_timestamp = start_timestamp!
                self.end_timestamp = end_timestamp!

                DispatchQueue.main.async {
                    self.currentTime = cur_time_str
                    self.remainingTime = all_time_str
                }
                
                // Timeline working
                let d = calculatePercentage(curTime: Double(cur_time), allTime: Double(all_time)) / 100
                DispatchQueue.main.async {
                    self.progress = d
                }
            }
            
            // Album image working
            self.album_image_link = track.album_image
            
            // Track link working
            self.track_link = track.track_url
            
        } catch {
            print("Failed to fetch current track: \(error)")
        }
    }
}
