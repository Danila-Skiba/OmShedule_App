import Flutter
import QuartzCore
import UIKit

/// Factory for creating iOS 26 native segmented control platform views
class iOS26SegmentedControlViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return iOS26SegmentedControlView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Native iOS 26 segmented control implementation
class iOS26SegmentedControlView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var segmentedControl: UISegmentedControl!
    private var channel: FlutterMethodChannel
    private var controlId: Int
    private var isDark: Bool = false
    private var tintColor: UIColor?
    private var textColor: UIColor?
    private var selectedTextColor: UIColor?

    // ФОРК: когда пользователь сам тапнул по сегменту. Нужно, чтобы отличить
    // смену темы, вызванную этим тапом (её надо отложить), от внешней
    // (системный тёмный режим, смена темы с другого экрана — применяем сразу).
    private var lastUserSelectionAt: CFTimeInterval = -.greatestFiniteMagnitude
    private var pendingThemeWork: DispatchWorkItem?

    /// Длительность анимации индикатора UISegmentedControl с запасом.
    private static let selectionAnimationDuration: CFTimeInterval = 0.35

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)

        if let config = args as? [String: Any] {
            controlId = config["id"] as? Int ?? 0
            isDark = config["isDark"] as? Bool ?? false
        } else {
            controlId = 0
        }

        channel = FlutterMethodChannel(
            name: "adaptive_platform_ui/ios26_segmented_control_\(controlId)",
            binaryMessenger: messenger
        )

        super.init()

        createNativeSegmentedControl(with: args)

        channel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }
    }

    func view() -> UIView {
        return _view
    }

    private func createNativeSegmentedControl(with args: Any?) {
        segmentedControl = UISegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.isUserInteractionEnabled = true
        _view.isUserInteractionEnabled = true

        if let config = args as? [String: Any] {
            // Check for SF symbols first
            if let sfSymbols = config["sfSymbols"] as? [String], !sfSymbols.isEmpty {
                // Use SF symbols for segments
                for (index, symbolName) in sfSymbols.enumerated() {
                    if let image = UIImage(systemName: symbolName) {
                        segmentedControl.insertSegment(with: image, at: index, animated: false)
                    } else {
                        // Fallback if symbol not found
                        print("⚠️ SF Symbol not found: \(symbolName)")
                    }
                }

                // Apply icon size if provided
                if let iconSizeNumber = config["iconSize"] as? NSNumber {
                    let iconSize = CGFloat(iconSizeNumber.doubleValue)
                    let configuration = UIImage.SymbolConfiguration(pointSize: iconSize)
                    for i in 0..<segmentedControl.numberOfSegments {
                        if let image = segmentedControl.imageForSegment(at: i) {
                            segmentedControl.setImage(image.withConfiguration(configuration), forSegmentAt: i)
                        }
                    }
                }

                // Apply icon color if provided
                if let iconColorValue = config["iconColor"] as? Int {
                    let iconColor = colorFromARGB(iconColorValue)
                    segmentedControl.setTitleTextAttributes([.foregroundColor: iconColor], for: .normal)
                }
            }
            // Otherwise use labels
            else if let labels = config["labels"] as? [String] {
                for (index, label) in labels.enumerated() {
                    segmentedControl.insertSegment(withTitle: label, at: index, animated: false)
                }
            }

            // Set enabled state
            if let enabled = config["enabled"] as? Bool {
                segmentedControl.isEnabled = enabled
            }

            // Set tint color if provided
            if let tintColorValue = config["tintColor"] as? Int {
                tintColor = colorFromARGB(tintColorValue)
            }

            if let textColorValue = config["textColor"] as? Int {
                textColor = colorFromARGB(textColorValue)
            }
            if let selectedTextColorValue = config["selectedTextColor"] as? Int {
                selectedTextColor = colorFromARGB(selectedTextColorValue)
            }

            // Set selected index
            if let selectedIndex = config["selectedIndex"] as? Int, selectedIndex >= 0 {
                segmentedControl.selectedSegmentIndex = selectedIndex
            }

            // Apply dark mode
            if let isDark = config["isDark"] as? Bool {
                if #available(iOS 13.0, *) {
                    _view.overrideUserInterfaceStyle = isDark ? .dark : .light
                }
            }
        }

        applyTheme()

        _view.addSubview(segmentedControl)
        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            segmentedControl.topAnchor.constraint(equalTo: _view.topAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
        ])

        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    private func colorFromARGB(_ argb: Int) -> UIColor {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    private func applyTheme() {
        let normalTextColor = textColor ?? .label
        let selectedColor = selectedTextColor ?? normalTextColor
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: normalTextColor,
            .font: font,
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: selectedColor,
            .font: font,
        ]
        let disabledAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: normalTextColor.withAlphaComponent(0.5),
            .font: font,
        ]

        if let tintColor = tintColor {
            segmentedControl.selectedSegmentTintColor = tintColor
        }
        segmentedControl.setTitleTextAttributes(normalAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedAttributes, for: .selected)
        segmentedControl.setTitleTextAttributes(selectedAttributes, for: [.selected, .highlighted])
        segmentedControl.setTitleTextAttributes(selectedAttributes, for: [.selected, .focused])
        segmentedControl.setTitleTextAttributes(disabledAttributes, for: .disabled)
        // ФОРК: layoutIfNeeded() убран. Синхронный layout обрывал анимацию
        // индикатора, когда тема менялась одновременно с выбором сегмента
        // (переключатель «Светлая/Тёмная» в настройках — ровно этот случай).
        // setNeedsLayout() планирует перерисовку на следующий цикл штатно.
        segmentedControl.setNeedsLayout()
    }

    @objc private func segmentChanged() {
        // ФОРК: засекаем тап, чтобы отложить вызванную им же смену темы
        // (см. setBrightness) до конца анимации индикатора.
        lastUserSelectionAt = CACurrentMediaTime()

        // ФОРК: здесь был вызов applyTheme(). Он заканчивается
        // setNeedsLayout() + layoutIfNeeded(), а синхронный layout обрывает
        // анимацию индикатора UISegmentedControl на первом же кадре — тап по
        // неактивному сегменту выглядел как мгновенный скачок (перетаскивание
        // не страдало, там неявной анимации нет).
        //
        // Вызов не нужен: атрибуты заголовков зарегистрированы для состояний
        // .normal/.selected ещё при создании, и UIKit сам выбирает нужные;
        // выбор сегмента тему не меняет.
        channel.invokeMethod("valueChanged", arguments: ["index": segmentedControl.selectedSegmentIndex])

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    /// ФОРК: тело бывшего обработчика `setBrightness`, вынесенное отдельно,
    /// чтобы его можно было выполнить как сразу, так и отложенно.
    private func applyThemeConfig(_ args: [String: Any]) {
        pendingThemeWork = nil

        if let dark = args["isDark"] as? Bool {
            isDark = dark
            if #available(iOS 13.0, *) {
                let style: UIUserInterfaceStyle = dark ? .dark : .light
                if _view.overrideUserInterfaceStyle != style {
                    _view.overrideUserInterfaceStyle = style
                }
            }
        }
        if let tintColorValue = args["tintColor"] as? Int {
            tintColor = colorFromARGB(tintColorValue)
        }
        if let textColorValue = args["textColor"] as? Int {
            textColor = colorFromARGB(textColorValue)
        }
        if let selectedTextColorValue = args["selectedTextColor"] as? Int {
            selectedTextColor = colorFromARGB(selectedTextColorValue)
        }

        applyTheme()
    }

    deinit {
        // ФОРК: отложенная смена темы не должна пережить саму вью.
        pendingThemeWork?.cancel()
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setSelectedIndex":
            if let args = call.arguments as? [String: Any],
               let index = args["index"] as? Int {
                // ФОРК: присваивание selectedSegmentIndex никогда не
                // анимируется. После тапа Flutter возвращает сюда эхом тот же
                // индекс, который нативный контрол уже выбрал сам, и это
                // присваивание вторично сбивало анимацию. Пишем, только если
                // значение действительно другое (программная смена извне).
                if index >= 0 && index < segmentedControl.numberOfSegments {
                    if segmentedControl.selectedSegmentIndex != index {
                        segmentedControl.selectedSegmentIndex = index
                    }
                } else if index == -1 {
                    if segmentedControl.selectedSegmentIndex != UISegmentedControl.noSegment {
                        segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
                    }
                }
            }
            result(nil)

        case "setBrightness":
            if let args = call.arguments as? [String: Any] {
                // ФОРК: если тему меняет сам тап по этому контролу
                // (переключатель «Светлая/Тёмная»), применяем её не сразу.
                // Запись overrideUserInterfaceStyle — это trait-change: UIKit
                // заново разрешает динамические цвета и перекладывает сабвью,
                // и индикатор прыгает в конечное положение, не доиграв.
                // Ждём, пока анимация выбора закончится.
                //
                // Смену темы извне (системный тёмный режим, другой экран)
                // это не задерживает: там тапа не было и окно уже истекло.
                let elapsed = CACurrentMediaTime() - lastUserSelectionAt
                let remaining = Self.selectionAnimationDuration - elapsed

                pendingThemeWork?.cancel()
                pendingThemeWork = nil

                if remaining > 0 {
                    let work = DispatchWorkItem { [weak self] in
                        self?.applyThemeConfig(args)
                    }
                    pendingThemeWork = work
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + remaining,
                        execute: work
                    )
                } else {
                    applyThemeConfig(args)
                }
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
