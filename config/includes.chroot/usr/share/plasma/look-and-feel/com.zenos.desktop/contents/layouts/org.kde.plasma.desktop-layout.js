import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid as Plasmoid

Plasmoid.Representation {
    id: root
    Layout.preferredWidth: PlasmaCore.Units.gridUnit * 20
    Layout.preferredHeight: PlasmaCore.Units.gridUnit * 20
    Layout.minimumWidth: PlasmaCore.Units.gridUnit * 10
    Layout.minimumHeight: PlasmaCore.Units.gridUnit * 10
}
