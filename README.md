# aws-cloudformation-performance-testing

If you are beginning your journey with
[Senzing](https://senzing.com/),
please start with
[Senzing Quick Start guides](https://docs.senzing.com/quickstart/).

You are in the
[Senzing Garage](https://github.com/senzing-garage)
where projects are "tinkered" on.
Although this GitHub repository may help you understand an approach to using Senzing,
it's not considered to be "production ready" and is not considered to be part of the Senzing product.
Heck, it may not even be appropriate for your application of Senzing!

## Synopsis

For use in testing versions of Senzing located on the staging server.

### Launch AWS Cloudformation

1. :thinking: **Warning:** This Cloudformation deployment will accrue AWS costs.
   With appropriate permissions, the
   [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/)
   can help evaluate costs.
1. Visit [AWS Cloudformation console](https://console.aws.amazon.com/cloudformation/home)
1. In upper-right, click "Create stack" > "With new resources (standard)"
1. In **Create stack** page
    1. Check ":radio_button: Upload a temporary file"
    1. Click "Choose file" button
    1. Select local copy of [cloudformation.yaml](cloudformation.yaml)
    1. In lower-right, click on "Next" button.
1. In **Specify stack details**
    1. In **Stack name**
        1. Make a stack starting with your initials.  (So we can see who owns a stack.)
           Example:
            1. `mjd-1001`
    1. In **Parameters**
        1. In **Security responsibility**
            1. Understand the nature of the security in the deployment.
            1. Once understood, enter "I AGREE".
        1. In **Senzing installation**
            1. Enter the version of `senzingapi` you want to test.
               Example: `2.5.0-21104`
            1. Accept the End User License Agreement
        1. In **Security**
            1. Enter your email address.  Example: `me@example.com`
    1. Other parameters are optional.
       The default values are fine.
    1. In lower-right, click "Next" button.
1. In **Configure stack options**
    1. In lower-right, click "Next" button.
1. In **Review {stack-name}**
    1. Near the bottom, in **Capabilities**
        1. Check ":ballot_box_with_check: I acknowledge that AWS CloudFormation might create IAM resources."
    1. In lower-right, click "Create stack" button.

## Testing

1. Visit [AWS Cloudformation console](https://console.aws.amazon.com/cloudformation/home)
1. Choose cloudformation stack that was deployed for testing
1. Choose "Outputs" tab
    1. Open value for **0penFirst** in a new browser tab
        1. Page will show warning because of the self-signed certificate used for HTTPS by the Application Load Balancer.
           Figure out how to proceed past the warning.
        1. You will be prompted for email and password.
           From the "Outputs" tab, use **UserName** and **UserInitPassword** values.
        1. Supply a new password.
    1. Open value for **UrlApiServerHeartbeat** in a new browser tab
        1. Verify that API server responds
        1. Change URL so that the URI is `/api/entities/1`
            1. Verify that an entity was returned
    1. Open value for **UrlWebApp** in a new browser tab
        1. In the "Entity Search" web app
            1. Search for "Robert Smith"
            1. Verify result
    1. Open value for **UrlXterm** in a new browser tab
        1. In XTerm window, enter
            1. `G2Command.py`
            1. `(g2cmd) getEntityByEntityID 1`
            1. Verify result
    1. Open value for **UrlSwagger** in a new browser tab
        1. Specify server
            1. **Servers**, choose `{protocol}://{host}:{port}{path}`
            1. **protocol:** https
            1. **host:** On "Outputs" tab, value of **Host**.  Be careful of leading or trailing spaces.
            1. **port:** 443
            1. **path:** /api
            1. Verify "Computed URL:"
        1. Try URIs
            1. GET `/heartbeat`
            1. GET `/entities/{entitId}`
