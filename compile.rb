
require 'language_pack/base'
require 'language_pack/ruby'

LanguagePack::ShellHelpers.initialize_env(ARGV[2])
pack = LanguagePack::Ruby.new(ARGV[0], ARGV[1])
pack.topic("Compiling #{pack.name}")
pack.log("compile") do
  pack.compile
end
