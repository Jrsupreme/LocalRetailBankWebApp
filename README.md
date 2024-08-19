# Deploying a Local Retail Bank Application through AWS Elastic Beanstalk

# CI/CD pipeline with AWS CLI

## Purpose

The purpose of this workload is to automate the CI/CD pipeline further by integrating AWS CLI and Elastic Beanstalk CLI (EB CLI) into the deployment process. This approach eliminates the need for manual uploads of source code, enhancing the efficiency and reliability of deployments.

## Steps Taken

### 1. Clone the Repository

Cloning the repository allows us to work with a local copy of the source code, which will be deployed through the CI/CD pipeline.

```jsx
$ git clone [https://github.com/kura-labs-org/C5-Deployment-Workload-2](https://github.com/kura-labs-org/C5-Deployment-Workload-2)
```

### 2. Create AWS Access Keys

AWS Access Keys are required to interact with AWS services via the CLI. They provide the necessary credentials to authenticate API requests.

- **Create Access Keys:**
    - Navigate to IAM in AWS Console
    - Create new access keys under your user profile
    - **Important:** Save the access keys securely as possible as they can only be viewed once.

### 3. Create an EC2 Instance for Jenkins

A new EC2 instance is necessary to run Jenkins, which will manage the CI/CD pipeline. This instance is where we will install Jenkins and configure the necessary tools for deployment.

- **Instance Type:** t2.micro
- **Operating System:** Ubuntu
- **Install Jenkins**: Follow the same steps as in the firs deployment to install Jenkins on this EC2 instance.

```jsx
$sudo apt update && sudo apt install fontconfig openjdk-17-jre software-properties-common && sudo add-apt-repository ppa:deadsnakes/ppa && sudo apt install python3.7 python3.7-venv
$sudo wget -O /usr/share/keyrings/jenkins-keyring.asc [https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key](https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key)
$echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" [https://pkg.jenkins.io/debian-stable](https://pkg.jenkins.io/debian-stable) binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
$sudo apt-get update
$sudo apt-get install jenkins
$sudo systemctl start jenkins
$sudo systemctl status jenkins
```

### 4. Create a System Resources Check Script

This script checks system resources (memory, CPU, disk) and uses exit codes to signal whether the resources are within acceptable limits. This is critical for monitoring system health, especially when running through a CI/CD pipeline.

```jsx
#!/bin/bash

#set up thresholds
#check for system resources
#get cpu, memory and disk usage
#compared usage to threshold
#display results
#set up exit

#Setting up functions to check for cpu, memory and disk usage.

# Function to check for cpu usage
check_cpu() {
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}') #Looks at system resource consumption logs and specifically isolates the cpu usage number and stores the result in the variable 'cpu_usage'.
    cpu_threshold=70

    if (( $(echo "$cpu_usage > $cpu_threshold" | bc -l) )); then #Compares the cpu usage numbers to the set threshold.
        echo "CPU usage is high: $cpu_usage%"    
        return 1 #If cpu usage exceeds threshold exit function with error code.
    else
        echo "CPU usage is normal: $cpu_usage%"
        return 0 #If cpu usage DOES NOT exceed threshold exit function with success code.
    fi
}

# Function to check memory usage
check_memory() {
    memory_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}') #Looks at the memory usage numbers and calculates the usage dividing used memory by total memory and stores the result in the variable 'memory_usage'.
    memory_threshold=90 

    if (( $(echo "$memory_usage > $memory_threshold" | bc -l) )); then #Compares memory usage numbers to the threshold.
        echo "Memory usage is high: $memory_usage%"
        return 1  #If mem usage exceeds threshold exit function with error code.
    else
        echo "Memory usage is normal: $memory_usage%"
        return 0  #If mem usage DOES NOT exceed threshold exit function with success code.
    fi
}

# Function to check disk usage
check_disk() {
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')  #Retrieves the disk usage percentage of the root ("/"), removes the "%" sign and stores the value in the variable "disk_usage".
    disk_threshold=70

    if (( disk_usage > disk_threshold )); then #compares disk usage to theshold.
        echo "Disk usage is high: $disk_usage%"
        return 1 #If disk usage exceeds threshold exit function with error code.
    else
        echo "Disk usage is normal: $disk_usage%"
        return 0 #If disk usage DOES NOT exceed threshold exit function with success code.
    fi
}

# Main script
#Since functions have already been set, the main script only needs to check for 1's and 0's (which is pretty cool)
echo "Checking system resources..."

check_cpu # Runs the check_cpu function and stores its exit status in the variable 'cpu_status'.
cpu_status=$?

check_memory # Runs the check_memory function and stores its exit status in the variable 'memory_status'.
memory_status=$?

check_disk # Runs the check_disk function and stores its exit status in the variable 'disk_status'.
disk_status=$?

# Check if any resource exceeded the threshold
if [ $cpu_status -eq 1 ] || [ $memory_status -eq 1 ] || [ $disk_status -eq 1 ]; then # If any of the conditions (cpu, memory, or disk status) is true, the script will post a warning and exit.
    echo "One or more system resources exceeded the threshold."
    exit 1
else
    echo "All system resources are within normal limits."
    exit 0
fi
```

