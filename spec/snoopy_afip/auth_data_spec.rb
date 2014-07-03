require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "AuthData" do
  it "should create constants for todays data" do
    Snoopy::AuthData.fetch
    if RUBY_VERSION >= "1.9"
      Snoopy.constants.should include(:TOKEN, :SIGN)
    else
      Snoopy.constants.should include("TOKEN", "SIGN")
    end
  end
end
