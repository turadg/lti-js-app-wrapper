require 'ims/lti'
# must include the oauth proxy object
require 'oauth/request_proxy/rack_request'

# the consumer keys/secrets for this demo
$oauth_creds = {"test" => "secret", "testing" => "supersecret"}

# based on https://github.com/instructure/lti_tool_provider_example/blob/master/tool_provider.rb
class DemoController < ApplicationController

  # disable CSRF for POSTs from LTI Consumer
  protect_from_forgery with: :null_session

  def index
  end

  def show_error(message)
    @message = message
  end

  def authorize!
    if key = params['oauth_consumer_key']
      if secret = $oauth_creds[key]
        @tp = IMS::LTI::ToolProvider.new(key, secret, params)
      else
        @tp = IMS::LTI::ToolProvider.new(nil, nil, params)
        @tp.lti_msg = "Your consumer didn't use a recognized key."
        @tp.lti_errorlog = "You did it wrong!"
        show_error "Consumer key wasn't recognized"
        return false
      end
    else
      show_error "No consumer key"
      return false
    end

    if !@tp.valid_request?(request)
      show_error "The OAuth signature was invalid"
      return false
    end

    if Time.now.utc.to_i - @tp.request_oauth_timestamp.to_i > 60*60
      show_error "Your request is too old."
      return false
    end

    # this isn't actually checking anything like it should, just want people
    # implementing real tools to be aware they need to check the nonce
    if was_nonce_used_in_last_x_minutes?(@tp.request_oauth_nonce, 60)
      show_error "Why are you reusing the nonce?"
      return false
    end

    @username = @tp.username("Dude")

    return true
  end

  def launch
    return render :error unless authorize!

    if @tp.outcome_service?
      # It's a launch for grading
      render :assessment
    else
      # normal tool launch without grade write-back
      signature = OAuth::Signature.build(request, :consumer_secret => @tp.consumer_secret)

      @signature_base_string = signature.signature_base_string
      @secret = signature.send(:secret)

      @tp.lti_msg = "Sorry that tool was so boring"
      render :boring_tool
    end
  end


  def test_signature
    render :proxy_setup
  end

  def proxy_launch
    uri = URI.parse(params.require(:launch_url))

    if uri.port == uri.default_port
      host = uri.host
    else
      host = "#{uri.host}:#{uri.port}"
    end

    consumer = OAuth::Consumer.new(
      params.require(:lti)['oauth_consumer_key'],
      params.require(:oauth_consumer_secret), {
        :site => "#{uri.scheme}://#{host}",
        :signature_method => "HMAC-SHA1"
      })

    path = uri.path
    path = '/' if path.empty?

    @lti_params = params.require('lti').clone
    if uri.query != nil
      CGI.parse(uri.query).each do |query_key, query_values|
        unless @lti_params[query_key]
          @lti_params[query_key] = query_values.first
        end
      end
    end

    path = uri.path
    path = '/' if path.empty?

    proxied_request = consumer.send(:create_http_request, :post, path, @lti_params)
    signature = OAuth::Signature.build(
      proxied_request,
      :uri => params.require(:launch_url),
      :consumer_secret => params.require(:oauth_consumer_secret)
      )

    @signature_base_string = signature.signature_base_string
    @secret = signature.send(:secret)
    @oauth_signature = signature.signature

    render :proxy_launch
  end

  # post the assessment results
  def assessment
    launch_params = params.require(:launch_params)
    if launch_params
      key = launch_params['oauth_consumer_key']
    else
      show_error "The tool never launched"
      return render :error
    end

    @tp = IMS::LTI::ToolProvider.new(key, $oauth_creds[key], launch_params)

    if !@tp.outcome_service?
      show_error "This tool wasn't lunched as an outcome service"
      return render :error
    end

    # post the given score to the TC
    score = (params['score'] != '' ? params['score'] : nil)
    res = @tp.post_replace_result!(params['score'])

    if res.success?
      @score = params['score']
      @tp.lti_msg = "Message shown when arriving back at Tool Consumer."
      render :assessment_finished
    else
      @tp.lti_errormsg = "The Tool Consumer failed to add the score."
      show_error "Your score was not recorded: #{res.description}"
      return render :error
    end
  end

  def show_config
    host = request.scheme + "://" + request.host_with_port
    url = (params['signature_proxy_test'] ? host + "/demo/test_signature" : host + "/demo/launch")
    tc = IMS::LTI::ToolConfig.new(:title => "Example ims-lti gem Tool Provider", :launch_url => url)
    tc.description = "This example LTI Tool Provider supports LIS Outcome pass-back."

    render xml: tc.to_xml(:indent => 2)
  end

  def was_nonce_used_in_last_x_minutes?(nonce, minutes=60)
    # some kind of caching solution or something to keep a short-term memory of used nonces
    false
  end


end
