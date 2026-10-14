//
//  ContentView.swift
//  appPlayground
//
//  Created by Dan Payne on 1/5/22.
//
import AVFoundation
import AVKit
import SwiftUI

// MARK: - Theme

enum Theme {
  static let void = Color(red: 0.02, green: 0.03, blue: 0.07)
  static let deep = Color(red: 0.05, green: 0.07, blue: 0.16)
  static let cyan = Color(red: 0.24, green: 0.91, blue: 1.0)
  static let violet = Color(red: 0.55, green: 0.24, blue: 1.0)
  static let green = Color(red: 0.16, green: 1.0, blue: 0.56)  // rolling
  static let red = Color(red: 1.0, green: 0.22, blue: 0.36)    // held
  static let text = Color.white
  static let dim = Color.white.opacity(0.55)

  static func display(_ size: CGFloat) -> Font {
    .system(size: size, weight: .heavy, design: .rounded)
  }
  static func mono(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
    .system(size: size, weight: weight, design: .monospaced)
  }
}

extension View {
  func glassPanel(cornerRadius: CGFloat, tint: Color = .white) -> some View {
    let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    return self
      .background(shape.fill(.ultraThinMaterial))
      .overlay(
        shape.stroke(
          LinearGradient(colors: [tint.opacity(0.6), tint.opacity(0.08)],
                         startPoint: .topLeading, endPoint: .bottomTrailing),
          lineWidth: 1)
      )
  }
}

struct PressableStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1)
      .brightness(configuration.isPressed ? 0.08 : 0)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

// MARK: - Game Model

final class GameModel: ObservableObject {
  @Published var dice = [1, 1, 1, 1, 1]
  @Published var rolling = [true, true, true, true, true]  // false = held
  @Published var spins = [0, 0, 0, 0, 0]
  @Published var rollNumber = 0

  @Published var freeRoll = UserDefaults.standard.bool(forKey: "freeRoll") {
    didSet {
      UserDefaults.standard.set(freeRoll, forKey: "freeRoll")
      if !freeRoll { rollNumber = min(rollNumber, maxRolls) }
    }
  }

  let maxRolls = 3
  var turnOver: Bool { !freeRoll && rollNumber >= maxRolls }

  private var audioPlayer: AVAudioPlayer?

  init() {
    if let url = Bundle.main.url(forResource: "rollDice", withExtension: "mp3") {
      audioPlayer = try? AVAudioPlayer(contentsOf: url)
      audioPlayer?.prepareToPlay()
    }
    #if DEBUG
    applyDemoState()
    #endif
  }

  #if DEBUG
  /// Launch args for App Store screenshots, e.g. `-demoDice 6,5,4,3,6 -demoHeld 1,1,1,0,0 -demoRoll 2`.
  private func applyDemoState() {
    let defaults = UserDefaults.standard
    func ints(_ key: String) -> [Int]? {
      guard let raw = defaults.string(forKey: key) else { return nil }
      let values = raw.split(separator: ",").compactMap { Int($0) }
      return values.count == dice.count ? values : nil
    }
    if let values = ints("demoDice") { dice = values }
    if let held = ints("demoHeld") { rolling = held.map { $0 == 0 } }
    if defaults.object(forKey: "demoRoll") != nil { rollNumber = defaults.integer(forKey: "demoRoll") }
  }
  #endif

  func toggleHold(_ i: Int) {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    rolling[i].toggle()
  }

  func setAll(rolling value: Bool) {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    rolling = Array(repeating: value, count: dice.count)
  }

  func roll() {
    if turnOver {
      AudioServicesPlaySystemSound(1305)
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      withAnimation(.easeInOut(duration: 0.35)) {
        dice = Array(repeating: 1, count: dice.count)
        rolling = Array(repeating: true, count: dice.count)
        rollNumber = 0
      }
      return
    }
    for i in dice.indices where rolling[i] {
      dice[i] = Int.random(in: 1...6)
      spins[i] += 1
    }
    audioPlayer?.currentTime = 0
    audioPlayer?.play()
    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
      rollNumber += 1
    }
  }
}

// MARK: - Root

