import json
import aws_s3

def handler(event, context):

    try:

        if 'pathParameters' not in event:
            parsed_content = aws_s3.find_all()
            return {
                'statusCode': 200,
                'body': json.dumps(parsed_content)
            }

        s3_file_key = event['pathParameters']['id']

        parsed_content = aws_s3.find_by_id(s3_file_key)
        
        return {
            'statusCode': 200,
            'body': json.dumps(parsed_content)
        }
    except Exception as e:
        return {
            'statusCode': 404,
            'body': f'Erro ao buscar o arquivo no S3: {str(e)}'
        }
