
require 'language_pack'
require 'language_pack/shell_helpers'
require 'language_pack/base'
require 'language_pack/ruby'

module Debug
  def copy from, to
    puts "FROM: #{from}, TO: #{to}"
    super
  end

  def read key
    p "READ: #{LanguagePack::Metadata::FOLDER}/#{key} #{exists?(key)} #{Dir.pwd} #{@cache}"
    puts `ls vendor/heroku`
    puts `cat vendor/heroku/stack`
    super
  end
end

LanguagePack::Cache.prepend Debug
LanguagePack::Metadata.prepend Debug

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

  def new_app?
    false
  end

  def build_bundler
    p "OLD? #{@bundler_cache.old?} #{@metadata.read('stack')}"

    if bundle_gemfile = ENV['BUNDLE_GEMFILE']
      prefix = File.dirname(bundle_gemfile).sub(%r{^#{Dir.pwd}/}, '')

      # relocate bin
      set_env_override 'PATH',
                       "$HOME/#{prefix}/#{bundler_binstubs_path}:$PATH"

      # relocate cache
      cache.define_singleton_method :store do |from, path=nil|
        super("#{prefix}/#{from}", path)
      end
      cache.define_singleton_method :add do |from, path=nil|
        super("#{prefix}/#{from}", path)
      end
      cache.define_singleton_method :load do |path, dest=nil|
        p "LOADING: #{prefix}/#{path} #{dest}"
        super("#{prefix}/#{path}", dest)
      end

      p "OLD? #{@bundler_cache.old?} #{@metadata.read('stack')}"
    end

    super

    if bundle_gemfile
      # write metadata back
      cache.instance_eval do
        copy("#{prefix}/vendor/heroku", "#{@cache_base}/vendor/heroku")
      end
    end
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
  puts `cat /app/tmp/cache/vendor/heroku/stack`
  puts `cat vendor/heroku/stack`
  pack.compile
end
