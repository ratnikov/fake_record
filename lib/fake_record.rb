begin
  Dir.glob(File.dirname(__FILE__) + '/fake_record/**/*.rb') do |file|
    require file
  end
rescue LoadError => lE
  raise LoadError, "Error in FakeRecord plugin: #{lE.inspect}."
end
