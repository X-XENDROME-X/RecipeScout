//
//  MapView.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 10/26/25.
//

// Name: Shorya Raj
// Description: This file shows the map view showing nearby grocery stores using MapKit and CoreLocation for dynamic location based search functionality

import SwiftUI

import MapKit

import CoreLocation

import Combine

struct StoreLocation:  Identifiable {
    
    let id = UUID()
    
    let name : String
    
    let coordinate : CLLocationCoordinate2D
    
    let mapItem : MKMapItem
    
    let distance : Double
}

private struct MapControls : View {
    
    @ObservedObject var viewModel : MapViewModel

    var body : some View {
        
        VStack(spacing : 8) {
            
            Button { viewModel.UserRECENTER()
            } label : {
                Image(systemName : "location.circle.fill")
                    .font(.title2)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Button { viewModel.ZoomIN()
            } label : {
                Image(systemName : "plus.magnifyingglass")
                    .font(.title3)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Button { viewModel.zoomOUT()
            } label : {
                Image(systemName : "minus.magnifyingglass")
                    .font(.title3)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(12)
    }
}

struct MapView : View {
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel = MapViewModel()

    var body : some View {
        
        VStack(spacing : 15) {
            
            HStack(spacing : 8) {
                
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width : 40 , height : 40)
                
                Text("Nearby Stores")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
            }
            .padding(.top , 10)

            switch viewModel.StatusOFAUTH {
                
            case .denied , .restricted:
                
                VStack(spacing : 10) {
                    
                    Text("The Location Access is Off 😕")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                    
                }
                .padding(.top , 40)

            default :
                ZStack(alignment : .topTrailing) {
                    
                    Map(position : .constant(.region(viewModel.region))) {
                        
                        UserAnnotation()

                        ForEach(viewModel.stores) { ST in
                            
                            Annotation(ST.name , coordinate : ST.coordinate) {
                                
                                VStack(spacing : 2) {

                                    if viewModel.selectedStore?.id==ST.id {
                                        
                                        Text(ST.name)
                                            .font(.caption2.weight(.semibold))
                                            .padding(4)
                                            .background(Color.white)
                                            .cornerRadius(6)
                                            .shadow(radius : 2)
                                        
                                    }

                                    Button { viewModel.SSELECTION(ST)
                                    } label : {
                                        
                                        ZStack {
                                            
                                            Circle()
                                                .fill(Color.orange)
                                                .frame(width : 30 , height : 30)
                                                .shadow(radius : 2)
                                            
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width : 18 , height : 18)
                                            
                                            Image(systemName : "mappin.circle.fill")
                                                .font(.system(size : 12 , weight : .bold))
                                                .foregroundColor(.orange)
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .mapStyle(.standard)

                    MapControls(viewModel : viewModel)
                }
                .frame(height : 320)
                .cornerRadius(16)
                .padding(.horizontal)

                if viewModel.stores.isEmpty {
                    
                    Text("Searching for the nearby grocery stores")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                else {

                    List(viewModel.stores) { ST in
                        
                        HStack(alignment : .center , spacing : 12) {
                            
                            VStack(alignment : .leading , spacing : 4) {
                                
                                Text(ST.name)
                                    .font(.headline)

                                let MILES = ST.distance/1609.34
                                
                                Text( String(format : "It's %.1f mile(s) away" , MILES) )
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Button(action : {
                                viewModel.AppleMapsOpener(ST)
                            }) {
                                Text("Directions")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal , 14)
                                    .padding(.vertical , 6)
                                    .background(Color.orange.opacity(0.95))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.vertical , 6)

                    }
                    .listStyle(.plain)
                }
            }

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        
        .onAppear { viewModel.RETRYER() }
        
        .navigationBarBackButtonHidden(true)
    }
}

@MainActor
final class MapViewModel : NSObject , ObservableObject , CLLocationManagerDelegate {
    
    @Published var StatusOFAUTH : CLAuthorizationStatus = .notDetermined

    @Published var region = MKCoordinateRegion( center : CLLocationCoordinate2D(latitude : 0 , longitude : 0) , span : MKCoordinateSpan(latitudeDelta: 0.08 , longitudeDelta : 0.08) )

    @Published var stores : [StoreLocation]=[]
    
    @Published var userLocation : CLLocation?
    
    @Published var selectedStore : StoreLocation?

    private let locationManager = CLLocationManager()

    override init() {
        
        super.init()
        
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.distanceFilter = 10

        let STATUS = locationManager.authorizationStatus
        
        StatusOFAUTH = STATUS
        
        AUTHStatus(STATUS)
    }

    private func AUTHStatus(_ STATUS : CLAuthorizationStatus) {
        
        switch STATUS {
            
        case .notDetermined :
            locationManager.requestWhenInUseAuthorization()
            
        case .authorizedAlways , .authorizedWhenInUse :
            locationManager.startUpdatingLocation()
            
        default :
            break
        }
    }

    func locationManager(_ MANAGE : CLLocationManager , didUpdateLocations LOCATIONS : [CLLocation]) {
        
        guard let NEW = LOCATIONS.last else { return }

        let LASTLocation = userLocation
        
        userLocation = NEW

        if region.center.latitude==0 && region.center.longitude==0 {
            
            region.center = NEW.coordinate
            
            NearbyStoresSearching()
            
            print("The initial location is set to => \(NEW.coordinate.latitude) , \(NEW.coordinate.longitude)")
        }
        else if let PREV=LASTLocation ,
                
                NEW.distance(from : PREV) > 500 {
            
            print("The User moved => \(Int(NEW.distance(from : PREV))) , so refreshing the stores")
            
            NearbyStoresSearching()
        }

    }
    
    func locationManagerDidChangeAuthorization(_ MANAGE : CLLocationManager) {
        
            let STATUS=MANAGE.authorizationStatus
        
            StatusOFAUTH = STATUS
        
            AUTHStatus(STATUS)
        }

    func locationManager(_ MANAGE : CLLocationManager , didFailWithError ERR: Error) {
        
        print("There is a location error => \(ERR.localizedDescription)")
    }

    func SSELECTION(_ ST : StoreLocation) {
        
        selectedStore=ST
        
        withAnimation {
            
            region.center=ST.coordinate

            region.span = MKCoordinateSpan( latitudeDelta : max(region.span.latitudeDelta/2 , 0.0051) , longitudeDelta : max(region.span.longitudeDelta/2 , 0.0051) )
        }
    }

    func UserRECENTER() {
        
        guard let USERLOC = userLocation else {

            locationManager.startUpdatingLocation()
            return
        }

        withAnimation {
            
            region.center = USERLOC.coordinate

            region.span = MKCoordinateSpan(latitudeDelta : 0.051 , longitudeDelta : 0.051)
        }
        
        NearbyStoresSearching()
    }

    private func ZOOMER(by F : Double) {
        
        withAnimation {
            
            region.span = MKCoordinateSpan( latitudeDelta : min(max(region.span.latitudeDelta*F , 0.0022) , 1.1) , longitudeDelta : min(max(region.span.longitudeDelta*F , 0.0022) , 1.1) )
            
        }
    }

    func ZoomIN() { ZOOMER(by : 0.51) }

    func zoomOUT() { ZOOMER(by : 2.1) }

    func NearbyStoresSearching() {
        
        guard let userLocation = userLocation else {
            
            print("There is no user location")
            return
        }

        print("searching stores near => \(userLocation.coordinate.latitude) , \(userLocation.coordinate.longitude)")

        let REQ=MKLocalSearch.Request()
        
        REQ.naturalLanguageQuery="Grocery Store"

        REQ.region = MKCoordinateRegion( center : userLocation.coordinate , span : MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) )

        let FIND = MKLocalSearch(request : REQ)
        
        FIND.start { [weak self] RESP , error in
            guard let self else { return }

            if let ERR = error {
                
                print("The search error which is \(ERR.localizedDescription)")
                return
                
            }

            guard let RESP = RESP else {
                
                print("There are no search results rn")
                return
                
            }

            DispatchQueue.main.async {
                
                self.stores = RESP.mapItems.map { X in
                    
                    let location = CLLocation(latitude: X.placemark.coordinate.latitude, longitude: X.placemark.coordinate.longitude)
                    let DIS = location.distance(from : userLocation)
                    
                    return StoreLocation(
                        name : X.name ?? "Store" ,
                        coordinate : X.placemark.coordinate ,
                        mapItem : X ,
                        distance : DIS
                    )
                }
                
                .sorted { $0.distance < $1.distance }
            }
        }
    }

    func AppleMapsOpener(_ ST : StoreLocation) { ST.mapItem.openInMaps(launchOptions : [ MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving ] ) }

    func RETRYER() {

        if userLocation==nil { locationManager.startUpdatingLocation() }

        if userLocation != nil&&stores.isEmpty { NearbyStoresSearching() }
    }
}


