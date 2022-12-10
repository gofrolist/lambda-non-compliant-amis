import boto3


def lambda_handler(event, context):
    region = event['region']
    compliant_amis = event['compliant_amis']
    email = event['email']

    # Create boto3 clients
    ec2 = boto3.client('ec2', region_name=region)
    ses = boto3.client('ses')

    # get the list of verified email addresses
    verified_emails = ses.list_verified_email_addresses()['VerifiedEmailAddresses']

    # check if the email address is verified
    if email not in verified_emails:
        # verify the email address
        print('Email address is not verified. Check your email and validate it first.')
        ses.verify_email_identity(EmailAddress=email)
        return

    # scan the region for EC2 instances
    instances_full_details = ec2.describe_instances(
        Filters=[
            {
                'Name': 'instance-state-name',
                'Values': ['running'],
            },
        ]
    )['Reservations']

    # check if any instances are running non-compliant AMIs
    non_compliant_instances = []
    for instance_detail in instances_full_details:
        group_instances = instance_detail['Instances']
        for instance in group_instances:
            # get the AMI ID of the instance
            ami_id = instance['ImageId']

            # check if the AMI is compliant
            if ami_id not in compliant_amis:
                # add the instance to the list of non-compliant instances
                non_compliant_instances.append(instance)

    # if there are any non-compliant instances, stop them and send an email
    if non_compliant_instances:
        # stop the non-compliant instances
        instance_ids = [i['InstanceId'] for i in non_compliant_instances]
        # ec2.stop_instances(InstanceIds=instance_ids)

        # send an email notification
        ses.send_email(
            Source=email,
            Destination={
                'ToAddresses': [email],
            },
            Message={
                'Subject': {
                    'Data': 'Non-compliant EC2 instances detected',
                },
                'Body': {
                    'Text': {
                        'Data': 'The following EC2 instances were detected as running non-compliant AMIs: {}'.format(
                            ', '.join(instance_ids)),
                    },
                },
            },
        )

    return
