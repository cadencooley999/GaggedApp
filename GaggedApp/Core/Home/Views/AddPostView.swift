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
//    @EnvironmentObject var eventsVm: EventsViewModel
    @EnvironmentObject var locationManager: LocationManager
    @StateObject var keyboard = KeyboardObserver()
    
    @Binding var showAddPostView: Bool
    
    @FocusState var isCaptionFocused: Bool
    @FocusState var isNameFocused: Bool
    @FocusState var locDetailsFocused: Bool
    
    @State var captionText: String = ""
    @State var nameText: String = ""
    @State var successful: Bool? = nil
    @State var isLoading: Bool = false
    @State var showCitySearch: Bool = false
//    @State var isEvent: Bool = false
    @State var isPoll: Bool = false
    @State var eventDate: Date = Date()
    @State var locationDetailsText: String = ""
    @State private var pollTitle = ""
    @State private var pollContext = ""
    @State private var pollOptions: [String] = ["", ""]
    
    @State private var cropRequest = false
    @State private var croppedResult: UIImage? = nil
    @State var continuation: CheckedContinuation<UIImage,Never>? = nil
    @State var showSheet: Bool = false
    
    let nameLimit = 20
    let captionLimit = 1000
    let optionCharLimit = 40
    let titleLimit = 100
    let contextLimit = 1000
    
    private var cropSize: CGSize {
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: width * (5/4))
    }
    
    func requestCroppedImage() async -> UIImage {
        await withCheckedContinuation { cont in
            continuation = cont
            cropRequest = true
        }
    }
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
            VStack(spacing: 0){
                ScrollView(showsIndicators: false) {
                    if !isPoll {
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
    //                        if isEvent {
    //                            dateSection
    //                                .frame(height: 50)
    //                                .background(Color.clear.onTapGesture {
    //                                    UIApplication.shared.endEditing()
    //                                })
    //
    //                            Divider()
    //                            locationDetailsSection
    //                                .frame(height: 50)
    //                                .background(Color.clear.onTapGesture {
    //                                    UIApplication.shared.endEditing()
    //                                })
    //                            Divider()
    //                        }
                            captionSection
                                .padding()
                                .background(Color.theme.background.onTapGesture {
                                    UIApplication.shared.endEditing()
                                })
                            tagSection
                                .padding(.vertical, 8)
                                .padding(.bottom, 64)
                                .background(Color.clear.onTapGesture {
                                    UIApplication.shared.endEditing()
                                })
                            Rectangle()
                                .fill(Color.theme.background)
                                .frame(height: 0)
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
                    else {
                        VStack(alignment: .leading, spacing: 16) {

                            // TITLE
                            HStack {
                                Text("Poll question")
                                    .font(.headline)
                                Spacer()
                                HStack {
                                    Text("Attach post")
                                        .font(.body)
                                        .foregroundColor(Color.theme.orange)
                                    Image(systemName: "link")
                                        .font(.body)
                                        .foregroundColor(Color.theme.orange)
                                }
                                .onTapGesture {
                                    print("attach code here")
                                }
                            }

                            TextField("Ask a question…", text: $pollTitle)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                                .onChange(of: pollTitle) { newValue in
                                    if newValue.count > titleLimit {
                                        pollTitle = String(newValue.prefix(titleLimit))
                                    }
                                }

                            // CONTEXT
                            Text("Context (optional)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextEditor(text: $pollContext)
                                .frame(minHeight: 90)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                                .onChange(of: pollContext) { newValue in
                                    if newValue.count > contextLimit {
                                        pollContext = String(newValue.prefix(contextLimit))
                                    }
                                }

                            // OPTIONS
                            Text("Options")
                                .font(.headline)
                                .padding(.top, 8)

                            VStack(spacing: 12) {
                                ForEach(pollOptions.indices, id: \.self) { index in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                TextField("Option \(index + 1)", text: $pollOptions[index])
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(Color.white)
                                                )
                                                .onChange(of: pollOptions[index]) { newValue in
                                                    if newValue.count > optionCharLimit {
                                                        pollOptions[index] = String(newValue.prefix(optionCharLimit))
                                                    }
                                                }
                                            }

                                            // CHARACTER COUNTER
                                            HStack {
                                                Spacer()
                                                Text("\(pollOptions[index].count)/\(optionCharLimit)")
                                                    .font(.caption2)
                                                    .foregroundStyle(
                                                        pollOptions[index].count == optionCharLimit
                                                        ? Color.red
                                                        : Color.secondary
                                                    )
                                            }
                                        }
                                        
                                        
                                        if (pollOptions.count > 2) {
                                            Button {
                                                pollOptions.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(Color.theme.gray)
                                            }
                                            .padding(.bottom, 8)
                                        }
                                    }
                                }
                            }

                            // ADD OPTION BUTTON
                            Button {
                                if pollOptions.count < 5 {
                                    pollOptions.append("")
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add option")
                                }
                                .font(.subheadline)
                                .foregroundStyle(Color.theme.darkBlue)
                            }
                            .padding(.top, 4)
                            
                            
                            
                            Spacer(minLength: 80) // leaves room for footer
                        }
                        .animation(.easeInOut(duration: 0.2), value: pollOptions)
                        .padding()
                        .background(Color.theme.background.onTapGesture {
                            UIApplication.shared.endEditing()
                        })
                    }
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
                            isPoll.toggle()
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
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
            TextField("Tell us about him...", text: $captionText, axis: .vertical)
                .lineLimit(6)
                .focused($isCaptionFocused)
                .padding()
                .frame(height: 120, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(Color.theme.lightGray)
                )
                .onChange(of: captionText) { newValue in
                    if newValue.count > captionLimit {
                        captionText = String(newValue.prefix(captionLimit))
                    }
                }
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
                TextField("First name only please...", text: $nameText)
                    .font(.body)
                    .focused($isNameFocused)
                    .onChange(of: nameText) { newValue in
                        nameText = newValue.replacingOccurrences(of: " ", with: "")
                        nameText = String(newValue.prefix(nameLimit))
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
                        Text(city.city)
                            .italic()
                        Text(", " + city.state_id)
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
                    Image(systemName: "plus")
                        .font(.body)
                        .padding(.trailing, 8)
                        .onTapGesture {
                            showCitySearch = true
                        }
                }
            }
            .padding(8)
        }
        .background(Color.theme.background)
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
                            clearTextFields()
                        }
                    }
                Spacer()
                HStack(spacing: 4){
                    Text("New")
                    Text("Post")
                        .foregroundStyle(isPoll ? Color.theme.gray : Color.theme.darkBlue)
                        .padding(.trailing, 4)
                    EllipsesToggleView(toggleValue: $isPoll, accentColor: isPoll ? Color.theme.orange : Color.theme.darkBlue)
                    Text("Poll")
                        .foregroundStyle(isPoll ? Color.theme.orange : Color.theme.gray)
                        .padding(.leading, 4)
                }
                .onTapGesture {
                    isPoll.toggle()
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
                CropImageView(
                    image: pickedImage,
                    cropSize: cropSize,
                    cropRequest: $cropRequest,
                    onCropped: { img in
                        continuation?.resume(returning: img)
                        continuation = nil   // VERY important
                    }
                )
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
            .fill((captionText != "" && vm.pickedImage != nil && nameText != "" && vm.selectedCities.count > 0) ? Color.theme.darkBlue : Color.theme.lightGray)
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
        if !isPoll {
            if captionText != "" && vm.pickedImage != nil && !vm.selectedCities.isEmpty && nameText != "" {
                Task {
                    isLoading = true
                    cropRequest = true
                    let finalImage = await requestCroppedImage()
                    let success = try await vm.uploadNewPost(text: captionText, name: nameText, image: finalImage, cityIds: vm.selectedCities.map({$0.id}))
                    withAnimation(.easeInOut) {
                        successful = success
                        print("Found success")
                        isLoading = false
                    }
                    if successful == true {
                        try await homeVm.fetchMorePosts(cities: locationManager.citiesInRange)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                            successful = nil
                            withAnimation(.bouncy(duration: 0.2)) {
                                showAddPostView = false
                            }
                            clearTextFields()
                        })
                    }
                }
            }
        }
        else {
            if pollContext != "" && pollTitle != "" {
                if let city = locationManager.selectedCity {
                    Task {
                        isLoading = true
                        let success = try await vm.uploadNewPoll(title: pollTitle, context: pollContext, options: pollOptions, cityId: city.id)
                        withAnimation(.easeInOut) {
                            successful = success
                            print("Found success")
                            isLoading = false
                        }
                        if successful == true {
    //                        try await homeVm.fetchMorePosts(cities: locationManager.citiesInRange)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                                successful = nil
                                withAnimation(.bouncy(duration: 0.2)) {
                                    showAddPostView = false
                                }
                                clearTextFields()
                            })
                        }
                    }
                }
            }
        }
    }
    
    func clearTextFields() {
        captionText = ""
        vm.pickedImage = nil
        vm.selectedCities = []
        nameText = ""
        locationDetailsText = ""
        eventDate = Date()
        pollTitle = ""
        pollContext = ""
        pollOptions = ["",""]
    }

}

