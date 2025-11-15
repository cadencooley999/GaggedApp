//
//  AddPostView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/5/25.
//

import Foundation
import SwiftUI
import PhotosUI

struct AddPostView: View {
    
    @EnvironmentObject var vm: AddPostViewModel
    @EnvironmentObject var homeVm: HomeViewModel
    @EnvironmentObject var eventsVm: EventsViewModel
    @StateObject var keyboard = KeyboardObserver()
    
    @Binding var showAddPostView: Bool
    @Binding var hideTabBar: Bool
    
    @FocusState var isCaptionFocused: Bool
    @FocusState var isNameFocused: Bool
    @FocusState var locDetailsFocused: Bool
    
    @State var titleText: String = ""
    @State var nameText: String = ""
    @State var successful: Bool? = nil
    @State var isLoading: Bool = false
    @State var showCitySearch: Bool = false
    @State var isEvent: Bool = false
    @State var eventDate: Date = Date()
    @State var locationDetailsText: String = ""
    
    let cityUtil = CityUtility.shared
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
            VStack(spacing: 0){
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0){
                        imageSection
                            .onTapGesture {
                                UIApplication.shared.endEditing()
                            }
                        Divider()
                        nameSection
                            .frame(height: 50)
                            .background(Color.clear.onTapGesture {
                                UIApplication.shared.endEditing()
                            })

                        Divider()
                        citySection
                            .frame(height: 50)
                            .background(Color.clear.onTapGesture {
                                UIApplication.shared.endEditing()
                            })
                        Divider()
                        if isEvent {
                            dateSection
                                .frame(height: 50)
                                .background(Color.clear.onTapGesture {
                                    UIApplication.shared.endEditing()
                                })

                            Divider()
                            locationDetailsSection
                                .frame(height: 50)
                                .background(Color.clear.onTapGesture {
                                    UIApplication.shared.endEditing()
                                })

                        }
                        Divider()
                        captionSection
                            .padding()
                            .background(Color.theme.background.onTapGesture {
                                UIApplication.shared.endEditing()
                            })
                        if !isEvent {
                            tagSection
                                .padding(.vertical, 8)
                                .padding(.bottom, 64)
                                .background(Color.clear.onTapGesture {
                                    UIApplication.shared.endEditing()
                                })
                        }
                        Rectangle()
                            .fill(Color.theme.background)
                            .frame(height: isEvent ? 60 : 0)
                            .onTapGesture {UIApplication.shared.endEditing()}

                    }
                    .offset(y: keyboard.keyboardHeight > 0 ? -(keyboard.keyboardHeight - 100) : 0)
//                    .offset(y: isCaptionFocused ? isEvent ? -275 : -225 : 0)
//                    .offset(y: isNameFocused ? -100 : 0)
//                    .offset(y: locDetailsFocused ?  -200 : 0)
                    .animation(.easeInOut, value: keyboard.keyboardHeight)
                    .animation(.easeInOut, value: isCaptionFocused)
                    .animation(.easeInOut, value: isNameFocused)
                    .animation(.easeInOut, value: locDetailsFocused)
                    .frame(maxHeight: .infinity)
                }
                .padding(.top, 25)
                .onScrollPhaseChange { oldPhase, newPhase in
                    if newPhase == .interacting {
                        UIApplication.shared.endEditing()
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -80 || value.translation.width > 80 { // left swipe
                            isEvent.toggle()
                            vm.selectedCities.removeAll()
                            nameText = ""
                        }
                    }
            )
            VStack {
                header
                    .background(Color.theme.background)
                Spacer()
                footer
                    .frame(height: 40)
                    .background(Color.theme.background.ignoresSafeArea())
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        
        .sheet(isPresented: $showCitySearch, onDismiss: ({return}), content: {
            CitySelectionView(showCitySelectionView: $showCitySearch)
                .presentationDetents([.fraction(0.65)])
                .presentationDragIndicator(.automatic)
        })
    }
    
    var captionSection: some View {
        VStack {
            HStack {
                Image(systemName: "person.circle")
                    .font(.headline)
                Text("Caden1234")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Rectangle()
                    .foregroundStyle(Color.theme.background)
                    .frame(maxWidth: 250)
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
            }
            TextField(isEvent ? "Event description..." : "Tell us about him...", text: $titleText, axis: .vertical)
                .lineLimit(6)
                .focused($isCaptionFocused)
                .padding()
                .frame(height: 120, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(Color.theme.lightGray)
                )
        }
    }
    
    var tagSection: some View {
        HStack {
            Capsule()
                .frame(width: 100, height: 30)
                .foregroundStyle(Color.theme.darkBlue)
                .overlay(content: {
                    Text("+ add tag")
                        .foregroundStyle(Color.theme.white)
                })
            Spacer()
            Rectangle()
                .fill(Color.theme.background)
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }
    
    var nameSection: some View {
        VStack {
            HStack {
                ZStack {
                    Color.theme.background
                    Image(systemName: "tag")
                        .font(.headline)
                }
                .frame(width: 20)
                TextField(isEvent ? "Event name..." : "First name only please...", text: $nameText)
                    .font(.body)
                    .focused($isNameFocused)
                    .onChange(of: nameText) { newValue in
                        if !isEvent {
                            nameText = newValue.replacingOccurrences(of: " ", with: "")
                        }
                    }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body)
                    .opacity(0)
            }
            .padding(8)
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
        }
    }
    
    var dateSection: some View {
        HStack {
            ZStack {
                Color.theme.background
                Image(systemName: "calendar.badge.clock")
            }
            .frame(width: 20)
            DatePicker(selection: $eventDate, label: {
                Text("Date & Time")
                    .foregroundStyle(Color.theme.lightGray)
            })
            .accentColor(Color.theme.darkBlue)
        }
        .padding(.horizontal, 8)
    }
    
    var citySection: some View {
        VStack {
            HStack {
                ZStack {
                    Color.theme.background
                    Image(systemName: "mappin")
                        .font(.headline)
                }
                .frame(width: 20)
                if vm.selectedCities.isEmpty {
                    Text("Add city")
                        .font(.body)
                        .italic()
                        .foregroundStyle(Color.theme.lightGray)
                }
                ForEach(vm.selectedCities) { city in
                    HStack(spacing: 0){
                        Text(city.name)
                            .italic()
                        Text(", " + (cityUtil.getStateAbbreviation(for: city.state) ?? ""))
                            .padding(.trailing)
                        Image(systemName: "xmark")
                            .font(.subheadline)
                            .onTapGesture {
                                vm.selectedCities.remove(at: vm.selectedCities.firstIndex(where: { $0.id == city.id }) ?? 0)
                            }
                    }
                    .foregroundStyle(Color.theme.white)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background {
                        Color.theme.darkBlue
                            .cornerRadius(20)
                    }
                }
                Spacer()
                if vm.selectedCities.count < 2 {
                    if isEvent && vm.selectedCities.count < 1 {
                        Image(systemName: "plus")
                            .font(.body)
                            .padding(.trailing, 8)
                            .onTapGesture {
                                showCitySearch = true
                            }
                    }
                    else if isEvent && vm.selectedCities.count == 1 {
                        Image(systemName: "plus")
                            .font(.body)
                            .padding(.trailing, 8)
                            .opacity(0)
                    }
                    else {
                        Image(systemName: "plus")
                            .font(.body)
                            .padding(.trailing, 8)
                            .onTapGesture {
                                showCitySearch = true
                            }
                    }
                }
            }
            .padding(8)
        }
    }
    
    var locationDetailsSection: some View {
        VStack {
            VStack {
                HStack {
                    ZStack {
                        Color.theme.background
                        Image(systemName: "map")
                            .font(.headline)
                    }
                    .frame(width: 20)
                    TextField("Location details...", text: $locationDetailsText, axis: .vertical)
                        .lineLimit(2)
                        .font(.body)
                        .focused($locDetailsFocused)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .opacity(0)
                }
                .padding(.horizontal, 8)
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
            }
        }
    }
    
    var header: some View {
        VStack (spacing: 0){
            HStack {
                Image(systemName: "xmark")
                    .font(.title3)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAddPostView = false
                            hideTabBar = false
                            clearTextFields()
                        }
                    }
                Spacer()
                HStack(spacing: 4){
                    Text("New")
                    Text(isEvent ? "Event" : "Post")
                        .foregroundStyle(Color.theme.darkBlue)
                        .padding(.trailing, 4)
                    EllipsesToggleView(toggleValue: $isEvent, accentColor: Color.theme.darkBlue)
                }
                .onTapGesture {
                    isEvent.toggle()
                    vm.selectedCities.removeAll()
                    nameText = ""
                }
                Spacer()
                Image(systemName: "xmark")
                    .font(.title3)
                    .opacity(0)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            Divider()
        }
    }
    
    var imageSection: some View {
        ZStack {
            if let pickedImage = vm.pickedImage {
                Image(uiImage: pickedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 400) // 👈 cap height here
                    .clipped()                       // crop any overflow outside the frame
            }
            else {
                Rectangle()
                    .fill(Color.theme.background)
                    .frame(width: 300)
                    .frame(height: 350)
            }
            HStack {
                if vm.pickedImage == nil {
                    PhotosPicker(selection: $vm.imageSelection, matching: .any(of: [.images])) {
                        Image(systemName: "camera")
                            .font(.largeTitle)
                            .foregroundStyle(Color.theme.darkBlue)
                    }
                }
            }
            .padding(.horizontal)
            if vm.pickedImage != nil {
                VStack {
                    Spacer()
                    Image(systemName: "trash")
                        .foregroundStyle(Color.theme.brightRed)
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                        .onTapGesture {
                            if vm.pickedImage != nil {
                                vm.pickedImage = nil
                            }
                        }
                        .padding()
                }
            }
        }
    }
    
    var footer: some View {
        VStack(spacing: 0){
            Divider()
            ZStack {
                Color.theme.background
                submitButton
                    .padding()
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
    }
    
    var submitButton: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill((titleText != "" && vm.pickedImage != nil && nameText != "" && vm.selectedCities.count > 0) ? Color.theme.darkBlue : Color.theme.lightGray)
            .frame(height: 40)
            .overlay {
                if let result = successful {
                    if result {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.theme.white)
                    }
                    else {
                        HStack {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.theme.brightRed)
                            Text("Failed to post")
                                .font(.headline)
                                .foregroundStyle(Color.theme.brightRed)
                                .onTapGesture {
                                    successful = nil
                                }
                        }
                    }
                }
                else {
                    if isLoading {
                        ProgressView()
                            .tint(Color.theme.white)
                    }
                    else {
                        Text("Post")
                            .foregroundStyle(Color.theme.white)
                            .font(.headline)
                    }
                }
            }
            .onTapGesture {
                submit()
            }
    }
    
    func submit() {
        if !isEvent {
            if titleText != "" && vm.pickedImage != nil && !vm.selectedCities.isEmpty && nameText != "" {
                Task {
                    isLoading = true
                    let success = try await vm.uploadNewPost(text: titleText, name: nameText, image: vm.pickedImage!, cities: vm.selectedCities, cityIds: vm.selectedCities.map({$0.id}))
                    withAnimation(.easeInOut) {
                        successful = success
                        print("Found success")
                        isLoading = false
                    }
                    if successful == true {
                        try await homeVm.fetchMorePosts()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                            successful = nil
                            withAnimation(.bouncy(duration: 0.2)) {
                                showAddPostView = false
                                hideTabBar = false
                            }
                            clearTextFields()
                        })
                    }
                }
            }
        }
        else {
            if titleText != "" && vm.selectedCities.count == 1 && nameText != "" {
                Task {
                    isLoading = true
                    let success = try await vm.uploadNewEvent(description: titleText, name: nameText, image: vm.pickedImage ?? nil, rsvps: 0, city: vm.selectedCities[0], cityId: vm.selectedCities[0].id, locationDetails: locationDetailsText, date: eventDate)
                    withAnimation(.easeInOut) {
                        successful = success
                        isLoading = false
                    }
                    if successful == true {
                        try await eventsVm.fetchMoreEvents()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                            successful = nil
                            withAnimation(.bouncy(duration: 0.2)) {
                                showAddPostView = false
                                hideTabBar = false
                            }

                            clearTextFields()
                        })
                    }
                    withAnimation(.easeInOut) {
                        successful = nil
                    }
                }
            }
        }
    }
    
    func clearTextFields() {
        titleText = ""
        vm.pickedImage = nil
        vm.selectedCities = []
        nameText = ""
        locationDetailsText = ""
        eventDate = Date()
    }
}

#Preview {
    AddPostView(showAddPostView: .constant(true), hideTabBar: .constant(true))
}
