#!/bin/bash

# Configuration - set your OpenAI API key
# Set this in your environment or replace with your actual API key
OPENAI_API_KEY="INSERT_KEY_HERE"
LLM_MODEL="gpt-4.1-2025-04-14"

# Default branch prefix (can be overridden)
DEFAULT_BRANCH_PREFIX="jordan/"

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "Error: This script requires curl to be installed."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: This script requires jq to be installed."
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository."
    exit 1
fi

# Function to generate a random string
generate_random_suffix() {
    # Generate 4 character random string using alphanumeric characters
    LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 4
}

# Get branch prefix from user or use default
read -p "Enter branch prefix (default: $DEFAULT_BRANCH_PREFIX): " USER_PREFIX
BRANCH_PREFIX=${USER_PREFIX:-$DEFAULT_BRANCH_PREFIX}

# Ensure prefix ends with / if it's not empty
if [ -n "$BRANCH_PREFIX" ] && [[ "$BRANCH_PREFIX" != */ ]]; then
    BRANCH_PREFIX="${BRANCH_PREFIX}/"
fi

# Get description from user
echo "What are you planning to work on? Provide a brief description:"
read -p "Description: " DESCRIPTION

if [ -z "$DESCRIPTION" ]; then
    echo "Error: Description is required."
    exit 1
fi

# Generate random suffix to avoid conflicts
RANDOM_SUFFIX=$(generate_random_suffix)

# Function to generate branch name using OpenAI API
generate_ai_branch_name() {
    echo "Generating branch name..."
    
    # Create the prompt
    PROMPT="You are a helpful assistant that generates git branch names from descriptions.

Description of the work: $DESCRIPTION

Generate a short, descriptive git branch name that:
- Uses kebab-case (lowercase with hyphens)
- Is between 3-6 words maximum
- Focuses on the main feature/change being made
- Is clear and professional
- Does NOT include any prefix (that will be added separately)
- Does NOT include random characters or numbers (those will be added separately)

Examples of good branch names:
- fix-login-bug
- add-user-authentication
- update-payment-flow
- refactor-api-endpoints

Return ONLY the branch name, nothing else."
    
    # Create a temporary file for our payload
    TEMP_FILE=$(mktemp)
    
    # Create the JSON payload properly using jq
    jq -n \
      --arg model "$LLM_MODEL" \
      --arg content "$PROMPT" \
      '{
        "model": $model,
        "messages": [{"role": "user", "content": $content}],
        "temperature": 0.7,
        "max_tokens": 50
      }' > "$TEMP_FILE"
    
    # Call the OpenAI API with the properly formatted JSON payload
    RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d @"$TEMP_FILE")
    
    # Clean up the temporary file
    rm "$TEMP_FILE"
    
    # Check if the API call was successful
    if [[ "$RESPONSE" == *"error"* ]]; then
        echo "Error calling OpenAI API:"
        echo "$RESPONSE" | jq -r '.error.message'
        exit 1
    fi
    
    # Extract the branch name from the response
    BRANCH_NAME=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | tr -d '\n' | tr -d '"' | xargs)
    
    # If extraction failed, exit
    if [ -z "$BRANCH_NAME" ]; then
        echo "Failed to parse API response."
        exit 1
    fi
    
    # Clean up the branch name (remove any invalid characters)
    BRANCH_NAME=$(echo "$BRANCH_NAME" | sed 's/[^a-zA-Z0-9-]//g' | tr '[:upper:]' '[:lower:]')
}

# Generate fallback branch name if AI fails
generate_fallback_branch_name() {
    # Convert description to kebab case
    BRANCH_NAME=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9 ]//g' | sed 's/ \+/-/g' | cut -c1-30)
}

# Try to generate AI branch name if API key is provided
if [ "$OPENAI_API_KEY" != "INSERT_KEY_HERE" ]; then
    generate_ai_branch_name
else
    echo "No OpenAI API key provided. Generating fallback branch name..."
    generate_fallback_branch_name
fi

# Construct the full branch name
FULL_BRANCH_NAME="${BRANCH_PREFIX}${RANDOM_SUFFIX}-${BRANCH_NAME}"

# Show the generated branch name and accept with Enter only
echo "Generated branch name:"
echo "$FULL_BRANCH_NAME"
echo
read -p "Press Enter to create and checkout this branch..." _
if git checkout -b "$FULL_BRANCH_NAME"; then
    echo "Successfully created and switched to branch: $FULL_BRANCH_NAME"
else
    echo "Error: Failed to create branch. Branch may already exist."
    exit 1
fi