import json

def handler(event, context):
    
    if 'Token' not in event:
        return {
            'statusCode': 401,
            'body': json.dumps({
                'error': 'Missing Authorization header',
                'event': event
            })
        }

    auth_token = event['Token']
    if auth_token != 'Bearer my_secret_token':
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
