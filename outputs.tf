output "printer_lambda_arn" {
  description = "printer lambda arn"
  value       = aws_lambda_function.printer_lambda.arn
}

output "queue_arn" {
  description = "queue arn"
  value       = aws_sqs_queue.queue.arn
}

output "topic_arn" {
  description = "topic arn"
  value       = aws_sns_topic.topic.arn
}
