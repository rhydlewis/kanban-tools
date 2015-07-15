require 'logger'

module JiraConstants
  attr_reader :client_options, :query_options, :logger, :arguments

  FIX_VERSIONS = 'fixVersions'
  NAME = 'name'
  HISTORIES = 'histories'
  CHANGELOG = 'changelog'
  DATE_FMT = '%Y-%m-%d'
  ITEMS = 'items'
  FIELD = 'field'
  STATUS = 'status'
  FROM_STR = 'fromString'
  TO_STR = 'toString'
  CREATED = 'created'

  def init_config
    @logger = Logger.new(STDOUT)
    @logger.sev_threshold = Logger::INFO
    @logger.datetime_format = '%Y-%m-%d %H:%M:%S'

    @config = YAML.load(File.read('./jira-settings.yaml'))

    @client_options = {
        :username => @config['username'],
        :password => @config['password'],
        :site => @config['jira'],
        :auth_type => :basic,
        :context_path => '',
        :use_ssl => @config['use_ssl']
    }

    @logger.debug("Client options - username: #{@client_options[:username]}, site: #{@client_options[:site]}")

    @query_options = {
        :fields => [],
        :start_at => 0,
        :max_results => @config['max_results']
    }
  end

  def run_query(query)
    @client = JIRA::Client.new(@client_options)
    issues = @client.Issue.jql(query, @query_options)
    @logger.info("Found #{issues.size.to_s} issue(s)")
    return issues
  end

  def describe_issue(issue)
    key = issue.key
    summary = issue.summary
    type = issue.issuetype.name
    status = issue.status.name
    created = DateTime.strptime(issue.created, DATE_FMT)

    details = { :key => key.dup, :summary => summary.dup, :type => type.dup, :status => status,
                :created => created.strftime(DATE_FMT)}
    @logger.debug("Issue details: #{details.to_s}")
    return details
  end
end