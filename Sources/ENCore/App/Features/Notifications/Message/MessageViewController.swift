/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import SnapKit
import UIKit

/// @mockable
protocol MessageViewControllable: ViewControllable {}

final class MessageViewController: ViewController, MessageViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    // MARK: - Init

    init(listener: MessageListener, theme: Theme, exposureDate: Date, messageManager: MessageManaging) {
        self.listener = listener
        self.messageManager = messageManager
        self.treatmentPerspectiveMessage = messageManager.getLocalizedTreatmentPerspective(withExposureDate: exposureDate)

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hasBottomMargin = true

        setThemeNavigationBar(withTitle: .contaminationChanceTitle)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: self,
                                                            action: #selector(didTapCloseButton(sender:)))

        internalView.infoView.actionHandler = { [weak self] in
            if let url = URL(string: .coronaTestPhoneNumber), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                self?.logError("Unable to open \(String.coronaTestPhoneNumber)")
            }
        }
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.messageWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - Private

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.messageWantsDismissal(shouldDismissViewController: true)
    }

    private lazy var internalView: MessageView = {
        MessageView(theme: self.theme, treatmentPerspectiveMessage: treatmentPerspectiveMessage)
    }()

    private weak var listener: MessageListener?
    private let messageManager: MessageManaging
    private let treatmentPerspectiveMessage: LocalizedTreatmentPerspective
}

private final class MessageView: View {

    // MARK: - Init

    init(theme: Theme, treatmentPerspectiveMessage: LocalizedTreatmentPerspective) {
        let config = InfoViewConfig(actionButtonTitle: .messageButtonTitle,
                                    headerImage: .messageHeader,
                                    headerBackgroundViewColor: theme.colors.headerBackgroundRed,
                                    stickyButtons: true)
        self.infoView = InfoView(theme: theme, config: config)
        self.treatmentPerspectiveMessage = treatmentPerspectiveMessage
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        let sections = treatmentPerspectiveMessage.paragraphs
            .map {
                InfoSectionTextView(theme: theme,
                                    title: $0.title.string,
                                    content: [$0.body])
            }

        infoView.addSections(sections)

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.edges.equalToSuperview()
        }
    }

    // MARK: - Private

    private let treatmentPerspectiveMessage: LocalizedTreatmentPerspective
    fileprivate let infoView: InfoView
}
