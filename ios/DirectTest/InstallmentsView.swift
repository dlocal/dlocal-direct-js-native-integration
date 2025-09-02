//
//  InstallmentsView.swift
//  DirectTest
//
//  Created by Adrian DeLeon on 21/8/25.
//

import SwiftUI
import WebKit

struct InstallmentsView: View {
    @StateObject private var webViewManager = WebViewManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var publicKey = "YOUR_PUBLIC_KEY"
    @State private var amount = "100"
    @State private var currency = "USD"
    @State private var country = "AR"
    @State private var bin = "411111"

    
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
                        
                        // Amount
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Amount")
                                .font(.headline)
                            TextField("Amount", text: $amount)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        // Currency
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Currency")
                                .font(.headline)
                            TextField("Currency", text: $currency)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Country
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Country Code")
                                .font(.headline)
                            TextField("Country Code", text: $country)
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
                        
                        // Get Installments Plan Button
                        Button("Get Installments Plan") {
                            if let amountInt = Int(amount) {
                                webViewManager.sendGetInstallmentsPlan(
                                    publicKey: publicKey,
                                    amount: amountInt,
                                    currency: currency,
                                    country: country,
                                    bin: bin
                                )
                            }
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
            .navigationTitle("Get Installments Plan")
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
    InstallmentsView()
}
