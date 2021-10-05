#!/usr/bin/env ruby
# frozen_string_literal: true

# Misc utility class
class Utils
  # Tries to find the PR url from the context.
  def self.git_current_pr_url
    # 2>&1 to prevent error output to terminal.
    result = `gh pr view --json 'url' --jq '.url' 2>&1`

    unless $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "Couldn't find the current repo or branch."
      exit(1)
    end

    result
  end

  def self.parse_current_reference(reference)
    # https://github.com/<owner>/<repo>/pull/<number>
    if %r{https://github.com/([^/]+)/([^/]+)/pull/(\d+)} =~ reference
      repo = "#{Regexp.last_match(1)}/#{Regexp.last_match(2)}"
      number = Regexp.last_match(3)
      branch, base, closed = `gh pr view --json 'headRefName,baseRefName,closed' --jq '"\\(.headRefName),\\(.baseRefName),\\(.closed)"' #{reference}`.strip.split(',')

      return [repo, number, branch, base, closed] if $?.success? # rubocop:disable Style/SpecialGlobalVars
    end

    # <owner>/<repo>/<branch>
    if %r{([^/]+)/([^/]+)/(.+)} =~ reference
      repo = "#{Regexp.last_match(1)}/#{Regexp.last_match(2)}"
      branch = Regexp.last_match(3)
      number, base, closed = `gh pr view --repo #{repo} --json 'number,baseRefName,closed' --jq '"\\(.number),\\(.baseRefName),\\(.closed)"' #{branch}`.strip.split(',')

      return [repo, number, branch, base, closed] if $?.success? # rubocop:disable Style/SpecialGlobalVars
    end

    # Try to infer the current repo, if we can't do this, we can't continue.
    repo = `gh repo view --json 'owner,name' --jq '"\\(.owner.login)/\\(.name)"'`.strip
    unless $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "× Couldn't find current repo , exiting.".red
      exit(1)
    end

    # <branch> or <pull_number>
    # gh can find the right one automatically
    branch, base, number, closed = `gh pr view --repo #{repo} --json 'headRefName,baseRefName,number,closed' --jq '"\\(.headRefName),\\(.baseRefName),\\(.number),\\(.closed)"' #{reference}`.strip.split(',')
    return [repo, number, branch, base, closed] if $?.success? # rubocop:disable Style/SpecialGlobalVars

    puts "× Couldn't parse '#{reference}', exiting.".red
    exit(1)
  end
end
