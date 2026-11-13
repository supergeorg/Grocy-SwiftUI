//
//  StockWidgetView.swift
//  Grocy Widget
//
//  Created by Georg Meissner on 06.12.25.
//

import SwiftUI
import WidgetKit

struct StockWidgetView: View {
    let entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var numExpiringSoon: Int {
        entry.summary?.dueSoon ?? 0
    }

    var numOverdue: Int {
        entry.summary?.overdue ?? 0
    }

    var numExpired: Int {
        entry.summary?.expired ?? 0
    }

    var numBelowStock: Int {
        entry.summary?.belowMinStock ?? 0
    }

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            largeWidget
        }
    }

    private var smallWidget: some View {
        Grid {
            GridRow {
                Label("\(numExpiringSoon)", systemImage: MySymbols.expiringSoon)
                    .foregroundStyle(Color(.GrocyColors.grocyYellow))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color(.GrocyColors.grocyYellowBackground))
                    .cornerRadius(8)
                Label("\(numOverdue)", systemImage: MySymbols.overdue)
                    .foregroundStyle(Color(.GrocyColors.grocyGray))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color(.GrocyColors.grocyGrayBackground))
                    .cornerRadius(8)
            }
            GridRow {
                Label("\(numExpired)", systemImage: MySymbols.expired)
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color(.GrocyColors.grocyRedBackground))
                    .cornerRadius(8)
                Label("\(numBelowStock)", systemImage: MySymbols.belowMinStock)
                    .foregroundStyle(Color(.GrocyColors.grocyBlue))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color(.GrocyColors.grocyBlueBackground))
                    .cornerRadius(8)
            }
        }
        .widgetURL(URL(string: "grocy://stock/filter/all"))
    }

    private var mediumWidget: some View {
        Grid {
            GridRow {
                Link(destination: URL(string: "grocy://stock/filter/\(ProductStatus.expiringSoon.caseName)")!) {
                    HStack {
                        Image(systemName: MySymbols.expiringSoon)
                        Text("\(numExpiringSoon)")
                            .font(.title3)
                        Spacer()
                        Text(ProductStatus.expiringSoon.rawValue)
                    }
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                    .foregroundStyle(Color(.GrocyColors.grocyYellow))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color(.GrocyColors.grocyYellowBackground))
                    .cornerRadius(8)
                }
                Link(destination: URL(string: "grocy://stock/filter/\(ProductStatus.overdue.caseName)")!) {
                    HStack {
                        Image(systemName: MySymbols.overdue)
                        Text("\(numOverdue)")
                            .font(.title3)
                        Spacer()
                        Text(ProductStatus.overdue.rawValue)
                    }
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                    .foregroundStyle(Color(.GrocyColors.grocyGray))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color(.GrocyColors.grocyGrayBackground))
                    .cornerRadius(8)
                }
            }
            GridRow {
                Link(destination: URL(string: "grocy://stock/filter/\(ProductStatus.expired.caseName)")!) {
                    HStack {
                        Image(systemName: MySymbols.expired)
                        Text("\(numExpired)")
                            .font(.title3)
                        Spacer()
                        Text(ProductStatus.expired.rawValue)
                    }
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color(.GrocyColors.grocyRedBackground))
                    .cornerRadius(8)
                }
                Link(destination: URL(string: "grocy://stock/filter/\(ProductStatus.belowMinStock.caseName)")!) {
                    HStack {
                        Image(systemName: MySymbols.belowMinStock)
                        Text("\(numBelowStock)")
                            .font(.title3)
                        Spacer()
                        Text(ProductStatus.belowMinStock.rawValue)
                    }
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                    .foregroundStyle(Color(.GrocyColors.grocyBlue))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color(.GrocyColors.grocyBlueBackground))
                    .cornerRadius(8)
                }
            }
        }
    }

    private var largeWidget: some View {
        Grid {
            GridRow {
                Link(destination: URL(string: "grocy://stock/filter/\(ProductStatus.expiringSoon.caseName)")!) {
                    VStack {
                        HStack {
                            Image(systemName: MySymbols.expiringSoon)
                            Text("\(numExpiringSoon)")
                        }
                        .font(.title)
                        Spacer()
                        Text(ProductStatus.expiringSoon.getDescription(amount: numExpiringSoon))
                    }
                    .padding()
                    .foregroundStyle(Color(.GrocyColors.grocyYellow))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color(.GrocyColors.grocyYellowBackground))
                    .cornerRadius(8)
                }
                Link(destination: URL(string: "grocy://stock/filter/\(ProductStatus.overdue.caseName)")!) {
                    VStack {
                        HStack {
                            Image(systemName: MySymbols.overdue)
                            Text("\(numOverdue)")
                        }
                        .font(.title)
                        Spacer()
                        Text(ProductStatus.overdue.getDescription(amount: numOverdue))
                    }
                    .padding()
                    .foregroundStyle(Color(.GrocyColors.grocyGray))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color(.GrocyColors.grocyGrayBackground))
                    .cornerRadius(8)
                }
            }
            GridRow {
                Link(destination: URL(string: "grocy://stock/filter/\(ProductStatus.expired.caseName)")!) {
                    VStack {
                        HStack {
                            Image(systemName: MySymbols.expired)
                            Text("\(numExpired)")
                        }
                        .font(.title)
                        Spacer()
                        Text(ProductStatus.expired.getDescription(amount: numExpired))
                    }
                    .padding()
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color(.GrocyColors.grocyRedBackground))
                    .cornerRadius(8)
                }
                Link(destination: URL(string: "grocy://stock/filter/\(ProductStatus.belowMinStock.caseName)")!) {
                    VStack {
                        HStack {
                            Image(systemName: MySymbols.belowMinStock)
                            Text("\(numBelowStock)")
                        }
                        .font(.title)
                        Spacer()
                        Text(ProductStatus.belowMinStock.getDescription(amount: numBelowStock))
                    }
                    .padding()
                    .foregroundStyle(Color(.GrocyColors.grocyBlue))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color(.GrocyColors.grocyBlueBackground))
                    .cornerRadius(8)
                }
            }
        }
    }
}

#Preview("Small", as: .systemSmall) {
    Grocy_Widget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), summary: WidgetStockSummary(dueSoon: 3, overdue: 1, expired: 2, belowMinStock: 4, updated: .now))
}

#Preview("Medium", as: .systemMedium) {
    Grocy_Widget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), summary: WidgetStockSummary(dueSoon: 3, overdue: 1, expired: 2, belowMinStock: 4, updated: .now))
}

#Preview("Large", as: .systemLarge) {
    Grocy_Widget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), summary: WidgetStockSummary(dueSoon: 3, overdue: 1, expired: 2, belowMinStock: 4, updated: .now))
}