struct ContentView: View {
  @AppStorage("classicMode") private var classicMode = false
  @StateObject private var game = GameModel()
  @State private var showInfo = false
  @State private var showSettings = false
  #if DEBUG
  private let demoSheet = UserDefaults.standard.string(forKey: "demoSheet")
  #endif

  var body: some View {
    Group {
      if classicMode {
        ClassicGameView(game: game, showInfo: $showInfo, showSettings: $showSettings)
      } else {
        ModernGameView(game: game, showInfo: $showInfo, showSettings: $showSettings)
      }
    }
    .fullScreenCover(isPresented: $showInfo) {
      if classicMode { ClassicInfoView() } else { InfoView() }
    }
    .sheet(isPresented: $showSettings) { SettingsView(game: game) }
    #if DEBUG
    .onAppear {
      showSettings = demoSheet == "settings"
      showInfo = demoSheet == "info"
      if let icon = UserDefaults.standard.string(forKey: "demoIcon") {
        // iOS rejects icon changes until the app is active.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          UIApplication.shared.setAlternateIconName(icon == "classic" ? "AppIconClassic" : nil) { error in
            NSLog("demoIcon \(icon): \(error?.localizedDescription ?? "ok")")
          }
        }
      }
    }
    #endif
  }
}

// MARK: - Modern Game

struct ModernGameView: View {
  @ObservedObject var game: GameModel
  @Binding var showInfo: Bool
  @Binding var showSettings: Bool

  var body: some View {
    ZStack {
      FuturisticBackground()

      VStack(spacing: 14) {
        header
        StatusHUD(dice: game.dice, rollNumber: game.rollNumber, maxRolls: game.maxRolls, freeRoll: game.freeRoll)
        VStack(spacing: 10) {
          ForEach(0..<5) { i in
            DieRow(index: i, value: game.dice[i], isRolling: game.rolling[i], spins: game.spins[i]) {
              game.toggleHold(i)
            }
          }
        }
        controls
      }
      .padding(.horizontal, 18)
      .padding(.top, 6)
      .padding(.bottom, 10)
    }
    .preferredColorScheme(.dark)
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text("ROLL FOR 6 · 5 · 4")
          .font(Theme.mono(11, .bold))
          .tracking(3)
          .foregroundColor(Theme.cyan)
        Text("Ship Cap'n Crew")
          .font(Theme.display(28))
          .foregroundStyle(LinearGradient(colors: [.white, Theme.cyan.opacity(0.8)],
                                          startPoint: .leading, endPoint: .trailing))
      }
      Spacer()
      HStack(spacing: 8) {
        circleButton("info", label: "How to play") { showInfo = true }
        circleButton("gearshape.fill", label: "Settings") { showSettings = true }
      }
    }
  }

  private func circleButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(Theme.text)
        .frame(width: 42, height: 42)
        .background(Circle().fill(.ultraThinMaterial))
        .overlay(Circle().stroke(Theme.cyan.opacity(0.5), lineWidth: 1))
    }
    .buttonStyle(PressableStyle())
    .accessibilityLabel(label)
  }

  private var controls: some View {
    VStack(spacing: 10) {
      HStack(spacing: 10) {
        SecondaryButton(title: "Hold All", icon: "lock.fill", tint: Theme.red) { game.setAll(rolling: false) }
        SecondaryButton(title: "Roll All", icon: "lock.open.fill", tint: Theme.green) { game.setAll(rolling: true) }
      }
      RollButton(turnOver: game.turnOver, action: game.roll)
    }
  }
}

// MARK: - HUD

struct StatusHUD: View {
  let dice: [Int]
  let rollNumber: Int
  let maxRolls: Int
  let freeRoll: Bool

  /// Sum of the two remaining dice once a 6, 5 and 4 are all on the table.
  private var cargo: Int? {
    var rest = dice
    for needed in [6, 5, 4] {
      guard let i = rest.firstIndex(of: needed) else { return nil }
      rest.remove(at: i)
    }
    return rest.reduce(0, +)
  }

