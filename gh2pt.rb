#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
require 'yaml'
require 'optparse'

Bundler.require(:default)

require_relative 'lib/gh2pt/gh2pt'

options = GitHub2PivotalTracker::Processor::DEFAULT_OPTIONS.dup

OptionParser.new do |opts|
  opts.banner = "Usage: gh2pt.rb [options]"

  opts.on('-d', '--dry-run', 'Dry run') do |v|
    options[:dry_run] = true
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
end.parse!


processor = GitHub2PivotalTracker::Processor.new(options)

if ENV['START_PRY']
  binding.pry

  # pry doesn't bind if it's the last line of a script
  abort
end

processor.run