struct CropImageView: View {
    let image: UIImage
    let cropSize: CGSize
    
    @Binding var cropRequest: Bool
    var onCropped: (UIImage) -> Void
    
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var translation: CGSize = .zero
    @State private var lastTranslation: CGSize = .zero
    
    @State var isInteracting: Bool = false
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .scaleEffect(scale)
                .offset(translation)
                .frame(width: cropSize.width, height: cropSize.height)
                .clipped()
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                isInteracting = true
                                let newScale = lastScale * value
                                scale = max(newScale, 1)
                                translation = clamp(translation)
                            }
                            .onEnded { _ in
                                isInteracting = false
                                lastScale = scale
                                lastTranslation = translation
                            },
                        
                        DragGesture()
                            .onChanged { value in
                                isInteracting = true
                                let newTranslation = CGSize(
                                    width: lastTranslation.width + value.translation.width,
                                    height: lastTranslation.height + value.translation.height
                                )
                                translation = clamp(newTranslation)   // ← clamp
                            }
                            .onEnded { _ in
                                isInteracting = false
                                lastTranslation = translation         // ← lock it in
                            }
                    )
                )
                .overlay {
                    if isInteracting {
                        interactionGrid
                    }
                }
        }
        .onChange(of: cropRequest) { newValue in
            if newValue == true {
                if let output = renderCroppedImage() {
                    onCropped(output)
                }
                cropRequest = false
            }
        }
    }
    
    func clamp(_ t: CGSize) -> CGSize {
        let size = displayedImageSize()
        
        let scaledW = size.width * scale
        let scaledH = size.height * scale
        
        let halfCropW = cropSize.width / 2
        let halfCropH = cropSize.height / 2
        
        let halfImageW = scaledW / 2
        let halfImageH = scaledH / 2
        
        // Max allowed movement before empty space appears
        let maxX = max(0, halfImageW - halfCropW)
        let maxY = max(0, halfImageH - halfCropH)
        
        return CGSize(
            width: min(max(t.width, -maxX), maxX),
            height: min(max(t.height, -maxY), maxY)
        )
    }
    
    func displayedImageSize() -> CGSize {
        let imageW = image.size.width
        let imageH = image.size.height
        
        let cropW = cropSize.width
        let cropH = cropSize.height
        
        let imageAspect = imageW / imageH
        let cropAspect = cropW / cropH
        
        if imageAspect > cropAspect {
            let height = cropH
            let width = height * imageAspect
            return CGSize(width: width, height: height)
        } else {
            let width = cropW
            let height = width / imageAspect
            return CGSize(width: width, height: height)
        }
    }
    
    var interactionGrid: some View {
        ZStack {
            // vertical lines
            HStack {
                Spacer()
                Rectangle().fill(Color.white.opacity(0.8)).frame(width: 1)
                Spacer()
                Rectangle().fill(Color.white.opacity(0.8)).frame(width: 1)
                Spacer()
            }

            // horizontal lines
            VStack {
                Spacer()
                Rectangle().fill(Color.white.opacity(0.8)).frame(height: 1)
                Spacer()
                Rectangle().fill(Color.white.opacity(0.8)).frame(height: 1)
                Spacer()
            }
        }
        .allowsHitTesting(false)
    }
    
    func renderCroppedImage() -> UIImage? {
        let original = image

        // 1. Get how the image is sized on screen
        let disp = displayedImageSize()
        let dispW = disp.width * scale
        let dispH = disp.height * scale

        // 2. Convert SwiftUI translation into "image origin inside crop"
        let originX = (cropSize.width - dispW) / 2 + translation.width
        let originY = (cropSize.height - dispH) / 2 + translation.height

        // 3. Convert points → pixels
        let scaleX = original.size.width / disp.width
        let scaleY = original.size.height / disp.height

        let pixelOriginX = originX * scaleX
        let pixelOriginY = originY * scaleY

        let pixelCropW = cropSize.width * scaleX
        let pixelCropH = cropSize.height * scaleY

        let format = UIGraphicsImageRendererFormat()
        format.scale = original.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: pixelCropW, height: pixelCropH),
            format: format
        )

        return renderer.image { context in
            original.draw(
                in: CGRect(
                    x: pixelOriginX,
                    y: pixelOriginY,
                    width: dispW * scaleX,
                    height: dispH * scaleY
                )
            )
        }
    }

}





