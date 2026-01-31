# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList['test/ruby_date/test_*.rb']
  t.verbose = true
end

# 個別のテストグループ
namespace :test do
  Rake::TestTask.new(:basic) do |t|
    t.test_files = FileList['test/ruby_date/test_date_new.rb',
                             'test/ruby_date/test_date_attr.rb']
  end

  Rake::TestTask.new(:arith) do |t|
    t.test_files = FileList['test/ruby_date/test_date_arith.rb']
  end

  Rake::TestTask.new(:compat) do |t|
    t.test_files = FileList['test/ruby_date/test_date_compat.rb']
  end

  Rake::TestTask.new(:conv) do |t|
    t.test_files = FileList['test/ruby_date/test_date_conv.rb']
  end

  Rake::TestTask.new(:marshal) do |t|
    t.test_files = FileList['test/ruby_date/test_date_marshal.rb']
  end

  Rake::TestTask.new(:strftime) do |t|
    t.test_files = FileList['test/ruby_date/test_date_strftime.rb']
  end

  Rake::TestTask.new(:strptime) do |t|
    t.test_files = FileList['test/ruby_date/test_date_strptime.rb']
  end

  Rake::TestTask.new(:parse) do |t|
    t.test_files = FileList['test/ruby_date/test_date_parse.rb']
  end

  Rake::TestTask.new(:ractor) do |t|
    t.test_files = FileList['test/ruby_date/test_date_ractor.rb']
  end

  Rake::TestTask.new(:switch) do |t|
    t.test_files = FileList['test/ruby_date/test_switch_hitter.rb']
  end
end

task default: :test
