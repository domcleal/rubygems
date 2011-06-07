require 'rubygems/test_case'
require 'rubygems'
require 'rubygems/rdoc'

class TestGemRDoc < Gem::TestCase

  def setup
    super

    @a = quick_spec 'a'

    @rdoc = Gem::RDoc.new @a

    begin
      Gem::RDoc.load_rdoc
    rescue Gem::DocumentError => e
      skip e.message
    end
  end

  def rdoc_3?
    Gem::Requirement.new('>= 3').satisfied_by? @rdoc.class.rdoc_version
  end

  def test_initialize
    assert @rdoc.generate_rdoc
    assert @rdoc.generate_ri

    assert_equal "#{@a.doc_dir}/rdoc", @rdoc.rdoc_dir
    assert_equal "#{@a.doc_dir}/ri",   @rdoc.ri_dir

    rdoc = Gem::RDoc.new @a, false, false

    refute rdoc.generate_rdoc
    refute rdoc.generate_ri
  end

  def test_delete_legacy_args
    args = %w[
      --inline-source
      --one-file
      --promiscuous
      -p
    ]

    @rdoc.delete_legacy_args args

    assert_empty args
  end

  def test_document
    skip 'RDoc 3+ required' unless rdoc_3?

    options = RDoc::Options.new
    options.files = []

    @rdoc.instance_variable_set :@rdoc, @rdoc.new_rdoc
    @rdoc.instance_variable_set :@file_info, []

    @rdoc.document 'darkfish', options, @rdoc.rdoc_dir

    assert @rdoc.rdoc_installed?
  end

  def test_generate
    skip 'RDoc 3+ required' unless rdoc_3?

    FileUtils.mkdir_p @a.doc_dir
    FileUtils.mkdir_p File.join(@a.gem_dir, 'lib')

    @rdoc.generate

    assert @rdoc.rdoc_installed?
    assert @rdoc.ri_installed?
  end

  def test_generate_disabled
    @rdoc.generate_rdoc = false
    @rdoc.generate_ri   = false

    @rdoc.generate

    refute @rdoc.rdoc_installed?
    refute @rdoc.ri_installed?
  end

  def test_generate_force
    skip 'RDoc 3+ required' unless rdoc_3?

    FileUtils.mkdir_p @rdoc.rdoc_dir
    FileUtils.mkdir_p @rdoc.ri_dir
    FileUtils.mkdir_p File.join(@a.gem_dir, 'lib')

    @rdoc.force = true

    @rdoc.generate

    assert_path_exists File.join(@rdoc.rdoc_dir, 'index.html')
    assert_path_exists File.join(@rdoc.ri_dir,   'cache.ri')
  end

  def test_generate_no_overwrite
    skip 'RDoc 3+ required' unless rdoc_3?

    FileUtils.mkdir_p @rdoc.rdoc_dir
    FileUtils.mkdir_p @rdoc.ri_dir
    FileUtils.mkdir_p File.join(@a.gem_dir, 'lib')

    @rdoc.generate

    refute_path_exists File.join(@rdoc.rdoc_dir, 'index.html')
    refute_path_exists File.join(@rdoc.ri_dir,   'created.rid')
  end

  def test_generate_legacy
    FileUtils.mkdir_p @a.doc_dir
    FileUtils.mkdir_p File.join(@a.gem_dir, 'lib')

    @rdoc.generate_legacy

    assert @rdoc.rdoc_installed?
    assert @rdoc.ri_installed?
  end

  def test_legacy_rdoc
    FileUtils.mkdir_p @a.doc_dir
    FileUtils.mkdir_p File.join(@a.gem_dir, 'lib')

    @rdoc.legacy_rdoc '--op', @rdoc.rdoc_dir

    assert @rdoc.rdoc_installed?
  end

  def test_new_rdoc
    assert_kind_of RDoc::RDoc, @rdoc.new_rdoc
  end

  def test_rdoc_installed?
    refute @rdoc.rdoc_installed?

    FileUtils.mkdir_p @rdoc.rdoc_dir

    assert @rdoc.rdoc_installed?
  end

  def test_remove
    FileUtils.mkdir_p @rdoc.rdoc_dir
    FileUtils.mkdir_p @rdoc.ri_dir

    @rdoc.remove

    refute @rdoc.rdoc_installed?
    refute @rdoc.ri_installed?
  end

  def test_remove_unwritable
    skip 'chmod not supported' if Gem.win_platform?
    FileUtils.mkdir_p @a.base_dir
    FileUtils.chmod 0, @a.base_dir

    e = assert_raises Gem::FilePermissionError do
      @rdoc.remove
    end

    assert_equal @a.base_dir, e.directory
  ensure
    FileUtils.chmod 0755, @a.base_dir
  end

  def test_ri_installed?
    refute @rdoc.ri_installed?

    FileUtils.mkdir_p @rdoc.ri_dir

    assert @rdoc.ri_installed?
  end

  def test_setup
    @rdoc.setup

    assert_path_exists @a.doc_dir
  end

  def test_setup_unwritable
    skip 'chmod not supported' if Gem.win_platform?
    FileUtils.mkdir_p @a.doc_dir
    FileUtils.chmod 0, @a.doc_dir

    e = assert_raises Gem::FilePermissionError do
      @rdoc.setup
    end

    assert_equal @a.doc_dir, e.directory
  ensure
    FileUtils.chmod 0755, @a.doc_dir
  end

end
