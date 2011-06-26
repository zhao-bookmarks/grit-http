require 'spec_helper'

describe 'API' do
  it 'should allow only GET requests' do
    get '/'
    last_response.status.should == 400
    api_response(last_response.body, true)['error'] == GritHttp::Helpers::ERROR_API_KEY_REQUIRED
    
    post '/'
    last_response.status.should == 400
    api_response(last_response.body, true)['error'] == GritHttp::Helpers::ERROR_INVALID_REQUEST_METHOD
  end
  
  
  context 'without authentication' do    
    it 'returns error 400 if no API key were provided' do
      get '/'
      last_response.status.should == 400
    end
    
    it 'returns error 403 if provided API key is invalid' do
      get '/', :api_key => 'invalid key'
      last_response.status.should == 403
    end
  end
  
  context 'with authentication' do
    before :all do
      GritHttp.add_api_key('foobar')
    end
    
    it 'returns a current time at /' do
      get '/', :api_key => 'foobar'
      last_response.status.should == 200
      
      resp = api_response(last_response.body)
      resp.key?('time').should == true
    end
    
    it 'returns a pong message at /ping' do
      get '/ping', :api_key => 'foobar'
      last_response.status.should == 200
      
      resp = api_response(last_response.body)
      resp.key?('pong').should == true
    end
    
    it 'returns a list of software versions' do
      get '/versions', :api_key => 'foobar'
      last_response.status.should == 200
      
      resp = api_response(last_response.body)
      resp.key?('versions').should == true
      resp['versions'].should be_an_instance_of(Hash)
      resp['versions'].key?('git').should == true
      resp['versions'].key?('app').should == true
      resp['versions']['app'].should == GritHttp::VERSION
    end
  
    it 'returns a list of repositories at /repositories' do
      get '/repositories', :api_key => 'foobar'
      last_response.status.should == 200
      last_response.body.empty?.should == false
      
      resp = api_response(last_response.body)
      resp.should be_an_instance_of(Hash)
      resp.key?('repositories').should == true
      resp['repositories'].should be_an_instance_of(Array)
    end
    
    context 'for repository routes' do
      it 'returns error 400 if no repository were provided' do
        routes = %w(authors tags heads refs commits commits_stats commits_count commit commit/payload compare payload tree tree_history blob raw blame)
        
        routes.each do |path|
          get "/#{path}", :api_key => 'foobar'
          last_response.status.should == 400
        end
      end
      
      it 'returns error 404 if no repository were found' do
        routes = %w(authors tags heads refs commits commits_stats commits_count commit compare payload tree tree_history blob raw blame repo_capacity)
        
        routes.each do |path|
          get "/#{path}", :api_key => 'foobar', :repo => 'foobar'
          last_response.status.should == 404
        end
      end
    end
  end
end