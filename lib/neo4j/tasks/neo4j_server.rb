# borrowed from architect4r
require 'os'
require 'httparty'
require 'zip'
require File.expand_path("../config_server", __FILE__)

namespace :neo4j do

  def download_neo4j(file)
    if OS::Underlying.windows? then
      file_name = "neo4j.zip"
      download_url = "http://dist.neo4j.org/neo4j-#{file}-windows.zip"
    else
      file_name = "neo4j-unix.tar.gz"
      download_url = "http://dist.neo4j.org/neo4j-#{file}-unix.tar.gz"
    end

    unless File.exist?(file_name)
      # check if file is available
      status = HTTParty.head(download_url).code
      raise "#{file} is not available to download, try a different version" if status < 200 || status >= 300

      df = File.open(file_name, 'wb')


      success = false
      begin
        df << HTTParty.get(download_url)
        success = true
      ensure
        df.close()
        File.delete(file_name) unless success
      end
    end



    # # http://download.neo4j.org/artifact?edition=community&version=2.1.2&distribution=tarball&dlid=3462770&_ga=1.110610309.1220184053.1399636580
    #
    # parsed_url = URI.parse(download_url)
    #
    # puts "parsed_url.host #{parsed_url.host} port #{parsed_url.port} uri: #{parsed_url.request_uri}"
    # Net::HTTP.start(parsed_url.host, parsed_url.port) do |http|
    #   request = Net::HTTP::Get.new parsed_url.request_uri
    #   http.request request do |response|
    #     File.open 'large_file.tar.gz', 'wb' do |io|
    #       response.read_body do |chunk|
    #         io.write chunk
    #       end
    #     end
    #   end
    # end
    #
    # puts "DOWN LOAD URL #{download_url}, exist #{file_name} : #{File.exist?(file_name)}"
    #

    file_name
  end

  def get_environment(args)
    args[:environment] || 'development'
  end

  def install_location(args)
    FileUtils.mkdir_p('db/neo4j') unless File.directory?('db')
    "db/neo4j/neo4j-#{get_environment(args)}"
  end

  desc "Install Neo4j, example neo4j:install[community-2.1.3,development]"
  task :install, :edition, :environment do |_, args|
    file = args[:edition]
    environment = get_environment(args)
    puts "Installing Neo4j-#{file} environment: #{environment}"

    downloaded_file = download_neo4j file
    
    if OS::Underlying.windows?
      # Extract and move to neo4j directory
      unless File.exist?(install_location(args))
        Zip::ZipFile.open(downloaded_file) do |zip_file|
          zip_file.each do |f|
           f_path=File.join(".", f.name)
           FileUtils.mkdir_p(File.dirname(f_path))
           begin
             zip_file.extract(f, f_path) unless File.exist?(f_path)
           rescue
             puts f.name + " failed to extract."
           end
          end
        end
        FileUtils.mv "neo4j-#{file}", install_location(args)
        FileUtils.rm downloaded_file
     end

      # Install if running with Admin Privileges
      if %x[reg query "HKU\\S-1-5-19"].size > 0
        %x["#{install_location(args)}/bin/neo4j install"]
        puts "Neo4j Installed as a service."
      end

    else
      %x[tar -xvf #{downloaded_file}]
      %x[mv neo4j-#{file} #{install_location(args)}]
      %x[rm #{downloaded_file}]
      puts "Neo4j Installed in to neo4j directory."
    end
    puts "Type 'rake neo4j:start' or 'rake neo4j:start[ENVIRONMENT]' to start it\nType 'neo4j:config[ENVIRONMENT,PORT]' for changing server port, (default 7474)"
  end
  
  desc "Start the Neo4j Server"
  task :start, :environment do |_, args|
    puts "Starting Neo4j #{get_environment(args)}..."
    if OS::Underlying.windows? 
      if %x[reg query "HKU\\S-1-5-19"].size > 0 
        %x[#{install_location(args)}/bin/Neo4j.bat start]  #start service
      else
        puts "Starting Neo4j directly, not as a service."
        %x[#{install_location(args)}/bin/Neo4j.bat]
      end      
    else
      %x[#{install_location(args)}/bin/neo4j start]
    end
  end

  desc "Configure Server, e.g. rake neo4j:config[development,8888]"
  task :config, :environment, :port do |_, args|

    port = args[:port]
    raise "no port given" unless port
    puts "Config Neo4j #{get_environment(args)} for port #{port}"
    location = "#{install_location(args)}/conf/neo4j-server.properties"
    text = File.read(location)
    replace = Neo4j::Tasks::ConfigServer.config(text, port)
    File.open(location, "w") {|file| file.puts replace}
  end

  desc "Stop the Neo4j Server"
  task :stop, :environment do |_, args|
    puts "Stopping Neo4j #{get_environment(args)}..."
    if OS::Underlying.windows? 
      if %x[reg query "HKU\\S-1-5-19"].size > 0
         %x[#{install_location(args)}/bin/Neo4j.bat stop]  #stop service
      else
        puts "You do not have administrative rights to stop the Neo4j Service"   
      end
    else  
      %x[#{install_location(args)}/bin/neo4j stop]
    end
  end

  desc "Get info the Neo4j Server"
  task :info, :environment do |_, args|
    puts "Info from Neo4j #{get_environment(args)}..."
    if OS::Underlying.windows?
      if %x[reg query "HKU\\S-1-5-19"].size > 0
        %x[#{install_location(args)}/bin/Neo4j.bat info]  #stop service
      else
        puts "You do not have administrative rights to get info from the Neo4j Service"
      end
    else
      puts %x[#{install_location(args)}/bin/neo4j info]
    end
  end

  desc "Restart the Neo4j Server"
  task :restart, :environment do |_, args|
    puts "Restarting Neo4j #{get_environment(args)}..."
    if OS::Underlying.windows? 
      if %x[reg query "HKU\\S-1-5-19"].size > 0
         %x[#{install_location(args)}/bin/Neo4j.bat restart]
      else
        puts "You do not have administrative rights to restart the Neo4j Service"   
      end
    else  
      %x[#{install_location(args)}/bin/neo4j restart]
    end
  end

  desc "Reset the Neo4j Server"
  task :reset_yes_i_am_sure, :environment do |_, args|
    # Stop the server
    if OS::Underlying.windows? 
      if %x[reg query "HKU\\S-1-5-19"].size > 0
         %x[#{install_location(args)}/bin/Neo4j.bat stop]
         
        # Reset the database
        FileUtils.rm_rf("#{install_location(args)}/data/graph.db")
        FileUtils.mkdir("#{install_location(args)}/data/graph.db")
        
        # Remove log files
        FileUtils.rm_rf("#{install_location(args)}/data/log")
        FileUtils.mkdir("#{install_location(args)}/data/log")

        %x[#{install_location(args)}/bin/Neo4j.bat start]
      else
        puts "You do not have administrative rights to reset the Neo4j Service"   
      end
    else  
      %x[#{install_location(args)}/bin/neo4j stop]
      
      # Reset the database
      FileUtils.rm_rf("#{install_location(args)}/data/graph.db")
      FileUtils.mkdir("#{install_location(args)}/data/graph.db")
      
      # Remove log files
      FileUtils.rm_rf("#{install_location(args)}/data/log")
      FileUtils.mkdir("#{install_location(args)}/data/log")
      
      # Start the server
      %x[#{install_location(args)}/bin/neo4j start]
    end
  end

end  
