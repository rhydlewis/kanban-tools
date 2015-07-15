#! /usr/bin/env ruby
require 'jira'
require 'yaml'
require 'table_print'
require 'json'
require 'ostruct'
require 'optparse'

$: << File.join(File.dirname(__FILE__), '.')
require 'jira_constants'

class History

  BANNER = 'Usage: history [options] query'
  MORE_INFO = 'For help use: history -h'

  include JiraConstants

  def initialize(args, stdin)
    init_config
    @options = OpenStruct.new
    @arguments = args
  end

  def run
    usage_and_exit unless parsed_options?

    @query = @arguments[0]

    if @options.verbose
      @logger.sev_threshold = Logger::DEBUG
    end

    @logger.info("Running query: '#{@query}'")
    output = []

    run_query(@query).each { |issue|
      desc = describe_issue(issue)
      history = find_history(desc[:key])
      @statuses.each { |status, use_first|
        date = transition_date(history, status, use_first)
        desc[status] = date
      }

      output << desc
    }

    display_results(output)
  end

  protected

  def display_results(output)
    if @options.json_output
      results = output.to_json
    else
      results = tp(output)
    end

    if @options[:output_file] == nil
      puts results
    else
      File.write(@options[:output_file], results)
    end
  end

  def parsed_options?
    return false unless (@arguments.size > 0)

    opts = OptionParser.new
    opts.banner = BANNER
    opts.on('-v', '--verbose', 'Enable verbose logging. Helps with debugging.') { @options.verbose = true }
    opts.on('-j', '--json-output', 'Prefer json output instead of a simple table') { @options.json_output = true }
    opts.on('-h', '--help', 'Display this screen') do
      puts opts
      puts
      puts FORMAT
      exit(0)
    end
    @options[:output_file] = nil
    opts.on('-f', '--output_file FILE', 'Write results to FILE' ) do |file|
      @options[:output_file] = file
    end

    opts.parse!(@arguments) rescue return false

    if @arguments.size > 0
      @query = @arguments[0]
      true
    else
      false
    end
  end

  def usage_and_exit
    puts BANNER
    puts
    puts MORE_INFO
    exit(0)
  end

  def init_config
    super()
    @statuses = YAML.load(File.read('./statuses.yaml'))
  end

  def find_history(key)
    status_changes = {}
    changelog = @client.Issue.find(key, :expand => CHANGELOG).changelog
    changelog[HISTORIES].each { |history|
      history[ITEMS].each { |item|
        if item[FIELD] == STATUS
          date = DateTime.strptime(history[CREATED], DATE_FMT)
          status = item[TO_STR]
          status_changes[status] = { :dates => []} unless status_changes.include?(status)
          @logger.debug("Adding #{date} to #{status}")
          status_changes[status][:dates] << date
        end
      }
    }
    return status_changes
  end

  def transition_date(status_changes, state, choose_first)
    result = nil
    if status_changes.include?(state) and choose_first
      @logger.debug("#{state} includes these dates: #{status_changes[state][:dates].to_s}")
      result = status_changes[state][:dates].first.strftime(DATE_FMT)
    elsif status_changes.include?(state) and not choose_first
      @logger.debug("#{state} includes these dates: #{status_changes[state][:dates].to_s}")
      result = status_changes[state][:dates].last.strftime(DATE_FMT)
    else
      @logger.debug("No dates found for #{state}")
    end
    return result
  end

end

app = History.new(ARGV, STDIN)
app.run