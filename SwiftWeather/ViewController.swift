//
//  ViewController.swift
//  SwiftWeather
//
//  Created by yuye wang on 3/7/15.
//  Copyright (c) 2015 yuye wang. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate{
    let locationManager:CLLocationManager = CLLocationManager()
    
    
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var loadingindicator: UIActivityIndicatorView!
    @IBOutlet weak var loading: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let background = UIImage(named: "background.png")!
        self.view.backgroundColor = UIColor(patternImage:background)
        // repeat x repeat y
        
        self.loadingindicator.startAnimating()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        
        //一个额外的函数用来启动location in ios8
        if (ios8()) {
            locationManager.requestAlwaysAuthorization()
        }
        //启用这个location manager
        locationManager.startUpdatingLocation()
    }
    
    func ios8() -> Bool {
        // uidevice是cocoapods带来的
        var deviceVersion:NSString = UIDevice.currentDevice().systemVersion
        return deviceVersion.substringWithRange(NSMakeRange(0, 1)) == "8"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        var location:CLLocation = locations[locations.count-1] as CLLocation
        if (location.horizontalAccuracy > 0) {
            println(location.coordinate.latitude)
            println(location.coordinate.longitude)
            
            //可以加self也可以不加，
            updateWeatherInfo(location.coordinate.latitude,longtitude: location.coordinate.longitude)
            
            
            //当我们得到location的时候就 停掉
            locationManager.stopUpdatingLocation()
        }
    }
    
    func updateWeatherInfo(latitude:CLLocationDegrees, longtitude: CLLocationDegrees) {
        
        //http://api.openweathermap.org/data/2.5/weather?lat=37.785834&%20lon=-122.406417&cnt=0
        
        let manager = AFHTTPRequestOperationManager()

        let url = "http://api.openweathermap.org/data/2.5/weather"
        
        let params = ["lat":latitude, "lon": longtitude, "cnt": 0]
        
        
        manager.GET(url,
            parameters: params,
            success: {(operation:AFHTTPRequestOperation!, responseObject: AnyObject!) in println("JSON: " + responseObject.description!)
                self.updateUISuccess(responseObject as NSDictionary!)
            },
            failure: {(operation:AFHTTPRequestOperation!, error:NSError!) in println("Error: " + error.localizedDescription)
            }
        )
        
    }
    
    func updateUISuccess(jsonResult:NSDictionary!) {
        self.loadingindicator.hidden = true
        self.loadingindicator.stopAnimating()
        self.loading.text = nil
        
        //问号转型的时候， 如果内容为空就返回nil
        //感叹号 如果转型不出来就会报错
        
        // if let xx =  如果取不出值在就到else里面去了
        if let tempResult = jsonResult["main"]?["temp"]? as? Double {
            //还需要cast
            //检查国家信息 转换摄氏化石
            var temperature: Double
            if (jsonResult["sys"]?["country"]? as String == "US") {
                temperature = round(((tempResult - 273.15) * 1.8) + 32)
            }
            else{
                temperature = round(tempResult - 273.15)
            }
            
            //放到ui上面
            self.temperature.text = "\(temperature)°"
            //通过代码设置字体
            self.temperature.font = UIFont.boldSystemFontOfSize(60)
            
            var name = jsonResult["name"] as String
            self.location.text = "\(name)"
            self.location.font = UIFont.boldSystemFontOfSize(25)
            
            // weather里面有个数组
            var weatherArray = jsonResult["weather"]? as NSArray
            var firstWeatherItem = weatherArray[0]  //@@@
            var condition = firstWeatherItem["id"]? as Int
            //var condition = (jsonResult["weather"]? as NSArray)[0]? ["id"]? as Int
            var sunrise = jsonResult["sys"]?["sunrise"]? as Double
            var sunset = jsonResult["sys"]?["sunset"]? as Double
            
            //判断排天还是晚上
            var nightTime = false
            var now = NSDate().timeIntervalSince1970
            
            
            if (now <  sunrise || now > sunset){
                nightTime = true
            }
            self.updateWeatherIcon(condition, nightTime: nightTime)
            
            
        }
        else{
            self.loading.text = "天气信息不可用"
        }
        
    }
    
    func updateWeatherIcon(condition: Int, nightTime: Bool){
        // <300 下雨
        if (condition < 300) {
            //白天下雨还是晚上下雨
            if nightTime {
                self.icon.image = UIImage(named:"tstrom1_night")
            }
            else{
                self.icon.image = UIImage(named: "tstorm1")
            }
        }
        // Drizzle
        else if (condition < 500) {
            self.icon.image = UIImage(named: "light_rain")
        }
        // Rain
        else if (condition < 600) {
            self.icon.image = UIImage(named: "shower3")
        }
        // Snow
        else if (condition < 700) {
            self.icon.image = UIImage(named: "snow4")
        }
        // fog / mist / haze / etc
        else if (condition < 771) {
            if nightTime {
                self.icon.image = UIImage(named:"fog_night")
            }
            else{
                self.icon.image = UIImage(named: "fog")
            }
        }
        // Toronado / Squalls
        else if (condition < 800) {
            self.icon.image = UIImage(named: "tstorm3")
        }
        //sunny
        else if (condition == 800) {
            if nightTime {
                self.icon.image = UIImage(named:"sunny_night")
            }
            else{
                self.icon.image = UIImage(named: "sunny")
            }
        }
        //few / scattered / broken clouds
        else if (condition < 804){
            if nightTime {
                self.icon.image = UIImage(named:"cloudy2_night")
            }
            else{
                self.icon.image = UIImage(named: "cloudy")
            }
        }
        // overcast clouds
        else if (condition < 800) {
            self.icon.image = UIImage(named: "overcast")
        }
        
        // Extreme
        else if ((condition >= 900 && condition < 903) || (condition > 904 && condition < 1000)){
            self.icon.image = UIImage(named: "tstorm3")
        }
        // cold
        else if (condition < 903) {
            self.icon.image = UIImage(named: "snow5")
        }
        // hot
        else if (condition < 903) {
            self.icon.image = UIImage(named: "sunny")
        }
        // weather condition is not available
        else {
            self.icon.image = UIImage(named: "dunno")
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println(error)
        self.loading.text = "地理位置信息不可用"
        //比较好的情况是要给用户feedback,报错
    }
}

