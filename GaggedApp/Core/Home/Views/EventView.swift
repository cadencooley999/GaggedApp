//
//  EventView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/25/25.
//

import SwiftUI

struct EventView: View {
    
    @AppStorage("userId") var userId = ""
    
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var eventsViewModel: EventsViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @FocusState var isCommentTextFieldFocused: Bool
    
    @Binding var showEventView: Bool
    @Binding var hideTabBar: Bool
    @Binding var showEventSearchView: Bool
    
    @State var commentText: String = ""
    @State var shiftScroll: Bool = false
    @State private var textEditorHeight: CGFloat = 36
    @State var parentId: String? = nil
    @State var parentAuthor: String? = nil
    @State var highlightedCommentId: String? = nil
    @State var showOptionsSheet: Bool = false
    @State var selectedItemForOptions: GenericItem? = nil
    
    let cityUtil = CityUtility.shared

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
            
            if let event = eventViewModel.event {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            postImage(url: event.imageUrl, maxHeight: 450)
                            
                            eventInfo(for: event)
                                .padding()
                                .id("eventTop")
                                .padding(.bottom, 8)
                            
                            Divider()
                            
                            commentSection
                                .id("commentSectionBottom")
                                .padding(.bottom, 32)
                            
                        }
                        .offset(y: shiftScroll ? -200 : 0)
                        .padding(.vertical, 56)
                        .onChange(of: isCommentTextFieldFocused) { newValue in
                            if newValue {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    shiftScroll = true
                                }
                            }
                            else {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    shiftScroll = false
                                }
                            }
                        }
                    }
                    .refreshable {
                        Task {
                            try await eventViewModel.fetchComments()
                        }
                    }
                    .onScrollPhaseChange { oldPhase, newPhase in
                        if newPhase == .interacting {
                            UIApplication.shared.endEditing()
                        }
                    }
                }
            }
            VStack(spacing: 0){
                header
                    .background(Color.theme.background)
                Divider()
                Spacer()
                commentBar
                    .background(Color.theme.background)
                    .focused($isCommentTextFieldFocused)
            }
        }
        .highPriorityGesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 { // left swipe
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showEventView = false
                        }
                        if !showEventSearchView {
                            hideTabBar = false
                        }
                        eventViewModel.comments = []
                    }
                }
        )
        .sheet(isPresented: $showOptionsSheet) {
            OptionsSheet(selectedItemForOptions: $selectedItemForOptions, showOptionsSheet: $showOptionsSheet, showPostView: $showEventView, hideTabBar: $hideTabBar)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThickMaterial) // or .regularMaterial
                .background(Color.black.opacity(1)) // makes it darker
        }
    }
    

        
    var header: some View {
        VStack(spacing: 0){
            HStack {
                Image(systemName: "chevron.left")
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showEventView = false
                        }
                        if !showEventSearchView {
                            hideTabBar = false
                        }
                        eventViewModel.comments = []
                    }
                    .frame(maxWidth: 50, alignment: .leading)
                VStack {
                    Text(eventViewModel.event?.name ?? "Name")
                        .font(.title2)
                    if let city = eventViewModel.event?.city {
                        Text(city.name + ", " + (cityUtil.getStateAbbreviation(for: city.state) ?? ""))
                            .italic(true)
                            .font(.callout)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                HStack {
                    Image("ellipses")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .onTapGesture {
                            if let event = eventViewModel.event {
                                selectedItemForOptions = GenericItem.event(event)
                                showOptionsSheet = true
                            }
                        }
                }
                .frame(maxWidth: 50, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .frame(height: 55)
    }
    
    var commentSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if eventViewModel.commentsIsLoading {
                    ProgressView()
                        .padding(.top, 32)
                }
                else {
                    if eventViewModel.comments.count == 0 {
                        Text("No comments yet")
                            .padding(.top, 32)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    else {
                        ForEach(eventViewModel.comments) { com in
                            HStack(alignment: .top) {
                                HStack(alignment: .top){
                                    Image(systemName: "person.circle")
                                        .font(.headline)
                                    VStack(alignment: .leading){
                                        HStack {
                                            Text(com.comment.authorId)
                                                .font(.subheadline)
                                            Text(eventViewModel.timeAgoString(from: com.comment.createdAt))
                                                .font(.caption)
                                                .foregroundStyle(Color.theme.gray)
                                        }
                                        (Text(com.isGrandchild
                                             ? "@\(eventViewModel.getAuthor(id: com.comment.parentCommentId ?? "") ?? "") "
                                              : "").foregroundStyle(Color.blue).font(.caption))
                                        + Text(com.comment.message)
                                            .font(.caption)
                                            .foregroundStyle(Color.theme.accent)
                                        HStack {
                                            Image(systemName: "message")
                                                .resizable()
                                                .frame(width: 12, height: 12)
                                                .foregroundStyle(Color.theme.accent)
                                                .onTapGesture {
                                                    parentId = com.comment.id
                                                    parentAuthor = com.comment.authorId
                                                    highlightedCommentId = com.comment.id
                                                    isCommentTextFieldFocused = true
                                                }
                                                .padding(.trailing, 8)
                                            Image(systemName: "flag")
                                                .resizable()
                                                .frame(width: 12, height: 12)
                                                .foregroundStyle(Color.theme.accent)
                                                .onTapGesture {
                                                    
                                                }
                                                .padding(.trailing, 8)
                                            if com.comment.authorId == userId {
                                                Image("ellipses")
                                                    .resizable()
                                                    .frame(width: 12, height: 12)
                                                    .foregroundColor(Color.theme.accent)
                                                    .onTapGesture {
                                                        selectedItemForOptions = GenericItem.comment(com.comment)
                                                        showOptionsSheet = true
                                                    }
                                                
                                            }
                                            Spacer()
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                .padding(.leading, com.indentLayer > 0 ? 16 : 0)
                                Spacer()
                                VStack {
                                    Image(systemName: "arrow.up")
                                        .foregroundStyle(.gray)
                                        .onTapGesture {
                                            eventViewModel.upvoteCom(comId: com.id)
                                        }
                                        .padding(.bottom, 8)
                                    Text("\(com.comment.upvotes)")
                                        .font(.caption)
                                }
                                .padding(.top, 8)
                            }
                            .padding(12)
                            .background(content: {
                                Color.theme.gray.opacity(com.id == highlightedCommentId ? 0.4 : 0.0)
                            })
                            if com.comment.hasChildren && com.isExpanded == false && com.indentLayer < 1 {
                                Text("--- View Replies ---")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.gray)
                                    .onTapGesture {
                                        Task {
                                            try await eventViewModel.catchChildren(viewCom: com)
                                            print("child fetched")
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
//                            else if com.comment.hasChildren && com.isExpanded == true {
//                                Text("--- Hide Replies ---")
//                                    .font(.caption)
//                                    .foregroundStyle(Color.theme.gray)
//                                    .onTapGesture {
//                                        postViewModel.collapseComments(viewComment: com)
//                                    }
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                            }
                        } // foreach
                    } // else
                } // else
            } // vstack
        } // scrollview
    } // sect
    
    var commentBar: some View {
        VStack(spacing: 0){
            Divider()
            HStack(alignment: .bottom){
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding(.bottom, 8)
                VStack {
                    if parentId != nil {
                        HStack {
                            Text("Replying to @\(parentAuthor!)")
                                .font(.caption)
                                .foregroundStyle(Color.theme.gray)
                            Image(systemName: "xmark")
                                .font(.headline)
                                .onTapGesture {
                                    parentId = nil
                                    parentAuthor = nil
                                    highlightedCommentId = nil
                                    UIApplication.shared.endEditing()
                                }
                        }
                    }
                    TextField("Add a comment...", text: $commentText, axis: .vertical)
                        .focused($isCommentTextFieldFocused)
                        .lineLimit(4)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(Color.theme.lightGray)
                        )
                }
                Image(systemName: "paperplane")
                    .resizable()
                    .foregroundStyle(Color.theme.lightBlue)
                    .onTapGesture {
                        if commentText != "" {
                            Task {
                                try await eventViewModel.uploadComment(message: commentText, parentId: parentId)
                                commentText = ""
                                try await eventViewModel.fetchComments()
                            }
                        }
                    }
                    .frame(width: 20, height: 20)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private func eventInfo(for event: EventModel) -> some View {
        VStack {
            HStack {
                HStack {
                    Image(systemName: "person.circle")
                        .font(.headline)
                    Text("\(event.authorId)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("•")
                        .font(.caption)
                    let str = eventViewModel.timeUntilString(from: event.date)
                    Text(str)
                        .foregroundColor(str == "Today" || str.contains("h") ? Color.theme.darkRed : str.contains("ago") ? Color.theme.gray : Color.theme.accent)
                        .font(.subheadline)
                    
                }
                Spacer()
                HStack {
                    Text("\(event.rsvps)")
                        .font(.headline)
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(Color.theme.darkBlue)
                        .fontWeight(.bold)
                        .onTapGesture {
//                                postViewModel.upvote(post: post)
//                                homeViewModel.upvotePost(post: post)
                            if !eventViewModel.isRsvpd {
                                eventViewModel.rsvpForEvent(event: event)
                                eventsViewModel.addRSVP(eventId: event.id)
                                print(event.rsvps)
                                eventViewModel.isRsvpd = true
                            }
                            else {
                                eventViewModel.removeRsvp(event: event)
                                eventsViewModel.removeRSVP(eventId: event.id)
                                print(event.rsvps)
                                eventViewModel.isRsvpd = false
                            }
                            if event.authorId == userId {
                                Task {
                                    try await profileViewModel.getMoreUserEvents()
                                }
                            }
                        }
                }
            }// hstack
            .padding(.bottom)
            HStack {
                Text("Date & Time:")
                    .font(.headline)
                Text(eventViewModel.getDateString(event.date))
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
            VStack (alignment: .leading) {
                Text("Location Details: ")
                    .font(.headline)
                    .padding(.bottom, 2)
                LocationTextView(text: event.locationDetails)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
            VStack(alignment: .leading){
                Text("Event Description: ")
                    .font(.headline)
                    .padding(.bottom, 2)
                InlineExpandableText(text: event.description, limit: 200)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
}

#Preview {
    EventView(showEventView: .constant(true), hideTabBar: .constant(true), showEventSearchView: .constant(false))
}