  var body: some View {
    HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text("ROLL")
          .font(Theme.mono(10, .bold))
          .tracking(2)
          .foregroundColor(Theme.dim)
        HStack(alignment: .firstTextBaseline, spacing: 1) {
          Text("\(rollNumber)")
            .font(Theme.display(30))
            .foregroundColor(Theme.text)
          Text(freeRoll ? "/∞" : "/\(maxRolls)")
            .font(Theme.mono(14, .bold))
            .foregroundColor(Theme.dim)
        }
        if freeRoll {
          Text("FREE")
            .font(Theme.mono(8, .bold))
            .tracking(2)
            .foregroundColor(Theme.cyan)
            .frame(height: 4)
        } else {
          HStack(spacing: 4) {
            ForEach(0..<maxRolls, id: \.self) { i in
              let lit = i < rollNumber
              Capsule()
                .fill(lit ? Theme.cyan : Color.white.opacity(0.12))
                .frame(width: 14, height: 4)
                .shadow(color: lit ? Theme.cyan : .clear, radius: 4)
            }
          }
        }
      }

      Rectangle()
        .fill(Color.white.opacity(0.1))
        .frame(width: 1)
        .padding(.vertical, 2)

      HStack(spacing: 6) {
        chip(label: "SHIP", value: "6", lit: rollNumber > 0 && dice.contains(6))
        chip(label: "CAPN", value: "5", lit: rollNumber > 0 && dice.contains(5))
        chip(label: "CREW", value: "4", lit: rollNumber > 0 && dice.contains(4))
        chip(label: "CARGO", value: cargo.map(String.init) ?? "–", lit: cargo != nil, accent: Theme.violet)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .fixedSize(horizontal: false, vertical: true)
    .glassPanel(cornerRadius: 22, tint: Theme.cyan)
    .animation(.easeInOut(duration: 0.25), value: dice)
  }

  private func chip(label: String, value: String, lit: Bool, accent: Color = Theme.cyan) -> some View {
    VStack(spacing: 4) {
      Text(value)
        .font(Theme.display(20))
        .foregroundColor(lit ? .white : Theme.dim.opacity(0.6))
        .shadow(color: lit ? accent : .clear, radius: 6)
      Text(label)
        .font(Theme.mono(8, .bold))
        .tracking(1)
        .foregroundColor(lit ? accent : Theme.dim.opacity(0.6))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(lit ? accent.opacity(0.16) : Color.white.opacity(0.04))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(lit ? accent.opacity(0.7) : Color.white.opacity(0.08), lineWidth: 1)
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(label) \(lit ? "found" : "missing")")
  }
}

// MARK: - Dice

struct DieRow: View {
  let index: Int
  let value: Int
  let isRolling: Bool
  let spins: Int
  let toggle: () -> Void

  private var tint: Color { isRolling ? Theme.green : Theme.red }

  var body: some View {
    Button(action: toggle) {
      HStack(spacing: 14) {
        DieFace(value: value, tint: tint)
          .rotationEffect(.degrees(Double(spins) * 720))
          .rotation3DEffect(.degrees(Double(spins) * 360), axis: (x: 1, y: 1, z: 0))
          .animation(.spring(response: 0.9, dampingFraction: 0.72), value: spins)

        VStack(alignment: .leading, spacing: 2) {
          Text("DIE 0\(index + 1)")
            .font(Theme.mono(10, .bold))
            .tracking(2)
            .foregroundColor(Theme.dim)
          Text(isRolling ? "Rolling" : "Held")
            .font(Theme.display(20))
            .foregroundColor(Theme.text)
          Text(isRolling ? "TAP TO HOLD" : "TAP TO RELEASE")
            .font(Theme.mono(9, .medium))
            .tracking(1)
            .foregroundColor(tint.opacity(0.85))
        }

        Spacer(minLength: 0)

        Image(systemName: isRolling ? "lock.open.fill" : "lock.fill")
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(isRolling ? tint : Theme.void)
          .frame(width: 40, height: 40)
          .background(Circle().fill(isRolling ? tint.opacity(0.12) : tint))
          .overlay(Circle().stroke(tint.opacity(0.8), lineWidth: 1))
          .shadow(color: tint.opacity(isRolling ? 0 : 0.8), radius: 8)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 7)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .glassPanel(cornerRadius: 20, tint: tint)
      .background(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .fill(tint.opacity(isRolling ? 0.03 : 0.12))
      )
      .shadow(color: tint.opacity(isRolling ? 0 : 0.35), radius: 14)
      .contentShape(Rectangle())
    }
    .buttonStyle(PressableStyle())
    .animation(.easeInOut(duration: 0.2), value: isRolling)
    .accessibilityLabel("Die \(index + 1), showing \(value), \(isRolling ? "rolling" : "held")")
    .accessibilityHint(isRolling ? "Double tap to hold" : "Double tap to release")
  }
}

struct DieFace: View {
  let value: Int
  let tint: Color

