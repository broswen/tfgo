package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

type PrinterResponse struct {
	Message string `json:"message"`
}

var ddbClient *dynamodb.Client

func Handler(ctx context.Context, sqsEvent events.SQSEvent) (PrinterResponse, error) {
	processed := 0
	total := len(sqsEvent.Records)
	for _, event := range sqsEvent.Records {
		snsEntity := events.SNSEntity{}
		err := json.Unmarshal([]byte(event.Body), &snsEntity)
		if err != nil {
			log.Println("Error unmarshalling sns entity", err.Error())
			continue
		}

		if snsEntity.Message == "SKIP" {
			log.Println("Skipping with explicit SKIP", snsEntity.MessageID)
			continue
		}

		j, err := json.Marshal(snsEntity)
		if err != nil {
			log.Println("Error marshalling sns entity", err.Error())
			continue
		}
		ddbClient.PutItem(context.TODO(), &dynamodb.PutItemInput{
			TableName: aws.String(os.Getenv("table")),
			Item: map[string]types.AttributeValue{
				"PK":      &types.AttributeValueMemberS{Value: snsEntity.MessageID},
				"SK":      &types.AttributeValueMemberS{Value: time.Now().Format(time.RFC3339)},
				"Message": &types.AttributeValueMemberS{Value: snsEntity.Message},
				"Subject": &types.AttributeValueMemberS{Value: snsEntity.Subject},
			},
		})
		fmt.Println(string(j))
		processed++
	}
	fmt.Printf("Processed %d out of %d\n", processed, total)
	return PrinterResponse{fmt.Sprintf("Processed %d out of %d", processed, total)}, nil
}

func init() {
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatal(err)
	}
	ddbClient = dynamodb.NewFromConfig(cfg)
}

func main() {
	lambda.Start(Handler)
}
