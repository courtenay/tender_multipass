require File.join(File.dirname(__FILE__), 'test_helper')

module Tender
  class TestUser < Struct.new(:email, :name)
    include Tender::MultiPassMethods
  end

  class DefaultOptionUser < TestUser
    tender_multipass do |user|
      {:bar => 'foo'}
    end
  end

  MultiPass.site_key       = "abc"
  MultiPass.support_domain = "help.xoo.com"
  MultiPass.cookie_domain  = ".xoo.com"

  class TestCookieJar < Hash
    attr_reader :deleted_keys

    def delete(key, opts = {})
      @deleted_keys ||= {}
      @deleted_keys[key] = opts
    end
  end
end

class Test::Unit::TestCase
  def assert_cookie(cookie, expected)
    assert_equal expected, cookie
  end
end

class TenderMultipassTest < Test::Unit::TestCase
  def setup
    @user    = Tender::TestUser.new("seaguy@hero.com", "Joe Seaguy")
    @cookies = Tender::TestCookieJar.new 
    @user.tender_multipass(@cookies, 1234)
  end

  def test_tender_email_cookie_is_set
    assert_cookie @cookies[:tender_email], { :value => @user.email, :domain => Tender::MultiPass.cookie_domain }
  end

  def test_tender_expires_cookie_is_set
    assert_cookie @cookies[:tender_expires], { :value => "1234", :domain => Tender::MultiPass.cookie_domain }
  end
  
  def test_tender_name_not_required
    @user = Tender::TestUser.new("seaguy@hero.com")
    @user.tender_multipass(@cookies, { :expires => 1234 })
    assert_nil @cookies[:tender_name]
  end

end

class TenderExpireTest < Test::Unit::TestCase
  def setup
    @user    = Tender::TestUser.new("seaguy@hero.com", "Sea Guy")
    @cookies = Tender::TestCookieJar.new 
    @user.tender_multipass(@cookies, { :expires => 1234, :name_field => :name })
    @user.tender_expire(@cookies)
  end

  def test_tender_email_cookie_is_cleared
    assert_cookie @cookies.deleted_keys[:tender_email], :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_expires_cookie_is_cleared
    assert_cookie @cookies.deleted_keys[:tender_expires], :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_hash_cookie_is_eaten
    assert_cookie @cookies.deleted_keys[:tender_hash], :domain => Tender::MultiPass.cookie_domain
  end
  
  def test_tender_name_cookie_is_eaten
    assert_cookie @cookies.deleted_keys[:tender_name], :domain => Tender::MultiPass.cookie_domain
  end
end

class TenderMultipassWithOptionsTest < Test::Unit::TestCase
  def setup
    @user    = Tender::TestUser.new("seaguy@hero.com")
    @cookies = Tender::TestCookieJar.new 
    @user.tender_multipass(@cookies, :expires => 1234, :foo => 'bar')
  end

  def test_custom_tender_cookie_is_set
    assert_cookie @cookies[:tender_foo], :value => 'bar', :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_email_cookie_is_set
    assert_cookie @cookies[:tender_email], :value => @user.email, :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_expires_cookie_is_set
    assert_cookie @cookies[:tender_expires], :value => "1234", :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_hash_cookie_is_set
    digest = OpenSSL::Digest::Digest.new("SHA1")
    hash   = OpenSSL::HMAC.hexdigest(digest, Tender::MultiPass.site_key, "#{Tender::MultiPass.support_domain}/#{@user.email}/1234")
    assert_cookie @cookies[:tender_email], :value => @user.email, :domain => Tender::MultiPass.cookie_domain
  end
end

class TenderMultipassWithDefaultOptionsTest < Test::Unit::TestCase
  def setup
    @user    = Tender::DefaultOptionUser.new("seaguy@hero.com")
    @cookies = Tender::TestCookieJar.new 
    @user.tender_multipass(@cookies, :expires => 1234)
  end

  def test_default_tender_cookie_is_set
    assert_cookie @cookies[:tender_bar], :value => 'foo', :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_email_cookie_is_set
    assert_cookie @cookies[:tender_email], :value => @user.email, :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_expires_cookie_is_set
    assert_cookie @cookies[:tender_expires], :value => "1234", :domain => Tender::MultiPass.cookie_domain
  end
  
  def test_tender_hash_cookie_is_set
    digest = OpenSSL::Digest::Digest.new("SHA1")
    hash   = OpenSSL::HMAC.hexdigest(digest, Tender::MultiPass.site_key, "#{Tender::MultiPass.support_domain}/#{@user.email}/1234")
    assert_equal({ :value => hash, :domain => Tender::MultiPass.cookie_domain },      @cookies[:tender_hash])
  end
  
end

class TenderMultipassWithNameTest < Test::Unit::TestCase
  def setup
    @user    = Tender::TestUser.new("seaguy@hero.com", "Sea Guy")
    @cookies = Tender::TestCookieJar.new 
    @user.tender_multipass(@cookies, :expires => 1234, :name_field => :name)
  end

  def test_tender_name_is_set
    assert_equal({ :value => "Sea Guy", :domain => Tender::MultiPass.cookie_domain }, @cookies[:tender_name])
  end

  def test_tender_hash_cookie_is_set
    digest = OpenSSL::Digest::Digest.new("SHA1")
    hash   = OpenSSL::HMAC.hexdigest(digest, Tender::MultiPass.site_key, "#{Tender::MultiPass.support_domain}/#{@user.email}/1234/Sea Guy")
    assert_equal({ :value => hash, :domain => Tender::MultiPass.cookie_domain },      @cookies[:tender_hash])
  end
end
