#!/usr/bin/env ruby
# frozen_string_literal: true

# Misc utility class
class Utils
  # Tries to find the PR url from the context.
  def self.git_current_pr_url
    # 2>&1 to prevent error output to terminal.
    result = `gh pr view --json 'url' --jq '.url' 2>&1`

    unless $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "! Couldn't find the current repo or branch.".yellow
      exit(1)
    end

    result
  end

  def self.parse_pr_url(reference)
    # https://github.com/<owner>/<repo>/pull/<number>
    return unless %r{https://github.com/([^/]+)/([^/]+)/pull/(\d+)} =~ reference

    repo = "#{Regexp.last_match(1)}/#{Regexp.last_match(2)}"
    number = Regexp.last_match(3)
    branch, base, closed = `gh pr view --json 'headRefName,baseRefName,closed' --jq '"\\(.headRefName),\\(.baseRefName),\\(.closed)"' #{reference}`.strip.split(',')

    [repo, number, branch, base, closed] if $?.success? # rubocop:disable Style/SpecialGlobalVars
  end

  def self.parse_owner_repo_branch(reference)
    # <owner>/<repo>/<branch>
    return unless %r{([^/]+)/([^/]+)/(.+)} =~ reference

    repo = "#{Regexp.last_match(1)}/#{Regexp.last_match(2)}"
    branch = Regexp.last_match(3)
    number, base, closed = `gh pr view --repo #{repo} --json 'number,baseRefName,closed' --jq '"\\(.number),\\(.baseRefName),\\(.closed)"' #{branch}`.strip.split(',')

    [repo, number, branch, base, closed] if $?.success? # rubocop:disable Style/SpecialGlobalVars
  end

  def self.parse_query(query)
    prs = `gh api -X GET search/issues --paginate -f q='#{query}' -q '.items[] | .html_url'`
    prs = prs.split("\n")

    prs.map do |pr|
      parse_pr_url(pr)
    end
  end

  def self.parse_current_repo(reference)
    # Try to infer the current repo, if we can't do this, we can't continue.
    repo = `gh repo view --json 'owner,name' --jq '"\\(.owner.login)/\\(.name)"'`.strip
    return unless $?.success? # rubocop:disable Style/SpecialGlobalVars

    if repo.nil?
      puts "! Couldn't find current repo, skipping.".yellow
      return
    end

    # <branch> or <pull_number>
    # gh can find the right one automatically given the repo.
    branch, base, number, closed = `gh pr view --repo #{repo} --json 'headRefName,baseRefName,number,closed' --jq '"\\(.headRefName),\\(.baseRefName),\\(.number),\\(.closed)"' #{reference}`.strip.split(',')
    return [repo, number, branch, base, closed] if $?.success? # rubocop:disable Style/SpecialGlobalVars

    puts "× Couldn't parse '#{reference}', skipping.".yellow
  end

  def self.parse_references(references)
    parsed_references = []

    references.each do |reference|
      parsed_reference = parse_pr_url(reference)
      unless parsed_reference.nil?
        parsed_references << parsed_reference
        next
      end

      parsed_reference = parse_owner_repo_branch(reference)
      unless parsed_reference.nil?
        parsed_references << parsed_reference
        next
      end

      parsed_reference = parse_query(reference)
      unless parsed_reference.nil?
        parsed_references.push(*parsed_reference)
        next
      end

      parsed_reference = parse_current_repo(reference)
      unless parsed_reference.nil?
        parsed_references << parsed_reference
        next
      end
    end

    parsed_references
  end
end
