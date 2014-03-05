require 'spec_helper'

describe 'Completions Requests' do
  before do
    @task = Task.create(title: 'test')
  end

  describe 'POST /completions' do
    it 'responds with a json containing the completable object marked as completed' do
      post api_completions_path, {
        completion: {
          user_id: current_user.id,
          completable: { type: 'Task', id: @task.id }
        }
      }.to_json

      last_response.status.should eq(201)
      parsed_response = JSON.parse(last_response.body)

      parsed_response['completion']['completable']['task'].should include('completed' => true)
      parsed_response['completion']['user_id'].should eq(current_user.id)
    end

    it 'sends a notification to flowdock' do
      flow = double(:flow)
      ApplicationController.any_instance.stub(flow: flow)

      flow.should_receive(:push_to_team_inbox).with(
        subject: 'Completed Task',
        content: @task.title,
        tags: %w(task completed),
        link: 'https://notdvs.herokuapp.com/#/tasks'
      )

      post api_completions_path, {
        completion: {
          user_id: current_user.id,
          completable: { type: 'Task', id: @task.id }
        }
      }.to_json
    end
  end

  describe 'DELETE /completions' do
    it 'responds with a json containing the completable object marked as not completed' do
      Completion.create(completable: @task)
      delete api_completions_path, {
        completion: { completable: { type: 'Task', id: @task.id } }
      }.to_json

      last_response.status.should eq(200)
      parsed_response = JSON.parse(last_response.body)

      parsed_response['completion']['completable']['task'].should include('completed' => false)
    end

    it "responds with 404 if it can't find the completion" do
      delete api_completions_path, {
        completion: { completable: { type: 'Task', id: '98beb7fd-f051-4f94-8fb2-c30255de5fab' } }
      }.to_json

      last_response.status.should eq(404)
    end
  end
end
