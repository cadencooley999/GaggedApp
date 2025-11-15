//
//  MiniEventView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/24/25.
//

import SwiftUI
import Foundation

struct MiniEventView: View {
    
    let event: EventModel
    
    @EnvironmentObject var eventsViewModel: EventsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    
    var body: some View {
        ZStack {
            VStack {
                GeometryReader { geo in
                    miniPostImage(url: event.imageUrl, height: 200, width: geo.size.width)
                }

            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            VStack {
                HStack {
                    Spacer()
                    Text(eventViewModel.timeUntilString(from: event.date))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(6)
                        .background(Color.theme.background.opacity(1).cornerRadius(10))
                        .frame(height: 20)
                }
                Spacer()
                HStack {
                    Text("\(event.name)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(6)
                        .background(Color.theme.background.opacity(1).cornerRadius(10))
                        .frame(height: 20)
                    Spacer()
                    HStack {
                        Text("\(event.rsvps)")
                            .fontWeight(.bold)
                            .font(.caption)
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(Color.theme.lightBlue)
                            .fontWeight(.bold)
                            .font(.caption)
                    }
                    .padding(6)
                    .background(Color.theme.background.opacity(1).cornerRadius(10))
                    .frame(height: 20)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            
        }
    }
}

