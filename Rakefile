#!/usr/bin/env ruby
require 'rake'
require 'fileutils'

PROJECT_DIR = File.dirname __FILE__
UNITY="/Applications/Unity/Unity.app/Contents"
DSTDIR="../build/Packager/Assets/Plugins"

task 'default' => 'build'

desc 'build plugins'
task :build do
  # %w(Mac iOS Android).each do |p|
  Dir.chdir('Plugins') do
    FileUtils.cp(%w(BCLService.cs BLEService.cs), DSTDIR)
  end
  %w(Android iOS).each do |p|
    Dir.chdir(File.join('Plugins', p)) do
      system_or_exit(%Q[./install.sh])
    end
  end
end


desc "pack"
task :pack do
  system "#{UNITY}/MacOS/Unity -projectPath `pwd`/build/Packager -batchmode -quit -executeMethod Packager.Export"
  FileUtils.mv "build/Packager/bluetoothservice.unitypackage", "./dist"
end

private

def system_or_exit(cmd, stdout = nil)
  cmd += " >#{stdout}" if stdout
  puts "$ #{cmd}"
  system(cmd) || fail('command failed. ')
end
