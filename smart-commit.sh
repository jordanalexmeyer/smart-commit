#!/bin/bash

# Configuration - set your OpenAI API key
# Set this in your environment or replace with your actual API key
OPENAI_API_KEY="INSERT_KEY_HERE"
LLM_MODEL="gpt-4.1-2025-04-14"

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

# Check if files are staged for commit
if [ -z "$(git diff --cached --name-only)" ]; then
    echo "No files staged for commit. Use 'git add' to stage files."
    exit 1
fi

# Get a summary of changes
FILES_CHANGED=$(git diff --cached --name-only | wc -l | tr -d ' ')
INSERTIONS=$(git diff --cached --stat | grep -o "[0-9]\+ insertion" | grep -o "[0-9]\+" || echo "0")
DELETIONS=$(git diff --cached --stat | grep -o "[0-9]\+ deletion" | grep -o "[0-9]\+" || echo "0")

# Get file types modified
FILE_TYPES=$(git diff --cached --name-only | grep -o "\.[^\.]*$" | sort | uniq | tr '\n' ' ')

# Determine primary action based on stats
if [ -z "$INSERTIONS" ]; then INSERTIONS=0; fi
if [ -z "$DELETIONS" ]; then DELETIONS=0; fi

if [ $INSERTIONS -gt $DELETIONS ]; then
    ACTION="Add"
elif [ $DELETIONS -gt $INSERTIONS ]; then
    ACTION="Remove"
else
    ACTION="Update"
fi

# Get directories affected
DIRS=$(git diff --cached --name-only | xargs -I{} dirname {} | sort | uniq | tr '\n' ' ' | xargs)

# Generate a basic fallback commit message
FALLBACK_MSG="$ACTION: Changes in $DIRS($FILES_CHANGED files changed, $FILE_TYPES)"

# If adding a new feature, check for new files
NEW_FILES=$(git diff --cached --name-only --diff-filter=A | wc -l)
if [ $NEW_FILES -gt 0 ]; then
    FALLBACK_MSG="Add: New ${FILE_TYPES}files in $DIRS"
fi

# Collect diff content from each file, up to a limit
collect_diff_content() {
    # Maximum number of lines to collect per file
    local LINES_PER_FILE=200
    # Maximum total lines across all files
    local MAX_TOTAL_LINES=1000
    # Total lines collected so far
    local TOTAL_LINES=0
    # Final diff content
    local FINAL_DIFF=""
    
    # Get list of changed files
    local CHANGED_FILES=$(git diff --cached --name-only)
    
    for FILE in $CHANGED_FILES; do
        # Check if we've hit the total limit
        if [ $TOTAL_LINES -ge $MAX_TOTAL_LINES ]; then
            FINAL_DIFF="${FINAL_DIFF}\n\n... additional changes truncated (reached maximum limit) ..."
            break
        fi
        
        # Get the diff for this file
        local FILE_DIFF=$(git diff --cached -- "$FILE")
        local FILE_DIFF_LINES=$(echo "$FILE_DIFF" | wc -l)
        
        # Truncate if needed and add file header
        FINAL_DIFF="${FINAL_DIFF}\n\n=== Changes in $FILE ==="
        
        if [ $FILE_DIFF_LINES -gt $LINES_PER_FILE ]; then
            # Truncate to LINES_PER_FILE
            FINAL_DIFF="${FINAL_DIFF}\n$(echo "$FILE_DIFF" | head -n $LINES_PER_FILE)"
            FINAL_DIFF="${FINAL_DIFF}\n... (additional changes in this file truncated) ..."
            TOTAL_LINES=$((TOTAL_LINES + LINES_PER_FILE))
        else
            # Add the entire diff
            FINAL_DIFF="${FINAL_DIFF}\n$FILE_DIFF"
            TOTAL_LINES=$((TOTAL_LINES + FILE_DIFF_LINES))
        fi
    done
    
    echo -e "$FINAL_DIFF"
}

# Collect diff content with limits
DIFF_CONTENT=$(collect_diff_content)

# Function to generate commit message using OpenAI API
generate_ai_commit_message() {
    echo "Generating commit message..."
    
    # Create the prompt
    PROMPT="You are a helpful assistant that generates concise and meaningful git commit messages.

Here's the git diff summary:
- Files changed: $FILES_CHANGED
- Insertions: $INSERTIONS
- Deletions: $DELETIONS
- File types: $FILE_TYPES
- Directories affected: $DIRS

Here are the actual changes (limited to first 200 lines per file, 1000 lines total):
$DIFF_CONTENT

Generate a clear, concise git commit message that follows these conventions:
- Be specific but brief (under 72 characters if possible)
- Focus on WHAT was changed and WHY, not HOW
- Use imperative mood (e.g., 'Add feature' not 'Added feature')"
    
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
        "max_tokens": 100
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
    
    # Extract the message from the response, preserving newlines
    COMMIT_MSG=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')
    
    # If extraction failed, exit
    if [ -z "$COMMIT_MSG" ]; then
        echo "Failed to parse API response."
        exit 1
    fi
}

# Try to generate AI commit message if API key is provided
if [ "$OPENAI_API_KEY" != "INSERT_KEY_HERE" ]; then
    generate_ai_commit_message
else
    echo "No OpenAI API key provided. Please set the OPENAI_API_KEY environment variable."
    exit 1
fi

# Show the generated message and accept with Enter only
echo "Generated commit message:"
echo "$COMMIT_MSG"
echo
read -p "Press Enter to commit with this message..." _
git commit -m "$COMMIT_MSG"
echo "Changes committed successfully!"