  private static let pips: [Int: [CGPoint]] = [
    1: [CGPoint(x: 0.5, y: 0.5)],
    2: [CGPoint(x: 0.27, y: 0.27), CGPoint(x: 0.73, y: 0.73)],
    3: [CGPoint(x: 0.27, y: 0.27), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.73, y: 0.73)],
    4: [CGPoint(x: 0.27, y: 0.27), CGPoint(x: 0.73, y: 0.27),
        CGPoint(x: 0.27, y: 0.73), CGPoint(x: 0.73, y: 0.73)],
    5: [CGPoint(x: 0.27, y: 0.27), CGPoint(x: 0.73, y: 0.27), CGPoint(x: 0.5, y: 0.5),
        CGPoint(x: 0.27, y: 0.73), CGPoint(x: 0.73, y: 0.73)],
    6: [CGPoint(x: 0.27, y: 0.25), CGPoint(x: 0.27, y: 0.5), CGPoint(x: 0.27, y: 0.75),
        CGPoint(x: 0.73, y: 0.25), CGPoint(x: 0.73, y: 0.5), CGPoint(x: 0.73, y: 0.75)],
  ]

  var body: some View {
    GeometryReader { geo in
      let s = min(geo.size.width, geo.size.height)
      let pip = s * 0.17
      let shape = RoundedRectangle(cornerRadius: s * 0.24, style: .continuous)
      ZStack {
        shape.fill(LinearGradient(colors: [tint.opacity(0.35), Theme.void.opacity(0.95)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing))
        shape.stroke(tint, lineWidth: 1.5)
        ForEach(Array((Self.pips[value] ?? []).enumerated()), id: \.offset) { _, p in
          Circle()
            .fill(Color.white)
            .frame(width: pip, height: pip)
            .shadow(color: tint, radius: pip * 0.5)
            .position(x: p.x * s, y: p.y * s)
        }
      }
      .frame(width: s, height: s)
      .shadow(color: tint.opacity(0.55), radius: 10)
    }
    .aspectRatio(1, contentMode: .fit)
  }
}

// MARK: - Buttons

struct SecondaryButton: View {
  let title: String
  let icon: String
  let tint: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: icon)
          .font(.system(size: 13, weight: .bold))
          .foregroundColor(tint)
        Text(title.uppercased())
          .font(Theme.mono(13, .bold))
          .tracking(1.5)
          .foregroundColor(Theme.text)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 46)
      .glassPanel(cornerRadius: 23, tint: tint)
    }
    .buttonStyle(PressableStyle())
  }
}

struct RollButton: View {
  let turnOver: Bool
  let action: () -> Void
  @State private var pulse = false

  private var colors: [Color] {
    turnOver ? [Theme.violet, Theme.cyan] : [Theme.green, Theme.cyan]
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: turnOver ? "arrow.counterclockwise" : "die.face.5.fill")
          .font(.system(size: 20, weight: .heavy))
        Text(turnOver ? "NEW TURN" : "ROLL")
          .font(Theme.display(22))
          .tracking(4)
      }
      .foregroundColor(Theme.void)
      .frame(maxWidth: .infinity)
      .frame(height: 64)
      .background(
        Capsule().fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
      )
      .overlay(
        Capsule()
          .stroke(Color.white.opacity(0.6), lineWidth: 1)
          .blendMode(.overlay)
      )
      .shadow(color: colors[0].opacity(pulse ? 0.75 : 0.4), radius: pulse ? 22 : 12)
    }
    .buttonStyle(PressableStyle())
    .onAppear {
      withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
        pulse = true
      }
    }
  }
}

