# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :rspec, cmd: 'bundle exec spring rspec' do
  watch(/^spec\/.+_spec\.rb$/)
  watch(/^features\/.+_spec\.rb$/)
  watch('spec/spec_helper.rb') { 'spec' }
  watch('features/acceptance_helper.rb') { 'features' }
  watch(/^app\/(.+)\.rb$/) { |m| "spec/#{m[1]}_spec.rb" }
  watch(/^app\/(.+)\.rb$/) { |m| "features/#{m[1]}_spec.rb" }
  watch(%r{^app/controllers/api/(.+)_(controller)\.rb$})  { |m| ["spec/requests/#{m[1]}_spec.rb"] }
  watch(%r{^app/controllers/api/(.+)_(controller)\.rb$})  { |m| ["featues/#{m[1]}_spec.rb"] }
end

guard :rubocop do
  watch(/.+\.rb$/)
  watch(/(?:.+\/)?\.rubocop\.yml$/) { |m| File.dirname(m[0]) }
end

### Guard::Konacha
#  available options:
#  - :run_all_on_start, defaults to true
#  - :notification, defaults to true
#  - :rails_environment_file, location of rails environment file,
#    should be able to find it automatically
guard :konacha do
  watch(%r{^app/assets/javascripts/(.*)\.js(\.coffee)?$}) { |m| "#{m[1]}_spec.js" }
  watch(%r{^spec/javascripts/.+_spec(\.js|\.js\.coffee)$})
end
