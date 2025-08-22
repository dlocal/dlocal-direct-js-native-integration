//
//  CreateTokenView.swift
//  DirectTest
//
//  Created by Adrian DeLeon on 21/8/25.
//

import SwiftUI
import WebKit

struct CreateTokenView: View {
    @StateObject private var webViewManager = WebViewManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var publicKey = "YOUR_PUBLIC_KEY"
    @State private var name = "JOHN DOE"
    @State private var cvv = "123"
    @State private var expirationMonth = "12"
    @State private var expirationYear = "30"
    @State private var pan = "4111111111111111"
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
                        
                        // Name
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Name")
                                .font(.headline)
                            TextField("Name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // CVV
                        VStack(alignment: .leading, spacing: 5) {
                            Text("CVV")
                                .font(.headline)
                            TextField("CVV", text: $cvv)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        // Expiration Month
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Expiration Month (MM)")
                                .font(.headline)
                            TextField("MM", text: $expirationMonth)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        // Expiration Year
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Expiration Year (YY)")
                                .font(.headline)
                            TextField("YY", text: $expirationYear)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        // PAN
                        VStack(alignment: .leading, spacing: 5) {
                            Text("PAN (Card Number)")
                                .font(.headline)
                            TextField("Card Number", text: $pan)
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
                        
                        // Create Token Button
                        Button("Create Token") {
                            webViewManager.sendCreateToken(
                                publicKey: publicKey,
                                name: name,
                                cvv: cvv,
                                expirationMonth: expirationMonth,
                                expirationYear: expirationYear,
                                pan: pan,
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
            .navigationTitle("Create Token")
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
    CreateTokenView()
}
