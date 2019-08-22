// ANDY ZIMMELMAN 2019
package main

// https://github.com/tensorflow/tensorflow/blob/master/tensorflow/go/example_inception_inference_test.go

import (
	"bytes"
	"log"

	tf "github.com/tensorflow/tensorflow/tensorflow/go"
	"github.com/tensorflow/tensorflow/tensorflow/go/op"
)

func generateTensorFromImage(imageBuffer *bytes.Buffer, imageFormat string) (*tf.Tensor, error) {
	// GENERATE TENSOR
	tensor, err := tf.NewTensor(imageBuffer.String())
	if err != nil {
		log.Printf("Error occurred generating the new TF Tensor.")
		return nil, err
	}

	// GENERATE GRAPH 
	graph, input, output, err := generateTransformImageGraph(imageFormat)
	if err != nil {
		log.Printf("Error occurred generating the TF graph.")
		return nil, err
	}

	// GENERATE TF SESSION WITH NEWLY GENERATED GRAPH
	session, err := tf.NewSession(graph, nil)
	if err != nil {
		log.Printf("Error occurred generating new TF session from graph.")
		return nil, err
	}

	defer session.Close()

	// RUN INFERENCE AND RETURN NORMALIZED OUTPUT TENSOR
	normalized, err := session.Run(
		map[tf.Output]*tf.Tensor{input: tensor},
		[]tf.Output{output},
		nil)
	if err != nil {
		log.Printf("Error occurred generating normalized image.")
		return nil, err
	}
	return normalized[0], nil
}

/*
	GENERATE TRANSFORM IMAGE GRAPH
	RETURN THE GRAPH ALONG WITH INPUT & OUTPUT
*/
func generateTransformImageGraph(imageFormat string) (graph *tf.Graph, input, output tf.Output, err error) {

	// GENERATE EMPTY NODE FOR *ROOT NODE OF GRAPH
	root := op.NewScope()
	
	// PLACEHOLDER STRING TENSOR
	// STRING = ENCODED JPG/PNG IMAGE
	input = op.Placeholder(root, tf.String)

	// DECODE IMAGE
	decode := decodeImage(imageFormat, root, input)

	// APPLY NORMALIZATION
	output = performOps(root, decode) 

	graph, err = root.Finalize()
	return graph, input, output, err
}

func decodeImage(imageFormat string, root *op.Scope, input tf.Output) tf.Output {
	
	if imageFormat == "png" {
		return op.DecodePng(root, input, op.DecodePngChannels(3))
	} else {
		return op.DecodeJpeg(root, input, op.DecodeJpegChannels(3))
	}
}

// MODEL RECIEVES 4D TENSOR OF SHAPE [BATCHSIZE, HEIGHT, WIDTH, COLORS=3]
// 
// RETURN OUTPUT AFTER RESIZING & NORMALIZING
func performOps (root *op.Scope, decode tf.Output) tf.Output {
	// CONSTANTS
	const (
		H, W  = 128, 128
		Mean  = float32(0)
		Scale = float32(255)
	)

	// DIV & SUB PERFORM VAL-MEAN / SCALE PER PIXEL
	// APPLIES NORMALIZATION ON EACH PIXEL
	return op.Div(root,
			op.Sub(root,
				// BILINIEAR 
				op.ResizeBilinear(root,
					// GENERATE BATCH OF SIZE 1 BY EXPANDDIMS
					op.ExpandDims(root,
						// APPLY SCOPES FOR GRAPH FINALIZATION
						op.Cast(root, decode, tf.Float),
						op.Const(root.SubScope("make_batch"), int32(0))),
					op.Const(root.SubScope("size"), []int32{H, W})),
				op.Const(root.SubScope("mean"), Mean)),
			op.Const(root.SubScope("scale"), Scale))
}

