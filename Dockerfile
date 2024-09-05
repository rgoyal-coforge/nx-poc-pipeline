name: Deploy to ECR

on:
 
  push:
    branches: [ main ]

jobs:
  
  build:
    
    name: Build Image
    runs-on: ubuntu-latest

   
      steps:
        - name: Checkout
          uses: actions/checkout@v2

        - name: Configure AWS credentials
          uses: aws-actions/configure-aws-credentials@v1
          with:
            aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
            aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
            aws-region: ap-south-1

        - name: Login to Amazon ECR
          id: login-ecr
          uses: aws-actions/amazon-ecr-login@v1

        - name: Get commit hash
          id: get-commit-hash
          run: echo "::set-output name=commit-hash::$(git rev-parse --short HEAD)"
        - name: Get timestamp
          id: get-timestamp
          run: echo "::set-output name=timestamp::$(date +'%Y-%m-%d-%H-%M')"

        - name: Build, tag, and push the image to Amazon ECR
          id: build-image
          env:
            ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
            ECR_REPOSITORY: ${{ secrets.REPO_NAME }}
            IMAGE_TAG: ${{ steps.get-commit-hash.outputs.commit-hash }}-${{ steps.get-timestamp.outputs.timestamp }}
          run: |
            docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
            docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAGFROM maven:3.8-jdk-11 AS build

WORKDIR /project

COPY ./javaapp/ /project

RUN mvn clean package

FROM openjdk:11-jre-slim

WORKDIR /app

COPY --from=build /project/target/helloworld-1.0-SNAPSHOT.jar ./

CMD ["java", "-jar", "./helloworld-1.0-SNAPSHOT.jar"]
