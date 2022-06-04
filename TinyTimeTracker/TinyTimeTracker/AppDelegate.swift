//
//  AppDelegate.swift
//  TinyTimeTracker
//

import Cocoa
import LaunchAtLogin

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    let appName = Bundle.main.infoDictionary?["CFBundleName"] as! String
    var appRunning: Bool = false
    var appTimerWorkRunning: Bool = false
    var appTimerRestRunning: Bool = false
    var timerWork: Timer? = nil
    var timerRest: Timer? = nil
    var elapsedTimeWork: Double = 0.0
    var elapsedTimeRest: Double = 0.0
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    let icon = NSImage(named:NSImage.Name("Icon"))
    let iconWork = NSImage(named:NSImage.Name("IconWork"))
    let iconRest = NSImage(named:NSImage.Name("IconRest"))
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var startStopMenuItem: NSMenuItem!
    @IBOutlet weak var changeModeMenuItem: NSMenuItem!
    @IBOutlet weak var statisticsMenuItem: NSMenuItem!
    @IBOutlet weak var workTimerMenuItem: NSMenuItem!
    @IBOutlet weak var restTimerMenuItem: NSMenuItem!
    @IBOutlet weak var launchAtLoginMenuItem: NSMenuItem!
    @IBOutlet weak var quitMenuItem: NSMenuItem!

    @IBAction func startStopClicked(_ sender: NSMenuItem) {
        let localDate = Date().currentTimeZoneDate()
        if(appRunning) {
            stopAllTimer()
            saveStats(logMessage: workTimerMenuItem.title + "\n")
            saveStats(logMessage: restTimerMenuItem.title + "\n")
            let logMessage = NSLocalizedString("logMessageStop", comment: "") + ": " + String("\(localDate)\n")
            saveStats(logMessage: logMessage)
            statusItem.button?.image = icon
        }
        else {
            let logMessage = "\n" + NSLocalizedString("logMessageStart", comment: "") + ": " + String("\(localDate)\n")
            saveStats(logMessage: logMessage)
            workTimerMenuItem.title = NSLocalizedString("textWork", comment: "") + String(": 00:00:00")
            restTimerMenuItem.title = NSLocalizedString("textRest", comment: "") + String(": 00:00:00")
            elapsedTimeWork = 0
            elapsedTimeRest = 0
            startTimerWork()
        }
    }

    @IBAction func changeModeClicked(_ sender: NSMenuItem) {
        ChangeMode()
    }
    
    @IBAction func statisticsClicked(_ sender: NSMenuItem) {
        let logFile = paths[0].appendingPathComponent(appName + ".txt")
        NSWorkspace.shared.open(logFile)
    }

    @IBAction func launchAtLoginClicked(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        if sender.state == .on {
            LaunchAtLogin.isEnabled = true
        } else {
            LaunchAtLogin.isEnabled = false
        }
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        let localDate = Date().currentTimeZoneDate()
        if(appRunning) {
            stopAllTimer()
            saveStats(logMessage: workTimerMenuItem.title + "\n")
            saveStats(logMessage: restTimerMenuItem.title + "\n")
            let logMessage = NSLocalizedString("logMessageStop", comment: "") + " " + String("\(localDate)\n")
            saveStats(logMessage: logMessage)
        }
        NSApp.terminate(self)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createStatusMenu()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func createStatusMenu() {
        statusItem.button?.image = icon
        icon?.isTemplate = true
        iconWork?.isTemplate = true
        iconRest?.isTemplate = true
        statusItem.menu = statusMenu
        if LaunchAtLogin.isEnabled {
            launchAtLoginMenuItem.state = .on
        } else {
            launchAtLoginMenuItem.state = .off
        }
        changeModeMenuItem.title = NSLocalizedString("menuTextChangemode", comment: "")
        statisticsMenuItem.title = NSLocalizedString("menuTextStatistics", comment: "")
        launchAtLoginMenuItem.title = NSLocalizedString("menuTextLaunchAtLogin", comment: "")
        quitMenuItem.title = NSLocalizedString("menuTextQuit", comment: "")
    }

    func menuWillOpen(_: NSMenu) {
        let logFile = paths[0].appendingPathComponent(appName + ".txt")
        if !FileManager.default.fileExists(atPath: logFile.path) {
            statisticsMenuItem.isHidden = true
        } else {
            statisticsMenuItem.isHidden = false
        }
        if(appRunning) {
            workTimerMenuItem.isHidden = false
            restTimerMenuItem.isHidden = false
            changeModeMenuItem.isHidden = false
            startStopMenuItem.title = NSLocalizedString("menuTextStop", comment: "")
        } else {
            if(elapsedTimeWork == 0) {
                workTimerMenuItem.isHidden = true
            }
            if(elapsedTimeRest == 0) {
                restTimerMenuItem.isHidden = true
            }
            changeModeMenuItem.isHidden = true
            startStopMenuItem.title = NSLocalizedString("menuTextStart", comment: "")
        }
    }

    func startTimerWork() {
        appRunning = true
        appTimerWorkRunning = true
        statusItem.button?.image = iconWork
        timerWork = Timer(
            timeInterval: 1,
            target: self,
            selector: #selector(updateTextWorkTimerMenuItem),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timerWork!, forMode: .common)
    }

    @objc
    func updateTextWorkTimerMenuItem(_ sender: Timer) {
        let mSecond: Double = timerWork?.timeInterval ?? 0.0
        elapsedTimeWork += mSecond
        let hms = secToTime(sec: elapsedTimeWork)
        workTimerMenuItem.title = NSLocalizedString("textWork", comment: "") + String(": ") + hms
    }

    func startTimerRest() {
        appRunning = true
        appTimerRestRunning = true
        statusItem.button?.image = iconRest
        timerRest = Timer(
            timeInterval: 1,
            target: self,
            selector: #selector(updateTextRestTimerMenuItem),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timerRest!, forMode: .common)
    }

    @objc
    func updateTextRestTimerMenuItem(_ sender: Timer) {
        let mSecond: Double = timerRest?.timeInterval ?? 0.0
        elapsedTimeRest += mSecond
        let hms = secToTime(sec: elapsedTimeRest)
        restTimerMenuItem.title = NSLocalizedString("textRest", comment: "") + String(": ") + hms
    }

    func secToTime(sec: Double) -> String {
        let hours = Int(sec) / 3600
        let minutes = Int(sec) / 60 % 60
        let seconds = Int(sec) % 60
        let hms = String(format:"%02i:%02i:%02i", hours, minutes, seconds)
        return hms
    }

    func stopTimerWork() {
        appTimerWorkRunning = false
        timerWork?.invalidate()
    }

    func stopTimerRest() {
        appTimerRestRunning = false
        timerRest?.invalidate()
    }

    func stopAllTimer() {
        appRunning = false
        stopTimerWork()
        stopTimerRest()
    }

    func ChangeMode() {
        if(appTimerWorkRunning) {
            stopTimerWork()
            startTimerRest()
        } else {
            stopTimerRest()
            startTimerWork()
        }
    }

    func saveStats(logMessage: String) {
        let logFile = paths[0].appendingPathComponent(appName + ".txt")
        let localDate = Date().currentTimeZoneDate()
        if FileManager.default.fileExists(atPath: logFile.path) {
            do {
                let fileHandle = try FileHandle(forUpdating: logFile)
                fileHandle.seekToEndOfFile()
                fileHandle.write(logMessage.data(using: .utf8)!)
                fileHandle.closeFile()
            } catch {
                statisticsMenuItem.title = NSLocalizedString("errorMessageWrite", comment: "") + " " + logFile.path
            }
        } else {
            let logMessage = NSLocalizedString("logMessageCreate", comment: "") + ": " + String("\(localDate)\n") + logMessage
            do {
                try logMessage.write(to: logFile, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                statisticsMenuItem.title = NSLocalizedString("errorMessageWrite", comment: "") + " " + logFile.path
            }
        }
    }
}

extension Date {
    func currentTimeZoneDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
        return dateFormatter.string(from: self)
    }
}
