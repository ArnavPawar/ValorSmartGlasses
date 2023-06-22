//
//  ValorWatch.swift
//  SwifuiTest
//
//  Created by Arnav on 6/20/23.
//

import Foundation
import SwiftUI

struct WatchOSApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                MainContentView()
            }
        }
    }
}

struct MainContentView: View {
    var body: some View {
        VStack {
            Text("Welcome to WatchOS!")
                .font(.largeTitle)
                .padding()
            
            Spacer()
            
            Button(action: {
                // Perform action when the button is tapped
            }) {
                Text("Tap Me!")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
    }
}

