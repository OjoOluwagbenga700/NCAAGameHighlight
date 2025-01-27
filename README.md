# NCAAGameHighlight
HighlightProcessor
This project uses RapidAPI to obtain NCAA game highlights using a Docker container and uses AWS Media Convert to convert the media file.

File Overview
The config.py script performs the following actions: Imports necessary environment variables and assigns them to Python variables, providing default values where appropriate. This approach allows for flexible configuration management, enabling different settings for various environments (e.g., development, staging, production) without modifying the source code.

The fetch.py script performs the following actions:

Establishes the date and league that will be used to find highlights. We are using NCAA in this example because it's included in the free version. This will fetch the highlights from the API and store them in an S3 bucket as a JSON file (basketball_highlight.json)

process_one_video.py performs the following actions:

Connects to the S3 bucket and retrieves the JSON file. Extracts the first video URL from within the JSON file. Downloads the video file from the internet into the memory using the requests library. Saves the video as a new file in the S3 bucket under a different folder (videos/) Logs the status of each step

mediaconvert_process.py performs the following actions:

Creates and submits a MediaConvert job Uses MediaConvert to process a video file - configures the video codec, resolution and bitrate. Also configured the audio settings Stores the processed video back into an S3 bucket

run_all.py performs the following actions: Runs the scripts in a chronological order and provides buffer time for the tasks to be created.

.env file stores all over the environment variables, these are variables that we don't want to hardcode into our script.

Dockerfile performs the following actions: Provides the step by step approach to build the image.

Terraform Scripts (main.tf): This script is used to create an ec2 instance along side with the required IAM role and permission to successfully run all the python scripts that is required to build the game highlight processor.

Prerequisites
Before running the scripts, ensure you have the following:

1 Create Rapidapi Account
Rapidapi.com account, will be needed to access highlight images and videos.

For this example we will be using NCAA (USA College Basketball) highlights since it's included for free in the basic plan.

Sports Highlights API is the endpoint we will be using

2 Verify prerequites are installed
Docker should be pre-installed on the ec2 instance 
Python3 should be pre-installed on the ec2 instance

3 Retrieve Access Keys and Secret Access Keys
I will be using an assume role for the EC2 instance with necessary policies attached for access to the necessary AWS services.

Technical Diagram
GameHighlightProcessor

![image](https://github.com/user-attachments/assets/f80b39c5-bbc3-48f6-a562-f17b8a3ff8eb)

Project Structure

├── main.tf

├── Dockerfile

├── config.py

├── fetch.py

├── mediaconvert_process.py

├── process_one_video.py

├── requirements.txt

├── run_all.py

├── .env

├── .gitignore


START HERE 


Step 1: Clone The Repo

git clone https://github.com/alahl1/NCAAGameHighlights.git


Step 2: Update .env file

RapidAPI_KEY: Ensure that you have successfully created the account and select "Subscribe To Test" in the top left of the Sports Highlights API

S3_BUCKET_NAME=your_S3_bucket_name_here

MEDIACONVERT_ENDPOINT=https://your_mediaconvert_endpoint_here.amazonaws.com

MEDIACONVERT_ROLE_ARN=arn:aws:iam::your_account_id:role/HighlightProcessorRole

Step 3: Run Terraform command (terraform apply --auto-approve ) to deploy our EC2 instance, SSH into the instance and automatically run the script below 

      # Install Docker
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      # secure.env file
      "sudo chmod 600 .env",
      # Create Docker image
      "sudo docker build -t highlight-processor .",
      # Run Docker container with env file
      "sudo docker run --env-file .env highlight-processor",
      
This will run fetch.py, process_one_video.py and mediaconvert_process.py and the following files should be saved in your S3 bucket:

 video uploaded to s3:///videos/first_video.mp4

 video uploaded to s3:///processed_videos/

What We Learned
Working with Docker and AWS Services
Identity Access Management (IAM) and least privilege
How to enhance media quality