// MARK: - Background

struct FuturisticBackground: View {
  @State private var drift = false

  var body: some View {
    ZStack {
      LinearGradient(colors: [Theme.deep, Theme.void], startPoint: .top, endPoint: .bottom)
      Circle()
        .fill(Theme.cyan.opacity(0.22))
        .frame(width: 360, height: 360)
        .blur(radius: 90)
        .offset(x: drift ? -130 : -50, y: drift ? -320 : -250)
      Circle()
        .fill(Theme.violet.opacity(0.25))
        .frame(width: 380, height: 380)
        .blur(radius: 100)
        .offset(x: drift ? 150 : 80, y: drift ? 240 : 320)
      GridFloor()
    }
    .ignoresSafeArea()
    .onAppear {
      withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
        drift = true
      }
    }
  }
}

struct GridFloor: View {
  var body: some View {
    Canvas { ctx, size in
      let horizon = size.height * 0.5
      let vanish = CGPoint(x: size.width / 2, y: horizon)
      var path = Path()
      for i in -12...12 {
        path.move(to: vanish)
        path.addLine(to: CGPoint(x: size.width / 2 + CGFloat(i) * size.width / 5, y: size.height))
      }
      for i in 1...16 {
        let t = CGFloat(i) / 16
        let y = horizon + (size.height - horizon) * t * t
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: size.width, y: y))
      }
      ctx.stroke(path, with: .color(Theme.cyan.opacity(0.22)), lineWidth: 0.7)
    }
    .mask(LinearGradient(colors: [.clear, .black],
                         startPoint: UnitPoint(x: 0.5, y: 0.5), endPoint: .bottom))
  }
}

// MARK: - Info

struct InfoView: View {
  @Environment(\.dismiss) var dismiss

  var body: some View {
    ZStack {
      FuturisticBackground()
      VStack(alignment: .leading, spacing: 20) {
        Text("HOW TO PLAY")
          .font(Theme.mono(12, .bold))
          .tracking(3)
          .foregroundColor(Theme.cyan)
        Text("Ship Cap'n Crew")
          .font(Theme.display(34))
          .foregroundColor(Theme.text)

        VStack(alignment: .leading, spacing: 16) {
          rule("die.face.6.fill", "Roll the dice until you have a 6, 5 and 4 — the Ship, Cap'n and Crew.")
          rule("plus.circle.fill", "The remaining two dice add up to your point, or cargo.")
          rule("lock.fill", "Tap a die to hold it. Hold and roll as you please.")
          rule("3.circle.fill", "You get three rolls per turn. After roll 3, pressing New Turn resets the game.")
        }
        .padding(18)
        .glassPanel(cornerRadius: 22, tint: Theme.cyan)

        Spacer()

        Button { dismiss() } label: {
          Text("BACK TO THE GAME")
            .font(Theme.mono(14, .bold))
            .tracking(2)
            .foregroundColor(Theme.text)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .glassPanel(cornerRadius: 27, tint: Theme.cyan)
        }
        .buttonStyle(PressableStyle())
      }
      .padding(24)
    }
    .preferredColorScheme(.dark)
  }

  private func rule(_ icon: String, _ text: String) -> some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: icon)
        .font(.system(size: 20, weight: .bold))
        .foregroundColor(Theme.cyan)
        .frame(width: 26)
      Text(text)
        .font(.system(size: 16, weight: .medium, design: .rounded))
        .foregroundColor(Theme.text.opacity(0.9))
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

// MARK: - Settings

enum AppIconChoice: CaseIterable, Identifiable {
  case new, classic

  var id: Self { self }
  var title: String { self == .new ? "New" : "Classic" }
  var previewImage: String { self == .new ? "IconPreviewNew" : "IconPreviewClassic" }
  /// Name of the alternate icon set in Assets.xcassets; nil is the primary AppIcon.
  var alternateIconName: String? { self == .new ? nil : "AppIconClassic" }

