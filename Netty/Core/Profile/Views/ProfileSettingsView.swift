//
//  ProfileSettingsView.swift
//  Netty
//
//  Created by Danny on 9/12/22.
//

import SwiftUI

struct ProfileSettingsView: View {
    
    @EnvironmentObject private var logInAndOutViewModel: LogInAndOutViewModel
    
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            List {
                
                Section {
                    Button {
                        print("privacy")
                    } label: {
                        Text("Privacy")
                    }
                    
                    Button {
                        print("privacy")
                    } label: {
                        Label("Privacy", systemImage: "lock.fill")
                    }
                    
                    Button {
                        print("privacy")
                    } label: {
                        HStack {
                            Text("Privacy")
                            
                            Image(systemName: "lock.fill")
                        }
                    }
                    
                    Button {
                        print("privacy")
                    } label: {
                        HStack {
                            Text("Privacy")
                            
                            Spacer(minLength: 0)
                            
                            Image(systemName: "lock.fill")
                        }
                    }
                    
                }
                
                Section {
                    Button {
                        print("privacy")
                    } label: {
                        HStack {
                            Text("Privacy")
                            
                            Spacer(minLength: 0)
                            
                            Image(systemName: "chevron.forward")
                        }
                    }
                    
                    Button {
                        print("privacy")
                    } label: {
                        HStack {
                            Label("Privacy", systemImage: "lock.fill")

                            Spacer(minLength: 0)
                            
                            Image(systemName: "chevron.forward")
                        }
                    }
                    
                    Button {
                        print("privacy")
                    } label: {
                        HStack {
                            Text("Privacy")
                            
                            Image(systemName: "lock.fill")
                            
                            Spacer(minLength: 0)
                            
                            Image(systemName: "chevron.forward")
                        }
                    }
                    
                    Button {
                        print("privacy")
                    } label: {
                        HStack {
                            Text("Privacy")
                            
                            Spacer(minLength: 0)
                            
                            Image(systemName: "lock.fill")
                            
                            Image(systemName: "chevron.forward")
                        }
                    }
                    
                }
                
                // Log Out
                Section {
                    Button(role: .destructive, action: {
                        Task {
                            isLoading = true
                            await logInAndOutViewModel.logOut()
                            isLoading = false
                        }
                    }) {
                        Text("Log Out")
                    }
                }
            }
            .disabled(isLoading)
            
            if isLoading {
                ProgressView()
            }
        }
    }
}

struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSettingsView()
        ProfileSettingsView()
    }
}
