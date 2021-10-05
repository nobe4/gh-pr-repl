#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'io/console'
require_relative 'colors'
require_relative 'utils'

# REPL is a simple read-eval print loop that takes pull requests and adds some
# easy processing on top of them.
class REPL
  def initialize(slack_link: nil, show_all: false)
    @slack_link = slack_link
    @show_all = show_all

    @help = []
    @mapping = {}

    setup_repl
  end

  def main(references = nil)
    references = [Utils.git_current_pr_url] unless references && !references.empty?

    references.each do |reference|
      process_reference(reference)
    end
  end

  private

  def process_reference(reference)
    @repo, @number, @branch, @base, closed = Utils.parse_current_reference(reference)
    @continue = true

    if !@show_all && closed == 'true'
      puts "✓ #{@repo}/#{@branch} (#{@number})".green
      return
    end

    puts "- #{@repo}/#{@branch} (#{@number})".yellow

    # Command loop
    loop do
      input = fetch_input
      process_input(input)

      break unless @continue
    end
  end

  # Setup the triggers and help with all the repl_* methods
  def setup_repl
    REPL.private_instance_methods.grep(/repl_/).each do |method|
      meta = send(method.to_sym, meta: true)
      next unless meta

      @mapping[meta[:trigger]] = method

      @help << "#{meta[:trigger]} - #{meta[:help]}"
    end
  end

  def fetch_input
    # ref https://stackoverflow.com/a/27021816
    print "#{@repo}/#{@branch} > "

    input = $stdin.getch

    # Break if sent C-c
    exit(1) if input == "\u0003"

    input
  end

  def process_input(input)
    command = @mapping[input]

    unless command
      puts "Unrecognized command #{input}, press 'h' for help."
      return
    end

    # Display the full command if matched
    puts command.to_s.gsub('repl_', '')

    send(command)
  end

  # From here, only repl commands

  def repl_help(meta: false)
    return { help: "Show this #{'H'.red}elp", trigger: 'h' } if meta

    puts @help.join("\n")
  end

  def repl_approve(meta: false)
    return { help: "#{'A'.red}pprove the PR, no comment", trigger: 'a' } if meta

    system("gh --repo #{@repo} pr review --approve #{@branch}")
  end

  def repl_merge(meta: false)
    return { help: "#{'M'.red}erge the PR with 'merge' strategy, no message", trigger: 'm' } if meta

    system("gh --repo #{@repo} pr merge --merge --delete-branch #{@branch}")
  end

  def repl_open(meta: false)
    return { help: "#{'O'.red}pen in browser", trigger: 'o' } if meta

    system("gh --repo #{@repo} pr view --web #{@branch}")
  end

  def repl_deploy(meta: false)
    return { help: "#{'D'.red}eploy the branch from slack", trigger: 'd' } if meta

    `echo ".deploy https://github.com/#{@repo}/pull/#{@number}" | pbcopy`

    `open "#{@slack_link}"` if @slack_link
    puts 'set -s flag for fast slack opening' unless @slack_link
  end

  def repl_view(meta: false)
    return { help: "#{'V'.red}iew the PR with all the comments", trigger: 'v' } if meta

    `tmux split-window -h -d "gh --repo #{@repo} pr diff #{@branch}"`
    system("gh --repo #{@repo} pr view --comments #{@branch}")
  end

  def repl_status(meta: false)
    return { help: "view the PR #{'S'.red}tatus checks", trigger: 's' } if meta

    system("gh --repo #{@repo} pr checks #{@branch}")
  end

  def repl_watch(meta: false)
    return { help: "#{'W'.red}atch the status", trigger: 'w' } if meta

    `tmux split-window -h -d "while true; do gh --repo #{@repo} pr checks #{@branch}; sleep 1; done"`
  end

  def repl_copy(meta: false)
    return { help: "#{'C'.red}opy the link to the clipboard", trigger: 'c' } if meta

    `echo "https://github.com/#{@repo}/pull/#{@number}" | pbcopy`
  end

  def repl_next(meta: false)
    return { help: "Go to #{'N'.red}ext branch", trigger: 'n' } if meta

    @continue = false
  end

  def repl_update(meta: false)
    return { help: "#{'U'.red}pdate the PR from the base branch.", trigger: 'u' } if meta

    # Create a merge commit between the base and the head.
    `gh api '/repos/#{@repo}/merges' -f head='#{@base}' -f base='#{@branch}'`
  end

  def repl_checkout(meta: false)
    return { help: "chec#{'K'.red}out the branch if in the right repo", trigger: 'k' } if meta

    # Check if we are in the right repo.
    # If so we can checkout and do other stuff.
    remote = `git config --get remote.origin.url`.strip

    if remote == "git@github.com:#{@repo}.git"
      system("gh --repo #{@repo} pr checkout #{@branch}")
    else
      puts "Cannot checkout #{@branch}, move to where #{@repo} cloned."
    end
  end

  def repl_quit(meta: false)
    return { help: "#{'Q'.red}uit", trigger: 'q' } if meta

    exit(0)
  end
end
