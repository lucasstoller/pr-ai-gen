require 'optparse'
require 'git'
require 'httparty'
require 'pry'

# Define the CLI class
class PullRequestAIGenerator
  OPEN_AI_URL = "https://api.openai.com/v1"

  attr_reader :options

  def initialize(args)
    @options = parse_options(args)
    @diff = nil
    @pr_content = nil
    @git_repo = nil
    @config = nil
  end

  def init
    puts 'Initializing PR AI Generator...'
    credentials_path = File.expand_path('~/.pr-gem/credentials')
    pr_gem_path = File.expand_path('~/.pr-gem')

    unless File.exist?(pr_gem_path)
      Dir.mkdir(pr_gem_path)
      puts '.pr-gem repository created successfully!'
    end

    if File.exist?(credentials_path)
      puts 'Credentials file already exists!'
    else
      puts 'Please enter your OpenAI API key:'
      openai_token = STDIN.gets.chomp
      File.write(credentials_path, "OPENAI_TOKEN=#{openai_token}\n")
      puts 'Credentials file created successfully!'
    end

    puts 'Configuring ChatGPT integration'
    puts 'Please choose the OpenAI API model:'
    puts '1. gpt-4-turbo-preview'
    puts '2. gpt-4'
    puts '3. gpt-3.5-turbo'
    
    model = nil
    while model.nil?
      case STDIN.gets.chomp
      when '1'
        model = 'gpt-4-turbo-preview'
      when '2'
        model = 'gpt-4'
      when '3'
        model = 'gpt-3.5-turbo'
      else
        puts 'Invalid model! Please choose a valid model:'
      end
    end

    config = {
      openai: {
        model: model,
        max_tokens: 1024
      }
    }

    File.write(File.join(pr_gem_path, 'config.yml'), config.to_yaml)
  end

  def run
    puts 'Running PR AI Generator...'
    fetch_diff
    load_template
    get_openai_token
    get_config
    generate_pr_content
    print_content
  end

  private

  def parse_options(args)
    OptionParser.new do |opts|
      opts.banner = "Usage: pr_ai_gen generate <directory_location> <branch>:<target-branch=main>"

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end

    end.parse!(args)

    options = { target_branch: 'main', directory_location: File.expand_path("."), command: :run } 

    if args[0] == 'init'
      options[:command] = :init
    elsif args[0] == 'generate'
      options[:command] = :run

      if args[1]
        options[:directory_location] = File.expand_path(args[1])
      end

      if args[2]
        local, target = args[2].split(':')
        options[:local_branch] = local
        options[:target_branch] = target || options[:target_branch]
      end
    else
      raise Exception.new "Invalid command!"
    end

    options
  end

  def fetch_diff
    # Start the ssh-agent in the background
    `eval $(ssh-agent -s)`

    # Add your SSH private key to the ssh-agent
    `ssh-add ~/.ssh/id_ed25519`
    ssh_keys = `ssh-add -l`

    if ssh_keys.include?('No identities')
      puts 'No SSH keys are added to the ssh-agent.'
      exit
    end

    @git_repo = Git.open(@options[:directory_location])
    @git_repo.fetch
    @git_repo.checkout(@options[:local_branch])
    @diff = @git_repo.diff(@options[:target_branch], @options[:local_branch])
  end

  def load_template
    template_path = File.join(@options[:directory_location], '.github', 'PULL_REQUEST_TEMPLATE.md')
    if File.exist?(template_path)
      @template = File.read(template_path)
    else
      @template = "# Default PR Template\n\n## Changes Made\n\nDescribe your changes in detail here."
    end
  end

  def get_config
    config_path = File.join(File.expand_path('~/.pr-gem'), 'config.yml')
    if File.exist?(config_path)
      @config = YAML.load_file(config_path)
    else
      raise "Config file not found!"
    end
  end

  def get_openai_token
    credentials_path = File.expand_path('~/.pr-gem/credentials')
    if File.exist?(credentials_path)
      credentials = File.readlines(credentials_path).map(&:strip)
      @openai_token = credentials.find { |line| line.start_with?('OPENAI_TOKEN=') }
      raise "OpenAI credentials not found!" unless @openai_token
      @openai_token = @openai_token.split('=')[1]
    else
      raise "OpenAI credentials file not found!"
    end
  end

  def generate_pr_content
    puts "Generating PR content..."

    response = HTTParty.post(
      "#{OPEN_AI_URL}/chat/completions",
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@openai_token}"
      },
      body: {
        model: @config[:openai][:model],
        messages: [
          {
            role: "user",
            content: "fill this templete:\n #{@template}\n with the following changes:\n #{@diff.to_s}"
          },
        ],
        max_tokens: @config[:openai][:max_tokens]
      }.to_json
    )

    @pr_content = response.dig("choices", 0, "message", "content").strip

    puts "PR content generated successfully!"
  end

  def print_content
    puts "PR CONTENT FOLLOWING:"
    puts "BEGIN-------------------------------------------------------------------------"
    puts @pr_content
    puts "---------------------------------------------------------------------------END"
  end
end