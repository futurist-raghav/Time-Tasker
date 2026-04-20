//
//  TimeTaskerTests.swift
//  TimeTaskerTests
//
//  Created by Raghav Agarwal on 04/12/25.
//

import Testing
import Foundation
@testable import TimeTasker

struct TimeTaskerTests {

    @Test("Category defaults map to blocked apps")
    func categoryDefaultsMapToBlockedApps() {
        #expect(Category.coding.defaultBlockedApps.contains("Safari"))
        #expect(Category.custom.defaultBlockedApps.isEmpty)
        #expect(Category.design.defaultApps == Category.design.defaultBlockedApps)
    }

    @Test("ResourceType website round-trips through Codable")
    func resourceTypeWebsiteCodableRoundTrip() throws {
        let encoded = try JSONEncoder().encode(ResourceType.website)
        let decoded = try JSONDecoder().decode(ResourceType.self, from: encoded)
        #expect(decoded == .website)
    }

    @Test("Resource equality is path-based")
    func resourceEqualityUsesPath() {
        let first = Resource(name: "Site A", path: "youtube.com", type: .website)
        let second = Resource(name: "Site B", path: "youtube.com", type: .website)
        let third = Resource(name: "Site C", path: "discord.com", type: .website)

        #expect(first == second)
        #expect(first != third)
    }

    @Test("Past-deadline tasks report EXPIRED")
    func pastDeadlineTaskReportsExpired() {
        let task = Task(
            title: "Expired Test",
            deadline: Date().addingTimeInterval(-5),
            category: .coding
        )

        #expect(task.timeRemaining < 0)
        #expect(task.formattedTimeRemaining == "EXPIRED")
    }

    @Test("Pomodoro status text reflects session and break")
    func pomodoroStatusTextReflectsState() {
        var task = Task(
            title: "Pomodoro",
            deadline: Date().addingTimeInterval(1200),
            category: .coding,
            isPomodoroMode: true
        )

        #expect(task.pomodoroStatusText == "Session \(task.pomodoroCurrentSession)")
        task.pomodoroIsOnBreak = true
        #expect(task.pomodoroStatusText == "Break Time")
    }

    @Test("Platform readiness labels are valid")
    func platformReadinessLabelsAreValid() {
        let platform = PlatformReadinessService.shared

        #if arch(arm64)
        #expect(platform.architectureLabel == "Apple Silicon")
        #else
        #expect(platform.architectureLabel == "Intel")
        #endif

        #expect(["Native", "Rosetta"].contains(platform.runtimeLabel))
        #expect(platform.osLabel.hasPrefix("macOS "))

        let supportValues = [
            "Legacy baseline",
            "Sequoia baseline",
            "Tahoe baseline",
            "Post-Tahoe era"
        ]
        #expect(supportValues.contains(platform.supportLabel))

        #expect(platform.appVersionLabel.hasPrefix("v"))
        #expect(platform.appVersionLabel.contains("("))
        #expect(platform.appVersionLabel.contains(")"))
    }

}
