//
//  FlutterAppInboxProvider.swift
//  exponea
//
//  Created by Adam Mihalik on 02/03/2023.
//

import Foundation
import ExponeaSDK

class FlutterAppInboxProvider: DefaultAppInboxProvider {
    
    private let appInboxStyle: AppInboxStyle

    override init() {
        appInboxStyle = AppInboxStyle()
    }

    init(_ style: AppInboxStyle) {
        appInboxStyle = style
    }

    override func getAppInboxButton() -> UIButton {
        let button = super.getAppInboxButton()
        if let buttonStyle = appInboxStyle.appInboxButton {
            buttonStyle.applyTo(button)
        }
        return button
    }

    override func getAppInboxListViewController() -> UIViewController {
        let listView = super.getAppInboxListViewController()
        guard let listView = listView as? AppInboxListViewController else {
            ExponeaSDK.Exponea.logger.log(.warning, message: "AppInbox list view impl mismatch - unable to customize")
            return listView
        }
        listView.loadViewIfNeeded()
        if let listViewStyle = appInboxStyle.listView {
            listViewStyle.applyTo(listView)
        }
        return listView
    }

    override func getAppInboxListTableViewCell(_ cell: UITableViewCell) -> UITableViewCell {
        guard let listViewItem = cell as? MessageItemCell else {
            ExponeaSDK.Exponea.logger.log(.warning, message: "AppInbox list item impl mismatch - unable to customize")
            return cell
        }
        if let listItemViewStyle = appInboxStyle.listView?.list?.item {
            listItemViewStyle.applyTo(listViewItem)
        }
        return listViewItem
    }

    override func getAppInboxDetailViewController(_ messageId: String) -> UIViewController {
        let detailView = super.getAppInboxDetailViewController(messageId)
        guard let detailView = detailView as? AppInboxDetailViewController else {
            ExponeaSDK.Exponea.logger.log(.warning, message: "AppInbox detail view impl mismatch - unable to customize")
            return detailView
        }
        guard let detailStyle = appInboxStyle.detailView else {
            return detailView
        }
        detailView.loadViewIfNeeded()
        detailView.actionsContainer.axis = .vertical
        detailView.actionsContainer.spacing = 8
        detailStyle.applyTo(detailView)
        return detailView
    }

}
