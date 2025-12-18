//
//  EventView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/9/25.
//
//
//import SwiftUI
//
//struct EventsView: View {
//    
//    func safeArea() -> UIEdgeInsets {
//        guard
//            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//            let window = scene.windows.first
//        else { return .zero }
//
//        return window.safeAreaInsets
//    }
//    
//    @EnvironmentObject var eventsViewModel: EventsViewModel
//    @EnvironmentObject var eventViewModel: EventViewModel
//    @EnvironmentObject var locationManager: LocationManager
//    
//    @Binding var hideTabBar: Bool
//    @Binding var showEventView: Bool
//    @Binding var selectedTab: TabBarItem
//    
//    @State var scrollOffset = CGPoint.zero
//    
//    var body: some View {
//        ZStack {
//            Color.theme.background
//                .ignoresSafeArea()
//            ScrollView {
//                VStack(spacing: 0){
//                    events
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 4)
//                }
//                .padding(.top, 60 + safeArea().top)
//                .padding(.bottom, 64)
//            }
//            .onScrollPhaseChange({ oldPhase, newPhase, context in
//                let newOffset = context.geometry.contentOffset
//                if newOffset.y < scrollOffset.y {
//                    withAnimation(.easeInOut(duration: 0.2)) {
//                        hideTabBar = false
//                    }
//                }
//                else if newOffset.y > scrollOffset.y && !(newOffset.y <= 10) {
//                    withAnimation(.easeInOut(duration: 0.2)) {
//                        hideTabBar = true
//                    }
//                }
//                scrollOffset = newOffset
//            })
//            .ignoresSafeArea()
//            .refreshable {
//                Task {
//                    try await eventsViewModel.fetchMoreEvents(cities: locationManager.citiesInRange)
//                }
//            }
//        }
////        .gesture(
////            DragGesture()
////                .onEnded { value in
////                    if value.translation.width < -80 {
////                        selectedTab = TabBarItem(iconName: "PollIcon", title: "Polls")
////                        hideTabBar = false
////                    }
////                    if value.translation.width > 80 {
////                        selectedTab = TabBarItem(iconName: "HomeIcon", title: "Home")
////                        hideTabBar = false
////                    }
////                }
////        )
//        .task {
//            Task {
//                try await eventsViewModel.fetchEventsIfNeeded(cities: locationManager.citiesInRange)
//            }
//        }
//    }
//    
//    var events: some View {
//        ForEach(eventsViewModel.eventList) { event in
//            MiniEventView(event: event)
//                .onTapGesture {
//                    print("Little Event Tapped")
//                    print(event)
//                    eventViewModel.setEvent(event: event)
//                    showEventView = true
//                    Task {
//                        eventViewModel.commentsIsLoading = true
//                        try await eventViewModel.fetchComments()
//                        eventViewModel.commentsIsLoading = false
//                    }
//                }
//        }
//    }
//    
//}
