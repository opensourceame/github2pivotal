module GitHub2PivotalTracker
  module GitHub
    class IssueParser

      attr_reader :processor, :config, :logger, :issue, :story_type, :estimate, :title, :description, :user_map, :gh_client, :tasks, :comments, :labels

      TASK_REGEX = /-\ (\[.+\]\ .*)/.freeze

      def initialize(processor, issue)
        @processor = processor
        @issue     = issue
        @tasks     = []
        @comments  = []
        @labels    = []

        setup_processor_links
      end

      def setup_processor_links
        @config    = processor.config
        @user_map  = config.gh_to_pt_users.to_h
        @gh_client = processor.gh_client
        @logger    = processor.logger
      end

      def parse
        @description = parse_gh_text(issue.body)
        @story_type  = parse_story_type
        @estimate    = parse_estimate
        @title       = parse_title

        parse_gh_comments

        true
      end

      def parse_gh_comments

        gh_comments = gh_client.issue_comments(processor.gh_repo, issue.number)

        gh_comments.each do |c|
          parsed_text = parse_gh_text(c.body)

          next if parsed_text.nil? || parsed_text == ''

          @comments << {
            text:      parsed_text,
            person_id: gh_username_to_pt(c.user.login)
          }
        end

      end

      def story_data
        data            = {
          story_type:      story_type,
          name:            title,
          requested_by_id: gh_username_to_pt(issue.user.login),
          owner_ids:       get_owner_ids,
          integration_id:  config.pivotal.integration_id,
          external_id:     issue.number.to_s,
          labels:          labels,
          description:     description,
        }

        data[:estimate] = estimate if estimate

        data

      end

      def story_data_pretty
        text = ''
        story_data.each do |k,v|
          if k == :description
            text += "\n---- description ----\n\n#{v}\n\n"
          else
            text += "#{k}: #{v}\n"
          end
        end
        text
      end


      def parse_title
        m = issue.title.match /\[(.*)\] ?(.*)/

        return issue.title unless m

        labels << m[1]

        m[2]
      end

      def parse_estimate

        return nil if story_type == :chore
        return nil if story_type == :bug

        return nil unless issue.labels?

        issue.labels.each do |label|
          m = label.name.match /(\d) point/
          return m[1].to_i if m
        end

        nil

      end

      def parse_story_type

        issue.labels.each do |label|
          return :bug     if label.name == 'bug'
          return :feature if label.name == 'enhancement'
          return :feature if label.name == 'proposal'
        end

        :chore
      end

      def parse_gh_text(text)

        desc  = []
        lines = text.split("\r\n")

        lines.each do |line|

          if line =~ TASK_REGEX
            extract_task(line)
          else
            desc << line
          end

        end

        desc.join("\n")

      end

      def extract_task(line)

        line = line.strip

        tasks << {
          description: line[6..-1],
          complete:    line[3].downcase == 'x'
        }
      end

      def gh_username_to_pt(username)

        username = username.to_sym

        return @user_map[username] if @user_map[username]

        logger.warn "missing map for GitHub user #{username}"
        logger.warn "falling back to default user"

        return @user_map.first.last

      end

      def get_owner_ids
        issue.assignees.map {|a| gh_username_to_pt(a.login)}
      end


    end
  end
end
