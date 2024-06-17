import json
import boto3
import os

def handler(event, context):
    
    try:
        secret_token = get_secret_token()
        auth_token = get_auth_token(event)

        if not auth_token:
            return generate_response(401, 'Missing Authorization header', event)

        if auth_token != f'Bearer {secret_token}':
            return generate_policy('user', 'Deny', event['methodArn'])

        return generate_policy('user', 'Allow', event['methodArn'])

    except Exception as e:
        return generate_response(500, f'Internal server error: {str(e)}', event)


def get_secret_token():
    parameter_name = os.environ['TOKEN_PARAMETER_NAME']
    ssm = boto3.client('ssm')
    response = ssm.get_parameter(Name=parameter_name, WithDecryption=True)
    return response['Parameter']['Value']


def get_auth_token(event):
    return event.get('authorizationToken')


def generate_policy(principal_id, effect, method_arn):
    # Extract the API Gateway ARN parts
    arn_parts = method_arn.split(':')
    api_gateway_arn_parts = arn_parts[5].split('/')
    # EXAMPLE : arn:aws:execute-api:us-east-1:0000000000:zzzzzzzzzzz/ESTestInvoke-stage/GET/
    # Construct the resource ARN to allow/deny all routes in the API Gateway
    resource_arn = f'{arn_parts[0]}:{arn_parts[1]}:{arn_parts[2]}:{arn_parts[3]}:{arn_parts[4]}:{api_gateway_arn_parts[0]}/*'
    
    return {
        'principalId': principal_id,
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': resource_arn
                }
            ]
        }
    }


def generate_response(status_code, message, event):
    return {
        'statusCode': status_code,
        'body': json.dumps({
            'error': message,
            'event': event
        })
    }
