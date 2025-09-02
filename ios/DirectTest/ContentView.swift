//
//  ContentView.swift
//  DirectTest
//
//  Created by Adrian DeLeon on 21/8/25.
//

import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("dLocal Direct SDK")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Test Application")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                // Description
                Text("Select an option to test the dLocal Direct SDK functionality")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Navigation Buttons
                VStack(spacing: 20) {
                    NavigationLink(destination: CreateTokenView()) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .font(.title2)
                            Text("Create Token")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: BinInfoView()) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                            Text("Get Bin Information")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: InstallmentsView()) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle.fill")
                                .font(.title2)
                            Text("Get Installments Plan")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Footer
                VStack(spacing: 5) {
                    Text("Powered by dLocal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Direct SDK Integration")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("dLocal Direct SDK")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    ContentView()
}

#Preview {
    ContentView()
}
