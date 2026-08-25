# frozen_string_literal: true

require "bundler/gem_tasks"

desc "Type-check the code base with Sorbet"
task :typecheck do
  sh "bundle exec srb tc" do |ok, _res|
    abort unless ok
  end
end

# Aliases for common names for this task.
desc "alias for typecheck"; task tc: :typecheck
desc "alias for typecheck"; task srb: :typecheck
desc "alias for typecheck"; task sorbet: :typecheck

require "minitest/test_task"

Minitest::TestTask.create do |t|
  t.libs.delete("test")
  t.libs << "spec"
  t.test_globs = ["spec/**/*_spec.rb"]
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: [:typecheck, :test, :rubocop]
