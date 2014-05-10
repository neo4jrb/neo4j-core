# borrowed from architect4r
require 'os'
require 'httparty'

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
      df = File.open(file_name, 'wb')
      begin
        df << HTTParty.get(download_url)
      ensure
        df.close()
      end
    end
    file_name
  end

  desc "Install Neo4j"
  task :install, :edition, :version do |t, args|
    args.with_defaults(:edition => "community")

    file = args[:version] ? "#{args[:edition]}-#{args[:version]}" : "#{args[:edition]}"
    puts "Installing Neo4j-#{file}"

    downloaded_file = download_neo4j file
    
    if OS::Underlying.windows?
      # Extract and move to neo4j directory
      unless File.exist?('neo4j')
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
        FileUtils.mv "neo4j-#{file}", "neo4j"
     end

      # Install if running with Admin Privileges
      if %x[reg query "HKU\\S-1-5-19"].size > 0 
        %x[neo4j/bin/neo4j install]
        puts "Neo4j Installed as a service."
      end

    else
      %x[tar -xvzf #{downloaded_file}]
      %x[mv neo4j-#{file} neo4j]
      %x[rm #{downloaded_file}]
      puts "Neo4j Installed in to neo4j directory."
    end
    puts "Type 'rake neo4j:start' to start it"
  end
  
  desc "Start the Neo4j Server"
  task :start do
    puts "Starting Neo4j..."
    if OS::Underlying.windows? 
      if %x[reg query "HKU\\S-1-5-19"].size > 0 
        %x[neo4j/bin/Neo4j.bat start]  #start service
      else
        puts "Starting Neo4j directly, not as a service."
        %x[neo4j/bin/Neo4j.bat]
      end      
    else
      %x[neo4j/bin/neo4j start]  
    end
  end
  
  desc "Stop the Neo4j Server"
  task :stop do
    puts "Stopping Neo4j..."
    if OS::Underlying.windows? 
      if %x[reg query "HKU\\S-1-5-19"].size > 0
         %x[neo4j/bin/Neo4j.bat stop]  #stop service
      else
        puts "You do not have administrative rights to stop the Neo4j Service"   
      end
    else  
      %x[neo4j/bin/neo4j stop]
    end
  end

  desc "Restart the Neo4j Server"
  task :restart do
    puts "Restarting Neo4j..."
    if OS::Underlying.windows? 
      if %x[reg query "HKU\\S-1-5-19"].size > 0
         %x[neo4j/bin/Neo4j.bat restart] 
      else
        puts "You do not have administrative rights to restart the Neo4j Service"   
      end
    else  
      %x[neo4j/bin/neo4j restart]
    end
  end

  desc "Reset the Neo4j Server"
  task :reset_yes_i_am_sure do
    # Stop the server
    if OS::Underlying.windows? 
      if %x[reg query "HKU\\S-1-5-19"].size > 0
         %x[neo4j/bin/Neo4j.bat stop]
         
        # Reset the database
        FileUtils.rm_rf("neo4j/data/graph.db")
        FileUtils.mkdir("neo4j/data/graph.db")
        
        # Remove log files
        FileUtils.rm_rf("neo4j/data/log")
        FileUtils.mkdir("neo4j/data/log")

        %x[neo4j/bin/Neo4j.bat start]
      else
        puts "You do not have administrative rights to reset the Neo4j Service"   
      end
    else  
      %x[neo4j/bin/neo4j stop]
      
      # Reset the database
      FileUtils.rm_rf("neo4j/data/graph.db")
      FileUtils.mkdir("neo4j/data/graph.db")
      
      # Remove log files
      FileUtils.rm_rf("neo4j/data/log")
      FileUtils.mkdir("neo4j/data/log")
      
      # Start the server
      %x[neo4j/bin/neo4j start]
    end
  end

end  
