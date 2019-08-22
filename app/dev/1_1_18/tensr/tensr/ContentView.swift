//
//  ContentView.swift
//  tensr
//
//  Created by azim on 8/12/19.
//  Copyright © 2019 azim. All rights reserved.
//

import SwiftUI
import Alamofire
import SwiftyJSON

struct Prediction: Encodable, Identifiable {
    var id = UUID()
    
    let name: String
    let score: Float32
}

struct ContentView: View {
    
    @State var showImagePicker: Bool = false
    @State var image: Image? = nil
    @State var imagePicked: Bool = false
    @State var imageData: Data? = nil

    @State var uploadProgress: Double = 0.0
    @State var uploadProgressStr: String = ""
    
    @State var prediction: String = ""
    @State var btnPredictUploadStr: String = "Predict!"
    @State var predictions: [Prediction] = [Prediction](repeating: Prediction(id: UUID(), name: "", score: 0), count: 5)
    @State var showPredictionScores: Bool = false
    
    @State var customURL: String = "http://192.168.1.222:8080/classify"
    // @State var params: [String: Any]? = nil
    
    let settingsBtnCfg:UIImage.SymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 0.3, weight: .black, scale: .small)
    
    var body: some View {
        NavigationView {
            // IMAGE
            VStack {
                
                // SHOW IMAGE PICKER
                if (showImagePicker) {
                    ImagePicker(isShown: $showImagePicker, image: $image, imagePicked: $imagePicked, imageData: $imageData)
                }
                
                // DATA FORM
                Form {
                    HStack {
                        Text("Server: ")
                            .font(.headline)
                        
                        TextField("URL", text: $customURL)
                            .font(.subheadline)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    Button(action: (self.useCustomURL), label: {
                        Text("Change Server")
                    })
                    
                }
                
                if (showPredictionScores) {
                    
                    List (self.predictions) { p in
                        Section(header: Text("Object:").font(.headline), footer: Text("\(p.score)").font(.subheadline)) {
                            // OBJECT NAME
                            Text("\(p.name)").font(.subheadline)
                            // SCORE LABEL
                            Text("Score").font(.headline)
                        }.listStyle(GroupedListStyle())
                    }
                }
                VStack {
                    
                    // PREDICTION LABEL
                    Text("\(self.prediction)")
                        .font(.headline).foregroundColor(.blue)
                    
                    // IMAGE
                    image?
                        .resizable()
                        .frame(width: 200.0, height: 200.0)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.gray, lineWidth: 4))
                        .shadow(radius: 10)
                    
                }
                
                // IF USER CHOOSES IMAGE TO UPLOAD
                if (imagePicked) {
                    
                    // QUERY TF SERVER BUTTON
                    Button(action: { withAnimation {
                        // QUERY TENSORFLOW SERVER FOR PREDICTION AND RETURN RESULTS
                        self.predictImage(imageData: self.imageData!)
                        }
                    }) {
                        Text("\(btnPredictUploadStr)").font(.title).padding()
                            
                    }
                    // PROGRESS BAR
                    HStack {
                        ProgressBar(value: $uploadProgress)
                            // PROGRESS BAR COLOR
                        .foregroundColor(.blue)
                        // FORMATTED UPLOAD PROGRESS
                        Text("\(String(format: "%.2f", CGFloat(self.uploadProgress)))%")
                            .font(.headline).foregroundColor(.blue)
                    }
                }
                
            }
            .padding()
            .navigationBarTitle(Text("Choose A Photo"), displayMode: .large)
            .navigationBarItems(leading: Button(action: {
                self.showImagePicker.toggle()
                self.toggleUI()
                }) {
                    Image(uiImage: UIImage(named: "pics.png", in: nil, with: self.settingsBtnCfg)!)
                }, trailing: NavigationLink(destination: SettingsView()) {
                    Image(uiImage: UIImage(named: "cog.png", in: nil, with: self.settingsBtnCfg)!)
                }
            )
            
        }
        
    }
    
    func useCustomURL() {
        _ = Alert(title: Text("Changed Server"), message: Text("Changed server from default to: \(self.customURL)"), dismissButton: .default(Text("OK")))
    }
    
    func toggleUI() {
        self.image = nil
        self.imageData = nil
        self.uploadProgress = 0.0
        self.imagePicked = false
        self.btnPredictUploadStr = "Predict!"
        self.prediction = ""
        self.predictions = [Prediction](repeating: Prediction(id: UUID(), name: "", score: 0), count: 5)
        self.showPredictionScores = false
        
    }
    
    func predictImage(imageData: Data) {
        
        print("PREDICTIONS!")
        self.btnPredictUploadStr = "Uploading..."
        self.uploadProgress = 0.0
        self.prediction = ""
        
        // URL STRING FOR TENSORFLOW SERVER
        var request = URLRequest(url: URL(string: self.customURL)!)
        request.httpMethod = "POST"
        upload(image: imageData, to: request, params: ["": ""], uploadProgress: uploadProgress)
        
    }
    
    // https://stackoverflow.com/questions/40519829/upload-image-to-server-using-alamofire
    func upload(image: Data, to url: Alamofire.URLRequestConvertible, params: [String: Any], uploadProgress: Double) {
        AF.upload(multipartFormData: { multiPart in
            for (key, value) in params {
                if let temp = value as? String {
                    multiPart.append(temp.data(using: .utf8)!, withName: key)
                }
                if let temp = value as? Int {
                    multiPart.append("\(temp)".data(using: .utf8)!, withName: key)
                }
                if let temp = value as? NSArray {
                    temp.forEach({ element in
                        let keyObj = key + "[]"
                        if let string = element as? String {
                            multiPart.append(string.data(using: .utf8)!, withName: keyObj)
                        } else
                            if let num = element as? Int {
                                let value = "\(num)"
                                multiPart.append(value.data(using: .utf8)!, withName: keyObj)
                        }
                    })
                }
            }
            multiPart.append(image, withName: "file", fileName: "file.png", mimeType: "image/png")
        }, with: url)
            .uploadProgress(queue: .main, closure: { progress in
                // UPLOAD PROGRESS OF FILE
                self.uploadProgress = progress.fractionCompleted * 100
                // print("Upload Progress: \(progress.fractionCompleted)")
                if (self.uploadProgress >= 100.0) {
                    self.btnPredictUploadStr = "Predict!"
                }
            })
            .responseJSON(completionHandler: { data in
                // PARSE JSON RESPONSE
                if (data.response?.statusCode == nil){
                    // NO CONNECTION CAN BE OR HAS BEEN ESTABLISHED
                    // SERVER MOST LIKELY OFFLINE!
                    self.btnPredictUploadStr = "Predict!"
                    self.prediction = "There was an error uploading your image!\nPlease try again later!"
                    return
                }
                if data.data != nil {
                    if let json = try? JSON(data: data.data!) {
                        // print(json)
                        for (index, item) in json["labels"].arrayValue.enumerated() {
                            let probableChance = item["probability"].doubleValue
                            let label = item["label"].stringValue
                            if (index == 0) {
                                // \(isStartVowel(str: label.lowercased()) ? "an" : "a")
                                self.prediction = "Most likely: \(label)"
                            }
                            
                            self.predictions[index] = Prediction(name: label, score: Float32(probableChance))
                            
                            if (index == 4) {
                                self.showPredictionScores = true
                            }
                            // return
                        }
                    }
                }
            })
    }
    
    
}


#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(showImagePicker: false, image: nil, imagePicked: false, imageData: nil)
    }
}
#endif


