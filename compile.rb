
require 'language_pack'
require 'language_pack/shell_helpers'
require 'language_pack/base'
require 'language_pack/ruby'

module Debug
  def copy from, to
    puts "FROM: #{from}, TO: #{to}"
    super
  end
end

LanguagePack::Cache.prepend Debug

class LanguagePack::RubyPure < LanguagePack::Ruby
  def create_database_yml            ; end
  def run_assets_precompile_rake_task; end
  def default_process_types          ; end

  def self.bundler
    @bundler ||= begin
      env = LanguagePack::ShellHelpers.user_env_hash
      gemfile = if bundle_gemfile = env['BUNDLE_GEMFILE']
        puts "=====> BUNDLE_GEMFILE detected, using #{bundle_gemfile}"
        "#{Dir.pwd}/#{bundle_gemfile}"
      end
      LanguagePack::Helpers::BundlerWrapper.
        new(:gemfile_path => gemfile).install
    end
  end

  def build_bundler
    if bundle_gemfile = ENV['BUNDLE_GEMFILE']
      prefix = File.dirname(bundle_gemfile).sub(%r{^#{Dir.pwd}/}, '')
      set_env_override 'PATH',
                       "$HOME/#{prefix}/#{bundler_binstubs_path}:$PATH"
      p "HACKING"
      @bundler_cache.instance_eval do # relocate bundler cache
        @bundler_dir = Pathname.new("#{prefix}/#{@bundler_dir}")
        stack_dir    = if @stack
                         Pathname.new(@stack) + @bundler_dir
                       else
                         @bundler_dir
                       end
        @stack_dir   = "#{prefix}/#{stack_dir}"
      end
    end

    super
  end

  def pipe cmd, opts
    if opts[:env] && (bundle_gemfile = ENV['BUNDLE_GEMFILE'])
      opts[:env]['BUNDLE_GEMFILE'] = bundle_gemfile
    end
    super
  end
end

LanguagePack::ShellHelpers.initialize_env(ARGV[2])
pack = LanguagePack::RubyPure.new(ARGV[0], ARGV[1])
pack.topic("Compiling #{pack.name}")
pack.log("compile") do
  pack.compile
end
