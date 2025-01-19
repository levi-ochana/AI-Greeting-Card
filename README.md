
# AI-Greeting-Card

This project demonstrates a scalable, cloud-based web application that allows users to generate, view, and download greeting cards dynamically using OpenAI's ChatGPT API. The application is deployed on AWS infrastructure, leveraging services like ECS, Fargate, and S3 for scalability, availability, and storage.

## Features

- **Dynamic Greeting Cards**: Users can generate greeting cards for real-world holidays using the OpenAI GPT API. The card text is generated dynamically and can be downloaded as an image.
- **User-Friendly Web Interface**: A Flask-based web application provides a simple and intuitive interface for interacting with the app.

### AWS Integration:
- **ECS (Fargate)** is used to run the containerized application.
- **S3** is utilized for storing generated greeting card images, enabling download functionality for users.
- **Application Load Balancer** ensures high availability and routes traffic to the containerized services.

### Infrastructure as Code (IaC):
- The AWS infrastructure is provisioned using Terraform, ensuring a repeatable and consistent deployment process.

### Auto Scaling:
- The ECS service auto-scales based on CPU utilization to handle traffic spikes efficiently.

### Cloud Logging and Monitoring:
- CloudWatch is configured to log application activity and monitor performance metrics.

### CI/CD Pipeline:
- GitHub Actions are used for automating the CI/CD process, integrated with Ansible for building and deploying the Docker image seamlessly.

## Architecture
![System Diagram](/infrastructure/diagram.png)

- **Frontend**: A lightweight HTML and CSS frontend served by Flask for user interaction.
- **Backend**: Python Flask application that interacts with:
  - OpenAI API for generating greeting card text.
  - AWS S3 for storing and retrieving images.

### AWS Services:
- **ECS Fargate**: For containerized deployment.
- **Application Load Balancer (ALB)**: For routing traffic to containers.
- **S3**: For storing generated greeting card images.
- **CloudWatch**: For logging and monitoring.
- **IaC (Terraform)**: Automates the provisioning of the entire infrastructure, including VPC, subnets, security groups, ECS services, and S3 buckets.

### CI/CD Pipeline:
- **GitHub Actions**: Executes automated workflows for building, testing, and deploying the application.
- **Ansible**: Used within the pipeline for managing infrastructure and deploying the Docker image to AWS ECR.

## Setup

### Prerequisites:
- Docker
- AWS CLI configured with proper credentials
- Terraform installed locally
- Python 3.10+
- GitHub account with repository access

### Steps:

#### Clone the Repository:
```bash
git clone https://github.com/levi-ochana/AI-Greeting-Card.git
cd AI-Greeting-Card
```

#### Set Up CI/CD:
Configure GitHub Actions in the repository by adding a workflow file (e.g., .github/workflows/deploy.yml).
reate an ansible directory with a `deploy.yml` playbook for ECR deployment.

#### Run Locally:
```bash
docker build -t greeting-card-app .
docker run -p 5000:5000 -e API_KEY=<your_openai_api_key> greeting-card-app
```

#### Access the Application:
- **Locally**: Open [http://localhost:5000](http://localhost:5000) in your browser.
- **Deployed**: Use the URL output by Terraform for the load balancer.

## Future Enhancements

- Implement user authentication for personalized greeting cards.
- Add support for multiple languages in card generation.
- Expand cloud functionality to include AI-driven card design templates.
- Enhance CI/CD pipelines for more advanced testing and monitoring capabilities.
