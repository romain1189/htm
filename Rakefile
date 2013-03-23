#!/usr/bin/env rake
require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs = ['lib', 'spec', 'test']
  t.test_files = FileList['test/**/*_test.rb']
end

desc "Run tests"
task :default => :test

namespace :bench do
  benchs = FileList['benchmarks/*.rb']
  benchs.each do |fn|
    task_name = fn.split('/').last.split('.').first
    desc "Run #{task_name} benchmark"
    task task_name.to_sym do
      sh "ruby #{fn}"
    end
  end

  desc "Run all benchmarks"
  task :all => benchs.map { |fn| fn.split('/').last.split('.').first.to_sym }
end