  static var current: AppIconChoice {
    UIApplication.shared.alternateIconName == "AppIconClassic" ? .classic : .new
  }
}

struct SettingsView: View {
  @ObservedObject var game: GameModel
  @AppStorage("classicMode") private var classicMode = false
  @State private var appIcon = AppIconChoice.current
  @Environment(\.dismiss) var dismiss

  var body: some View {
    ZStack {
      FuturisticBackground()
      VStack(alignment: .leading, spacing: 20) {
        HStack {
          Text("SETTINGS")
            .font(Theme.mono(12, .bold))
            .tracking(3)
            .foregroundColor(Theme.cyan)
          Spacer()
          Button { dismiss() } label: {
            Image(systemName: "xmark")
              .font(.system(size: 14, weight: .bold))
              .foregroundColor(Theme.text)
              .frame(width: 36, height: 36)
              .background(Circle().fill(.ultraThinMaterial))
          }
          .accessibilityLabel("Close")
        }

        settingToggle("Classic Mode",
                      detail: "The original marble table look, for the long-time crew.",
                      isOn: $classicMode)
        settingToggle("Free Roll",
                      detail: "No roll limit. Keep rollin' and holdin' as long as you like.",
                      isOn: $game.freeRoll)

        Text("Your current turn carries over when you switch.")
          .font(Theme.mono(11, .medium))
          .foregroundColor(Theme.dim)

        if UIApplication.shared.supportsAlternateIcons {
          iconPicker
        }

        Spacer()
      }
      .padding(24)
    }
    .preferredColorScheme(.dark)
  }

