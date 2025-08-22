//
//  BinInfoView.swift
//  DirectTest
//
//  Created by Adrian DeLeon on 21/8/25.
//

import SwiftUI
import WebKit

struct BinInfoView: View {
    @StateObject private var webViewManager = WebViewManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var publicKey = "YOUR_PUBLIC_KEY"
    @State private var bin = "411111"
    @State private var country = "AR"

    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // WebView Status
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 100)
                    
                    VStack {
                        Text("dLocal Direct SDK")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("WebView Status: \(webViewManager.webViewStatus)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if webViewManager.webViewStatus == "Ready" {
                            Text("SDK loaded successfully")
                                .foregroundColor(.green)
                        } else {
                            Text("Initializing...")
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Form Fields
                ScrollView {
                    VStack(spacing: 15) {
                        // Public Key
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Public Key")
                                .font(.headline)
                            TextField("Public Key", text: $publicKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // BIN
                        VStack(alignment: .leading, spacing: 5) {
                            Text("BIN (Bank Identification Number)")
                                .font(.headline)
                            TextField("BIN", text: $bin)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        // Country
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Country Code")
                                .font(.headline)
                            TextField("Country Code", text: $country)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Get Bin Information Button
                        Button("Get Bin Information") {
                            webViewManager.sendGetBinInformation(
                                publicKey: publicKey,
                                bin: bin,
                                country: country
                            )
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        // Response Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Response:")
                                .font(.headline)
                            
                            ScrollView {
                                Text(webViewManager.responseText)
                                    .font(.system(.body, design: .monospaced))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .frame(height: 200)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Get Bin Information")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(false)
            .onAppear {
                webViewManager.initializeWebView()
            }
        }
        .onReceive(webViewManager.$webViewStatus) { status in
            if status == "Ready" {
                // WebView is ready
            }
        }
    }
}

#Preview {
    BinInfoView()
}
