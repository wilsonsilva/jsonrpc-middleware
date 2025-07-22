# frozen_string_literal: true

require 'English' # For $CHILD_STATUS
require 'bundler/audit/task'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yaml'
require 'yard/rake/yardoc_task'
require 'yard-junk/rake'
require 'yardstick/rake/measurement'
require 'yardstick/rake/verify'

yardstick_options = YAML.load_file('.yardstick.yml')

Bundler::Audit::Task.new
RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
YARD::Rake::YardocTask.new
YardJunk::Rake.define_task
Yardstick::Rake::Measurement.new(:yardstick_measure, yardstick_options)
Yardstick::Rake::Verify.new(:verify_measurements, yardstick_options)

task default: %i[spec rubocop]

# Remove the report on rake clobber
CLEAN.include('measurements', 'doc', '.yardoc', 'tmp')

# Delete these files and folders when running rake clobber.
CLOBBER.include('coverage', '.rspec_status')

desc 'Run spec with coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].execute
  `open coverage/index.html`
end

desc 'Test, lint and perform security and documentation audits'
task qa: %w[spec rubocop yard:junk verify_measurements bundle:audit]

namespace :yard do
  desc 'Format YARD documentation'
  task :format do
    require 'fileutils'

    ruby_files = Dir.glob(File.join(Dir.pwd, 'lib', '**', '*.rb'))

    puts "Found #{ruby_files.length} Ruby files in lib directory"
    puts

    ruby_files.each do |file_path|
      puts "Processing #{file_path}..."

      content = File.read(file_path)
      lines = content.split("\n")
      result = []

      lines.each_with_index do |line, index|
        result << line

        current_is_yard = line.strip.match?(/^\s*#\s*@\w+/)
        next_line_exists = index + 1 < lines.length

        # Process YARD tag spacing
        next unless current_is_yard && next_line_exists

        next_line = lines[index + 1]

        next unless next_line.strip.match?(/^\s*#\s*@\w+/)

        current_tag = line.strip.match(/^\s*#\s*@(\w+)/)[1]
        next_tag = next_line.strip.match(/^\s*#\s*@(\w+)/)[1]

        groupable = %w[param option]
        should_group = groupable.include?(current_tag) && groupable.include?(next_tag)

        # Add blank line between different tag types
        unless should_group
          indentation = line.match(/^(\s*)/)[1]
          result << "#{indentation}#"
        end
      end

      formatted_content = "#{result.join("\n")}\n"

      if content == formatted_content
        puts '  - No changes needed'
      else
        File.write(file_path, formatted_content)
        puts '  ✓ Updated'
      end
    end

    puts
    puts 'Done!'
  end
end

namespace :examples do
  desc 'Run bundle install on all example folders'
  task :bundle_install do
    examples_dir = File.join(Dir.pwd, 'examples')

    unless Dir.exist?(examples_dir)
      puts 'Examples directory not found'
      exit 1
    end

    example_folders = Dir.glob(File.join(examples_dir, '*')).select { |path| Dir.exist?(path) }

    if example_folders.empty?
      puts 'No example folders found'
      return
    end

    puts "Found #{example_folders.length} example folders:"
    example_folders.each { |folder| puts "  - #{File.basename(folder)}" }
    puts

    failed_folders = []

    example_folders.each do |folder|
      gemfile_path = File.join(folder, 'Gemfile')

      unless File.exist?(gemfile_path)
        puts "Skipping #{File.basename(folder)} - no Gemfile found"
        next
      end

      puts "Running bundle install in #{File.basename(folder)}..."

      Dir.chdir(folder) do
        system('bundle install')

        if $CHILD_STATUS.success?
          puts "  ✓ Successfully installed gems in #{File.basename(folder)}"
        else
          failed_folders << File.basename(folder)
          puts "  ✗ Failed to bundle install in #{File.basename(folder)}"
        end
      end

      puts
    end

    if failed_folders.empty?
      puts 'All example folders processed successfully!'
    else
      puts "Failed to process #{failed_folders.length} folders: #{failed_folders.join(", ")}"
      exit 1
    end
  end
end
