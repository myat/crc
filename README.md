# Resume site repo

This repo contains the files of my [resume site](https://resume.kgmy.at). This is built as a hands-on response to the Cloud Resume Challenge. Full details of the Cloud Resume Challenge can be found [here](https://cloudresumechallenge.dev/).

[![Backend Pipeline](https://github.com/myat/crc/actions/workflows/run-backend-pipeline.yml/badge.svg?branch=main)](https://github.com/myat/crc/actions/workflows/run-backend-pipeline.yml)
[![Frontend Pipeline](https://github.com/myat/crc/actions/workflows/run-frontend-pipeline.yml/badge.svg?branch=main)](https://github.com/myat/crc/actions/workflows/run-frontend-pipeline.yml)

## Architecture

The frontend static site is hosted in an AWS S3 bucket, served via CloudFront. The backend (a simple view counter) is provided by Lambda and DynamoDB, exposed through API Gateway. All infrastructure deployment is handled by Github Actions and Terraform.

![Architecture overview diagram of the serverless resume site on AWS](docs/images/CRC_Architecture.png)

## Deployment

Repo is continuously tested and deployed. Check [run-backend-pipeline](.github/workflows/run-backend-pipeline.yml) and [run-front-pipeline](.github/workflows/run-frontend-pipeline.yml) workflows for deployment steps.


## Contributing

Feedback, suggestions and pull requests for are welcome. Please open an issue first to discuss what you would like to change.