#!/bin/bash

# Function to authenticate the user and configure AWS CLI
authenticate() {
    # Check if AWS CLI is installed
    if command -v aws &>/dev/null; then
        echo "AWS CLI is already installed."
    else
        # Download and install AWS CLI
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        if [ $? -ne 0 ]; then
            echo "AWS CLI installation failed."
            exit 1
        fi
        echo "AWS CLI installed."
    fi

    # Configure AWS CLI (this will prompt for input)
    aws configure
    if [ $? -ne 0 ]; then
        echo "AWS CLI configuration failed."
        exit 1
    fi
    echo "You're logged in."
}

# Function to print out the first 5 recommended AWS regions
print_out_regions() {
    regions_array=($(aws ec2 describe-regions --query "Regions[*].{Name:RegionName}" --output text | head -n 5))
    if [ $? -ne 0 ]; then
        echo "Failed to retrieve regions."
        exit 1
    fi
    for region in "${regions_array[@]}"; do
        echo "$region"
    done
}

# Function to check and select a valid AWS region
check_region() {
    local region_exists=false
    while [[ "$region_exists" = false ]]; do
        print_out_regions
        read -p "Enter your region: " selected_region
        for region in "${regions_array[@]}"; do
            if [[ "$selected_region" == "$region" ]]; then
                region_exists=true
                echo "Region exists."
                break
            else
                continue
            fi
        done
        if [ "$region_exists" = false ]; then
            echo "Invalid region. Please try again."
        fi
    done
}

# Function to list all existing S3 buckets
list_buckets() {
    echo "Listing all S3 buckets:"
    bucket_array=($(aws s3api list-buckets --query "Buckets[*].Name" --output text))
    if [ $? -ne 0 ]; then
        echo "Failed to list S3 buckets."
        exit 1
    fi
    for bucket in "${bucket_array[@]}"; do
        echo "$bucket"
    done
}

# Function to ensure the S3 bucket name is unique
check_bucket() {
    while true; do
        read -p "Enter a name for your S3 bucket: " bucket_name
        if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
            echo "The bucket $bucket_name exists, please provide another name..."
        else
            break
        fi
    done
}

# Function to create an S3 bucket in the selected region
create_bucket() {
    echo "Creating S3 bucket: $bucket_name in $selected_region"
    aws s3api create-bucket --bucket "$bucket_name" --region "$selected_region" --create-bucket-configuration LocationConstraint="$selected_region"
    if [ $? -ne 0 ]; then
        echo "Failed to create S3 bucket."
        exit 1
    fi
}

# Function to check if a file exists in the S3 bucket
check_file() {
    echo "filename: $file_name"
    if aws s3api head-object --bucket "$bucket_name" --key "$file_name" 2>/dev/null; then
        echo "File already exists in S3."
        read -p "Do you want to (O)verwrite, (S)kip, or (R)ename the file? [O/S/R]: " user_decision
        case $user_decision in
        O | o)
            echo "Overwriting the existing file..."
            overwrite_file
            ;;
        S | s)
            echo "Skipping the upload..."
            ;;
        R | r)
            read -p "Enter a new name for the file: " new_file_name
            mv "$file_name" "$new_file_name"
            file_name="$new_file_name"
            echo "File renamed to: $file_name"
            upload_file
            ;;
        *)
            echo "Invalid option. Skipping the upload."
            ;;
        esac
    else
        echo "File does not exist in S3."
        upload_file
    fi
}

# Function to upload a file to the S3 bucket
upload_file() {
    aws s3 cp "$file_name" "s3://$bucket_name/$file_name"
    if [ $? -ne 0 ]; then
        echo "File upload failed."
        exit 1
    fi
    echo "File uploaded."
    generate_presigned_url "$file_name"
}

# Function to overwrite an existing file in the S3 bucket
overwrite_file() {
    aws s3 cp "$file_name" "s3://$bucket_name/$file_name" --force
    if [ $? -ne 0 ]; then
        echo "File overwrite failed."
        exit 1
    fi
    echo "File overwritten."
    generate_presigned_url "$file_name"
}

# Function to generate a presigned URL for the uploaded file
generate_presigned_url() {
    local file_name="$1"
    presigned_url=$(aws s3 presign "s3://$bucket_name/$file_name" --expires-in 604800) # URL valid for 1 week
    if [ $? -ne 0 ]; then
        echo "Failed to generate presigned URL."
        exit 1
    fi
    echo "Presigned URL: $presigned_url"
}

# Main script logic
option=$1      # The 1st argument (option for multi-file or single-file upload)
file_name=$2   # The 2nd argument (file name)
file_name_2=$3 # The 3rd argument (optional second file name)

authenticate

# Prompt user for bucket creation
echo "Would you like to create a new S3 bucket? (Y/N)"
read answer

if [ "$answer" == "yes" ] || [ "$answer" == "y" ]; then
    check_region
    check_bucket
    create_bucket
else
    # List existing S3 buckets and prompt user to select one
    list_buckets
    while true; do
        read -p "Enter the name of the S3 bucket you would like to use: " bucket_name
        if [[ " ${bucket_array[*]} " == *" $bucket_name "* ]]; then
            echo "Using existing bucket: $bucket_name"
            break
        else
            echo "Bucket name not found. Please select a valid bucket from the list."
        fi
    done
fi

if [ "$option" == "-m" ] || [ "$option" == "-s" ]; then
    check_file

    if [ "$option" == "-m" ]; then
        file_name=$file_name_2
        check_file
    else
        echo "Single file."
    fi
else
    echo "Incorrect use of command."
fi
