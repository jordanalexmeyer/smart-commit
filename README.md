# smart-commit

A Git commit helper that uses AI to generate meaningful commit messages based on your changes.

## Installation

1. Clone this repository:

```bash
git clone git@github.com:jordanalexmeyer/smart-commit.git
cd smart-commit
```

2. Add your OpenAI API key to the script. Open `smart-commit.sh` and replace the placeholder API key:

```bash
# Find this line in smart-commit.sh
OPENAI_API_KEY="your-api-key-here"
# Replace with your actual API key
OPENAI_API_KEY="sk-..."
```

3. Make the install script executable:

```bash
chmod +x install.sh
```

4. Run the install script:

```bash
./install.sh
```

This will:

- Install the script to `~/bin/git-smart-commit.sh`
- Create a git alias `sc` for easy use

## Usage

After installation, you can use the smart commit tool with:

```bash
git sc
```

The tool will:

1. Analyze your staged changes
2. Generate a meaningful commit message using AI
3. Let you choose to:
   - Use the generated message
   - Edit the message
   - Regenerate with AI
   - Cancel the commit

## Requirements

- Git (comes pre-installed on macOS)
- curl (comes pre-installed on macOS)
- jq (install with: `brew install jq`)
- OpenAI API key (added directly to the script)

Note: The script will fail if the OpenAI API key is not set in the script. Make sure to add your API key before running the script.
