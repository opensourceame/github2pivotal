module GitHub2PivotalTracker
  class Processor

    attr_reader :config, :options, :logger, :gh_client, :pt_client, :project, :stories, :issues

    DEFAULT_OPTIONS = {
      dry_run:      false,
    }.freeze

    def initialize(**options)
      @options  = options
      @logger   = Logger.new(STDOUT)
      @migrated = {}
    end

    def run
      load_config
      setup_clients

      fetch_gh_issues

      fetch_pt_project
      fetch_pt_stories

      process_issues
    end

    def load_config
      @config = RecursiveOpenStruct.new(YAML.load_file('config.yaml'))
    end

    def setup_clients

      Octokit.auto_paginate = true

      @gh_client = Octokit::Client.new(
        login:    config.github.username,
        password: config.github.password
      )

      @pt_client = TrackerApi::Client.new(
        token: config.pivotal.api_token
      )
    end

    def fetch_gh_issues
      logger.debug "fetching issues from GitHub"

      @issues = gh_client.issues(gh_repo)
    end

    def fetch_pt_project
      @project = pt_client.project(config.pivotal.project_id)
    end

    def fetch_pt_stories

      logger.debug "fetching stories from Pivotal Tracker"

      @stories = project.stories
      @idx_migrated_issues = @stories.map {|s| s.external_id.to_i }
    end

    def process_issues

      logger.info "found #{issues.count} issues to process"

      issues.each do |issue|
        next if issue_migrated?(issue)
        process_issue(issue)
      end
    end

    def process_issue(issue)

      logger.debug "processing issue #{issue.number}"

      parser = GitHub2PivotalTracker::GitHub::IssueParser.new(self, issue)
      parser.parse

      if options[:dry_run]

        logger.debug "would create issue: \n\n" + parser.story_data_pretty
      else

        story = project.create_story(parser.story_data)

        add_story_tasks(story, parser.tasks)
        add_story_comments(story, parser.comments)

        logger.debug "created story #{story.id}"
      end

      story

    end

    def issue_migrated?(issue)
      if @idx_migrated_issues.member?(issue.number)
        logger.warn "skipping already migrated issue #{issue.number}"

        return true
      end

      false
    end

    def add_story_comments(story, comments)

      return true if comments.empty?

      logger.debug "adding #{comments.count} comments"

      comments.each do |comment|
        story.create_comment(comment)
      end

    end

    def add_story_tasks(story, tasks)

      return true if tasks.empty?

      logger.debug "adding #{tasks.count} tasks"

      tasks.each do |t|
        story.create_task(t)
      end
    end

    def gh_repo
      config.github.repository
    end

    def gh_org
      gh_repo.split('/').first
    end

  end

end