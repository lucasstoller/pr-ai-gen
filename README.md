# pr_ai_gen

## Description

pr_ai_gen is a CLI tool that acelerate the process of creating pull requests by Generate the PR description in markdown format.
It uses OpenAI to generate the content based on the differences between the two git branches beeing merged.

## Installation

Install the gem by running:

```bash
gem install pr_ai_gen
```

### Setup

```bash
pr_ai_gen init
```
The tool will ask you to input the OPENAI_TOKEN to make the ChatGPT calls. If you don't have one, please generate one [here](https://platform.openai.com/api-keys).
After input the token if you want to change it you can change it in `~/.pr_gem/credentials`.

### Usage

When the setup is already done you will be good to use the tool.

Commands: 
- `generate <directory_location> <branch>:<target-branch=main>`: Generate the PR description based on diff from the branch and target-branch (default main)

## Development

To develop you must:
1. make the script in exe directory executable
`chmod -x ./exe/pr_ai_gen`
2. run the script directly as it is the cli tool
`./exe/pr_ai_gen generate <directory_location> <branch>:<target-branch=main>`
