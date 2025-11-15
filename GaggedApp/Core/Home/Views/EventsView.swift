//
//  EventView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/9/25.
//

import SwiftUI

struct EventsView: View {
    
    @EnvironmentObject var eventsViewModel: EventsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    
    @Binding var hideTabBar: Bool
    @Binding var showEventView: Bool
    @Binding var showEventSearchView: Bool
    @Binding var selectedTab: TabBarItem
    
    @State var blurHeader: Bool = false
    @State var scrollOffset = CGPoint.zero
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0){
                    events
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .padding(.top, 120)
                .padding(.bottom, 64)
            }
            .onScrollPhaseChange({ oldPhase, newPhase, context in
                let newOffset = context.geometry.contentOffset
                if newOffset.y < scrollOffset.y {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hideTabBar = false
                    }
                }
                else if newOffset.y > scrollOffset.y && !(newOffset.y <= 10) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hideTabBar = true
                    }
                }
                scrollOffset = newOffset
                if newPhase.isScrolling {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        blurHeader = true
                    }
                }
                if newPhase == .decelerating  {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            blurHeader = false
                        }
                    })
                }
                if newPhase == .idle {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        blurHeader = false
                    }
                }
            })
            .ignoresSafeArea()
            .refreshable {
                Task {
                    try await eventsViewModel.fetchMoreEvents()
                }
            }
            VStack(spacing: 0){
                header
                    .frame(height: 55)
                    .background(Color.theme.background)
                    .opacity(blurHeader ? 0.9 : 1)
                Divider()
                Spacer()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -80 {
                        selectedTab = TabBarItem(iconName: "ProfileIcon", title: "Profile")
                        hideTabBar = false
                    }
                    if value.translation.width > 80 {
                        selectedTab = TabBarItem(iconName: "HomeIcon", title: "Home")
                        hideTabBar = false
                    }
                }
        )
        .task {
            Task {
                try await eventsViewModel.fetchEventsIfNeeded()
            }
        }
    }
    
    var header: some View {
        VStack(spacing: 0){
            HStack(spacing: 0){
                Image(systemName: "chevron.down")
                    .font(.title2)
                Text("Events")
                    .font(.title2)
                    .padding(.horizontal, 4)
                Text("San Marcos, TX")
                    .italic()
                    .font(.title2)
                    .padding(.horizontal, 8)
                    .foregroundStyle(Color.theme.darkBlue)
                Spacer()
                Image(systemName: "magnifyingglass")
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            print("Showing event search")
                            hideTabBar = true
                            showEventSearchView = true
                        }
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    var events: some View {
        ForEach(eventsViewModel.eventList) { event in
            MiniEventView(event: event)
                .onTapGesture {
                    print("Little Event Tapped")
                    print(event)
                    eventViewModel.setEvent(event: event)
                    hideTabBar = true
                    showEventView = true
                    Task {
                        eventViewModel.commentsIsLoading = true
                        try await eventViewModel.fetchComments()
                        eventViewModel.commentsIsLoading = false
                    }
                }
        }
    }
    
}

#Preview {
    EventsView(hideTabBar: .constant(false), showEventView: .constant(false), showEventSearchView: .constant(false), selectedTab: .constant(TabBarItem(iconName: "EventsIcon", title: "Events")))
        .environmentObject(EventsViewModel.previewModel())
}
