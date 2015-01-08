=begin
 * Import/Export Scripts
 * 
 * This script imports and exports scripts to and from the Scripts.rvdata2
 * file in a RPGVXAce project.
 *
 * Recommended if you want to:
 *   - do projects that involve heavy coding
 *   - use version control
 *   - allow multiple scripters to work concurrently
 *   - work in your own text editor
 * 
 * To run:
 *   - first make sure Ruby is installed and works on your command-line
 *   - place this file in your VXAce project directory
 *   - open up a command-line shell in the project directory
 *   - and simply run the script (type in 'ruby scripts.rb')
 * 
 * After running for the first time, you should see a folder named 
 * '#{yourProjectName}_scripts' next to your project folder. On subsequent
 * runs, the script will make a new Scripts.rvdata2 file from the scripts in 
 * the scripts folder. 
 *
 * USAGE NOTES: 
 * To prevent an old version of Scripts.rvdata2 from overwriting your import,
 * it is recommended that the RPG Maker application is closed while running
 * this script. Also, editing the scripts in RPG Maker will not affect the 
 * scripts in the scripts folder. Be sure to edit the scripts in the scripts
 * folder if you actually want to save them.
 *
 * Set AUTOPLAYTEST to false if you want to import or export without 
 * playtesting the game.
 *
=end

require "zlib"
require "fileutils"

# Automatically runs the game after importing or exporting if true
AUTOPLAYTEST = true

# Important paths
SCRIPTS_DATA = "Data/Scripts.rvdata2"
PROJECT = File.basename(Dir.getwd)
SCRIPTS_FOLDER = "../#{PROJECT}_scripts"
SCRIPTS_INCLUDE = "#{SCRIPTS_FOLDER}/script_include.txt"

#-----------------------------------------------------------------------------
# Export functions
#-----------------------------------------------------------------------------

#
# Loads file and returns deserialized Ruby object 
#
def read_object_from_file(file)
  File.open(file, "rb") do |f| 
    return Marshal.load(f)
  end
end

#
# Exports the names and order of the scripts you want include in your import
#
def export_script_include(scripts)
  script_names = scripts.map { |script| script[1] }
  File.write(SCRIPTS_INCLUDE, script_names.join("\n"))
end

#
# Export scripts
#
def export_scripts
  scripts = read_object_from_file(SCRIPTS_DATA)

  FileUtils.mkdir_p(SCRIPTS_FOLDER)

  export_script_include(scripts)

  folder = false
  script_folder = ""

  scripts.each do |script|
    script_name = script[1]

    # Not a script
    if script_name == ""
      folder = true

    # Make a folder
    elsif folder
      script_folder = "#{SCRIPTS_FOLDER}/#{script_name}"
      FileUtils.mkdir_p(script_folder)
      folder = false

    # Export script
    else
      script_path = "#{script_folder}/#{script_name}.rb"
      File.open(script_path, "wb") do |script_file|
        script_content = Zlib::Inflate.inflate(script[2])
        script_file.write(script_content)
      end
    end
  end
end

#-----------------------------------------------------------------------------
# Import functions
#-----------------------------------------------------------------------------

#
# Serializes object data and writes data into file 
#
def write_object_to_file(file, data)
  File.open(file, "wb") do |f|
    Marshal.dump(data, f)
  end
end

#
# Import scripts
#
def import_scripts
  script_names = File.read(SCRIPTS_INCLUDE, :encoding => 'utf-8').split("\n")

  folder = false
  script_folder = ""

  data = Array.new

  script_names.each do |script_name|
    script_data = Array.new(3)
    script_data[0] = 42
    script_data[1] = script_name

    # Not a script
    if script_name == ""
      folder = true
      script_data[2] = Zlib::Deflate.deflate("", Zlib::BEST_COMPRESSION)

    # Found holding folder
    elsif folder
      script_folder = "#{SCRIPTS_FOLDER}/#{script_name}"
      folder = false
      script_data[2] = Zlib::Deflate.deflate("", Zlib::BEST_COMPRESSION)

    # Import script
    else
      script_path = "#{script_folder}/#{script_name}.rb"
      script = File.read(script_path, :encoding => 'utf-8')
      script_data[2] = Zlib::Deflate.deflate(script, Zlib::BEST_COMPRESSION)
    end

    data.push(script_data)
  end

  write_object_to_file(SCRIPTS_DATA, data)
end

#-----------------------------------------------------------------------------
# Rest of the code
#-----------------------------------------------------------------------------

#
# Checks if the exported scripts folder exists
#
def scripts_exported?
  Dir.exists?(SCRIPTS_FOLDER)
end

#
# Import, Export, and Play
#
def main
  if scripts_exported?
    puts "Scripts folder found. Importing scripts..."
    import_scripts
    puts "Import complete."
  else
    puts "Scripts folder not found. Exporting scripts..."
    export_scripts
    puts "Export complete. Your scripts are in #{SCRIPTS_FOLDER}"
  end

  if AUTOPLAYTEST
    puts "Starting Game..."
    exec("Game.exe console")
  end
end

main
