//
//  EventSearchView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/24/25.
//

//import SwiftUI
//
//struct EventSearchView: View {
//    
//    @EnvironmentObject var searchViewModel: SearchViewModel
////    @EnvironmentObject var eventViewModel: EventViewModel
//    @EnvironmentObject var locationManager: LocationManager
//    
//    @FocusState var isFocused: Bool
//    @Binding var showEventSearchView: Bool
//    @Binding var showEventView: Bool
//    
//    var body: some View {
//        ZStack {
//            Color.theme.background
//                .ignoresSafeArea()
//            ScrollView {
//                VStack {
//                    ForEach(searchViewModel.eventList) { event in
//                        MiniEventView(event: event)
//                            .onTapGesture {
//                                handleEventTap(event)
//                            }
//                    }
//                }
//                .padding(.horizontal)
//                .padding(.vertical, 64)
//            }
//            .onScrollPhaseChange({ oldPhase, newPhase in
//                if newPhase == .interacting {
//                    UIApplication.shared.endEditing()
//                }
//            })
//            VStack(spacing: 0){
//                header
//                    .frame(height: 55)
//                    .background(Color.theme.background.ignoresSafeArea())
//                Spacer()
//            }
//        }
//        .highPriorityGesture(
//            DragGesture()
//                .onEnded { value in
//                    if value.translation.width > 80 { // left swipe
//                        UIApplication.shared.endEditing()
//                        withAnimation(.easeInOut(duration: 0.2)) {
//                            showEventSearchView = false
//                        }
//                        searchViewModel.eventSearchText = ""
//                    }
//                }
//        )
//        .onAppear{
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
//                searchViewModel.addSubscribers {
//                    locationManager.citiesInRange
//                }
//                isFocused = true
//            })
//        }
//    }
//    
//    
//    var header: some View {
//        VStack(spacing: 0){
//            HStack {
//                Image(systemName: "chevron.left")
//                    .font(.headline)
//                    .onTapGesture {
//                        print("CHEV TAPPED")
//                        UIApplication.shared.endEditing()
//                        withAnimation(.easeInOut(duration: 0.3)) {
//                            eventViewModel.eventsTransitionOffset = 0
//                            showEventSearchView = false
//                        }
//                        searchViewModel.eventSearchText = ""
//                    }
//                    .padding(.horizontal)
//                Spacer()
//                TextField("Search events...", text: $searchViewModel.eventSearchText)
//                    .focused($isFocused)
//            }
//            .padding()
//            Divider()
//        }
//
//    }
//    
//    private func handleEventTap(_ event: EventModel) {
//        eventViewModel.setEvent(event: event)
//        UIApplication.shared.endEditing()
//        showEventView = true
//        Task {
//            eventViewModel.commentsIsLoading = true
//            try await eventViewModel.fetchComments()
//            eventViewModel.commentsIsLoading = false
//        }
//    }
//}
//
