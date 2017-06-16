require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'active_record'

enable :logging, :dump_errors, :raise_errors

log = File.new("sinatra.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)

ActiveRecord::Base.configurations = YAML.load(ERB.new(File.read('database.yml')).result)
ActiveRecord::Base.establish_connection(:development)

class Employee < ActiveRecord::Base; end

arcus = Dalli::Client.new("#{ENV['ARCUS_HOST']}:11211")

get '/mysql' do
  employee = Employee.find((20000..25000).to_a)
  Employee.clear_all_connections!
  employee.to_json
end

get '/arcus' do
  cache = arcus.get('employee')
  if cache.nil?
    employee_json = Employee.find((20000..25000).to_a).to_json
    Employee.clear_all_connections!
    arcus.set('employee', employee_json)
    employee_json
  else
    employee_json = JSON.parse(cache)
    employee_json[:cached] = true
    employee_json.to_json
  end
end
