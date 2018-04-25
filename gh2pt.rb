#!/usr/bin/env ruby

require 'octokit'
require 'tracker_api'
require 'pry'
require 'logger'
require 'recursive_open_struct'
require 'redis'

require_relative 'processor'
require_relative 'gh_issue_parser'

migrator = Migrator::Processor.new
migrator.run

binding.pry

# pry doesn't work if it's the last line of a script
abort



