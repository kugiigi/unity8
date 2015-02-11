/*
 * Copyright (C) 2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import Ubuntu.Components 1.1

Item {
    id: root

    property alias active: loader.active
    property bool paused

    property Item launcher
    property Item panel
    property Item stages
    property Item overlay

    readonly property bool launcherEnabled: loader.item ? loader.item.launcherEnabled : true
    readonly property bool stagesEnabled: loader.item ? loader.item.stagesEnabled : true
    readonly property bool panelEnabled: loader.item ? loader.item.panelEnabled : true
    readonly property bool panelContentEnabled: loader.item ? loader.item.panelContentEnabled : true
    readonly property bool running: loader.item ? loader.item.running : false

    function finish() {
        if (loader.item) {
            loader.item.finish();
        }
    }

    signal finished()

    Loader {
        id: loader
        anchors.fill: parent
        source: "TutorialContent.qml"

        Binding {
            target: loader.item
            property: "paused"
            value: root.paused
        }

        Binding {
            target: loader.item
            property: "launcher"
            value: root.launcher
        }

        Binding {
            target: loader.item
            property: "panel"
            value: root.panel
        }

        Binding {
            target: loader.item
            property: "stages"
            value: root.stages
        }

        Binding {
            target: loader.item
            property: "overlay"
            value: root.overlay
        }

        Connections {
            target: loader.item
            onFinished: root.finished()
        }
    }
}
