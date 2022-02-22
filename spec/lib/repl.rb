# frozen_string_literal: true

require_relative '../../lib/repl'

describe REPL do # rubocop:disable Metrics/BlockLength
  let(:slack_link) { 'slack_link' }
  let(:command) { 'command' }

  let(:show_all) { true }
  let(:repo) { 'repo' }
  let(:branch) { 'branch' }
  let(:subject) { described_class.new(slack_link: slack_link, show_all: show_all, command: command) }

  describe '#initialize' do
    it 'pass arguments and calls setup_repl' do
      expect_any_instance_of(described_class).to receive(:setup_repl)
      instance = described_class.new(slack_link: slack_link, show_all: show_all, command: command)
      expect(instance.instance_variable_get(:@slack_link)).to eq(slack_link)
      expect(instance.instance_variable_get(:@show_all)).to eq(show_all)
      expect(instance.instance_variable_get(:@command)).to eq(command)
    end
  end

  describe '#main' do
    let(:references) { %w[A B C] }
    it 'get the references from current PR_url and loop through them' do
      expect(Utils).to receive(:git_current_pr_url).and_return(references[0])
      expect(Utils).to receive(:parse_references).with([references[0]]).and_return(references)
      references.each do |ref|
        expect(subject).to receive(:process_reference).with(ref)
      end

      subject.main
    end

    it 'get the references from argument and loop through them' do
      expect(Utils).to receive(:parse_references).with(references).and_return(references)
      references.each do |ref|
        expect(subject).to receive(:process_reference).with(ref)
      end

      subject.main(references)
    end
  end

  describe '#process_reference'

  describe '#setup_repl' do
    it 'setups the triggers and help string'
  end

  describe '#fetch_input' do
    it 'exits on C-c' do
      subject.instance_variable_set(:@repo, repo)
      subject.instance_variable_set(:@branch, branch)

      expect($stdin).to receive(:getch).and_return("\u0003")

      expect do
        subject.send(:fetch_input)
      end.to output("#{repo}/#{branch} > ").to_stdout.and raise_error(SystemExit)
    end

    it 'returns the input' do
      subject.instance_variable_set(:@repo, repo)
      subject.instance_variable_set(:@branch, branch)

      char = 'A'
      expect($stdin).to receive(:getch).and_return(char)

      expect do
        expect(subject.send(:fetch_input)).to eq(char)
      end.to output("#{repo}/#{branch} > ").to_stdout
    end
  end

  describe '#process_input' do
    before(:each) do
      subject.instance_variable_set(
        :@mapping, {
          '1' => 'repl1',
          '2' => 'repl2'
        }
      )
    end
    it 'returns if no command is found' do
      input = 'a'
      expect do
        subject.send(:process_input, input)
      end.to output("Unrecognized command #{input}, press 'h' for help.\n").to_stdout
    end

    it 'executes the command if found' do
      input = '1'

      expect(subject).to receive(:repl1).and_return('OK')

      expect do
        expect(subject.send(:process_input, input)).to eq('OK')
      end.to output("repl#{input}\n").to_stdout
    end
  end
end