  private var iconPicker: some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text("App Icon")
          .font(Theme.display(20))
          .foregroundColor(Theme.text)
        Text("Pick the icon for your Home Screen.")
          .font(.system(size: 14, weight: .medium, design: .rounded))
          .foregroundColor(Theme.dim)
      }
      HStack(spacing: 16) {
        ForEach(AppIconChoice.allCases) { choice in
          iconTile(choice)
        }
        Spacer(minLength: 0)
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassPanel(cornerRadius: 22, tint: Theme.cyan)
  }

  private func iconTile(_ choice: AppIconChoice) -> some View {
    let selected = appIcon == choice
    let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    return Button { setIcon(choice) } label: {
      VStack(spacing: 8) {
        Image(choice.previewImage)
          .resizable()
          .frame(width: 80, height: 80)
          .clipShape(shape)
          .overlay(shape.stroke(selected ? Theme.cyan : Color.white.opacity(0.15), lineWidth: selected ? 3 : 1)
                     .padding(-4))
          .shadow(color: selected ? Theme.cyan.opacity(0.6) : .clear, radius: 10)
          .padding(4)
        HStack(spacing: 5) {
          if selected {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(Theme.cyan)
          }
          Text(choice.title.uppercased())
            .font(Theme.mono(11, .bold))
            .tracking(1.5)
            .foregroundColor(selected ? Theme.text : Theme.dim)
        }
      }
    }
    .buttonStyle(PressableStyle())
    .accessibilityLabel("\(choice.title) app icon")
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private func setIcon(_ choice: AppIconChoice) {
    guard choice != appIcon else { return }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    UIApplication.shared.setAlternateIconName(choice.alternateIconName) { error in
      DispatchQueue.main.async {
        if error == nil { appIcon = choice }
      }
    }
  }

  private func settingToggle(_ title: String, detail: String, isOn: Binding<Bool>) -> some View {
    Toggle(isOn: isOn) {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(Theme.display(20))
          .foregroundColor(Theme.text)
        Text(detail)
          .font(.system(size: 14, weight: .medium, design: .rounded))
          .foregroundColor(Theme.dim)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .tint(Theme.cyan)
    .padding(18)
    .glassPanel(cornerRadius: 22, tint: Theme.cyan)
  }
}

// MARK: - Classic Mode

struct ClassicGameView: View {
  @ObservedObject var game: GameModel
  @Binding var showInfo: Bool
  @Binding var showSettings: Bool

  var body: some View {
    ZStack {
      Image("background3")
        .resizable()
        .edgesIgnoringSafeArea(.all)
      VStack {
        HStack(spacing: 24) {
          Button { showInfo = true } label: {
            Image(systemName: "info.circle")
              .foregroundColor(.black)
          }
          Button { showSettings = true } label: {
            Image(systemName: "gearshape")
              .foregroundColor(.black)
          }
          .accessibilityLabel("Settings")
        }
        .padding(.top)
        Spacer()
        Spacer()
        Text("Roll")
          .font(Font.custom("PaytoneOne-Regular", size: 30))
          .foregroundColor(.black)
        if game.freeRoll {
          Text("\(game.rollNumber)")
            .font(Font.custom("PaytoneOne-Regular", size: 80))
            .foregroundColor(.black)
            .frame(width: 190, height: 152)
        } else {
          Image("metal\(game.rollNumber)")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 190)
        }
        Spacer()
      }
      HStack {
        VStack {
          ForEach(0..<5) { i in
            ClassicDiceView(n: game.dice[i], rollDice: game.rolling[i], spins: game.spins[i])
          }
          Spacer()
          VStack {
            Button { game.setAll(rolling: false) } label: {
              classicPill("Hold All", width: 140, cornerRadius: 25,
                          fill: LinearGradient(colors: [Color("diceRedLight"), Color("diceRed")],
                                               startPoint: .leading, endPoint: .trailing))
            }
            Button { game.setAll(rolling: true) } label: {
              classicPill("Roll All", width: 130, cornerRadius: 25,
                          fill: LinearGradient(colors: [Color("dutchGreen"), Color("dutchGreenDark")],
                                               startPoint: .leading, endPoint: .trailing))
            }
          }
        }
        .padding()
        Spacer()
        VStack {
          ForEach(0..<5) { i in
            Button { game.toggleHold(i) } label: {
              let color = game.rolling[i] ? Color("dutchGreen") : Color("diceRed")
              classicPill(game.rolling[i] ? "Hold?" : "HELD!", width: 150, height: 105, cornerRadius: 25,
                          fill: LinearGradient(colors: [color, color], startPoint: .leading, endPoint: .trailing))
            }
          }
          Spacer()
          Button(action: game.roll) {
            classicPill("ROLL", width: 200, height: 100, cornerRadius: 85,
                        fill: LinearGradient(colors: [Color("dutchGreen"), Color("dutchGreenDark")],
                                             startPoint: .leading, endPoint: .trailing))
          }
        }
      }
    }
    .preferredColorScheme(.light)
  }

  private func classicPill(_ title: String, width: CGFloat, height: CGFloat = 80,
                           cornerRadius: CGFloat, fill: LinearGradient) -> some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(fill)
      .padding(.all)
      .frame(width: width, height: height)
      .shadow(color: .black, radius: 10, x: 3, y: 3)
      .overlay(
        Text(title)
          .font(Font.custom("PaytoneOne-Regular", size: 20))
          .foregroundColor(.black)
      )
  }
}

struct ClassicDiceView: View {
  let n: Int
  let rollDice: Bool
  let spins: Int

  var body: some View {
    Image(rollDice ? "dice\(n)" : "diceRed\(n)")
      .resizable()
      .scaledToFit()
      .rotationEffect(.degrees(Double(spins) * 1080))
      .animation(.spring(response: 1.25), value: spins)
  }
}

struct ClassicInfoView: View {
  @Environment(\.dismiss) var dismiss

  var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()
      VStack {
        Text("Ship Cap'n Crew")
          .font(.title)
          .foregroundColor(.white)
          .bold()
        Spacer()
        Text("Roll the dice and once you have a 4 5 and 6, the remaining two dice add up to your point. You may hold and roll dice as you please, but you only get three rolls per turn.")
          .foregroundColor(.white)
          .padding(.horizontal)
        Text("On roll 3, when you press Roll, the game will automatically reset")
          .foregroundColor(.white)
          .padding(.top)
          .padding(.horizontal)
        Spacer()
        Button { dismiss() } label: {
          Text("Back To The Game")
            .foregroundColor(.white)
        }
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
