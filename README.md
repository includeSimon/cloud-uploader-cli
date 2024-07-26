# Cloud Uploader CLI Tool
This Bash script enables you to upload files to AWS S3 using the AWS Command Line Interface (CLI). It includes functionalities for authentication, region selection, bucket creation, and file upload.

## Prerequisites

1. **AWS Account**: Ensure you have an active AWS account. If not, you can [create a free account](https://aws.amazon.com/free/).
2. **AWS CLI**: Ensure AWS CLI is installed and configured on your machine.

## Installation

1. Clone the repository to your local machine:

    ```bash
    git clone https://github.com/includeSimon/cloud-uploader-cli.git
    ```

2. Navigate to the script directory:

    ```bash
    cd cloud-uploader-cli
    ```

3. Make the script executable:

    ```bash
    chmod +x upload_script.sh
    ```

## Usage

1. Run the script for a single file using the `-s` option:

    ```bash
    ./upload_script.sh -s <single_file>
    ```

    - Replace `<single_file>` with the actual file name.

2. Run the script for multiple files using the `-m` option:

    ```bash
    ./upload_script.sh -m <file1> <file2>
    ```

    - Replace `<file1>` and `<file2>` with the actual file names.

3. Follow the prompts to authenticate, select a region, and configure S3 buckets.

4. Choose whether to create new S3 buckets or use existing ones.

5. The script will guide you through the file upload, handling overwriting, skipping, renaming, and generating shareable links.

## Functions

- **Authentication**: Configures AWS CLI and logs in using AWS credentials.
- **Region Selection**: Prompts the user to select a region from the available list.
- **Bucket Handling**: Creates or uses an S3 bucket and lists existing buckets.
- **File Handling**: Checks for file existence, manages overwriting, skipping, renaming, and generates shareable links.
