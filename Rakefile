task :bgem do
  sh 'bundle exec bgem'
end

task :build do
  sh 'shards build'
end

task :spec => :bgem do
  sh 'crystal spec'
end

task :default => [:bgem, :build]
