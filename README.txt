Hello,

Here you will find an introduction to utilizing terraform on AWS for Insight DO Fellows.

The requirements are:
1) Docker
2) An active AWS account
3) A Pemkey downloaded from AWS console in your ~/.ssh/ folder

In order to deploy a level in AWS use the command:
docker run -it -v $(pwd):/tmp -rm my_images:terraformTutorial /bin/sh
