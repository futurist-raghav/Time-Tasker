import Foundation
import AVFoundation
import Combine
import AppKit

class AudioPlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentSong: String = "No song loaded"
    @Published var playlist: [URL] = []
    @Published var currentIndex: Int = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isAutoplayEnabled = true
    @Published var audioLevels: [CGFloat] = Array(repeating: 0, count: 8)  // For visualization
    
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupAudioSession()
        setupKeyboardShortcuts()
    }
    
    private func setupAudioSession() {
        // For macOS, we don't need AVAudioSession like iOS
        print("🎵 Audio player initialized")
    }
    
    private func setupKeyboardShortcuts() {
        NotificationCenter.default.publisher(for: .musicPlayPause)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.playOrPause() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .musicNext)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.nextSong() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .musicPrevious)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.previousSong() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .musicForward)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.forward5Seconds() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .musicRewind)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.rewind5Seconds() }
            .store(in: &cancellables)
        
        print("⌨️ Keyboard shortcuts set up for music player")
    }
    
    // AVAudioPlayerDelegate - called when song finishes
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🎵 Song finished playing (success: \(flag))")
        if flag && isAutoplayEnabled && !playlist.isEmpty {
            DispatchQueue.main.async {
                self.playNextSongAutomatically()
            }
        }
    }
    
    private func playNextSongAutomatically() {
        let nextIndex = (currentIndex + 1) % playlist.count
        currentIndex = nextIndex
        loadSong(at: nextIndex)
        
        // Auto-play the next song
        if let player = audioPlayer {
            let success = player.play()
            isPlaying = success
            if success {
                startProgressTimer()
                print("▶️ Auto-playing next: \(currentSong)")
            }
        }
    }

    func addSongs(urls: [URL]) {
        for url in urls {
            // Start accessing security-scoped resource
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            
            if didStartAccessing {
                // Create a local copy or bookmark for later access
                playlist.append(url)
                print("✅ Added song: \(url.lastPathComponent)")
            } else {
                // Try adding anyway (might work for non-sandboxed)
                playlist.append(url)
                print("⚠️ Added song without security scope: \(url.lastPathComponent)")
            }
        }
        
        if audioPlayer == nil && !playlist.isEmpty {
            loadSong(at: 0)
        }
        
        objectWillChange.send()
    }

    func removeSong(at index: Int) {
        guard index < playlist.count else { return }
        let url = playlist[index]
        url.stopAccessingSecurityScopedResource()
        playlist.remove(at: index)
        
        if playlist.isEmpty {
            audioPlayer?.stop()
            audioPlayer = nil
            currentSong = "No song loaded"
            isPlaying = false
            stopProgressTimer()
        } else if index == currentIndex {
            let newIndex = min(currentIndex, playlist.count - 1)
            loadSong(at: newIndex)
        }
    }

    func playOrPause() {
        if audioPlayer == nil && !playlist.isEmpty {
            loadSong(at: currentIndex)
        }
        
        guard let player = audioPlayer else {
            print("⚠️ No audio player available")
            return
        }

        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopProgressTimer()
            print("⏸ Paused")
        } else {
            let success = player.play()
            isPlaying = success
            if success {
                startProgressTimer()
                print("▶️ Playing: \(currentSong)")
            } else {
                print("❌ Failed to play")
            }
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopProgressTimer()
    }

    func nextSong() {
        guard !playlist.isEmpty else { return }
        currentIndex = (currentIndex + 1) % playlist.count
        loadSong(at: currentIndex)
        if isPlaying {
            audioPlayer?.play()
            startProgressTimer()
        }
    }

    func previousSong() {
        guard !playlist.isEmpty else { return }
        
        // If more than 3 seconds in, restart current song
        if let player = audioPlayer, player.currentTime > 3 {
            player.currentTime = 0
            currentTime = 0
            return
        }
        
        currentIndex = (currentIndex - 1 + playlist.count) % playlist.count
        loadSong(at: currentIndex)
        if isPlaying {
            audioPlayer?.play()
            startProgressTimer()
        }
    }

    func rewind5Seconds() {
        guard let player = audioPlayer else { return }
        player.currentTime = max(0, player.currentTime - 5.0)
        currentTime = player.currentTime
    }

    func forward5Seconds() {
        guard let player = audioPlayer else { return }
        player.currentTime = min(player.duration, player.currentTime + 5.0)
        currentTime = player.currentTime
    }
    
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        player.currentTime = min(max(0, time), player.duration)
        currentTime = player.currentTime
    }

    private func loadSong(at index: Int) {
        guard index >= 0 && index < playlist.count else {
            print("❌ Invalid song index: \(index)")
            return
        }
        
        stopProgressTimer()
        let url = playlist[index]
        currentSong = url.lastPathComponent
        currentIndex = index

        do {
            // Stop current player
            audioPlayer?.stop()
            
            // Create new player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self  // Set delegate for autoplay
            audioPlayer?.isMeteringEnabled = true  // Enable metering for visualization
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            
            print("✅ Loaded: \(currentSong) (duration: \(formatTime(duration)))")
        } catch {
            print("❌ Error loading audio: \(error.localizedDescription)")
            currentSong = "Failed to load: \(url.lastPathComponent)"
            duration = 0
            currentTime = 0
        }
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            
            DispatchQueue.main.async {
                self.currentTime = player.currentTime
                
                // Update audio levels for visualization
                if self.isPlaying {
                    player.updateMeters()
                    let power = player.averagePower(forChannel: 0)
                    // Convert dB to linear scale (0-1)
                    let normalizedPower = CGFloat(max(0, min(1, (power + 60) / 60)))
                    
                    // Shift levels and add new one
                    self.audioLevels.removeFirst()
                    self.audioLevels.append(normalizedPower)
                } else {
                    // Fade out levels when paused
                    self.audioLevels = self.audioLevels.map { max(0, $0 - 0.1) }
                }
            }
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    deinit {
        stopProgressTimer()
        // Release security-scoped resources
        for url in playlist {
            url.stopAccessingSecurityScopedResource()
        }
    }
}
