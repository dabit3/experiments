import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func applicationDidFinishLaunching(_ application: UIApplication) {
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.rootViewController = DeckController()
    window.makeKeyAndVisible()
    self.window = window
    UIApplication.shared.isIdleTimerDisabled = true
  }
}

@MainActor
final class DeckController: UIViewController {
  private let session = Session()
  private var deck: DeckView!
  private let stage = UIView(frame: CGRect(x: 0, y: 0, width: 1000, height: 440))
  private let lobby = UIView(frame: CGRect(x: 186, y: 71, width: 598, height: 355))
  private let serverField = UITextField()
  private let nameField = UITextField()
  private let roomField = UITextField()
  private let info = UILabel()
  private let roster = UILabel()
  private let offsetLabel = UILabel()
  private let speedLabel = UILabel()
  private let preview = UIButton(type: .system)
  private let create = UIButton(type: .system)
  private let join = UIButton(type: .system)
  private let ready = UIButton(type: .system)
  private let back = UIButton(type: .system)
  private let offsetSlider = UISlider()
  private let speedSlider = UISlider()
  private var displayLink: CADisplayLink?
  private var previewing = false
  private var oldPhase = ""
  private let cyan = UIColor(red: 0.2, green: 0.82, blue: 1, alpha: 1)

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
  override var prefersStatusBarHidden: Bool { true }
  override var prefersHomeIndicatorAutoHidden: Bool { true }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    deck = DeckView(session: session)
    stage.addSubview(deck)
    view.addSubview(stage)
    buildLobby()
    deck.onExit = { [weak self] in self?.confirmExit() }
    session.onChange = { [weak self] in self?.refresh() }
    displayLink = CADisplayLink(target: self, selector: #selector(frame))
    displayLink?.preferredFrameRateRange = CAFrameRateRange(
      minimum: 60, maximum: 120, preferred: 60)
    displayLink?.add(to: .main, forMode: .common)
    configureArguments()
    refresh()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let area = view.safeAreaLayoutGuide.layoutFrame
    let scale = min(area.width / 1000, area.height / 440)
    stage.transform = CGAffineTransform(scaleX: scale, y: scale)
    stage.center = CGPoint(x: area.midX, y: area.midY)
  }

  @objc private func frame() { deck.animate() }

  private func label(_ title: String, frame: CGRect, size: CGFloat = 12, color: UIColor = .white)
    -> UILabel
  {
    let label = UILabel(frame: frame)
    label.text = title
    label.textColor = color
    label.font = .monospacedSystemFont(ofSize: size, weight: .medium)
    lobby.addSubview(label)
    return label
  }

  private func field(_ field: UITextField, placeholder: String, frame: CGRect) {
    field.frame = frame
    field.placeholder = placeholder
    field.backgroundColor = UIColor(white: 0.035, alpha: 1)
    field.textColor = .white
    field.tintColor = cyan
    field.font = .monospacedSystemFont(ofSize: 15, weight: .medium)
    field.autocorrectionType = .no
    field.autocapitalizationType = .none
    field.layer.borderColor = cyan.withAlphaComponent(0.35).cgColor
    field.layer.borderWidth = 1
    field.layer.cornerRadius = 4
    field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    field.leftViewMode = .always
    field.accessibilityLabel = placeholder
    lobby.addSubview(field)
  }

  private func button(
    _ button: UIButton, title: String, frame: CGRect, action: Selector, primary: Bool = false
  ) {
    button.frame = frame
    button.setTitle(title, for: .normal)
    button.titleLabel?.font = .monospacedSystemFont(ofSize: 13, weight: .bold)
    button.setTitleColor(primary ? .black : cyan, for: .normal)
    button.backgroundColor = primary ? cyan : cyan.withAlphaComponent(0.09)
    button.layer.borderWidth = 1
    button.layer.borderColor = cyan.withAlphaComponent(0.6).cgColor
    button.layer.cornerRadius = 3
    button.addTarget(self, action: action, for: .touchUpInside)
    lobby.addSubview(button)
  }

