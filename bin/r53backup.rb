# Backup Route53 DNS records to your S3 bucket!

# Get lib files added to path
$:.unshift File.join(File.dirname(__FILE__), "../lib")

require 'bundler/setup'
require 'rubygems'
require 'route53backup'
require 'daemon'
require 'timer'

class Route53ToS3 < Daemon::Base
	def self.start
		# Create configuration object from the config file
		Configuration.new('spec/.route53_test')

		# Do an initial upload on start
		upload

		# Now upload based on time if specified in the configuration file.
		if !Configuration.daemon['times'].nil?
			timeList = Configuration.daemon['times'].split(',')
			@timer = Timer.new(timeList)

			# Keep looping and waiting until the time has come to upload,
			# and then upload once it's time!
			loop do

				if @timer.ready_for_upload? 
					upload
				end

				# Sleep for 20 seconds at a time, no need to check as fast as possible!
				sleep(20)
			end
		end
	end

	def self.stop
		puts "Stopping Route53 to S3 backups"
	end
	
	private
	def self.upload
		# Connect to S3
		Route53Backup.connect

		# Grab DNS records and populate a sqlite3 database with them
		Route53Backup.populate_db

		# Upload the populated db to S3
		Route53Backup.upload_db
	end
end

#Route53ToS3.daemonize
Route53ToS3.start