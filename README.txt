Hello,

Here you will find an introduction to utilizing terraform on AWS for Insight DO Fellows.
Please clap the accompanying Medium Article : LINK

The requirements are:
1) Docker
2) An active AWS account
3) A Pemkey downloaded from AWS console in your ~/.ssh/ folder
4) Your environment variables set up as per the Insight documentation.  I.E. AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
In order to deploy a level in AWS use the command:
docker run --rm -it -v $(pwd):/tmp  my_images:terraformTutorial /bin/sh
