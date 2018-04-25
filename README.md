## GitHub 2 Pivotal Tracker

This project migrates issues from GitHub to Pivotal Tracker, including comments and tasks.

Pivotal Tracker's tasks are global for the issue, thus tasks defined in different comments in a
GitHub issue will be extracted from the comments and added to the global tasks.

GitHub attachments are supported, however they are not migrated and the links in the Pivotal Tracker stories
and comments will point to GitHub's site. For this reason it's important not to delete your repository from GitHub
if you wish to preserve the attachments in stories.

### Setup

First you will need to set up your Pivotal Tracker repository and all the users that you will be migrating.

* run `bundle install` to install required gems
* copy `config-sample.yaml` to `config.yaml` and edit appropriately


### Configuration

Most of the YAML config should be self explanatory. 

The `gh_to_pt_users` section maps a GitHub _username_ to the _user_id_ of a Pivotal Tracker user.

### Running

Run `./gh2pt.rb`

##### Options

`-d | --dry-run` - don't create any tickets, just show what stories would be created

### Roadmap

Some features I'd like to add:

* migration of attachments to Pivotal Tracker's server


### License

The gem is available as open source under the terms of the MIT License.