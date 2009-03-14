require File.dirname(__FILE__) + '/../test_helper'

class AttachmentTest < ActiveSupport::TestCase
  
  require 'fileutils'

  def setup
    FileUtils.mkdir(Attachment.pwd) if !File.exists?(Attachment.pwd)
  end

  def teardown
    FileUtils.rm_rf(Attachment.pwd) if File.exists?(Attachment.pwd)
  end

  # Test if the actual file is created in the expected place
  def test_should_create_new_file
    attachment = Attachment.new("#{RAILS_ROOT}/public/images/rails.png", :node_id => '1')
    attachment.save
    assert File.exists?(Attachment.pwd + "/1/1.rails.png")
  end

  # Confirm that an attachment can be found by filename and node_id
  def test_should_find_file_by_file_name
    attachment = Attachment.new("#{RAILS_ROOT}/public/images/rails.png", :node_id => '1')
    attachment.save
    attachment = Attachment.find("rails.png", :conditions => {:node_id => 1})
    assert_equal "rails.png", attachment.filename
  end

  def test_should_create_new_file_from_file_io
    attachment = Attachment.new("rails.png", :node_id => '1')
    file_handle = File.new("#{RAILS_ROOT}/public/images/rails.png",'r')
    content = file_handle.read
    attachment << content
    attachment.save
    attachment_content = Attachment.find("rails.png", :conditions => {:node_id => 1}).read
    assert_equal content, attachment_content
  end
end