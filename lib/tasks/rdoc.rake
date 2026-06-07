require "rdoc/task"

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "doc"
  rdoc.title    = "Activity Finder"
  rdoc.main     = "README.md"
  rdoc.markup   = "markdown"
  rdoc.options << "--line-numbers"
  rdoc.rdoc_files.include(
    "README.md",
    "app/**/*.rb",
    "lib/**/*.rb"
  )
end
