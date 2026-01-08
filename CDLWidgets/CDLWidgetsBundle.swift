//
//  CDLWidgetsBundle.swift
//  CDLWidgets
//
//  Created by Devan Desai on 2026-01-06.
//

import WidgetKit
import SwiftUI

@main
struct CDLWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CDLWidgets()
        CDLWidgetsControl()
        CDLWidgetsLiveActivity()
    }
}
