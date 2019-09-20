// ANDY ZIMMELMAN 2019
package main

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"html/template"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"sort"
	"strings"

	"github.com/julienschmidt/httprouter"
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
)

type ClassificationResult struct {
	Filename string        			`json:"filename"`
	Labels   []LabelResult 			`json:"labels"`
}

type LabelResult struct {
	Label       string  				`json:"label"`
	Probability float32 				`json:"probability"`
}

type Prediction struct {
	LabelText       string 			
	ProbabilityText string
}

type ModelResponse struct {
	Models 					[]string 		`json:"models"` 
}

type ProbabilityLabels []LabelResult

func (lbls ProbabilityLabels) Len() int           { return len(lbls) }
func (lbls ProbabilityLabels) Swap(i, j int)      { lbls[i], lbls[j] = lbls[j], lbls[i] }
func (lbls ProbabilityLabels) Less(i, j int) bool { return lbls[i].Probability > lbls[j].Probability }

var (

	// GRAPH MODELS
	graphModels map[string]*tf.Graph

	// SESSION MODELS
	sessionModels map[string]*tf.Session

	// LABELS FOR EACH GRAPH
	graphLabels map[string][]string

	// names of models
	modelNames []string

	// HELPER MODEL RESPONSE JSON
	modelResponse ModelResponse

	// FLAG VARS
	graphsFlag      string
	graphNameFlag   string
	labelNameFlag   string
	inputNodeFlag   string
	outputNodeFlag  string
	labelsCountFlag int
)

func init() {
	// FLAGS
	flag.StringVar(&graphsFlag, "graphs", "models", "path to TF model output graphs and labels")
	flag.StringVar(&graphNameFlag, "graph_name", "output_graph.pb", "name of graph file")
	flag.StringVar(&labelNameFlag, "label_name", "output_labels.txt", "name of labels file")
	flag.StringVar(&inputNodeFlag, "input", "Placeholder", "model input node name. model dependent.")
	flag.StringVar(&outputNodeFlag, "output", "final_result", "model output node name. model dependent.")
	flag.IntVar(&labelsCountFlag, "count", 5, "amount of labels returned to the client. default=5")
}

func main() {
	flag.Parse()
	if err := generateModelsAndLabels(graphsFlag, graphNameFlag, labelNameFlag); err != nil {
		log.Fatal(err)
		return
	}

	r := httprouter.New()

	r.GET("/wa", ServeWebApp)

	r.GET("/models", GetModels)

	r.POST("/classify/:model", ClassifyHandler)
	r.POST("/classify", ClassifyHandler)

	fmt.Println("Listening on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", r))
}

func generateModelsAndLabels(parentDir string, graphFileName string, labelFileName string) error {
	// LOAD MODEL
	dirs, err := ioutil.ReadDir(parentDir)
	if err != nil {
		log.Fatal(err)
	}

	// MODELS MAP
	models := make(map[string]*[]byte)

	// GENERATE GRAPH LABELS MAP
	graphLabels = make(map[string][]string, len(dirs))
	for _, dir := range dirs {
		if !dir.IsDir() {
			continue
		}
		log.Printf("Searching for a TF model within %s/%s...", parentDir, dir.Name())
		model := readFile(fmt.Sprintf("%s/%s/%s", parentDir, dir.Name(), graphFileName))
		log.Printf("Found model file...")
		// log.Printf("Updating models map... %s", model)
		models[dir.Name()] = &model
		log.Printf("Updated models map with new model.")

		if loadFileLabels(fmt.Sprintf("%s/%s/%s", parentDir, dir.Name(), labelFileName), dir.Name()) != nil {
			log.Printf("Generated Graph and Labels for imported model: %s", dir.Name())
		}

	}

	log.Printf(fmt.Sprintf("Located %d models for inference.", len(models)))
	graphModels = make(map[string]*tf.Graph, len(models))
	sessionModels = make(map[string]*tf.Session, len(models))

	// MODEL NAMES
	modelNames = make([]string, len(models))

	i := 0
	for key, model := range models {
		modelNames[i] = key
		modelResponse.Models = append(modelResponse.Models, key)
		log.Printf(modelNames[i])
		// log.Printf(key)
		graphModels[key] = tf.NewGraph()
		if err := graphModels[key].Import(*model, ""); err != nil {
			return err
		}
		// ASSIGN MODEL FOR NEW SESSION
		sessionModels[key], err = tf.NewSession(graphModels[key], nil)
		if err != nil {
			log.Fatal(err)
		}
		i++
	}

	return nil

}

