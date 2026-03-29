//
//  ContentView.swift
//  LoanCalculator
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CalculatorView()
                .tabItem {
                    Label("计算", systemImage: "calculator")
                }
                .tag(0)
        }
    }
}
