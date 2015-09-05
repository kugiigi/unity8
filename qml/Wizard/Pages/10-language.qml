/*
 * Copyright (C) 2013-2015 Canonical, Ltd.
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
import Ubuntu.Components 1.2
import Ubuntu.SystemSettings.LanguagePlugin 1.0
import Wizard 0.1
import ".." as LocalComponents

LocalComponents.Page {
    objectName: "languagePage"

    title: i18n.tr("Language")
    forwardButtonSourceComponent: forwardButton

    UbuntuLanguagePlugin {
        id: plugin
    }

    Component.onCompleted: {
        if (!modemManager.available) { // don't wait for the modem if it's not there
            print("== Modem manager not available, init language manually")
            init();
        }
    }

    Connections {
        target: modemManager
        onGotSimCardChanged: {
            print("== Got a usable SIM card, init language page");
//            print("SIM 1 languages:", simManager0.preferredLanguages);
//            print("SIM 1 country:", LocalePlugin.mccToCountryCode(simManager0.mobileCountryCode));
//            print("SIM 2 languages:", simManager1.preferredLanguages);
//            print("SIM 2 country:", LocalePlugin.mccToCountryCode(simManager1.mobileCountryCode));
            init();
        }
    }

    function init()
    {
        var detectedLang = "";
        // try to detect the language+country from the SIM card
        if (simManager0.present && simManager0.preferredLanguages.length > 0) {
            detectedLang = simManager0.preferredLanguages[0] + "_" + LocalePlugin.mccToCountryCode(simManager0.mobileCountryCode);
            print("SIM 0 detected lang:", detectedLang);
        } else if (simManager1.present && simManager1.preferredLanguages.length > 0) {
            detectedLang = simManager1.preferredLanguages[0] + "_" + LocalePlugin.mccToCountryCode(simManager1.mobileCountryCode);
            print("SIM 1 detected lang:", detectedLang);
        } else if (plugin.currentLanguage != -1) {
            detectedLang = plugin.languageCodes[plugin.currentLanguage];
            print("Using current language", detectedLang, "as default");
        } else {
            print("No lang detected, falling back to default (en_US)");
            detectedLang = "en_US"; // fallback to default lang
        }

        // preselect the detected language
        for (var i = 0; i < plugin.languageCodes.length; i++) {
            var code = plugin.languageCodes[i].split(".")[0]; // remove the encoding part, after dot (en_US.utf8 -> en_US)
            if (detectedLang === code) {
                print("Found detected language", detectedLang, "at index", i);
                languagesListView.currentIndex = i;
                languagesListView.positionViewAtIndex(i, ListView.Center);
                break;
            }
        }
    }

    Column {
        id: column
        anchors.fill: content

        ListView {
            id: languagesListView
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            currentIndex: plugin.currentLanguage
            snapMode: ListView.SnapToItem

            anchors {
                left: parent.left;
                right: parent.right;
            }

            height: column.height - column.spacing

            model: plugin.languageNames

            delegate: ListItem {
                id: itemDelegate

                readonly property bool isCurrent: index === ListView.view.currentIndex

                Label {
                    id: langLabel
                    text: modelData

                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }

                    fontSize: "medium"
                    font.weight: itemDelegate.isCurrent ? Font.Normal : Font.Light
                    color: textColor
                }

                Image {
                    anchors {
                        right: parent.right;
                        verticalCenter: parent.verticalCenter;
                    }
                    fillMode: Image.PreserveAspectFit
                    height: langLabel.height / 2

                    source: "data/Tick@30.png"
                    visible: itemDelegate.isCurrent
                }

                onClicked: {
                    languagesListView.currentIndex = index;
                    i18n.language = plugin.languageCodes[index];
                }
            }
        }
    }

    Component {
        id: forwardButton
        LocalComponents.StackButton {
            text: i18n.tr("Next")
            enabled: languagesListView.currentIndex
            onClicked: {
                if (plugin.currentLanguage !== languagesListView.currentIndex) {
                    plugin.currentLanguage = languagesListView.currentIndex;
                    print("Updating session locale:", plugin.languageCodes[plugin.currentLanguage]);
                    System.updateSessionLocale(plugin.languageCodes[plugin.currentLanguage]);
                }
                i18n.language = plugin.languageCodes[plugin.currentLanguage]; // re-notify of change after above call (for qlocale change)
                root.countryCode = plugin.languageCodes[plugin.currentLanguage].split('_')[1].split('.')[0]; // extract the country code, save it for the timezone page
                pageStack.next();
            }
        }
    }
}
