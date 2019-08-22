# *tensr*

## Open source iOS App and Backend Tensorflow Server
### Train your models in python, serve the models in Go, and show them off with tensr. (ios App or WebApp)

#### tensr gives anyone the ability to easily and efficiently test Custom/Trained Tensorflow Image Classification Models

#### iOS App (iOS 13 & Swift UI Left & Center) | WebApp (Right)
<span>
	<img align="" width="250" height="550" src="https://raw.githubusercontent.com/revzim/tensr/master/examples/IMG_0649.PNG">
	<img align="" width="250" height="550" src="https://raw.githubusercontent.com/revzim/tensr/master/examples/IMG_0655.PNG">
	<img align="" width="250" height="550" src="https://raw.githubusercontent.com/revzim/tensr/master/examples/IMG_0657.PNG">
</span>

` Andy Zimmelman 2019 `

##### Environment
` macOS Catalina Beta 10.15 | Go 1.12 | XCode 11 beta 5 & Swift 5.0 | Tensorflow `


#### Server Mutli-Model Hosting Support

# 

#### Client Installation (iOS 13 App)
* Easy: Install the App from the iOS Apple App Store: tensr (pending... Requires iOS 13)
* Easy: 
	* In the `app/releases` directory, I will provide ipas for different versions
		* Until at least Apple's iOS 13 is universally released
		* Or until I get bored of this project and move onto another one :)
* Or:
* Clone repo `git clone https://github.com./revzim/tensr.git`
* Enter the `app/dev/` directory and find the correct version (ex. 1_1_18 is build 0.1.18)
* Ensure cocoapods is installed if you would like to successfully modify, test, and/or run the client from source
* Install pods `pod install`
* Open the app (ex. `open tensr.xcworkspace`)

#### Client (WebApp)
* Spin up the server
* Head to `localhost:8080/wa`
* Specify name of model if hosting multiple models
* Upload your image and test

#### Docker Server Installation
* Ensure docker is installed on your machine
* Build the Dockerfile and then run the docker image container
	* you may have to run docker as an elevated user depending on your install/machine
	* `docker build -t <NAME_OF_DOCKER_IMAGE_CONTAINER> .`
* Run the docker image container
	* `docker run -p 8080:8080 <NAME_OF_DOCKER_IMAGE_CONTAINER>`

#### Server Installation
* Clone this repo if you have not already: `git clone https://github.com/revzim/tensr.git`
* Server location: `go/src/`
	* Serve any custom trained Tensorflow Image Classification model with tensr
* Responds to any post requests that conform to the multipart upload of your test image file from the client
* Build this server to a location of your choosing: `go build -o bin/app`
* Once built, spin up your server with optional command line arguments/flags
	* Optional flags include a model graphs, graph file name, label file name, input node name, and output node name
	* There is an extra optional argument/flag labeled `count`
	* Specify count to increase/decrease amount of top labels returned as opposed to the default: 5
* Run the server:
	* `./go/bin/app --input=input_node_name --output=output_node_name --graphs=models_dir`


#### Requirements
* Client:
	* If you would like to work on the client, the client (app) is developed in Swift (5.0) and uses SwiftUI as the main UI library.
	* Depending on when you're attempting modification, you may be required to install XCode 11 beta to alter any code provided within the Swift iOS Application.
* Server: 
	* Modify the server files and any flags as necessary. You will need go installed to run the server.


##### Languages, Libraries, and Papers
* [Go](https://https://golang.org)
* [Swift](https://swift.org)
* [Tensorflow](https://tensorflow.org)
* [Cocoapods](https://cocoapods.org/)
* [Docker](https://www.docker.com/)
* [Inception-v4, Inception-ResNet and the Impact of Residual Connections on Learning](https://arxiv.org/abs/1602.07261)
* [Learning Transferable Architectures for Scalable Image Recognition](https://arxiv.org/abs/1707.07012)
* [Residual Attention Network for Image Classification](https://arxiv.org/abs/1704.06904)

##### Cocoapods
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
* [Alamofire](https://github.com/Alamofire/Alamofire)