func readFile(filePath string) []byte {
	f, err := ioutil.ReadFile(filePath)
	if err != nil {
		log.Panic(err)
	}
	log.Printf("Found file...")
	return f
}

func loadFileLabels(labelsFileName string, modelName string) error {
	// LOAD LABELS
	log.Printf("Searching for corresponding labels file...")
	labelsFile, err := os.Open(labelsFileName)
	if err != nil {
		return err
	}
	var lbls []string
	defer labelsFile.Close()
	log.Printf("Found corresponding label file")

	scanner := bufio.NewScanner(labelsFile)

	// NEW LINE DEFINE NEW LABEL
	log.Printf("Updating labels map...")
	for scanner.Scan() {
		lbls = append(lbls, scanner.Text())
	}
	if err := scanner.Err(); err != nil {
		return err
	}
	graphLabels[modelName] = lbls
	return nil
}

func GetModels(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	responseJSON(w, modelResponse)
}

func ServeWebApp(w http.ResponseWriter, r *http.Request, params httprouter.Params) {
	t, err := template.ParseFiles("go/src/public/index.html")
	if err != nil {
		fmt.Println(err)
	}
	prediction := Prediction{
		LabelText:       "Label",
		ProbabilityText: "Probability",
	}
	t.Execute(w, prediction)
}

func ClassifyHandler(w http.ResponseWriter, r *http.Request, params httprouter.Params) {
	// MODEL NAME USER REQUESTED
	var chosenModel string
	chosenModel = params.ByName("model")

	if chosenModel == "" {
		log.Println("User did not specify model, using default: model")
		chosenModel = "model"
	}
	log.Printf("Using model: %s", chosenModel)

	if !doesModelExist(chosenModel) {
		log.Panic("Model chosen does not exist!")
	}

	// IMAGE FROM POST REQUEST
	imageFile, header, err := r.FormFile("file")

	// FILNAME & EXTENSION JPG/PNG
	imageName := strings.Split(header.Filename, ".")
	if err != nil {
		responseError(w, "Could not read image", http.StatusBadRequest)
		return
	}

	defer imageFile.Close()

	var imageBuffer bytes.Buffer

	// IMAGE DATA COPIED TO BUFFER
	io.Copy(&imageBuffer, imageFile)

	// MAKE TENSOR
	tensor, err := generateTensorFromImage(&imageBuffer, imageName[:1][0])
	if err != nil {
		log.Printf("INVALID IMAGE")
		responseError(w, "Invalid image", http.StatusBadRequest)
		return
	}

	// EXECUTE SESSION AND RUN INFERENCE
	output, err := sessionModels[chosenModel].Run(
		map[tf.Output]*tf.Tensor{
			graphModels[chosenModel].Operation(inputNodeFlag).Output(0): tensor,
		},
		[]tf.Output{
			graphModels[chosenModel].Operation(outputNodeFlag).Output(0),
		},
		nil)
	if err != nil {
		responseError(w, "Could not run inference", http.StatusInternalServerError)
		return
	}

	// RETURN BEST LABELS FROM CLASSIFICATION
	responseJSON(w, ClassificationResult{
		Filename: header.Filename,
		Labels:   getBestLabels(output[0].Value().([][]float32)[0], labelsCountFlag, chosenModel),
	})
}

func doesModelExist(modelName string) bool {
	// IF MODEL NAME EXISTS RETURN TRUE, ELSE FALSE
	for i := range modelNames {
		if modelNames[i] == modelName {
			return true
		}
	}
	return false
}

func getBestLabels(probabilities []float32, amount int, chosenModel string) []LabelResult {
	// GENERATE LABELS & PROBABILITY LIST
	var results []LabelResult
	for i, p := range probabilities {
		if i >= len(graphLabels[chosenModel]) {
			break
		}
		results = append(results, LabelResult{Label: graphLabels[chosenModel][i], Probability: p})
	}
	// SORT RESULTS BY PROBABILITY SCORE
	sort.Sort(ProbabilityLabels(results))

	return results[:amount]
}
