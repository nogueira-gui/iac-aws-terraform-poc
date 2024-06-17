import json
import boto3
import os

def handler(event, context):
    """
    Lambda function to authorize API Gateway requests based on a token stored in AWS SSM Parameter Store.
    """
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


def generate_response(status_code, message, event):
    return {
        'statusCode': status_code,
        'body': json.dumps({
            'error': message,
            'event': event
        })
    }
