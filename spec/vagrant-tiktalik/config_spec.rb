require "vagrant-tiktalik/config"

describe VagrantPlugins::Tiktalik::Config do
  let(:instance) { described_class.new }

  # Ensure tests are not affected by Tiktalik credential environment variables
  before :each do
    ENV.stub(:[] => nil)
  end

  puts "config_spec"

  describe "defaults" do
    subject do
      instance.tap do |o|
        o.finalize!
      end
    end

    its("api_key")     { should be_nil }
    its("image")               { should be_nil }
    #its("availability_zone") { should be_nil }
    #its("instance_ready_timeout") { should == 120 }
    #its("instance_type")     { should == "m1.small" }
    #its("keypair_name")      { should be_nil }
    #its("private_ip_address") { should be_nil }
    #its("region")            { should == "us-east-1" }
    its("api_secret") { should be_nil }
    #its("security_groups")   { should == [] }
    #its("subnet_id")         { should be_nil }
    #its("tags")              { should == {} }
    #its("user_data")         { should be_nil }
    #its("use_iam_profile")   { should be_false }
    #its("block_device_mapping")  {should == {} }
  end

  describe "overriding defaults" do
    # I typically don't meta-program in tests, but this is a very
    # simple boilerplate test, so I cut corners here. It just sets
    # each of these attributes to "foo" in isolation, and reads the value
    # and asserts the proper result comes back out.
    #[:api_key, :ami, :availability_zone, :instance_ready_timeout,
    #  :instance_type, :keypair_name,
    #  :region, :api_secret, :security_groups,
    #  :subnet_id, :tags,
    #  :use_iam_profile, :user_data, :block_device_mapping].each do |attribute|
    [:api_key, :api_secret, :image].each do |attribute|
      it "should not default #{attribute} if overridden" do
        instance.send("#{attribute}=".to_sym, "foo")
        instance.finalize!
        instance.send(attribute).should == "foo"
      end
    end
  end

  #describe "getting credentials from environment" do
  #  context "without EC2 credential environment variables" do
  #    subject do
  #      instance.tap do |o|
  #        o.finalize!
  #      end
  #    end
  #
  #    its("api_key")     { should be_nil }
  #    its("api_secret") { should be_nil }
  #  end
  #
  #  context "with EC2 credential environment variables" do
  #    before :each do
  #      ENV.stub(:[]).with("AWS_ACCESS_KEY").and_return("access_key")
  #      ENV.stub(:[]).with("AWS_SECRET_KEY").and_return("secret_key")
  #    end
  #
  #    subject do
  #      instance.tap do |o|
  #        o.finalize!
  #      end
  #    end
  #
  #    its("api_key")     { should == "access_key" }
  #    its("api_secret") { should == "secret_key" }
  #  end
  #end

  describe "region config" do
    let(:config_api_key)     { "foo" }
    let(:config_ami)               { "foo" }
    let(:config_instance_type)     { "foo" }
    let(:config_keypair_name)      { "foo" }
    let(:config_region)            { "foo" }
    let(:config_api_secret) { "foo" }

    def set_test_values(instance)
      instance.api_key     = config_api_key
      instance.ami               = config_ami
      instance.instance_type     = config_instance_type
      instance.keypair_name      = config_keypair_name
      instance.region            = config_region
      instance.api_secret = config_api_secret
    end

    it "should raise an exception if not finalized" do
      expect { instance.get_region_config("us-east-1") }.
        to raise_error
    end

    context "with no specific config set" do
      subject do
        # Set the values on the top-level object
        set_test_values(instance)

        # Finalize so we can get the region config
        instance.finalize!

        # Get a lower level region
        instance.get_region_config("us-east-1")
      end

      its("api_key")     { should == config_api_key }
      its("ami")               { should == config_ami }
      its("instance_type")     { should == config_instance_type }
      its("keypair_name")      { should == config_keypair_name }
      its("region")            { should == config_region }
      its("api_secret") { should == config_api_secret }
    end

    context "with a specific config set" do
      let(:region_name) { "hashi-region" }

      subject do
        # Set the values on a specific region
        instance.region_config region_name do |config|
          set_test_values(config)
        end

        # Finalize so we can get the region config
        instance.finalize!

        # Get the region
        instance.get_region_config(region_name)
      end

      its("api_key")     { should == config_api_key }
      its("ami")               { should == config_ami }
      its("instance_type")     { should == config_instance_type }
      its("keypair_name")      { should == config_keypair_name }
      its("region")            { should == region_name }
      its("api_secret") { should == config_api_secret }
    end

    describe "inheritance of parent config" do
      let(:region_name) { "hashi-region" }

      subject do
        # Set the values on a specific region
        instance.region_config region_name do |config|
          config.ami = "child"
        end

        # Set some top-level values
        instance.api_key = "parent"
        instance.ami = "parent"

        # Finalize and get the region
        instance.finalize!
        instance.get_region_config(region_name)
      end

      its("api_key") { should == "parent" }
      its("ami")           { should == "child" }
    end

    describe "shortcut configuration" do
      subject do
        # Use the shortcut configuration to set some values
        instance.region_config "us-east-1", :ami => "child"
        instance.finalize!
        instance.get_region_config("us-east-1")
      end

      its("ami") { should == "child" }
    end

    describe "merging" do
      let(:first)  { described_class.new }
      let(:second) { described_class.new }

      it "should merge the tags" do
        first.tags["one"] = "one"
        second.tags["two"] = "two"

        third = first.merge(second)
        third.tags.should == {
          "one" => "one",
          "two" => "two"
        }
      end
    end
  end
end
