/*
 * Copyright (C) 2013,2015-2016 Canonical, Ltd.
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

#include "Greeter.h"
#include "UsersModel.h"
#include <QIdentityProxyModel>
#include <QLightDM/UsersModel>

#include <libintl.h>

// First, we define an internal class that wraps LightDM's UsersModel.  This
// class will modify some of the data coming from LightDM.  For example, we
// modify any empty Real Names into just normal Names.  We also add optional
// rows, depending on configuration.
// (We can't modify the data directly in UsersModel below because it won't sort
// using the modified data.)
class MangleModel : public QIdentityProxyModel
{
    Q_OBJECT

public:
    explicit MangleModel(QObject* parent=0);

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;

private:
    int guestRow() const;
};

MangleModel::MangleModel(QObject* parent)
  : QIdentityProxyModel(parent)
{
    setSourceModel(new QLightDM::UsersModel(this));
}

QVariant MangleModel::data(const QModelIndex &index, int role) const
{
    QVariant variantData;

    if (index.row() == guestRow() && index.column() == 0) {
        switch (role) {
        case QLightDM::UsersModel::NameRole:
            variantData = QStringLiteral("*guest"); break;
        case QLightDM::UsersModel::RealNameRole:
            variantData = gettext("Guest Session"); break;
        case QLightDM::UsersModel::LoggedInRole:
            variantData = false; break;
        case QLightDM::UsersModel::SessionRole:
            variantData = Greeter::instance()->defaultSessionHint(); break;
        }
    } else {
        variantData = QIdentityProxyModel::data(index, role);
    }

    // If user's real name is empty, switch to unix name
    if (role == QLightDM::UsersModel::RealNameRole && variantData.toString().isEmpty()) {
        variantData = QIdentityProxyModel::data(index, QLightDM::UsersModel::NameRole);
    } else if (role == QLightDM::UsersModel::BackgroundPathRole && variantData.toString().startsWith('#')) {
        const QString stringData = "data:image/svg+xml,<svg><rect width='100%' height='100%' fill='" + variantData.toString() + "'/></svg>";
        variantData = stringData;
    }

    return variantData;
}

int MangleModel::guestRow() const
{
    return Greeter::instance()->hasGuestAccount() ?
           QIdentityProxyModel::rowCount() : -1;
}

int MangleModel::rowCount(const QModelIndex &parent) const
{
    auto count = QIdentityProxyModel::rowCount(parent);

    if (Greeter::instance()->hasGuestAccount() && !parent.isValid())
        count++;

    return count;
}

QModelIndex MangleModel::index(int row, int column, const QModelIndex &parent) const
{
    if (row == guestRow() && !parent.isValid()) {
        return createIndex(row, column);
    } else {
        return QIdentityProxyModel::index(row, column, parent);
    }
}

// **** Now we continue with actual UsersModel class ****

UsersModel::UsersModel(QObject* parent)
  : UnitySortFilterProxyModelQML(parent)
{
    setModel(new MangleModel(this));
    setSortCaseSensitivity(Qt::CaseInsensitive);
    setSortLocaleAware(true);
    setSortRole(QLightDM::UsersModel::RealNameRole);
    sort(0);
}

bool UsersModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    auto leftName = source_left.data(QLightDM::UsersModel::NameRole);
    auto rightName = source_right.data(QLightDM::UsersModel::NameRole);

    if (leftName == QStringLiteral("*guest"))
        return false;
    if (rightName == QStringLiteral("*guest"))
        return true;

    return UnitySortFilterProxyModelQML::lessThan(source_left, source_right);
}

#include "UsersModel.moc"
