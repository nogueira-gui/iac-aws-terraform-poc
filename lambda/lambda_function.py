import json
import boto3
import os

def lambda_handler(event, context):
    # Verificar se o evento contém dados do corpo da requisição
    s3_bucket = os.environ['BUCKET_NAME']
    s3_file_key = event['pathParameters']['id']
    
    s3 = boto3.client('s3')  # Defina o endpoint_url para o LocalStack S3
    
    try:
        response = s3.get_object(Bucket=s3_bucket, Key=s3_file_key)
        file_content = response['Body'].read()
        parsed_content = json.loads(file_content)
        
        return {
            'statusCode': 200,
            'body': json.dumps(parsed_content)
        }
    except Exception as e:
        return {
            'statusCode': 404,
            'body': f'Erro ao buscar o arquivo no S3: {str(e)}'
        }
