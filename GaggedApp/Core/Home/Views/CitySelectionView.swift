//
//  CitySelectionView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/20/25.
//

import SwiftUI

struct CitySelectionView: View {
    
    @EnvironmentObject var addPostVm: AddPostViewModel
    
    @Binding var showCitySelectionView: Bool
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            ScrollView {
                header
//                cityList
            }
        }
    }
    
    var header: some View {
        VStack(spacing: 0){
            HStack {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .onTapGesture {
                        print("CHEV TAPPED")
                        isFocused = false
                        showCitySelectionView = false
                    }
                    .padding(.trailing, 8)
                TextField("Search cities...", text: $addPostVm.searchText)
                    .focused($isFocused)
                    .padding(8)
                    .background(Color.theme.lightGray.cornerRadius(5))
                
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            Divider()
        }
        .background(Color.theme.background)
    }
    
//    var cityList: some View {
//        VStack {
//            ForEach(addPostVm.citiesFound) { city in
//                HStack(spacing: 0){
//                    Text(city.name)
//                        .italic()
//                        .font(.body)
//                    Text(", " + (cityUtil.getStateAbbreviation(for: city.state) ?? ""))
//                        .font(.body)
//                    Spacer()
//                    if addPostVm.selectedCities.contains(where: { $0.id == city.id }) {
//                        Image(systemName: "checkmark")
//                            .font(.body)
//                    }
//                    else {
//                        Image(systemName: "plus")
//                            .font(.body)
//                    }
//                }
//                .frame(height: 35)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.horizontal)
//                .onTapGesture {
//                    if !addPostVm.selectedCities.contains(where: { $0.id == city.id }) {
//                        addPostVm.selectedCities.append(CityLiteModel(id: city.id, name: city.name, state: city.state, country: city.country))
//                        showCitySelectionView = false
//                    }
//                }
//                Divider()
//            }
//        }
//    }
}

#Preview {
    CitySelectionView(showCitySelectionView: .constant(true))
}
