import json
import aws_s3

def handler(event, context):
    
    try:
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
    