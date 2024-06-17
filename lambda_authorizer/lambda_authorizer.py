import json
import boto3
import os

ssm = boto3.client('ssm')
parameter_name = os.environ['TOKEN_PARAMETER_NAME']

def handler(event, context):
    token_response = ssm.get_parameter(
        Name=parameter_name,
        WithDecryption=True
    )
    secret_token = token_response['Parameter']['Value']
    
    if 'authorizationToken' not in event:
        return {
            'statusCode': 401,
            'body': json.dumps({
                'error': 'Missing Authorization header',
                'event': event
            })
        }

    auth_token = event['authorizationToken']
    if auth_token != f'Bearer {secret_token}':
        return generate_policy('user', 'Deny', event['methodArn'])

    return generate_policy('user', 'Allow', event['methodArn'])

def generate_policy(principal_id, effect, resource):
    return {
        'principalId': principal_id,
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': resource
                }
            ]
        }
    }
