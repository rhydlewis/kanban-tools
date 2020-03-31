#! /usr/bin/env ruby
require 'jira-ruby'
require 'yaml'
require 'table_print'
require 'json'
require 'ostruct'
require 'optparse'
require 'csv'

$: << File.join(File.dirname(__FILE__), '.')
require 'jira_constants'

class History

  BANNER = 'Usage: history [options] query'
  MORE_INFO = 'For help use: history -h'
  JSON_FORMAT = 'json'
  CSV_FORMAT = 'csv'
  TSV_FORMAT = 'tsv'

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

    # hack to avoid problem of JIRA API returning max 100 results at a time
    offsets = [0, 100, 200, 300, 400, 500]

    offsets.each do |offset|
      run_query(@query, offset).each { |issue|
        desc = describe_issue(issue)
        history = find_history(desc[:key])
        @statuses.each { |status, use_first|
          date = transition_date(history, status, use_first)
          desc[status] = date
        }

        output << desc
      }
    end


    if @options[:format] == JSON_FORMAT
      display_results_as_json(output)
    elsif @options[:format] == CSV_FORMAT
      display_results_as_csv(output, ',')
    elsif @options[:format] == TSV_FORMAT
      display_results_as_csv(output, "\t")
    else
      display_results_as_table(output)
    end
  end

  protected

  def display_results_as_json(output)
    if @options[:output_file] == nil
      puts output.to_json
    else
      write_results_to_file(output.to_json)
    end
  end

  def display_results_as_table(output)
    if @options[:output_file] != nil
      f = File.open(@options[:output_file], 'w')
      tp.set(:io, f)
      @logger.info("Writing results to #{path}")
      File.write(@options[:output_file], output.to_json)
    end
    tp(output)
  end

  def display_results_as_csv(output, col_sep)
    csv = CSV.generate_line(output.first.keys, {:col_sep => col_sep})
    output.each { |result|
      csv << CSV.generate_line(result.values, {:col_sep => col_sep})
    }

    if @options[:output_file] == nil
      puts csv
    else
      write_results_to_file(csv)
    end
  end

  def write_results_to_file(data)
    path = @options[:output_file]
    @logger.info("Writing results to #{path}")
    File.write(path, data)
  end

  def parsed_options?
    return false unless (@arguments.size > 0)

    opts = OptionParser.new
    opts.banner = BANNER
    opts.on('-f', '--format <format>', 'Specify either <json>, <csv> or <tsv> output instead of a simple table') do |format|
      if [JSON_FORMAT, CSV_FORMAT, TSV_FORMAT].include?(format)
        @options[:format] = format
      else
        puts "Unknown format #{format}"
        return false
      end
    end
    @options[:format] = nil
    @options[:output_file] = nil
    opts.on('-o', '--output <file>', 'Write results to <file>' ) do |file|
      @options[:output_file] = file
    end
    opts.on('-h', '--help', 'Usage help') do
      puts opts
      puts
      puts FORMAT
      exit(0)
    end
    opts.on('-v', '--verbose', 'Enable verbose logging. Helps with debugging.') { @options.verbose = true }
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
    @logger.info("Processing #{key}")
    status_changes = {}
    changelog = @client.Issue.find(key, :expand => CHANGELOG).changelog
    changelog[HISTORIES].each { |history|
      history[ITEMS].each { |item|
        if item[FIELD] == STATUS
          date = DateTime.strptime(history[CREATED], DATE_FMT)
          status = item[TO_STR]
          status_changes[status] = { :dates => []} unless status_changes.include?(status)
          @logger.warn("Found missing status #{status}") unless status_changes.include?(status)
          @logger.debug("Adding #{date} to '#{status}'")
          status_changes[status][:dates] << date
        end
      }
    }
    return status_changes
  end

  def transition_date(status_changes, state, use_first)
    result = nil
    if status_changes.include?(state) and use_first
      @logger.debug("#{state} includes these dates: #{status_changes[state][:dates].to_s}")
      result = status_changes[state][:dates].first.strftime(DATE_FMT)
    elsif status_changes.include?(state) and not use_first
      @logger.debug("#{state} includes these dates: #{status_changes[state][:dates].to_s}")
      result = status_changes[state][:dates].last.strftime(DATE_FMT)
    else
      @logger.debug("No dates found for '#{state}'")
    end
    @logger.debug("Using date #{result} for '#{state}'")
    return result
  end

end

app = History.new(ARGV, STDIN)
app.run