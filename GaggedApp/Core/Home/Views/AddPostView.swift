//
//  AddPostView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/5/25.
//

import Foundation
import SwiftUI
import PhotosUI

enum NewContent: String, CaseIterable {
    case post = "Post"
    case poll = "Poll"
}

struct UIPollOption: Identifiable {
    let id = UUID()
    var text: String
}

enum FieldToScroll: Hashable {
    case caption
    case option(UUID)
    case name
}

struct AddPostView: View {
    
    @EnvironmentObject var vm: AddPostViewModel
    @EnvironmentObject var homeVm: HomeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
//    @EnvironmentObject var eventsVm: EventsViewModel
    @EnvironmentObject var locationManager: LocationManager
    @StateObject var keyboard = KeyboardObserver()
    @EnvironmentObject var pollsViewModel: PollsViewModel
    @EnvironmentObject var windowSize: WindowSize
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    @AppStorage("chosenProfileImageAddress") var chosenProfileImageAddress: String = ""
    @AppStorage("username") var username: String = ""
    
    @Binding var showAddPostView: Bool
    @Binding var selectedTab: TabBarItem
    
    @State var captionText: String = ""
    @State var nameText: String = ""
    @State var successful: Bool? = nil
    @State var isLoading: Bool = false
    @State var showCitySearch: Bool = false
//    @State var isEvent: Bool = false

    @State var eventDate: Date = Date()
    @State var locationDetailsText: String = ""
    @State private var pollTitle = ""
    @State private var pollContext = ""
    @State private var pollOptions: [UIPollOption] = [.init(text: ""), .init(text: "")]
    @State var showTagSheet: Bool = false
    @State private var cropRequest = false
    @State private var croppedResult: UIImage? = nil
    @State var continuation: CheckedContinuation<UIImage,Never>? = nil
    @State var showSheet: Bool = false
    @State var showPostPicker: Bool = false

    @State var photoSelected: Bool = false
    @State var selectedPhoto: UIImage? = nil
    
    @FocusState var focusedField: FieldToScroll?
    
    @Namespace var segmentedSwitch
    @Namespace var pic
    
    let nameLimit = 20
    let captionLimit = 1000
    let optionCharLimit = 40
    let titleLimit = 50
    let contextLimit = 1000
    
    private let cropAspectRatio: CGFloat = 1.111 // ≈ 5:4.5
    
    private var cropSize: CGSize {
        let width = windowSize.size.width - 64
        return CGSize(width: min(width, 700), height: min(width * cropAspectRatio, 700*cropAspectRatio))
    }
    
    func requestCroppedImage() async -> UIImage {
        await withCheckedContinuation { cont in
            continuation = cont
            cropRequest = true
        }
    }
    
