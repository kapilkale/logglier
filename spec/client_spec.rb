require 'spec_helper'

describe Logglier::Client do

  context "#new" do

    context "w/o any params" do

      it "should raise an error" do
        expect { Logglier::Client.new() }.to raise_error Logglier::InputURLRequired
      end

    end

    context "with a single string param" do

      context "that is a valid http uri" do

        it "should return an instance of the proper client" do
          log = Logglier::Client.new('http://localhost')
          log.should be_an_instance_of Logglier::Client::HTTP
        end

      end

      context "that is a valid udp uri" do

        it "should return an instance of the proper client" do
          log = Logglier::Client.new('udp://logs.loggly.com:42538')
          log.should be_an_instance_of Logglier::Client::Syslog
        end
      end

      context "that is a valid tcp uri" do

        before do
          TCPSocket.stub(:new) { MockTCPSocket.new }
        end

        it "should return an instance of the proper client" do
          log = Logglier::Client.new('tcp://logs.loggly.com:42538')
          log.should be_an_instance_of Logglier::Client::Syslog
        end
      end

      context "valid url with a scheme not supported" do

        it "should raise an error" do
          expect { Logglier::Client.new('foo://bar:1234') }.to raise_error Logglier::UnsupportedScheme
        end
      end

      context "that is NOT a valid uri" do

        it "should raise an error" do
          expect { Logglier::Client.new('f://://://') }.to raise_error Logglier::InputURLRequired
        end

      end

    end

  end

  context "HTTPS" do
    context "#write" do
      context "with a simple text message" do
        it "should post a message" do
          log = Logglier::Client.new('https://localhost')
          log.http.stub(:request_post)
          log.http.should_receive(:request_post).with('','msg')
          log.write('msg')
        end
      end
    end

    context "message formatting methods" do
      subject { Logglier::Client.new('https://localhost') }

      it "should mash out hashes" do
        message = subject.massage_message({:foo => :bar},"WARN")
        message.should =~ /^severity=WARN,/
        message.should =~ /foo=bar/
      end

      it "should mash out nested hashes" do
        message = subject.massage_message({:foo => :bar, :bazzle => { :bom => :bastic } }, "WARN")
        message.should =~ /^severity=WARN,/
        message.should =~ /foo=bar/
        message.should =~ /bazzle\.bom=bastic/
      end

      it "should mash out deeply nested hashes" do
        message = subject.massage_message({:foo => :bar, :bazzle => { :bom => :bastic, :totally => { :freaking => :funny } } }, "WARN")
        message.should =~ /^severity=WARN,/
        message.should =~ /foo=bar/
        message.should =~ /bazzle\.bom=bastic/
        message.should =~ /bazzle\.totally\.freaking=funny/
      end

      it "should mash out deeply nested hashes, with an array" do
        message = subject.massage_message({:foo => :bar, :taste => ["this","sauce"], :bazzle => { :bom => :bastic, :totally => { :freaking => :funny } } }, "WARN")
        message.should =~ /^severity=WARN,/
        message.should =~ /foo=bar/
        message.should =~ /taste=\["this", "sauce"\]/
        message.should =~ /bazzle\.bom=bastic/
        message.should =~ /bazzle\.totally\.freaking=funny/
      end
    end
  end

  context "Syslog" do
    context "udp" do
      context "#write" do
        it "should send a message" do
          log = Logglier::Client.new('udp://localhost:12345')
          log.syslog.stub(:send)
          log.syslog.should_receive(:send).with('msg',0)
          log.write('msg')
        end
      end
    end

    context "tcp" do
      context "#write" do
        before { TCPSocket.stub(:new) { MockTCPSocket.new } }
        it "should send a message" do
          log = Logglier::Client.new('tcp://localhost:12345')
          log.syslog.stub(:send)
          log.syslog.should_receive(:send).with('msg',0)
          log.write('msg')
        end
      end
    end
  end

end
