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
import Wizard 0.1
import ".." as LocalComponents

LocalComponents.Page {
    objectName: "countryPage"

    title: i18n.tr("Country")
    forwardButtonSourceComponent: forwardButton

    property string selectedCountry: ""
    readonly property var preferedCountries: LocalePlugin.countriesForLanguage(root.language)

    Component.onCompleted: {
        populateModel(preferedCountries);
    }

    function populateModel(preferedCountries)
    {
        var countries = LocalePlugin.countries();
        //console.log("All countries:" + countries);
        Object.keys(countries).map(function(code) { // prepare the object
            //console.log("Got country:" + code);
            return { "code": code, "country":  countries[code] || code,
                "dept": Object.keys(preferedCountries).indexOf(code) !== -1 ? i18n.tr("Prefered") : i18n.tr("All") };
        })
        .sort(function(a, b) { // group by status, sort by country name
            if (a.dept === b.dept) {
                 return a.country.localeCompare(b.country);
            } else if (a.dept === i18n.tr("Prefered")) {
                return -1
            }
            return 1
        })
        .forEach(function(country) { // build the model
            //console.debug("Adding country:" + country.code);
            if (country.code === "C") {
                return;
            }
            model.append(country);
        });
        busyIndicator.running = false;
        busyIndicator.visible = false;
    }

    function selectCountry(code, index)
    {
        selectedCountry = code
        regionsListView.currentIndex = index
    }

    ActivityIndicator {
        id: busyIndicator;

        anchors.centerIn: column;
        running: true;
    }

    Column {
        id: column
        anchors.fill: content

        ListView {
            id: regionsListView;

            boundsBehavior: Flickable.StopAtBounds;
            clip: true;
            currentIndex: -1
            snapMode: ListView.SnapToItem

            anchors {
                left: parent.left;
                right: parent.right;
            }

            height: column.height

            section {
                property: "dept";
                criteria: ViewSection.FullString;
                labelPositioning: ViewSection.InlineLabels | ViewSection.CurrentLabelAtStart
                delegate: Label {
                    fontSize: "large"
                }
            }

            model: ListModel {
                id: model;
            }

            delegate: ListItem {
                id: itemDelegate;

                readonly property bool isCurrent: index === ListView.view.currentIndex

                Label {
                    id: countryLabel
                    text: country;

                    anchors {
                        left: parent.left;
                        right: parent.right;
                        verticalCenter: parent.verticalCenter;
                    }

                    fontSize: "medium"
                    font.weight: itemDelegate.isCurrent ? Font.Normal : Font.Light
                    color: "black" // FIXME proper color from the theme
                }

                Image {
                    anchors {
                        right: parent.right;
                        verticalCenter: parent.verticalCenter;
                    }
                    fillMode: Image.PreserveAspectFit
                    height: countryLabel.paintedHeight

                    source: "data/Tick.png"
                    visible: itemDelegate.isCurrent
                }

                onClicked: {
                    selectCountry(code, index)
                    print("Selected country: " + selectedCountry)
                    print("Current index: " + ListView.view.currentIndex)
                }
            }
        }
    }

    Component {
        id: forwardButton
        LocalComponents.StackButton {
            text: i18n.tr("Next")
            enabled: selectedCountry !== ""
            onClicked: {
                //                if (selectedLanguage !== plugin.languageCodes[plugin.currentLanguage]) {
                //                    //plugin.currentLanguage = listview.currentIndex; // setting system language by some magic index? wtf
                //                    //System.updateSessionLanguage(selectedLanguage); // TODO
                //                    i18n.language = i18n.language; // re-notify of change after above call (for qlocale change)
                //                }
                // FIXME export the selected locale to the system
                pageStack.next()
            }
        }
    }
}
