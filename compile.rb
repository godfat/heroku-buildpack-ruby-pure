
require 'language_pack'
require 'language_pack/shell_helpers'
require 'language_pack/base'
require 'language_pack/ruby'

module Debug
  def copy from, to
    # f, t = File.expand_path(from), File.expand_path(to)
    # puts "FROM: #{f}, TO: #{t}"
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
      gemfile = if bundle_gemfile = env['BUNDLE_GEMFILE']
        puts "=====> BUNDLE_GEMFILE detected, using #{bundle_gemfile}"
        "#{Dir.pwd}/#{bundle_gemfile}"
      end
      LanguagePack::Helpers::BundlerWrapper.
        new(:gemfile_path => gemfile).install
    end
  end

  def self.env
    LanguagePack::ShellHelpers.user_env_hash
  end

  def build_bundler
    p "build_bundler #{Dir.pwd}/#{self.class.env['BUNDLE_GEMFILE']} #{ENV['BUNDLE_GEMFILE']}"
    if bundle_gemfile = self.class.env['BUNDLE_GEMFILE']
      prefix = File.dirname(bundle_gemfile).sub(%r{^#{Dir.pwd}/}, '')

      # relocate bin
      set_env_override 'PATH',
                       "$HOME/#{prefix}/#{bundler_binstubs_path}:$PATH"

      # relocate cache
      # cache.define_singleton_method :store do |from, path=nil|
      #   super("#{prefix}/#{from}", path)
      # end
      # cache.define_singleton_method :add do |from, path=nil|
      #   super("#{prefix}/#{from}", path)
      # end
      # cache.define_singleton_method :load do |path, dest=nil|
      #   super("#{prefix}/#{path}", dest)
      # end
    end

    super

    # if bundle_gemfile
    #   # write metadata back
    #   cache.instance_eval do
    #     copy("#{prefix}/vendor/heroku", "#{@cache_base}/vendor/heroku")
    #   end
    # end
  end

  def pipe cmd, opts
    p "pipe #{Dir.pwd}/#{self.class.env['BUNDLE_GEMFILE']} #{ENV['BUNDLE_GEMFILE']}"
    if opts[:env] && (bundle_gemfile = self.class.env['BUNDLE_GEMFILE'])
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
