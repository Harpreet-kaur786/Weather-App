

//
//  ViewController.swift
//  Lab04
//
//  Created by Harpreet Kaur on 2024-11-05.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var weatherConditionImage: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
     //   locationManager.startUpdatingLocation()
        displayDefaultImage()
    }

    // Display default image when the app loads
    private func displayDefaultImage() {
        let config = UIImage.SymbolConfiguration(paletteColors: [
                  .systemYellow, .systemIndigo, .systemBlue
              ])
              weatherConditionImage.preferredSymbolConfiguration = config
              weatherConditionImage.image = UIImage(systemName: "sun.dust.fill")
        
    }

    // Display image based on weather condition code
    private func displayImage(for conditionCode: Int) {
        let systemImageName: String
        switch conditionCode {
            case 1000:
                systemImageName = "sun.max.fill" // Clear
            case 1003, 1006:
                systemImageName = "cloud.fill" // Partly Cloudy
            case 1009:
                systemImageName = "smoke.fill" // Cloudy
            case 1030, 1135, 1147:
                systemImageName = "cloud.fog.fill" // Foggy
            case 1063, 1150...1189:
                systemImageName = "cloud.drizzle.fill" // Rain
            case 1192...1201:
                systemImageName = "cloud.heavyrain.fill" // Heavy Rain
            case 1210...1216:
                systemImageName = "cloud.snow.fill" // Snow
            case 1273...1276:
                systemImageName = "cloud.bolt.rain.fill" // Thunderstorm
            default:
                systemImageName = "cloud.sun.rain.fill" // Default for unknown codes
        }
        
        if let image = UIImage(systemName: systemImageName) {
            weatherConditionImage.image = image
        } else {
            weatherConditionImage.image = UIImage(systemName: "cloud.sun.circle.fill") // Fallback image
        }
    }

    // Action for current location button
    @IBAction func onLocationTapped(_ sender: UIButton) {
        let latitude = 42.983612
        let longitude = -81.249725
        let query = "\(latitude), \(longitude)"
        loadWeather(search: query)
    }

    // Action for search button (for city/country)
    @IBAction func onSearchTapped(_ sender: UIButton) {
        loadWeather(search: searchTextField.text)
    }

    // Load weather based on the provided query (location or city)
    private func loadWeather(search: String?) {
        guard let search = search?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty else {
            print("Invalid query")
            return
        }
        
        guard let url = getURL(query: search) else {
            print("Could not get URL for query:", search)
            return
        }
        fetchWeatherData(url: url)
    }

    // Fetch weather data from the API
    private func fetchWeatherData(url: URL) {
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) { data, response, error in
            guard error == nil else {
                print("Received error:", error!)
                return
            }
            guard let data = data else {
                print("No data found")
                return
            }
            if let weatherResponse = self.parseJson(data: data) {
                DispatchQueue.main.async {
                    self.locationLabel.text = weatherResponse.location.name
                    self.temperatureLabel.text = "\(weatherResponse.current.temp_c)°C"
                    self.displayImage(for: weatherResponse.current.condition.code)
                }
            } else {
                print("Failed to parse JSON")
            }
        }
        dataTask.resume()
    }

    // Construct the API URL
    private func getURL(query: String) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/" // Updated to https
        let currentEndPoint = "current.json?"
        let apiKey = "95cdf94e49a14f2bb4e233826240511"
        let urlString = "\(baseUrl)\(currentEndPoint)key=\(apiKey)&q=\(query)"
        
        guard let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedUrlString) else {
            print("Error encoding URL for Query:", query)
            return nil
        }
        return url
    }

    // Parse the JSON response from the API
    private func parseJson(data: Data) -> WeatherResponse? {
        let decoder = JSONDecoder()
        var weather: WeatherResponse?
        do {
            weather = try decoder.decode(WeatherResponse.self, from: data)
        } catch {
            print("Error decoding JSON:", error)
        }
        return weather
    }

    // MARK: CLLocationManagerDelegate Methods
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .denied {
            print("Location access denied. Please enable location permissions in Settings.")
        } else {
            print("Failed to get user location:", error.localizedDescription)
        }
        locationManager.stopUpdatingLocation()
    }

}

// Response structure for JSON
struct WeatherResponse: Decodable {
    let location: Location
    let current: Weather
}

struct Location: Decodable {
    let name: String
}

struct Weather: Decodable {
    let temp_c: Float
    let condition: WeatherCondition
}

struct WeatherCondition: Decodable {
    let text: String
    let code: Int
}
