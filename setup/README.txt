This folder gets you set up to utilize a docker container with the respective levels.


Files in this folder:
Dockerfile    - This Dockerfile has the correct configuration for terraform 0.11.3 and will copy your secrets.tf in order to 'carry' it with you.  NOTE: THIS IS NOT A SECURE BEST PRACTICE and other more cumbersome workflows should be used in production.



Directions:
1) run the command:
docker build --build-arg AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID --build-arg AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -t my_images:terraformTutorial -f Dockerfile .
