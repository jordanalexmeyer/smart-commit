# smart-commit

A collection of Git helpers that use AI to improve your development workflow:

- **smart-commit**: Generate meaningful commit messages based on your changes
- **smart-branch**: Generate descriptive branch names from your work description

## Installation

1. Clone this repository:

```bash
git clone git@github.com:jordanalexmeyer/smart-commit.git
cd smart-commit
```

2. Add your OpenAI API key to both scripts. Open `smart-commit.sh` and `smart-branch.sh` and replace the placeholder API key:

```bash
# Find this line in both scripts
OPENAI_API_KEY="INSERT_KEY_HERE"
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

- Install `smart-commit.sh` to `~/bin/git-smart-commit.sh`
- Install `smart-branch.sh` to `~/bin/git-smart-branch.sh`
- Create git alias `sc` for smart commit
- Create git alias `sb` for smart branch

## Usage

### Smart Commit

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

### Smart Branch

Create a new branch with an AI-generated name:

```bash
git sb
```

The tool will:

1. Ask for your branch prefix (default: "jordan/")
2. Ask for a description of what you're working on
3. Generate a descriptive branch name using AI
4. Add random characters to avoid conflicts
5. Create and checkout the new branch

Example branch names generated:

- `jordan/a1b2-fix-login-validation`
- `jordan/c3d4-add-user-dashboard`
- `jordan/e5f6-refactor-api-endpoints`

## Requirements

- Git (comes pre-installed on macOS)
- curl (comes pre-installed on macOS)
- jq (install with: `brew install jq`)
- OpenAI API key (added directly to the script)

Note: Both scripts will fail if the OpenAI API key is not set. Make sure to add your API key to both scripts before running them.
