import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct MusicPlayerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: AudioPlayerViewModel
    @State private var showFilePicker = false
    @State private var showPlaylist = false

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundColor(.accentColor)
                Text("Music Player")
                    .font(.headline)

                Spacer()
                
                // Playlist count
                if !viewModel.playlist.isEmpty {
                    Text("\(viewModel.playlist.count) songs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                PlayerIconButton(systemImage: "plus", tint: .accentColor) {
                    showFilePicker = true
                }
                .help("Add music files")
                
                if !viewModel.playlist.isEmpty {
                    // Autoplay toggle
                    PlayerIconButton(
                        systemImage: "repeat",
                        tint: viewModel.isAutoplayEnabled ? .accentColor : .secondary
                    ) {
                        viewModel.isAutoplayEnabled.toggle()
                    }
                    .help(viewModel.isAutoplayEnabled ? "Autoplay On" : "Autoplay Off")
                    
                    PlayerIconButton(systemImage: "list.bullet", tint: showPlaylist ? .accentColor : .secondary) {
                        showPlaylist.toggle()
                    }
                    .help("Show playlist")
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if viewModel.playlist.isEmpty {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "music.note.house.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.8))

                    Text("No music added")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Load local focus tracks to stay inside one workspace")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.75))

                    Button("Add Music Files") {
                        showFilePicker = true
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.03))
                )
            } else {
                // Song info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.currentSong)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        // Progress time
                        HStack {
                            Text(viewModel.formatTime(viewModel.currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                            
                            Text("/")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.formatTime(viewModel.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    }
                    
                    Spacer()
                    
                    // Song index
                    Text("\(viewModel.currentIndex + 1)/\(viewModel.playlist.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .liquidGlassCard(cornerRadius: 6, tint: .white, tintOpacity: 0.08, strokeOpacity: 0.45, shadowOpacity: 0.08)
                }
                .padding(.horizontal)

                // Progress bar with audio visualization
                VStack(spacing: 4) {
                    // Audio level visualization
                    if viewModel.isPlaying {
                        HStack(spacing: 3) {
                            ForEach(0..<viewModel.audioLevels.count, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.accentColor.opacity(0.8))
                                    .frame(width: 4, height: max(4, viewModel.audioLevels[index] * 20))
                            }
                        }
                        .frame(height: 20)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            // Progress
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: viewModel.duration > 0 ? CGFloat(viewModel.currentTime / viewModel.duration) * geometry.size.width : 0, height: 4)
                                .cornerRadius(2)
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let percentage = max(0, min(1, value.location.x / geometry.size.width))
                                    viewModel.seek(to: Double(percentage) * viewModel.duration)
                                }
                        )
                    }
                    .frame(height: 4)
                }
                .padding(.horizontal)

                // Playback controls
                HStack(spacing: 16) {
                    // Previous
                    PlayerIconButton(systemImage: "backward.fill", tint: .primary, action: viewModel.previousSong)
                    .help("Previous (Cmd + [)")

                    // Rewind 5s
                    PlayerIconButton(systemImage: "gobackward.5", tint: .primary, action: viewModel.rewind5Seconds)
                    .help("Rewind 5 seconds (⌘←)")

                    // Play/Pause
                    Button(action: viewModel.playOrPause) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("Play/Pause (Cmd + K or media key)")

                    // Forward 5s
                    PlayerIconButton(systemImage: "goforward.5", tint: .primary, action: viewModel.forward5Seconds)
                    .help("Forward 5 seconds (⌘→)")

                    // Next
                    PlayerIconButton(systemImage: "forward.fill", tint: .primary, action: viewModel.nextSong)
                    .help("Next (Cmd + ])")
                }
                .padding(.bottom, 8)
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.audio, .mp3, .wav, .aiff],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                viewModel.addSongs(urls: urls)
            case .failure(let error):
                print("❌ File picker error: \(error.localizedDescription)")
            }
        }
        .popover(isPresented: $showPlaylist) {
            PlaylistView(viewModel: viewModel)
                .frame(width: 300, height: 400)
        }
    }
}

struct PlayerIconButton: View {
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct PlaylistView: View {
    @ObservedObject var viewModel: AudioPlayerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Playlist")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.playlist.count) songs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            if viewModel.playlist.isEmpty {
                Spacer()
                Text("No songs in playlist")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(Array(viewModel.playlist.enumerated()), id: \.offset) { index, url in
                        HStack {
                            if index == viewModel.currentIndex {
                                Image(systemName: viewModel.isPlaying ? "speaker.wave.2.fill" : "speaker.fill")
                                    .foregroundColor(.accentColor)
                                    .frame(width: 20)
                            } else {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                            }
                            
                            Text(url.lastPathComponent)
                                .lineLimit(1)
                                .foregroundColor(index == viewModel.currentIndex ? .accentColor : .primary)
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.removeSong(at: index)
                            }) {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Play this song
                            if index != viewModel.currentIndex {
                                viewModel.currentIndex = index
                                viewModel.playOrPause()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct MusicPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        MusicPlayerView(viewModel: AudioPlayerViewModel())
            .frame(width: 480, height: 150)
    }
}