    var body: some View {
        ZStack {
            Background()
                .ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
            VStack(spacing: 0){
                
                if vm.currentNewContent == .post && !photoSelected {
                    VStack(spacing: 16) {
                        VStack {
                            Spacer()
                            imageSection
                                .onTapGesture { UIApplication.shared.endEditing() }
                                .clipped()
                            nextButton
                                .padding(.top)
                            Spacer()
                        }
                    }
                }
                
                if vm.currentNewContent == .post && photoSelected {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                imagePreviewSection
                                    .padding(.top, 72)
                                nameSection
                                    .id("name")
                                citySection
                                captionSection
                                    .id("caption")
                                tagSection
                                Rectangle()
                                    .fill(Color.theme.background)
                                    .frame(height: 0)
                                    .onTapGesture { UIApplication.shared.endEditing() }
                            }
                            .padding(.bottom, 72 + keyboard.keyboardHeight)
                        }
                        .animation(.easeInOut(duration: 0.25), value: keyboard.keyboardHeight)
                        .onScrollPhaseChange { oldPhase, newPhase in
                            if newPhase == .interacting { UIApplication.shared.endEditing() }
                        }
                        .onChange(of: focusedField) { newValue in
                            guard let newValue else { return }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    switch newValue {
                                    case .caption:
                                        proxy.scrollTo("caption", anchor: .center)
                                    case .name:
                                        proxy.scrollTo("name", anchor: .center)
                                    case .option(let id):
                                        proxy.scrollTo("option_\(id.uuidString)", anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if vm.currentNewContent == .poll {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                SectionCard(title: "Poll question") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        TextField("Ask a question…", text: $pollTitle)
                                            .font(.body)
                                            .padding()
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.theme.lightGray, lineWidth: 1)
                                            )
                                            .onChange(of: pollTitle) { newValue in
                                                if newValue.count > titleLimit { pollTitle = String(newValue.prefix(titleLimit)) }
                                            }
                                        HStack {
                                            Text("Required")
                                                .font(.caption2)
                                                .italic()
                                                .fontWeight(.light)
                                            Spacer()
                                            Text("\(pollTitle.count)/\(titleLimit)")
                                                .font(.caption2)
                                                .foregroundStyle(
                                                    pollTitle.count == titleLimit ? Color.red : Color.secondary
                                                )
                                        }
                                    }
                                } toolbar: {
                                    if let post = vm.linkedPost {
                                        HStack(spacing: 6) {
                                            Image(systemName: "link")
                                            Text(post.name)
                                                .lineLimit(1)
                                            Button { vm.linkedPost = nil } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(Color.theme.gray)
                                            }
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.theme.darkBlue)
                                    } else {
                                        Button {
                                            print("button pressed")
                                            searchViewModel.searchText = ""
                                            showPostPicker = true
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "link")
                                                Text("Attach post")
                                            }
                                            .font(.subheadline.weight(.semibold))
                                        }
                                        .foregroundStyle(Color.theme.darkBlue)
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.top, 88)

