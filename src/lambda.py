import boto3
import requests

print "starting lambda"

eb_client = boto3.client('elasticbeanstalk')
ec2 = boto3.resource('ec2')

def lambda_handler(event, context):
    # get all instances of an EB environemt and iterate over it
    response = eb_client.describe_environment_resources(EnvironmentName='my-fancy-environment')
    for instance in response["EnvironmentResources"]["Instances"]:
        instance = ec2.Instance(instance["Id"])
        print instance.private_ip_address
        try:
            response = requests.get("http://%s" % (instance.private_ip_address))
            # XXX: add healthcheck logic here and dont forget to fetch external libs (see Makefile)
            print "XXX: "+str(response.json())
        except Exception as e:
            print(e)

if __name__ == "__main__":
    lambda_handler(None, None)
