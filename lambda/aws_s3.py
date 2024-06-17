import json
import boto3
import os

def find_by_id(s3_file_key:str):

    s3_bucket = os.environ['BUCKET_NAME']
    
    s3 = boto3.client('s3')
    
    try:
        response = s3.get_object(Bucket=s3_bucket, Key=s3_file_key)
        file_content = response['Body'].read()
        parsed_content = json.loads(file_content)
        
        return parsed_content
    except Exception as e:
        return {
            'statusCode': 404,
            'body': f'Erro ao buscar o arquivo no S3: {str(e)}'
        }
    
def find_all():
        
        s3_bucket = os.environ['BUCKET_NAME']
        
        s3 = boto3.client('s3')
        
        try:
            response = s3.list_objects_v2(Bucket=s3_bucket)
            parsed_content = [content['Key'] for content in response['Contents']]
            
            return parsed_content
        except Exception as e:
            return {
                'statusCode': 404,
                'body': f'Erro ao buscar o arquivo no S3: {str(e)}'
            }


def upload_json_file(s3_file_key:str, file_content:dict):
    
    s3_bucket = os.environ['BUCKET_NAME']
    
    s3 = boto3.client('s3')
    
    try:
        response = s3.put_object(Bucket=s3_bucket, Key=s3_file_key, Body=json.dumps(file_content))
        
        return response
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Erro ao salvar o arquivo no S3: {str(e)}'
        }

def delete_json_file(s3_file_key:str):
    
    s3_bucket = os.environ['BUCKET_NAME']
    
    s3 = boto3.client('s3')
    
    try:
        response = s3.delete_object(Bucket=s3_bucket, Key=s3_file_key)
        
        return response
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Erro ao deletar o arquivo no S3: {str(e)}'
        }