                                SectionCard(title: "Details") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        TextEditor(text: $pollContext)
                                            .frame(minHeight: 90)
                                            .padding(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.theme.lightGray, lineWidth: 1)
                                            )
                                            .onChange(of: pollContext) { newValue in
                                                if newValue.count > contextLimit { pollContext = String(newValue.prefix(contextLimit)) }
                                            }
                                            .scrollContentBackground(.hidden)
                                        HStack {
                                            Spacer()
                                            Text("\(pollContext.count)/\(contextLimit)")
                                                .font(.caption2)
                                                .foregroundStyle(
                                                    pollContext.count == contextLimit ? Color.red : Color.secondary
                                                )
                                        }
                                    }
                                }
                                .id("details")

                                SectionCard(title: "Options") {
                                    VStack(spacing: 12) {
                                        ForEach($pollOptions) { $option in
                                            HStack(alignment: .top, spacing: 8) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    if let index = $pollOptions.wrappedValue.firstIndex(where: { $0.id == option.id }) {
                                                        TextField("Option \(index + 1)", text: $option.text)
                                                            .id("option_\(option.id.uuidString)")
                                                            .focused($focusedField, equals: .option(option.id))
                                                            .padding()
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 12)
                                                                    .stroke(Color.theme.lightGray, lineWidth: 1)
                                                            )
                                                            .onChange(of: option.text) { newValue in
                                                                if newValue.count > optionCharLimit { option.text = String(newValue.prefix(optionCharLimit)) }
                                                            }
                                                    }

                                                    HStack {
                                                        Spacer()
                                                        Text("\(option.text.count)/\(optionCharLimit)")
                                                            .font(.caption2)
                                                            .foregroundStyle(
                                                                option.text.count == optionCharLimit ? Color.red : Color.secondary
                                                            )
                                                    }
                                                }

                                                if (pollOptions.count > 2) {
                                                    Button {
                                                        pollOptions.removeAll(where: { $0.id == option.id })
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundStyle(Color.theme.gray)
                                                    }
                                                    .padding(.top, 6)
                                                }
                                            }
                                        }
                                        if pollOptions.count < 5 {
                                            HStack {
                                                Text("Required")
                                                    .font(.caption2)
                                                    .italic()
                                                    .fontWeight(.light)
                                                Spacer()
                                                Text("Up to 5 options")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .padding(.leading, 4)
                                        }
                                    }
                                } toolbar: {
                                    Button {
                                        if pollOptions.count < 5 { pollOptions.append(UIPollOption(text: "")) }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add option")
                                        }
                                        .font(.subheadline.weight(.semibold))
                                    }
                                    .foregroundStyle(Color.theme.darkBlue)
                                    .buttonStyle(.plain)
                                }
                                .id("option")
                            }
                            .padding(.bottom, 88 + keyboard.keyboardHeight)
                        }
                        .onScrollPhaseChange { oldPhase, newPhase in
                            if newPhase == .interacting { UIApplication.shared.endEditing() }
                        }
                        .onChange(of: focusedField) { newValue in
                            guard let newValue else {
                                UIApplication.shared.endEditing()
                                return
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    switch newValue {
                                    case .caption:
                                        proxy.scrollTo("caption", anchor: .center)
                                    case .name:
                                        proxy.scrollTo("name", anchor: .center)
                                    case .option(let id):
                                        proxy.scrollTo("option_\(id.uuidString)", anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                }
                
            }
            VStack {
                ZStack(alignment: .top) {

                    // 👇 visual-only blur layer
                    Rectangle()
                        .fill(.thinMaterial)
                        .overlay(Color.theme.background.opacity(0.9))
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .black, location: 0.0),
                                    .init(color: .black.opacity(0.9), location: 0.35),
                                    .init(color: .black.opacity(0.7), location: 0.55),
                                    .init(color: .black.opacity(0.3), location: 0.75),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 140)
                        .ignoresSafeArea(edges: .top)
                        .allowsHitTesting(false)   // 👈 SAFE now

                    // 👇 actual header (fully interactive)
                    header
                        .zIndex(1)
                }
                Spacer()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        
        VStack {
            Spacer()
            if (vm.currentNewContent == .post && photoSelected) || (vm.currentNewContent == .poll) {
                HStack {
                    submitButton
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 0.5)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
//    
//        VStack {
//            if photoSelected == false {
//
//            }
//        
//            Spacer()
//        }
        
        .sheet(isPresented: $showCitySearch, onDismiss: ({return}), content: {
            CitySelectionView(showCitySelectionView: $showCitySearch)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        })
        
        .sheet(isPresented: $showPostPicker, content: {
            PostLinker(linkedPost: $vm.linkedPost, showPostPicker: $showPostPicker)
        })
        
        .sheet(isPresented: $showTagSheet) {
            TagSheet(showTagSheet: $showTagSheet)
                .presentationDetents([.medium])
        }
    }
    
    var captionSection: some View {
        SectionCard(title: "Caption") {
            VStack {
                TextField("Tell us...", text: $captionText, axis: .vertical)
                    .lineLimit(6)
                    .focused($focusedField, equals: .caption)
                    .padding()
                    .frame(minHeight: 120, alignment: .topLeading)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.theme.lightGray, lineWidth: 1)
                    )
                    .onChange(of: captionText) { newValue in
                        if newValue.count > captionLimit {
                            captionText = String(newValue.prefix(captionLimit))
                        }
                    }
                HStack {
                    Text("Required")
                        .font(.caption2)
                        .italic()
                        .fontWeight(.light)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
        .onTapGesture {
            focusedField = .caption
        }
    }
    
    var tagSection: some View {
        SectionCard(title: "Tags") {
            if vm.selectedTags.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "tag")
                        .foregroundStyle(Color.theme.lightGray)
                    Text("No tags added")
                        .foregroundStyle(Color.theme.lightGray)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { showTagSheet = true }
            } else {
                FlowLayout {
                    ForEach(vm.selectedTags, id: \.title) { tag in
                        TagPill(title: tag.title, isSelected: true, color: Color.theme.darkBlue)
                    }
                }
            }
        } toolbar: {
            Button {
                UIApplication.shared.endEditing()
                showTagSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: vm.selectedTags.isEmpty ? "plus.circle.fill" : "pencil.circle.fill")
                    Text(vm.selectedTags.isEmpty ? "Add Tags" : "Edit Tags")
                }
                .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Color.theme.darkBlue)
            .buttonStyle(.plain)
        }
    }
    
    var nameSection: some View {
        SectionCard(title: "Name") {
            VStack {
                HStack(spacing: 10) {
                    Image(systemName: "tag")
                        .font(.headline)
                        .foregroundStyle(Color.theme.darkBlue)
                    TextField("First name only please...", text: $nameText)
                        .font(.body)
                        .focused($focusedField, equals: .name)
                        .onChange(of: nameText) { newValue in
                            let new = newValue.replacingOccurrences(of: " ", with: "")
                            nameText = String(new.prefix(nameLimit))
                        }
                }
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.theme.lightGray.opacity(0.5), lineWidth: 1)
                )
                HStack {
                    Text("Required")
                        .font(.caption2)
                        .italic()
                        .fontWeight(.light)
                    Spacer()
                }
                .padding(.horizontal, 4)
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
        SectionCard(title: "Cities") {
            VStack {
                if vm.selectedCities.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin")
                            .font(.headline)
                            .foregroundStyle(Color.theme.lightGray)
                        Text("Add up to 2 cities")
                            .font(.body)
                            .italic()
                            .foregroundStyle(Color.theme.lightGray)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .padding(4)
                    .onTapGesture {
                        focusedField = nil
                        UIApplication.shared.endEditing()
                        showCitySearch = true
                    }
                } else {
                    HStack {
                        ForEach(vm.selectedCities) { city in
                            HStack(spacing: 0){
                                Text(city.city)
                                    .italic()
                                Text(", " + city.state_id)
                                Image(systemName: "xmark")
                                    .onTapGesture {
                                        vm.selectedCities.remove(at: vm.selectedCities.firstIndex(where: { $0.id == city.id }) ?? 0)
                                    }
                                    .padding(.leading, 4)
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.theme.background)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(LinearGradient(colors: [Color.theme.darkBlue, Color.theme.darkBlue.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Capsule())
                        }
                        Spacer()
                    }
                }
                HStack {
                    Text("Required")
                        .font(.caption2)
                        .italic()
                        .fontWeight(.light)
                    Spacer()
                }
                .padding(.top, 4)
                .padding(.horizontal, 4)
            }
        }
        toolbar: {
            if vm.selectedCities.count < 2 {
                Button {
                    showCitySearch = true
                    UIApplication.shared.endEditing()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add City")
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.theme.darkBlue)
                .buttonStyle(.plain)
            }
            else {
                Button {
                    showCitySearch = true
                    UIApplication.shared.endEditing()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil.circle.fill")
                        Text("Edit Cities")
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.theme.darkBlue)
                .buttonStyle(.plain)
            }
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
                if vm.currentNewContent == .post  {
                    if photoSelected == false {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAddPostView = false
                                clearTextFields()
                                vm.linkedPost = nil
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .padding(8)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                                .glassEffect(.regular.interactive())
                        }
                        .buttonStyle(.plain)
                    }
                    else {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                UIApplication.shared.endEditing()
                                photoSelected = false
                                selectedPhoto = nil
                                
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .padding(8)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                                .glassEffect(.regular.interactive())
                        }
                        .buttonStyle(.plain)
                    }
                }
                else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAddPostView = false
                            clearTextFields()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .padding(8)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                            .glassEffect(.regular.interactive())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                segmentedController
                    .frame(height: 35)
                    .padding()
//                HStack(spacing: 4){
//                    Text(vm.currentNewContent == .poll ? "New Poll" : "New Post")
//                        .font(.headline)
//                        .fontWeight(.regular)
//                }
                Spacer()
                Image(systemName: "xmark")
                    .font(.title3)
                    .padding(8)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .glassEffect(.regular.interactive())
                    .opacity(0)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    var segmentedController: some View {
        let selected = vm.currentNewContent

        return HStack(spacing: 6) {
            ForEach(NewContent.allCases, id: \.self) { content in
                segmentButton(
                    title: content.rawValue,
                    isSelected: selected == content,
                    namespace: segmentedSwitch
                ) {
                    guard selected != content else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        vm.currentNewContent = content
                    }
                }
            }
        }
        .padding(2)
        .glassEffect()
    }

    @ViewBuilder
    func segmentButton(
        title: String,
        isSelected: Bool,
        namespace: Namespace.ID,
        action: @escaping () -> Void
    ) -> some View {
        ZStack {
            if isSelected {
                Capsule()
                    .fill(Color.theme.lightBlue.opacity(0.2))
                    .matchedGeometryEffect(id: "SEGMENT_PILL", in: namespace)
                    .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
            }

            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(Color.theme.darkBlue)
                .padding(.vertical, 12)
                .padding(.horizontal)
        }
        .contentShape(Capsule())
        .frame(width: 100)
        .onTapGesture(perform: action)
    }
    
    var nextButton: some View {
        Button {
            guard vm.pickedImage != nil else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                next()
            }
        } label: {
            HStack {
                Text("Next")
                Image(systemName: "arrow.right")
            }
            .font(.subheadline)
            .foregroundColor(vm.pickedImage == nil ? Color.theme.lightGray : Color.theme.background)
            .frame(maxWidth: 100)
            .padding(.vertical, 8)
            .background(
                Group {
                    if vm.pickedImage == nil {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.02),
                                    radius: 4,
                                    y: 2)
                    } else {
                        Capsule()
                            .fill(Color.theme.darkBlue)
                            .shadow(color: Color.black.opacity(0.02),
                                    radius: 4,
                                    y: 2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
    
    var imagePreviewSection: some View {
        ZStack {
            if let photo = selectedPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cropSize.width * 0.75, height: cropSize.height * 0.75)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            } else {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.theme.lightGray.opacity(0.25))
                    .frame(width: cropSize.width * 0.75, height: cropSize.height * 0.75)
            }
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
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .padding(.vertical)
                .overlay(alignment: .bottomLeading, content: {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if vm.pickedImage != nil {
                                vm.pickedImage = nil
                            }
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.headline)
                            .foregroundColor(Color.theme.trashcanGray)
                            .frame(width: 32, height: 32)
                            .padding(4)
                            .glassEffect(.regular.interactive())
                    }
                    .padding(10)
                    .padding(.bottom)
                })
            }
            else {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.theme.lightBlue.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.theme.darkBlue.opacity(0.25),
                                    style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
                    .frame(width: cropSize.width, height: cropSize.height)
                    .padding(.vertical)
            }
            HStack {
                if vm.pickedImage == nil {
                    PhotosPicker(selection: $vm.imageSelection, matching: .any(of: [.images])) {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(Color.theme.darkBlue)
                                .padding(16)
                                .background(
                                    Circle()
                                        .fill(Color.theme.lightGray.opacity(0.25))
                                )
                            Text("Add Photo")
                                .font(.headline)
                                .foregroundColor(Color.theme.darkBlue)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    var footer: some View {
        VStack(spacing: 0){
            Divider()
            ZStack {
                submitButton
                    .padding()
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
    }
    
    func next() {
        Task {
            cropRequest = true
            let finalImage = await requestCroppedImage()
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedPhoto = finalImage
                photoSelected = true
            }
        }
    }
    
    var submitButton: some View {
        let isEnabled = vm.currentNewContent == .poll
        ? (pollTitle != "" && !(pollOptions.contains { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) == "" }))
        : ((captionText.trimmingCharacters(in: .whitespacesAndNewlines) != "" && vm.pickedImage != nil && nameText != "" && vm.selectedCities.count > 0))

        return Button {
            guard isEnabled && !isLoading else { return }
            submit()
        } label: {
            ZStack {
                if let result = successful {
                    if result {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.theme.background)
                            .font(.headline)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.theme.background)
                            Text("Post failed, try again")
                                .font(.headline)
                                .foregroundStyle(Color.theme.background)
                        }
                    }
                } else if isLoading {
                    ProgressView()
                        .tint(Color.theme.background)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text("Post")
                    }
                    .foregroundStyle(isEnabled ? Color.theme.background : Color.theme.lightGray.opacity(0.75))
                    .font(.headline)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(
                        isEnabled
                        ? LinearGradient(colors: [Color.theme.darkBlue.opacity(0.95), Color.theme.darkBlue.opacity(0.90)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.theme.background], startPoint: .top, endPoint: .top)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        isEnabled ? Color.theme.darkBlue.opacity(0.55) : Color.theme.background.opacity(0.18),
                        lineWidth: 1
                    )
            )
            .shadow(color: (isEnabled ? Color.theme.darkBlue : Color.black).opacity(0.18), radius: 12, y: 6)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
            .opacity(1)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }
    
    func submit() {
        if vm.currentNewContent == .post {
            if captionText.trimmingCharacters(in: .whitespacesAndNewlines) != "" && vm.pickedImage != nil && !vm.selectedCities.isEmpty && nameText != "" {
                Task {
                    if let photo = selectedPhoto {
                        isLoading = true
                        let success = try await vm.uploadNewPost(text: captionText, name: nameText, image: photo, cityIds: vm.selectedCities.map({$0.id}))
                        withAnimation(.easeInOut) {
                            successful = success
                            print("Found success")
                            isLoading = false
                        }
                        if successful == true {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                                successful = nil
                                print("loading more")
                                Task {
                                    await homeVm.loadInitialPostFeed(cityIds: locationManager.citiesInRange)
                                }
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAddPostView = false
                                    selectedTab = TabBarItem(iconName: "HomeIcon", title: "Home")
                                }
                                clearTextFields()
                            })
                            try await profileViewModel.loadMoreUserInfo()
                        }
                    }
                }
            }
        }
        else {
            let hasOptions = !(pollOptions.contains(where: { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) == ""}))
            if pollTitle != "" && hasOptions {
                if let city = locationManager.selectedCity {
                    Task {
                        isLoading = true
                        let success = try await vm.uploadNewPoll(title: pollTitle, context: pollContext, options: pollOptions.map({$0.text}), cityId: city.id, linkedPostId: vm.linkedPost?.id ?? "", linkedPostName: vm.linkedPost?.name ?? "")
                        withAnimation(.easeInOut) {
                            successful = success
                            print("Found success")
                            isLoading = false
                        }
                        if successful == true {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                                successful = nil
                                Task {
                                    try await pollsViewModel.getInitialPolls(cityIds: locationManager.citiesInRange)
                                }
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAddPostView = false
                                    selectedTab = TabBarItem(iconName: "PollIcon", title: "Polls")
                                }
                                clearTextFields()
                            })
                            try await profileViewModel.loadMoreUserInfo()

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
        pollOptions = [.init(text: ""), .init(text: "")]
        vm.selectedTags = []
    }

}

private struct SectionCard<Content: View, Toolbar: View>: View {
    let title: String?
    let content: Content
    let toolbar: Toolbar

    init(title: String? = nil,
         @ViewBuilder content: () -> Content,
         @ViewBuilder toolbar: () -> Toolbar = { EmptyView() }) {
        self.title = title
        self.content = content()
        self.toolbar = toolbar()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    toolbar
                }
            }
            content
        }
        .padding(16)
        .background(Rectangle()
            .fill(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.theme.lightGray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
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
                Rectangle().fill(Color.theme.background.opacity(0.8)).frame(width: 1)
                Spacer()
                Rectangle().fill(Color.theme.background.opacity(0.8)).frame(width: 1)
                Spacer()
            }

            // horizontal lines
            VStack {
                Spacer()
                Rectangle().fill(Color.theme.background.opacity(0.8)).frame(height: 1)
                Spacer()
                Rectangle().fill(Color.theme.background.opacity(0.8)).frame(height: 1)
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
