# Kanban Tools

* A set of tools to help produce data about your Kanban system.
* Currently very Jira-specific but more to follow...

## Jira Tools

*Notes* 

* requires ruby 2.1.x or later (might work with default Mac OS X ruby install (1.9.3) but not tested)
* depends on:
    * [jira-ruby 0.1.13](https://github.com/sumoheavy/jira-ruby) (or greater)
    * [table_print 1.5.3](http://tableprintgem.com) (or greater)

### History

#### Installation

    # gem install jira-ruby
    # gem install table_print

#### Configuration

1. Copy the file **jira-settings.yaml.example** and rename as **jira-settings.yaml**.
2. Update the 5 configuration options to suit your Jira install:
    * **username** - your username
    * **password** - your password
    * **max_results** - maximum number of results you want to return
    * **jira** - your Jira URL
    * **use_ssl**: true if your Jira install uses https:// or false if it uses http://
3. Copy the file **statuses.yaml.example** and rename as **statuses.yaml**
4. Add your project's workflow statuses into this file using the format **'Status Name: true|false'**. 

The example file contains:

    To Do: true
    In Progress: true
    Done: true

where:

* 'To Do' is a valid Jira status and:
    * 'true' means you want to see the *first* time an issue transitions for this status
    * 'false' means you want to see the *last* time an issue transitions for this status

#### Usage

Given a JQL query, the tool tries to show information about the transition history for each issue found.
  
For example, Jira project TEST contains 2 issues (TEST-1 and TEST-2). Running:

    ./history.rb "project = TEST"

produces the following output:

    KEY    | SUMMARY       | TYPE  | STATUS      | CREATED    | TO DO      | IN PROGRESS | DONE      
    -------|---------------|-------|-------------|------------|------------|-------------|-----------
    TEST-2 | Example task  | Task  | Done        | 2015-07-13 | 2015-07-13 |             | 2015-07-15
    TEST-1 | Example story | Story | In Progress | 2015-07-13 | 2015-07-13 | 2015-07-13  |           

#### Options

    -f, --format <format>            Specify either <json> or <csv> output instead of a simple table
    -o, --output <file>              Write results to <file>
    -h, --help                       Usage help
    -v, --verbose                    Enable verbose logging. Helps with debugging.

**JSON Output**

Running:

    ./history.rb -f json "project = TEST"

displays:

    [{"key":"TEST-2","summary":"Example task","type":"Task","status":"Done","created":"2015-07-13","To Do":"2015-07-13","In Progress":null,"Done":"2015-07-15"},{"key":"TEST-1","summary":"Example story","type":"Story","status":"In Progress","created":"2015-07-13","To Do":"2015-07-13","In Progress":"2015-07-13","Done":null}]

**CSV Output**

Running:

    ./history.rb -f csv "project = TEST"

displays:

    key,summary,type,status,created,To Do,In Progress,Done
    TEST-2,Example task,Task,Done,2015-07-13,2015-07-13,,2015-07-15
    TEST-1,Example story,Story,In Progress,2015-07-13,2015-07-13,2015-07-13,

**TSV Output**

(Useful if you want to copy and paste straight into a spreadsheet). Running:

    ./history.rb -f tsv "project = TEST"

displays:

    key	summary	type	status	created	To Do	In Progress	Done
    TEST-2	Example task	Task	Done	2015-07-13	2015-07-13		2015-07-15
    TEST-1	Example story	Story	In Progress	2015-07-13	2015-07-13	2015-07-13

**Outputting to file**

Run:

    ./history.rb -f csv -o output.csv "project = TEST"

to write the results to the filename provided.

#### Future updates

* support for lead time calculation based on 2 statuses of your choice