During this workload I decided to challenge my self and learn something new. Since my bash skill could use some improvement. I went ahead and did extensive research on bash functions. I learned how to define and re-call a function, and their various practical applications in scripting.

### 5. Create a Multi-Branch Pipeline

As in the previous deployment, multi-branch pipeline allows Jenkins to automatically detect and build branches in the repository. This setup is very important when it comes to handling different versions and environments of the application.

### 6. Install AWS CLI on Jenkins

AWS CLI allows for automated interaction with AWS services, enabling us to deploy the application directly from Jenkins without manual intervention.

```
$curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
$unzip awscliv2.zip
$sudo ./aws/install
$aws --version
```

**Result:** AWS CLI installed and version confirmed.

### 7. Install and Configure AWS Elastic Beanstalk CLI (EB CLI)

EB CLI simplifies the process of deploying applications to Elastic Beanstalk, enabling us to create, manage, and update environments directly from the Jenkins server.

```jsx
# Switch to the Jenkins user
$sudo passwd jenkins
$sudo su - jenkins

# Navigate to the pipeline directory
$cd workspace/LocalRetailBank_main

# Activate the Python Virtual Environment
$source venv/bin/activate

# Install EB CLI
$pip install awsebcli
$eb --version
```

Result: EB CLI installed and version confirmed.

### 8. Configure AWS CLI

Configuring AWS CLI with the access keys enables the Jenkins server to interact with AWS services like EC2 and Elastic Beanstalk.

```jsx
$aws configure
# Enter Access Key (created in step 2)
# Secret Access Key (also created in step 2)
# region (us-east-1) 
# output format (json)
```

**Verification:** Ensure the configuration is correct by running:

```jsx
$aws ec2 describe-instances
```

Results:

```jsx
{
  "Reservations": [
    {
      "Groups": [],
      "Instances": [
        {
          "AmiLaunchIndex": 0,
          "ImageId": "[REDACTED]",
          "InstanceId": "[REDACTED]",
          "InstanceType": "t2.micro",
          "KeyName": "[REDACTED]",
          "LaunchTime": "2024-08-08T21:37:04+00:00",
          "Monitoring": {
            "State": "disabled"
          },
          "Placement": {
            "AvailabilityZone": "us-east-1c" ,
            "GroupName": "",
            "Tenancy": "default"
          },
          "PrivateDnsName": "[REDACTED]",
          "PrivateIpAddress": "[REDACTED]",
          "ProductCodes": [],
          "PublicDnsName": "",
          "State": {
            "Code": 80,
            "Name": "stopped"
          },
          "StateTransitionReason": "User initiated (2024-08-09 07:00:48 GMT)",
          "SubnetId": "[REDACTED]",
          "VpcId": "[REDACTED]",
          "Architecture": "x86_64",
          "BlockDeviceMappings": [
            {
              "DeviceName": "/dev/xvda",
              "Ebs": {
                "AttachTime": "2024-08-08T21:37:05+00:00",
                "DeleteOnTermination": true,
                "Status": "attached",
                "VolumeId": "[REDACTED]"
              }
            }
          ]
        }
      ]
    }
  ]
}

```