  private func buildLobby() {
    lobby.backgroundColor = UIColor(red: 0.035, green: 0.065, blue: 0.105, alpha: 0.98)
    lobby.layer.borderColor = cyan.withAlphaComponent(0.5).cgColor
    lobby.layer.borderWidth = 1
    stage.addSubview(lobby)
    _ = label(
      "ENTER THE AFTERHOURS", frame: CGRect(x: 23, y: 13, width: 430, height: 30), size: 24,
      color: cyan)
    _ = label(
      "A TWO-DJ EX SCORE BATTLE / ONE SYNCHRONIZED TRACK",
      frame: CGRect(x: 24, y: 45, width: 550, height: 18), size: 10, color: .lightGray)
    _ = label(
      "SERVER ADDRESS", frame: CGRect(x: 24, y: 71, width: 400, height: 17), size: 10,
      color: .lightGray)
    field(
      serverField, placeholder: "WebSocket server",
      frame: CGRect(x: 24, y: 92, width: 550, height: 38))
    serverField.text = session.address
    serverField.keyboardType = .URL
    _ = label(
      "GUEST DJ", frame: CGRect(x: 24, y: 140, width: 200, height: 16), size: 10, color: .lightGray)
    _ = label(
      "ROOM CODE • BLANK TO CREATE", frame: CGRect(x: 272, y: 140, width: 305, height: 16),
      size: 10, color: .lightGray)
    field(
      nameField, placeholder: "Guest name", frame: CGRect(x: 24, y: 160, width: 232, height: 38))
    nameField.text = session.guest
    field(
      roomField, placeholder: "Room code", frame: CGRect(x: 272, y: 160, width: 302, height: 38))
    roomField.autocapitalizationType = .allCharacters
    button(
      create, title: "CREATE ROOM", frame: CGRect(x: 24, y: 213, width: 232, height: 42),
      action: #selector(createRoom), primary: true)
    button(
      join, title: "JOIN ROOM", frame: CGRect(x: 272, y: 213, width: 302, height: 42),
      action: #selector(joinRoom))
    button(
      ready, title: "READY / START", frame: CGRect(x: 24, y: 213, width: 422, height: 42),
      action: #selector(readyUp), primary: true)
    button(
      back, title: "LEAVE", frame: CGRect(x: 459, y: 213, width: 115, height: 42),
      action: #selector(leaveRoom))
    roster.frame = CGRect(x: 24, y: 153, width: 550, height: 48)
    roster.font = .monospacedSystemFont(ofSize: 17, weight: .bold)
    roster.textColor = .white
    roster.numberOfLines = 2
    lobby.addSubview(roster)
    offsetLabel.frame = CGRect(x: 24, y: 269, width: 240, height: 18)
    speedLabel.frame = CGRect(x: 272, y: 269, width: 190, height: 18)
    for label in [offsetLabel, speedLabel] {
      label.font = .monospacedSystemFont(ofSize: 10, weight: .medium)
      label.textColor = .lightGray
      lobby.addSubview(label)
    }
    offsetSlider.frame = CGRect(x: 24, y: 286, width: 229, height: 28)
    offsetSlider.minimumValue = -100
    offsetSlider.maximumValue = 100
    offsetSlider.value = Float(session.calibration)
    offsetSlider.tintColor = cyan
    offsetSlider.accessibilityLabel = "Timing offset milliseconds"
    offsetSlider.addTarget(self, action: #selector(optionsChanged), for: .valueChanged)
    lobby.addSubview(offsetSlider)
    speedSlider.frame = CGRect(x: 272, y: 286, width: 177, height: 28)
    speedSlider.minimumValue = 1.2
    speedSlider.maximumValue = 3.5
    speedSlider.value = Float(session.speed)
    speedSlider.tintColor = cyan
    speedSlider.accessibilityLabel = "Note scroll speed"
    speedSlider.addTarget(self, action: #selector(optionsChanged), for: .valueChanged)
    lobby.addSubview(speedSlider)
    button(
      preview, title: "LISTEN", frame: CGRect(x: 466, y: 280, width: 108, height: 32),
      action: #selector(togglePreview))
    info.frame = CGRect(x: 24, y: 323, width: 550, height: 22)
    info.font = .monospacedSystemFont(ofSize: 10, weight: .medium)
    info.textColor = cyan
    info.adjustsFontSizeToFitWidth = true
    lobby.addSubview(info)
    optionsChanged()
  }

  private func readFields() {
    session.address = serverField.text ?? session.address
    session.guest = nameField.text ?? session.guest
    session.code = (roomField.text ?? "").trimmingCharacters(in: .whitespaces).uppercased()
    view.endEditing(true)
    previewing = false
    session.audio.stop()
    preview.setTitle("LISTEN", for: .normal)
  }

  @objc private func createRoom() {
    readFields()
    session.connect(create: true)
  }
  @objc private func joinRoom() {
    readFields()
    session.connect(create: false)
  }
  @objc private func readyUp() {
    if session.connected { session.ready() } else { session.connect(create: false) }
  }
  @objc private func leaveRoom() {
    session.leave()
    roomField.text = ""
  }

  @objc private func togglePreview() {
    previewing.toggle()
    if previewing { session.audio.start(round: -1, songTime: 0) } else { session.audio.stop() }
    preview.setTitle(previewing ? "STOP" : "LISTEN", for: .normal)
  }

  @objc private func optionsChanged() {
    session.calibration = Double(offsetSlider.value.rounded())
    session.speed = (Double(speedSlider.value) * 10).rounded() / 10
    UserDefaults.standard.set(session.calibration, forKey: "calibration")
    UserDefaults.standard.set(session.speed, forKey: "speed")
    offsetLabel.text = "TIMING \(Int(session.calibration))ms / + SHIFTS LATER"
    speedLabel.text = "HI-SPEED ×\(String(format: "%.1f", session.speed))"
  }

  private func refresh() {
    let inRoom = session.state != nil
    let phase = session.state?.phase ?? ""
    lobby.isHidden = phase == "playing" || phase == "result"
    create.isHidden = inRoom
    join.isHidden = inRoom
    ready.isHidden = !inRoom
    back.isHidden = !inRoom
    nameField.isHidden = inRoom
    roomField.isHidden = inRoom
    roster.isHidden = !inRoom
    serverField.isEnabled = !inRoom
    info.text = session.status
    if let state = session.state {
      roster.text = state.players.map {
        "\($0.ready ? "READY" : "STANDBY")  \($0.name)  \($0.online ? "●" : "○")"
      }.joined(separator: "\n")
      ready.setTitle(
        !session.connected
          ? "RECONNECT" : session.me?.ready == true ? "CANCEL READY" : "READY / START", for: .normal
      )
    }
    if phase != oldPhase {
      oldPhase = phase
      if lobby.isHidden {
        view.endEditing(true)
        deck.becomeFirstResponder()
      }
    }
  }

  private func confirmExit() {
    let alert = UIAlertController(
      title: "Leave the decks?",
      message: "The match continues for your rival. Your scores are kept until the room expires.",
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Keep playing", style: .cancel))
    alert.addAction(
      UIAlertAction(title: "Leave", style: .destructive) { [weak self] _ in self?.leaveRoom() })
    present(alert, animated: true)
  }

  private func configureArguments() {
    let args = ProcessInfo.processInfo.arguments
    func value(_ flag: String) -> String? {
      guard let index = args.firstIndex(of: flag), index + 1 < args.count else { return nil }
      return args[index + 1]
    }
    if let name = value("--name") {
      session.guest = name
      nameField.text = name
    }
    if let address = value("--server") {
      session.address = address
      serverField.text = address
    }
    if let room = value("--room") {
      session.code = room
      roomField.text = room
    }
    session.auto = args.contains("--auto")
    session.autoRematch = args.contains("--auto-rematch")
    session.autoDelay = Double(value("--delay-ms") ?? "0") ?? 0
    if args.contains("--connect") {
      session.connect(create: args.contains("--create"))
    }
  }
}
