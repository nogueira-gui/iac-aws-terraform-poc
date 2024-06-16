import json
import aws_s3

def handler(event, context):

    try:
        if event['httpMethod'] == 'POST' and event['path'] == '/exams':
            if 'body' not in event or event['body'] is None:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'Missing request body'})
                }

            body = json.loads(event['body'])
            if 'file_name' not in body or 'content' not in body:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'Missing file_name or content in request body'})
                }

            s3_file_key = body['file_name']
            file_content = body['content']
            aws_s3.upload_json_file(s3_file_key, file_content)
            
            return {
                'statusCode': 201,
                'body': json.dumps({'message': 'File uploaded successfully'})
            }

        if 'pathParameters' not in event or event['pathParameters'] is None:
            parsed_content = aws_s3.find_all()
            if parsed_content is None:
                parsed_content = []  # Ensure a non-None value is returned
            return {
                'statusCode': 200,
                'body': json.dumps(parsed_content)
            }

        s3_file_key = event['pathParameters'].get('id')
        if not s3_file_key:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Missing file key'})
            }

        parsed_content = aws_s3.find_by_id(s3_file_key)
        if parsed_content is None:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'File not found'})
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps(parsed_content)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
    