This shows that AWS CLI is properly configured and able to communicate with AWS services. It successfully retrieves information about EC2 instances in the account, including instance types, states, and resources like VPCs and subnets. This indicates that the credentials and permissions are correctly set up. Specific instance IDs, private IP addresses, and other unique identifiers confirms that real EC2 resources are being accessed. Sensitive information was redacted for privacy and security purposes.

### 9. Initialize Elastic Beanstalk Environment

Initializing Elastic Beanstalk via EB CLI sets up the application environment for deployment.

```jsx
$eb init
# Set region to us-east-1
# Select Python 3.7 as the platform
# Skip CodeCommit setup
# Configure SSH
```

### 10. Add Deploy Stage to Jenkinsfile

The deploy stage in the Jenkinsfile automates the deployment of the application to Elastic Beanstalk, making the process more efficient and less error-prone.

```jsx
stage ('Deploy') {
          steps {
              sh '''#!/bin/bash
              source venv/bin/activate
              eb create [enter-name-of-environment-here] --single
              '''
          }
      }
```

With this, the pipeline will automatically deploy the application to Elastic Beanstalk when the deploy stage runs.

# Issues and trouble shooting

### **Issue: High Memory Usage During Jenkins Build**

The Jenkins build was initially failing to build due to high memory usage.

**Troubleshooting Steps:**

1. **Checked for Background Processes:**
    
    Investigated other programs, applications, or processes running in the background to identify memory usage. However, there was no significant amount of memory being consumed.
    
2. **Increased Memory Threshold:**
    
    Due to the limitations of the t2.micro instance, memory could not be increased. Instead, the memory threshold within Jenkins was raised to allow the build to proceed.
    

**Resolution:**

After increasing the memory threshold, the build ran successfully.

---

### **Issue: Environment Not Being Created Automatically**

**Symptom:**

Despite the successful build, the environment was not automatically created. An error indicated that the Jenkins user on the EC2 server was missing key components required to create an Elastic Beanstalk (EB) environment.

**Troubleshooting Steps:**

1. **Temporary Sudo Privileges for Jenkins User:**
    
    Temporarily granted the Jenkins user sudo privileges to install the necessary components required for environment creation.
    
2. **Virtual Environment Setup:**
    
    Realized that all of these steps should have been performed within a virtual environment (venv). Attempted to configure and start the virtual environment but faced issues as the setup was already configured and not prompting for a new setup.
    
3. **Manual Environment Creation:**
    
    Since the environment wasn’t automatically deployed, ran the following commands to manually create and deploy the environment:
    
    ```bash
    
    eb create <my_environment> --single
    eb deploy
    eb status
    ```
    
4. **Environment Status Check:**
    
    Verified that the environment was up and running after manual deployment.
    

**Resolution:**

The environment had to be created and deployed manually. The build was not attached to any environment, so default environment settings needed to be configured.

**Note:** This issue emphasizes the importance of correctly setting up the virtual environment and ensuring that Jenkins has the necessary permissions and components to automatically create and deploy the environment.

---

### Optimizations

- **Review Jenkinsfile:** Ensure that the Jenkinsfile is properly configured to handle virtual environments and automatically attach the build to the correct environment.
- **Optimize Instance Type:** If possible, consider upgrading the EC2 instance type to avoid memory constraints.
- **Proper Environment Management:** Ensure that the default environment is set in the Jenkins build pipeline to avoid manual intervention in the future.

## Conclusion

This workload further enhanced our CI/CD pipeline by integrating AWS CLI and EB CLI, automating the deployment process to AWS Elastic Beanstalk. The automation achieved here reduces manual intervention and increases the efficiency and reliability of deployments, making it a valuable approach for continuous software delivery in production environments.
